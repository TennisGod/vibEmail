import Foundation
import GoogleSignIn

class GmailAPIService {
    static let shared = GmailAPIService()
    
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me"
    
    // MARK: - Email Fetching
    
    func fetchEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=in:inbox"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No inbox messages found")
            return []
        }
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
    
    func fetchSentEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=in:sent"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No sent messages found")
            return []
        }
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
    
    func fetchArchivedEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=in:all"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No archived messages found")
            return []
        }
        
        // Fetch detailed information for each message and filter for archived
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                // Filter for archived emails (not in inbox, sent, or trash)
                if !email.labels.contains("INBOX") && !email.labels.contains("SENT") && !email.labels.contains("TRASH") {
                    emails.append(email)
                }
            }
        }
        
        return emails
    }
    
    func fetchStarredEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=is:starred"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No starred messages found")
            return []
        }
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
    
    func fetchUnreadEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=is:unread"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No unread messages found")
            return []
        }
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
    
    func fetchTrashEmails(maxResults: Int = 20) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "\(baseURL)/messages?maxResults=\(maxResults)&q=in:trash"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No trash messages found")
            return []
        }
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
    
    func fetchEmailDetails(messageId: String) async throws -> Email? {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        let accessToken = user.accessToken.tokenString
        
        let urlString = "\(baseURL)/messages/\(messageId)?format=full"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailAPIError.networkError
        }
        
        let messageResponse = try JSONDecoder().decode(GmailMessageResponse.self, from: data)
        return parseGmailMessage(messageResponse)
    }
    
    private func parseGmailMessage(_ gmailMessage: GmailMessageResponse) -> Email? {
        let headers = gmailMessage.payload.headers
        
        let subject = headers.first { $0.name.lowercased() == "subject" }?.value ?? "No Subject"
        let from = headers.first { $0.name.lowercased() == "from" }?.value ?? "Unknown Sender"
        let to = headers.first { $0.name.lowercased() == "to" }?.value ?? "Unknown Recipient"
        let dateString = headers.first { $0.name.lowercased() == "date" }?.value ?? ""
        
        // Debug: Print the actual date string from Gmail
        print("📧 Gmail Date String: \(dateString) for message: \(gmailMessage.id)")
        print("📧 Gmail Internal Date: \(gmailMessage.internalDate ?? "nil") for message: \(gmailMessage.id)")
        
        // Parse sender information
        let senderName = extractNameFromEmailString(from)
        let senderEmail = extractEmailFromString(from)
        
        // Parse recipients
        let recipients = to.components(separatedBy: ",").map { extractEmailFromString($0.trimmingCharacters(in: .whitespaces)) }
        
        // Enhanced timestamp parsing with multiple fallbacks
        let timestamp = parseEmailTimestamp(
            internalDate: gmailMessage.internalDate, 
            dateHeader: dateString, 
            messageId: gmailMessage.id
        )
        
        // Extract content
        let content = extractContent(from: gmailMessage.payload)
        
        // Determine if email is read
        let isRead = !gmailMessage.labelIds.contains("UNREAD")
        
        // Determine if email is starred
        let isStarred = gmailMessage.labelIds.contains("STARRED")
        
        // Determine if email is in trash
        let isTrash = gmailMessage.labelIds.contains("TRASH")
        
        // Determine if email is archived (not in INBOX but not in TRASH)
        let isArchived = !gmailMessage.labelIds.contains("INBOX") && !isTrash
        
        // Determine if email is sent (has SENT label)
        let isSent = gmailMessage.labelIds.contains("SENT")
        
        // Enhanced label processing for better categorization
        var processedLabels = gmailMessage.labelIds
        
        print("📧 Original Gmail labels for \(gmailMessage.id): \(gmailMessage.labelIds)")
        
        // Add derived labels for better filtering
        if isRead {
            processedLabels.append("READ")
        } else {
            processedLabels.append("UNREAD")
        }
        
        if isStarred {
            processedLabels.append("STARRED")
        }
        
        if isTrash {
            processedLabels.append("TRASH")
        }
        
        if isArchived {
            processedLabels.append("ARCHIVED")
        }
        
        if isSent {
            processedLabels.append("SENT")
        }
        
        // Remove duplicates while preserving order
        processedLabels = Array(Set(processedLabels))
        
        print("📧 Processed labels for \(gmailMessage.id): \(processedLabels)")
        
        return Email(
            subject: subject,
            sender: senderName,
            senderEmail: senderEmail,
            recipients: recipients,
            content: content,
            timestamp: timestamp,
            isRead: isRead,
            isStarred: isStarred,
            isTrash: isTrash,
            isArchived: isArchived,
            priority: .medium, // Will be determined by AI later
            requiresAction: false, // Will be determined by AI later
            messageId: gmailMessage.id, // Store the Gmail message ID
            threadId: gmailMessage.threadId,
            labels: processedLabels, // Use processed labels with derived categories
            senderProfileImageURL: nil, // Will be populated later by ProfileImageService
            version: 1,
            lastModified: timestamp,
            syncStatus: .synced
        )
    }
    
    // MARK: - Enhanced Timestamp Parsing with Multiple Fallbacks

    private var timestampCache: [String: Date] = [:]

    private func parseEmailTimestamp(internalDate: String?, dateHeader: String, messageId: String) -> Date {
        // Check cache first using messageId as key
        if let cachedDate = timestampCache[messageId] {
            print("📅 Using cached timestamp for message: \(messageId)")
            return cachedDate
        }
        
        var timestamp: Date?
        
        // Priority 1: Use Gmail's internalDate (most reliable)
        if let internalDate = internalDate, !internalDate.isEmpty {
            // Gmail internalDate is in milliseconds since epoch
            if let milliseconds = Int64(internalDate) {
                timestamp = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
                print("📅 Parsed timestamp from internalDate for message: \(messageId) - \(timestamp!)")
            }
        }
        
        // Priority 2: Fallback to Date header parsing
        if timestamp == nil {
            print("⚠️ internalDate not available, falling back to Date header parsing for message: \(messageId)")
            timestamp = parseEmailDate(dateHeader)
            if let ts = timestamp {
                print("📅 Parsed timestamp from Date header for message: \(messageId) - \(ts)")
            }
        }
        
        // Priority 3: Emergency fallback - use a date far in the past to indicate parsing failure
        // This prevents emails from showing "0 seconds ago"
        if timestamp == nil {
            print("❌ All timestamp parsing failed for message: \(messageId), using fallback date")
            // Use January 1, 2020 as emergency fallback so it's obvious something went wrong
            // but doesn't show as "0 seconds ago"
            timestamp = Date(timeIntervalSince1970: 1577836800) // January 1, 2020
        }
        
        // Cache the result
        let finalTimestamp = timestamp!
        timestampCache[messageId] = finalTimestamp
        
        return finalTimestamp
    }
    
    private func extractNameFromEmailString(_ emailString: String) -> String {
        // Handle format: "John Doe <john.doe@example.com>"
        if let range = emailString.range(of: "<") {
            let name = emailString[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? "Unknown" : name
        }
        return "Unknown"
    }
    
    private func extractEmailFromString(_ emailString: String) -> String {
        // Handle format: "John Doe <john.doe@example.com>"
        if let startRange = emailString.range(of: "<"),
           let endRange = emailString.range(of: ">") {
            return String(emailString[startRange.upperBound..<endRange.lowerBound])
        }
        return emailString.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractContent(from payload: GmailPayload) -> String {
        // Try to get text content from payload
        if let body = payload.body, let data = body.data {
            return decodeBase64(base64String: data) ?? ""
        }
        
        // If no body, try parts
        if let parts = payload.parts {
            for part in parts {
                if part.mimeType == "text/plain" {
                    if let data = part.body?.data {
                        return decodeBase64(base64String: data) ?? ""
                    }
                }
            }
        }
        
        return ""
    }
    
    private func decodeBase64(base64String: String) -> String? {
        guard let data = Data(base64Encoded: base64String.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private func parseEmailDate(_ dateString: String) -> Date? {
        // Common Gmail date formats
        let dateFormats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",           // "Mon, 15 Jan 2024 10:30:00 +0000"
            "EEE, dd MMM yyyy HH:mm:ss zzz",         // "Mon, 15 Jan 2024 10:30:00 GMT"
            "dd MMM yyyy HH:mm:ss Z",                // "15 Jan 2024 10:30:00 +0000"
            "EEE, dd MMM yyyy HH:mm Z",              // "Mon, 15 Jan 2024 10:30 +0000"
            "dd MMM yyyy HH:mm Z",                   // "15 Jan 2024 10:30 +0000"
            "EEE MMM dd HH:mm:ss yyyy",              // "Mon Jan 15 10:30:00 2024"
            "EEE, dd MMM yyyy HH:mm:ss",             // "Mon, 15 Jan 2024 10:30:00"
            "dd MMM yyyy HH:mm:ss",                  // "15 Jan 2024 10:30:00"
            "yyyy-MM-dd'T'HH:mm:ssZ",                // "2024-01-15T10:30:00Z"
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",            // "2024-01-15T10:30:00.000Z"
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",          // "2024-01-15T10:30:00.000Z"
            "yyyy-MM-dd'T'HH:mm:ss'Z'",              // "2024-01-15T10:30:00Z"
            "yyyy-MM-dd'T'HH:mm:ss",                 // "2024-01-15T10:30:00"
            "yyyy-MM-dd HH:mm:ss",                   // "2024-01-15 10:30:00"
            "MMM dd, yyyy HH:mm:ss",                 // "Jan 15, 2024 10:30:00"
            "MMM dd yyyy HH:mm:ss",                  // "Jan 15 2024 10:30:00"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        // Try RFC 2822 format as fallback
        let rfc2822Formatter = DateFormatter()
        rfc2822Formatter.locale = Locale(identifier: "en_US_POSIX")
        rfc2822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        
        // Handle various timezone formats
        let timezoneFormats = ["GMT", "UTC", "EST", "EDT", "CST", "CDT", "MST", "MDT", "PST", "PDT"]
        for timezone in timezoneFormats {
            let modifiedDateString = dateString.replacingOccurrences(of: timezone, with: "+0000")
            if let date = rfc2822Formatter.date(from: modifiedDateString) {
                return date
            }
        }
        
        // Handle UTC format with parentheses: "Fri, 18 Jul 2025 22:33:48 +0000 (UTC)"
        if dateString.contains("(UTC)") {
            let cleanedDateString = dateString.replacingOccurrences(of: " (UTC)", with: "")
            if let date = rfc2822Formatter.date(from: cleanedDateString) {
                return date
            }
        }
        
        // Final fallback: try to parse with ISO8601DateFormatter
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        print("⚠️ Failed to parse date: \(dateString)")
        return nil
    }
    
    // MARK: - Email Actions
    
    func markAsRead(_ messageId: String) async throws -> Bool {
        return try await modifyLabels(messageId: messageId, addLabelIds: [], removeLabelIds: ["UNREAD"])
    }
    
    func markAsUnread(_ messageId: String) async throws -> Bool {
        return try await modifyLabels(messageId: messageId, addLabelIds: ["UNREAD"], removeLabelIds: [])
    }
    
    func starEmail(_ messageId: String) async throws -> Bool {
        return try await modifyLabels(messageId: messageId, addLabelIds: ["STARRED"], removeLabelIds: [])
    }
    
    func unstarEmail(_ messageId: String) async throws -> Bool {
        return try await modifyLabels(messageId: messageId, addLabelIds: [], removeLabelIds: ["STARRED"])
    }
    
    func deleteEmail(_ messageId: String) async throws -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        let accessToken = user.accessToken.tokenString
        
        let urlString = "\(baseURL)/messages/\(messageId)/trash"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailAPIError.networkError
        }
        
        return true
    }
    
    func archiveEmail(_ messageId: String) async throws -> Bool {
        // Archive by removing the INBOX label
        return try await modifyLabels(messageId: messageId, addLabelIds: [], removeLabelIds: ["INBOX"])
    }
    
    func unarchiveEmail(_ messageId: String) async throws -> Bool {
        // Unarchive by adding the INBOX label back
        return try await modifyLabels(messageId: messageId, addLabelIds: ["INBOX"], removeLabelIds: [])
    }
    
    func untrashEmail(_ messageId: String) async throws -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        let accessToken = user.accessToken.tokenString
        
        let urlString = "\(baseURL)/messages/\(messageId)/untrash"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailAPIError.networkError
        }
        
        return true
    }
    
    private func modifyLabels(messageId: String, addLabelIds: [String], removeLabelIds: [String]) async throws -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        let accessToken = user.accessToken.tokenString
        
        let urlString = "\(baseURL)/messages/\(messageId)/modify"
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GmailModifyLabelsRequest(addLabelIds: addLabelIds, removeLabelIds: removeLabelIds)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailAPIError.networkError
        }
        
        return true
    }
    
    // MARK: - Recent Changes Fetching
    
    // MARK: - Recent Changes Fetching (FIXED VERSION)

    func fetchRecentChanges(since date: Date) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        
        // FIX: Use Unix timestamp format that Gmail understands
        let unixTimestamp = Int(date.timeIntervalSince1970)
        
        // Debug logging
        print("🔍 fetchRecentChanges:")
        print("   Input date: \(date)")
        print("   Unix timestamp: \(unixTimestamp)")
        
        // Query using Unix timestamp (Gmail accepts this format)
        let query = "after:\(unixTimestamp)"
        print("   Gmail query: \(query)")
        
        let urlString = "\(baseURL)/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&maxResults=50"
        print("   Full URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        print("   Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No new messages found since \(date) (timestamp: \(unixTimestamp))")
            return []
        }
        
        print("📧 Found \(messages.count) messages since \(date)")
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        print("✅ Fetched \(emails.count) recent emails since \(date)")
        return emails
    }

    // Alternative implementation using date format (if Unix timestamp doesn't work)
    func fetchRecentChangesAlternative(since date: Date) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Alternative: Use date format that Gmail understands (yyyy/MM/dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC") // or TimeZone.current depending on your needs
        let dateString = dateFormatter.string(from: date)
        
        print("🔍 fetchRecentChanges (Alternative):")
        print("   Input date: \(date)")
        print("   Formatted date: \(dateString)")
        
        // Query using date format
        let query = "after:\(dateString)"
        print("   Gmail query: \(query)")
        
        let urlString = "\(baseURL)/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&maxResults=50"
        print("   Full URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        print("   Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No new messages found since \(dateString)")
            return []
        }
        
        print("📧 Found \(messages.count) messages since \(dateString)")
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        print("✅ Fetched \(emails.count) recent emails since \(dateString)")
        return emails
    }

    // Most robust implementation using relative time
    func fetchRecentChangesRelative(hoursAgo: Int = 24) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Use Gmail's relative time format (newer_than:Xh for hours, Xd for days)
        let query = "newer_than:\(hoursAgo)h"
        
        print("🔍 fetchRecentChanges (Relative):")
        print("   Fetching emails from last \(hoursAgo) hours")
        print("   Gmail query: \(query)")
        
        let urlString = "\(baseURL)/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&maxResults=50"
        print("   Full URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailAPIError.networkError
        }
        
        print("   Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        // Handle case where no messages are returned
        guard let messages = messagesResponse.messages else {
            print("📧 No new messages found in last \(hoursAgo) hours")
            return []
        }
        
        print("📧 Found \(messages.count) messages from last \(hoursAgo) hours")
        
        // Fetch detailed information for each message
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        print("✅ Fetched \(emails.count) recent emails from last \(hoursAgo) hours")
        return emails
    }
    // MARK: - Comprehensive Email Fetching
    
    func fetchAllEmailsForRefresh(maxResults: Int = 100) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        print("🔄 Fetching all emails for refresh")
        
        let accessToken = user.accessToken.tokenString
        
        // Fetch from multiple categories to ensure we get everything
        var allEmails: [Email] = []
        
        // Fetch inbox
        let inboxQuery = "in:inbox"
        allEmails.append(contentsOf: try await fetchEmailsWithQuery(query: inboxQuery, maxResults: 50, accessToken: accessToken))
        
        // Fetch sent
        let sentQuery = "in:sent"
        allEmails.append(contentsOf: try await fetchEmailsWithQuery(query: sentQuery, maxResults: 30, accessToken: accessToken))
        
        // Fetch starred
        let starredQuery = "is:starred"
        allEmails.append(contentsOf: try await fetchEmailsWithQuery(query: starredQuery, maxResults: 20, accessToken: accessToken))
        
        // Remove duplicates based on messageId
        var uniqueEmails: [String: Email] = [:]
        for email in allEmails {
            let key = email.messageId ?? email.id
            if let existing = uniqueEmails[key] {
                // Keep the one with more labels (more complete)
                if email.labels.count > existing.labels.count {
                    uniqueEmails[key] = email
                }
            } else {
                uniqueEmails[key] = email
            }
        }
        
        let result = Array(uniqueEmails.values).sorted { $0.timestamp > $1.timestamp }
        print("✅ Fetched \(result.count) unique emails for refresh")
        return result
    }
    
    private func fetchEmailsWithQuery(query: String, maxResults: Int, accessToken: String) async throws -> [Email] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/messages?q=\(encodedQuery)&maxResults=\(maxResults)"
        
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Increased timeout to 60 seconds
        request.cachePolicy = .reloadIgnoringLocalCacheData // Force fresh data
        
        print("📧 Making request to: \(urlString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GmailAPIError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorString)")
                }
                throw GmailAPIError.networkError
            }
            
            let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
            
            // Handle case where no messages are returned
            guard let messages = messagesResponse.messages else {
                print("📧 No messages found for query: \(query)")
                return []
            }
            
            print("📧 Received \(messages.count) messages for query: \(query)")
            
            var emails: [Email] = []
            for message in messages {
                if let email = try await fetchEmailDetails(messageId: message.id) {
                    emails.append(email)
                }
            }
            
            print("📧 Successfully fetched \(emails.count) emails for query: \(query)")
            return emails
            
        } catch let urlError as URLError {
            if urlError.code == .cancelled {
                print("⚠️ Request was cancelled for query: \(query)")
                throw urlError
            } else {
                print("❌ Network error for query \(query): \(urlError)")
                throw GmailAPIError.networkError
            }
        } catch {
            print("❌ Unexpected error for query \(query): \(error)")
            throw error
        }
    }
    
    func fetchRecentEmails(hoursAgo: Int = 2) async throws -> [Email] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GmailAPIError.notAuthenticated
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Use Gmail's relative time format - this is the industry standard approach
        let query = "newer_than:\(hoursAgo)h"
        
        print("📧 Fetching emails from last \(hoursAgo) hours")
        
        let urlString = "\(baseURL)/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&maxResults=50"
        
        guard let url = URL(string: urlString) else {
            throw GmailAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailAPIError.networkError
        }
        
        let messagesResponse = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)
        
        guard let messages = messagesResponse.messages else {
            print("📧 No new messages in last \(hoursAgo) hours")
            return []
        }
        
        print("📧 Found \(messages.count) messages from last \(hoursAgo) hours")
        
        var emails: [Email] = []
        for message in messages {
            if let email = try await fetchEmailDetails(messageId: message.id) {
                emails.append(email)
            }
        }
        
        return emails
    }
}

// MARK: - Error Types

enum GmailAPIError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case networkError
    case decodingError
    case insufficientPermissions
    case rateLimitExceeded
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Gmail"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

// MARK: - Gmail API Response Models

struct GmailMessagesResponse: Codable {
    let messages: [GmailMessageSummary]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?
}

struct GmailMessageSummary: Codable {
    let id: String
    let threadId: String
}

struct GmailMessageResponse: Codable {
    let id: String
    let threadId: String
    let labelIds: [String]
    let payload: GmailPayload
    let internalDate: String? // Gmail's internal timestamp (milliseconds since epoch)
}

struct GmailPayload: Codable {
    let headers: [GmailHeader]
    let body: GmailBody?
    let parts: [GmailPayload]?
    let mimeType: String?
}

struct GmailHeader: Codable {
    let name: String
    let value: String
}

struct GmailBody: Codable {
    let data: String?
    let size: Int?
}

struct GmailModifyLabelsRequest: Codable {
    let addLabelIds: [String]
    let removeLabelIds: [String]
} 
