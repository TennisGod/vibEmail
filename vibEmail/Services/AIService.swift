import Foundation

class AIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Load API key from environment or configuration
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
            self.apiKey = key
        } else if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            self.apiKey = key
        } else {
            // For demo purposes, disable AI features if no key provided
            self.apiKey = ""
            print("⚠️ No OpenAI API key configured. AI features will be simulated.")
        }
    }
    
    // MARK: - Email Analysis
    
    func analyzePriority(_ email: Email) async -> EmailPriority {
        do {
            let prompt = createPriorityAnalysisPrompt(for: email)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 50)
            return parsePriorityResponse(response)
        } catch {
            print("❌ OpenAI API Error: \(error)")
            print("🔄 Using local fallback analysis...")
            return fallbackPriorityAnalysis(email)
        }
    }
    
    func analyzeSentiment(_ email: Email) async -> String {
        do {
            let prompt = createSentimentAnalysisPrompt(for: email)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 20)
            return parseSentimentResponse(response)
        } catch {
            print("Error analyzing sentiment: \(error)")
            return fallbackSentimentAnalysis(email)
        }
    }
    
    func classifyEmail(_ email: Email) async -> [String] {
        do {
            let prompt = createClassificationPrompt(for: email)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 100)
            return parseClassificationResponse(response)
        } catch {
            print("Error classifying email: \(error)")
            return fallbackEmailClassification(email)
        }
    }
    
    func determineActionRequired(_ email: Email) async -> EmailAction? {
        do {
            let prompt = createActionAnalysisPrompt(for: email)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 20)
            return parseActionResponse(response)
        } catch {
            print("Error determining action: \(error)")
            return fallbackActionAnalysis(email)
        }
    }
    
    // MARK: - Content Generation
    
    func generateReply(for email: Email, tone: EmailTone) async -> String {
        do {
            let prompt = createReplyGenerationPrompt(for: email, tone: tone)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 300)
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            print("Error generating reply: \(error)")
            return fallbackReplyGeneration(for: email, tone: tone)
        }
    }
    
    func generateForward(for email: Email, tone: EmailTone) async -> String {
        do {
            let prompt = createForwardGenerationPrompt(for: email, tone: tone)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 300)
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            print("Error generating forward: \(error)")
            return fallbackForwardGeneration(for: email, tone: tone)
        }
    }
    
    func generateEmailFromPrompt(_ prompt: String, tone: EmailTone) async -> String {
        do {
            let aiPrompt = createEmailFromPromptGenerationPrompt(userPrompt: prompt, tone: tone)
            let response = try await callOpenAI(prompt: aiPrompt, maxTokens: 400)
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            print("Error generating email from prompt: \(error)")
            return fallbackEmailFromPromptGeneration(prompt: prompt, tone: tone)
        }
    }
    
    func generateTextResponse(_ prompt: String, maxTokens: Int = 300) async throws -> String {
        do {
            let response = try await callOpenAI(prompt: prompt, maxTokens: maxTokens)
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            // For missing API key, return helpful message instead of throwing
            if apiKey.isEmpty {
                return "I'd be happy to help! However, AI features require an OpenAI API key to be configured. You can still use all the core email features like organizing, filtering, and managing your emails."
            }
            // For other errors, still throw
            throw error
        }
    }
    
    // MARK: - Custom Filter Generation
    
    func generateCustomFilter(for userRequest: String, emails: [Email]) async -> CustomFilterResult {
        do {
            let prompt = createCustomFilterPrompt(userRequest: userRequest, emails: emails)
            let response = try await callOpenAI(prompt: prompt, maxTokens: 300)
            return parseCustomFilterResponse(response)
        } catch {
            print("Error generating custom filter: \(error)")
            return fallbackCustomFilterGeneration(for: userRequest, emails: emails)
        }
    }
    
    // MARK: - Improved Prompt Creation Methods
    
    private func createPriorityAnalysisPrompt(for email: Email) -> String {
        let currentTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let currentTimeString = dateFormatter.string(from: currentTime)
        
        return """
        Analyze this email's priority for immediate response. Current time: \(currentTimeString)
        
        Email Details:
        From: \(email.sender) <\(email.senderEmail)>
        Subject: \(email.subject)
        Received: \(dateFormatter.string(from: email.timestamp))
        Content: \(email.content)
        Has Attachments: \(email.attachments.isEmpty ? "No" : "Yes")
        Is Reply: \(email.suggestedAction == .reply ? "Yes" : "No")
        Thread Count: \(email.threadId != nil ? "1" : "0")
        
        PRIORITY RULES (in order of importance):
        
        1. URGENT (Respond within 2 hours):
           - System outages, security incidents, data breaches
           - Emergency meetings or crisis situations
           - Time-critical business decisions with deadlines TODAY
           - Direct requests from CEO/C-suite with urgent language
           - Critical client escalations
           - Keywords WITH business context: "urgent", "emergency", "critical", "immediately", "ASAP"
           
        2. HIGH (Respond same day):
           - Direct requests from your manager or key stakeholders
           - Important client communications requiring response
           - Meeting requests for this week
           - Project deliverables due within 48 hours
           - Action items assigned directly to you
           - Questions blocking others' work
           
        3. MEDIUM (Respond within 24-48 hours):
           - Regular work updates requiring feedback
           - Non-urgent project discussions
           - Meeting requests for next week or later
           - General questions from colleagues
           - FYI emails that may need acknowledgment
           - Social emails (congratulations, thank you notes)
           
        4. LOW (Respond within 3-5 days or archive):
           - Marketing/promotional emails (even with "urgent" language)
           - Newsletters and digest emails
           - Automated notifications
           - CC'd emails where you're not the primary recipient
           - Mass emails to large distribution lists
           
        5. UPDATE (No response needed):
           - System notifications
           - Automated status updates
           - Information-only announcements
           - Read receipts
           
        CRITICAL DISTINCTIONS:
        - Marketing emails are ALWAYS LOW priority, regardless of urgency language
        - Being CC'd usually reduces priority by one level
        - Thread count > 5 often indicates ongoing discussion (less urgent)
        - Weekend/after-hours emails are less urgent unless explicitly stated
        
        Analyze the email and respond with ONLY one word: URGENT, HIGH, MEDIUM, LOW, or UPDATE
        """
    }
    
    private func createSentimentAnalysisPrompt(for email: Email) -> String {
        return """
        Analyze the emotional tone and sentiment of this email:
        
        Subject: \(email.subject)
        Content: \(email.content)
        
        Consider:
        - Overall emotional tone
        - Level of frustration or satisfaction
        - Urgency of language
        - Professional vs emotional language
        
        Categories:
        - POSITIVE: Appreciative, satisfied, congratulatory, enthusiastic
        - NEGATIVE: Frustrated, disappointed, complaining, critical
        - CRITICAL: Angry, urgent issues, escalations, threats
        - NEUTRAL: Professional, factual, balanced, informational
        
        Respond with ONLY one word: POSITIVE, NEGATIVE, CRITICAL, or NEUTRAL
        """
    }
    
    private func createClassificationPrompt(for email: Email) -> String {
        return """
        Classify this email into 1-3 most relevant categories:
        
        From: \(email.sender)
        Subject: \(email.subject)
        Content: \(email.content)
        
        Categories:
        - Meeting: Invitations, scheduling, agenda, minutes
        - Project: Updates, tasks, milestones, deliverables
        - Finance: Invoices, budgets, expenses, payments
        - Support: Help requests, issues, troubleshooting
        - Newsletter: Digests, announcements, regular updates
        - Social: Personal messages, celebrations, casual chat
        - Marketing: Promotions, sales, product announcements
        - System: Automated alerts, notifications, receipts
        - HR: Personnel matters, policies, benefits
        - Client: Customer communications, external requests
        
        Respond with ONLY category names separated by commas (e.g., "Project, Client")
        """
    }
    
    // MARK: - Missing Helper Functions
    
    private func createReplyGenerationPrompt(for email: Email, tone: EmailTone) -> String {
        return """
        Generate a professional email reply to this message with a \(tone.rawValue) tone:
        
        Original Email:
        From: \(email.sender)
        Subject: \(email.subject)
        Content: \(email.content)
        
        Tone: \(tone.description)
        
        Guidelines:
        - Keep it concise and professional
        - Address the main points from the original email
        - Match the requested tone
        - Include appropriate greeting and closing
        - Be helpful and constructive
        
        Generate only the reply content (no subject line):
        """
    }
    
    private func createForwardGenerationPrompt(for email: Email, tone: EmailTone) -> String {
        return """
        Generate a professional email forward for this message with a \(tone.rawValue) tone:
        
        Original Email:
        From: \(email.sender)
        Subject: \(email.subject)
        Content: \(email.content)
        
        Tone: \(tone.description)
        
        Guidelines:
        - Add a brief introduction explaining why you're forwarding
        - Keep the original content intact
        - Match the requested tone
        - Include appropriate greeting and closing
        
        Generate only the forward content (no subject line):
        """
    }
    
    private func createEmailFromPromptGenerationPrompt(userPrompt: String, tone: EmailTone) -> String {
        return """
        Generate a professional email based on this request with a \(tone.rawValue) tone:
        
        User Request: \(userPrompt)
        Tone: \(tone.description)
        
        Guidelines:
        - Create a complete email (subject and body)
        - Match the requested tone
        - Be professional and appropriate
        - Include appropriate greeting and closing
        - Make it actionable and clear
        
        Generate the complete email:
        """
    }
    
    private func createCustomFilterPrompt(userRequest: String, emails: [Email]) -> String {
        let emailSamples = emails.prefix(20).map { email in
            """
            Subject: \(email.subject)
            From: \(email.sender) <\(email.senderEmail)>
            Content: \(String(email.content.prefix(200)))
            Labels: \(email.labels.joined(separator: ", "))
            Priority: \(email.priority.rawValue)
            Is Starred: \(email.isStarred)
            Is Read: \(email.isRead)
            """
        }.joined(separator: "\n\n")
        
        return """
        You are an expert email filtering assistant. Analyze the user's request and the provided email samples to create an intelligent Gmail query filter.
        
        User Request: "\(userRequest)"
        
        Email Samples (showing patterns in the user's inbox):
        \(emailSamples)
        
        TASK: Create a Gmail query filter that will find emails matching the user's request.
        
        Gmail Query Syntax Rules:
        - subject: searches email subjects
        - from: searches sender email addresses
        - to: searches recipient addresses
        - has: searches for specific attributes (attachment, priority, etc.)
        - label: searches for specific labels
        - is: searches for read/unread, starred, etc.
        - Use OR for multiple conditions
        - Use AND for combined conditions
        - Use quotes for exact phrases
        - Use parentheses for grouping
        
        Examples:
        - subject:(meeting OR calendar) OR from:(boss@company.com)
        - from:(amazon.com OR ebay.com) OR subject:(order OR receipt)
        - has:attachment AND subject:(report OR document)
        - is:unread AND (subject:urgent OR subject:important)
        
        RESPONSE FORMAT:
        Title: [Smart, descriptive title for the filter]
        Query: [Gmail query string]
        Description: [Brief explanation of what this filter finds]
        Confidence: [0.0-1.0 score indicating how confident you are in this filter]
        
        Guidelines:
        1. Analyze the email samples to understand patterns
        2. Look for common senders, subjects, or content patterns
        3. Create a query that will be effective for the user's specific request
        4. Use appropriate Gmail syntax
        5. Make the title descriptive and user-friendly
        6. Provide a clear description of what the filter will find
        
        Generate the filter:
        """
    }
    
    private func createActionAnalysisPrompt(for email: Email) -> String {
        return """
        Determine the primary action required for this email:
        
        Subject: \(email.subject)
        Content: \(email.content)
        
        Action Types:
        - REPLY: Direct questions asked, response requested, feedback needed
        - FORWARD: Explicitly asks to share, wrong recipient, needs others' input
        - ARCHIVE: Informational only, no action needed, for reference
        - DELETE: Spam, irrelevant, duplicate, expired content
        - NONE: No clear action required
        
        Look for:
        - Question marks indicating queries
        - Phrases like "please respond", "let me know", "your thoughts?"
        - Requests to share or forward
        - Pure FYI or informational content
        
        Respond with ONLY one word: REPLY, FORWARD, ARCHIVE, DELETE, or NONE
        """
    }
    
    // MARK: - Enhanced Response Parsing Methods
    
    private func parsePriorityResponse(_ response: String) -> EmailPriority {
        let cleanResponse = response.uppercased()
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .first ?? ""
        
        switch cleanResponse {
        case "URGENT":
            return .urgent
        case "HIGH":
            return .high
        case "MEDIUM":
            return .medium
        case "LOW":
            return .low
        case "UPDATE":
            return .update
        default:
            print("Unexpected priority response: '\(response)'")
            return .medium
        }
    }
    
    private func parseSentimentResponse(_ response: String) -> String {
        let cleanResponse = response.uppercased()
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .first ?? ""
        
        switch cleanResponse {
        case "POSITIVE":
            return "Positive"
        case "NEGATIVE":
            return "Negative"
        case "CRITICAL":
            return "Critical"
        case "NEUTRAL":
            return "Neutral"
        default:
            print("Unexpected sentiment response: '\(response)'")
            return "Neutral"
        }
    }
    
    private func parseClassificationResponse(_ response: String) -> [String] {
        let cleanResponse = response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let categories = cleanResponse.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return categories.isEmpty ? ["General"] : categories
    }
    
    private func parseActionResponse(_ response: String) -> EmailAction? {
        let cleanResponse = response.uppercased()
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .first ?? ""
        
        switch cleanResponse {
        case "REPLY":
            return .reply
        case "FORWARD":
            return .forward
        case "ARCHIVE":
            return .archive
        case "DELETE":
            return .delete
        case "NONE":
            return nil
        default:
            print("Unexpected action response: '\(response)'")
            return nil
        }
    }
    
    private func parseCustomFilterResponse(_ response: String) -> CustomFilterResult {
        let lines = response.components(separatedBy: .newlines)
        var title = "Custom Filter"
        var query = ""
        var description = "AI-generated filter based on your request"
        var confidence = 0.7
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("Title:") {
                title = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Query:") {
                query = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Description:") {
                description = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("Confidence:") {
                let confidenceStr = String(trimmed.dropFirst(11)).trimmingCharacters(in: .whitespacesAndNewlines)
                confidence = Double(confidenceStr) ?? 0.7
            }
        }
        
        // Fallback if no query was found
        if query.isEmpty {
            query = "subject:(custom) OR from:(custom)"
        }
        
        return CustomFilterResult(
            title: title,
            query: query,
            description: description,
            confidence: confidence
        )
    }
    
    // MARK: - AI Response Simulation (for demo when no API key)
    
    private func simulateAIResponse(for prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        
        // Priority analysis simulation
        if lowercasePrompt.contains("priority") || lowercasePrompt.contains("analyze email") {
            if lowercasePrompt.contains("urgent") || lowercasePrompt.contains("immediate") {
                return "urgent"
            } else if lowercasePrompt.contains("important") || lowercasePrompt.contains("asap") {
                return "high" 
            } else if lowercasePrompt.contains("spam") || lowercasePrompt.contains("marketing") {
                return "low"
            } else {
                return "medium"
            }
        }
        
        // Action analysis simulation
        if lowercasePrompt.contains("action required") || lowercasePrompt.contains("determine action") {
            if lowercasePrompt.contains("question") || lowercasePrompt.contains("?") {
                return "reply"
            } else if lowercasePrompt.contains("meeting") || lowercasePrompt.contains("schedule") {
                return "schedule"
            } else if lowercasePrompt.contains("document") || lowercasePrompt.contains("attachment") {
                return "review"
            } else {
                return "none"
            }
        }
        
        // Email generation simulation
        if lowercasePrompt.contains("reply") || lowercasePrompt.contains("respond") {
            return "Thank you for your email. I'll review this and get back to you soon."
        }
        
        if lowercasePrompt.contains("forward") {
            return "Please see the email below that may be of interest to you."
        }
        
        // Custom filter simulation
        if lowercasePrompt.contains("filter") || lowercasePrompt.contains("query") {
            return "from:important OR has:attachment"
        }
        
        // Default fallback
        return "Simulated AI response (OpenAI API key not configured)"
    }
    
    // MARK: - OpenAI API Call with Retry Logic
    
    private func callOpenAI(prompt: String, maxTokens: Int, retries: Int = 2) async throws -> String {
        // Return simulated response if no API key configured
        guard !apiKey.isEmpty else {
            return simulateAIResponse(for: prompt)
        }
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        // Try different models in order of preference
        let models = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview"]
        
        for model in models {
            do {
                // Debug: Print request details
                print("🔍 OpenAI API Request:")
                print("   URL: \(baseURL)")
                print("   Model: \(model)")
                print("   Max Tokens: \(maxTokens)")
                print("   API Key: \(String(apiKey.prefix(10)))...")
                
                let requestBody = OpenAIRequest(
                    model: model,
                    messages: [
                        Message(role: "system", content: "You are an expert email prioritization assistant. You analyze emails and provide accurate, concise responses following the exact format requested. You understand business context and can distinguish between genuine urgency and marketing tactics."),
                        Message(role: "user", content: prompt)
                    ],
                    max_tokens: maxTokens,
                    temperature: 0.1 // Lower temperature for more consistent results
                )
        
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(requestBody)
                request.timeoutInterval = 30.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIError.apiError("Invalid response type")
                }
                
                if httpResponse.statusCode == 200 {
                    let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    print("✅ OpenAI API Success with model: \(model)")
                    return openAIResponse.choices.first?.message.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
                } else {
                    // Debug: Print error response
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("❌ OpenAI API Error Response for model \(model): \(errorData)")
                    }
                    print("❌ HTTP Status for model \(model): \(httpResponse.statusCode)")
                    
                    // If it's a 404, try the next model
                    if httpResponse.statusCode == 404 {
                        print("🔄 Model \(model) not found, trying next model...")
                        continue
                    }
                    
                    // For other errors, throw immediately
                    throw AIError.apiError("HTTP \(httpResponse.statusCode) for model \(model)")
                }
                
            } catch {
                print("❌ Error with model \(model): \(error)")
                // Continue to next model
                continue
            }
        }
        
        // If all models failed, throw error
        throw AIError.apiError("All OpenAI models failed")
    }
    
    // MARK: - Enhanced Fallback Methods
    
    private func fallbackPriorityAnalysis(_ email: Email) -> EmailPriority {
        print("🔄 FALLBACK ANALYSIS STARTING for: '\(email.subject)' from '\(email.sender)'")
        
        // Create normalized versions for analysis
        let content = normalizeText(email.content)
        let subject = normalizeText(email.subject)
        let sender = normalizeText(email.sender)
        let senderEmail = email.senderEmail.lowercased()
        
        // Special case: "Immediate Response Required" in subject is always urgent
        if subject.contains("immediate response required") {
            print("🚨 Fallback: Immediate Response Required detected - marking as URGENT")
            return .urgent
        }
        
        // Domain-based sender categorization
        let senderDomain = extractDomain(from: senderEmail)
        
        // Enhanced marketing detection
        print("🔍 Checking if '\(email.subject)' is marketing email...")
        if isMarketingEmail(subject: subject, content: content, sender: sender,
                           senderEmail: senderEmail, domain: senderDomain) {
            print("📧 Marketing email detected early - returning LOW priority")
            return .low
        }
        print("✅ Not a marketing email - continuing analysis")
        
        // System/automated email detection
        if isSystemEmail(sender: sender, senderEmail: senderEmail, subject: subject) {
            return .update
        }
        
        // Calculate urgency score
        var urgencyScore = 0.0
        
        // Meeting detection - high priority for meeting requests
        if subject.lowercased().contains("meeting") || 
           subject.lowercased().contains("schedule") ||
           content.lowercased().contains("setup a meeting") ||
           content.lowercased().contains("schedule a meeting") ||
           content.lowercased().contains("meeting request") ||
           content.lowercased().contains("discuss") ||
           content.lowercased().contains("collaboration") ||
           content.lowercased().contains("availability") {
            urgencyScore += 3.5
            print("📅 Meeting detected: '\(email.subject)' - adding high urgency score")
        }
        
        // Time-based urgency
        urgencyScore += calculateTimeUrgency(content: content, subject: subject)
        
        // Sender importance
        urgencyScore += calculateSenderImportance(sender: sender, senderEmail: senderEmail,
                                                domain: senderDomain, email: email)
        
        // Content urgency
        urgencyScore += calculateContentUrgency(content: content, subject: subject)
        
        // Work collaboration detection
        let collaborationKeywords = ["collaboration", "project", "work together", "partnership", "team up"]
        for keyword in collaborationKeywords {
            if content.lowercased().contains(keyword) {
                urgencyScore += 1.0
                print("🤝 Collaboration detected: '\(keyword)' in '\(email.subject)' - adding urgency score")
                break
            }
        }
        
        // Social/personal event detection
        let socialKeywords = ["game", "party", "dinner", "lunch", "coffee", "drinks", "hang out", 
                             "get together", "celebration", "birthday", "anniversary", "wedding",
                             "concert", "movie", "event", "invitation", "rsvp", "let me know if you want"]
        for keyword in socialKeywords {
            if content.lowercased().contains(keyword) || subject.lowercased().contains(keyword) {
                urgencyScore += 2.5
                print("🎉 Social event detected: '\(keyword)' in '\(email.subject)' - adding high urgency score")
                break
            }
        }
        
        // Action requirements
        urgencyScore += calculateActionUrgency(content: content)
        
        // Marketing email penalty - strong negative score
        if isMarketingEmail(subject: subject, content: content, sender: sender,
                           senderEmail: senderEmail, domain: senderDomain) {
            urgencyScore -= 3.0
            print("📧 Marketing email detected: '\(email.subject)' - applying strong penalty")
        } else {
            print("📧 Not a marketing email: '\(email.subject)' - no penalty applied")
        }
        
        // Thread context
        if email.suggestedAction == .reply && email.threadId != nil {
            urgencyScore -= 0.5 // Ongoing discussions are usually less urgent
        }
        
        // Convert score to priority
        let priority: EmailPriority
        if urgencyScore >= 4.0 {
            priority = .urgent
        } else if urgencyScore >= 3.0 {
            priority = .high
        } else if urgencyScore >= 1.5 {
            priority = .medium
        } else {
            priority = .low
        }
        
        print("📊 Fallback Analysis: '\(email.subject)' - Final Score: \(urgencyScore) -> \(priority.rawValue)")
        print("📊 Breakdown: Base(0.0) + Time(\(calculateTimeUrgency(content: content, subject: subject))) + Sender(\(calculateSenderImportance(sender: sender, senderEmail: senderEmail, domain: senderDomain, email: email))) + Content(\(calculateContentUrgency(content: content, subject: subject))) + Action(\(calculateActionUrgency(content: content)))")
        return priority
    }
    
    // MARK: - Helper Methods for Fallback Analysis
    
    private func normalizeText(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func extractDomain(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.count > 1 ? components[1].lowercased() : ""
    }
    
    private func isMarketingEmail(subject: String, content: String, sender: String,
                                 senderEmail: String, domain: String) -> Bool {
        // Comprehensive marketing indicators
        let marketingPatterns = [
            // Promotional language
            "limited time", "act now", "don't miss", "exclusive offer", "special deal",
            "save now", "% off", "discount code", "free shipping", "buy now",
            "flash sale", "ends soon", "hurry", "last chance", "today only",
            "score some savings", "shop now", "order today", "this week's deals", "up to",
            "off select", "valid online only", "while quantities last", "check out these picks",
            
            // Newsletter patterns
            "unsubscribe", "email preferences", "opt out", "mailing list",
            "newsletter", "weekly digest", "monthly update", "promotional email",
            
            // Marketing sender patterns
            "noreply", "no-reply", "donotreply", "marketing@", "sales@",
            "promotions@", "deals@", "offers@", "news@", "updates@", "dsg@e.dcsg.com"
        ]
        
        let marketingDomains = [
            "mailchimp.com", "constantcontact.com", "sendgrid.net", "amazonses.com",
            "sparkpost.com", "mailgun.org", "sendinblue.com", "e.dcsg.com",
            "dcsg.com"
        ]
        
        // Check patterns
        for pattern in marketingPatterns {
            if subject.contains(pattern) || content.contains(pattern) ||
               senderEmail.contains(pattern) {
                return true
            }
        }
        
        // Check domains
        for marketingDomain in marketingDomains {
            if domain.contains(marketingDomain) || senderEmail.contains(marketingDomain) {
                return true
            }
        }
        
        // Check for tracking pixels (common in marketing emails)
        if content.contains("pixel.gif") || content.contains("track.php") ||
           content.contains("click.php") {
            return true
        }
        
        return false
    }
    
    private func isSystemEmail(sender: String, senderEmail: String, subject: String) -> Bool {
        let systemPatterns = [
            "system", "automated", "notification", "alert@", "notify@",
            "daemon", "postmaster", "mailer-daemon", "auto-confirm"
        ]
        
        for pattern in systemPatterns {
            if sender.contains(pattern) || senderEmail.contains(pattern) {
                return true
            }
        }
        
        // Check for common system email subjects
        let systemSubjects = [
            "backup complete", "report generated", "sync complete",
            "update available", "maintenance notice"
        ]
        
        for systemSubject in systemSubjects {
            if subject.contains(systemSubject) {
                return true
            }
        }
        
        return false
    }
    
    private func calculateTimeUrgency(content: String, subject: String) -> Double {
        var score = 0.0
        let combined = "\(subject) \(content)"
        
        // Immediate urgency indicators
        let immediatePatterns = [
            "right now", "immediately", "urgent", "emergency", "asap",
            "within the hour", "by end of day", "by eod", "before you leave"
        ]
        
        for pattern in immediatePatterns {
            if combined.contains(pattern) {
                score += 1.5
                break
            }
        }
        
        // Today indicators
        let todayPatterns = ["today", "this afternoon", "this morning", "tonight"]
        for pattern in todayPatterns {
            if combined.contains(pattern) {
                score += 1.0
                break
            }
        }
        
        // This week indicators
        let weekPatterns = ["this week", "by friday", "by thursday", "next few days"]
        for pattern in weekPatterns {
            if combined.contains(pattern) {
                score += 0.5
                break
            }
        }
        
        return score
    }
    
    private func calculateSenderImportance(sender: String, senderEmail: String,
                                         domain: String, email: Email) -> Double {
        var score = 0.0
        
        // Executive indicators
        let executiveTitles = ["ceo", "cto", "cfo", "president", "vp", "director", "chief"]
        for title in executiveTitles {
            if sender.contains(title) || senderEmail.contains(title) {
                score += 2.0
                break
            }
        }
        
        // Personal contact indicators (friends, family)
        let personalNames = ["bryan", "sun", "bearlytrying"] // Add common personal contacts
        for name in personalNames {
            if sender.lowercased().contains(name) || senderEmail.lowercased().contains(name) {
                score += 1.5
                print("👤 Personal contact detected: '\(name)' in sender '\(sender)' - adding importance score")
                break
            }
        }
        
        // Direct communication (not CC'd)
        // Check if email is to a small group (likely direct communication)
        if email.recipients.count <= 3 {
            score += 0.5
        }
        
        // Small recipient list (more targeted)
        if email.recipients.count < 3 {
            score += 0.5
        }
        
        // Same domain (internal email)
        // This would need to be configured with your company domain
        // if domain == "yourcompany.com" {
        //     score += 0.5
        // }
        
        return score
    }
    
    private func calculateContentUrgency(content: String, subject: String) -> Double {
        var score = 0.0
        let combined = "\(subject) \(content)"
        
        // Critical business terms
        let criticalTerms = [
            "contract", "deal", "proposal", "deadline", "deliverable",
            "escalation", "outage", "down", "not working", "broken",
            "security", "breach", "compliance", "audit", "legal"
        ]
        
        for term in criticalTerms {
            if combined.contains(term) {
                score += 0.5
            }
        }
        
        // Question indicators (need response)
        let questionCount = combined.components(separatedBy: "?").count - 1
        if questionCount > 0 {
            score += Double(min(questionCount, 3)) * 0.3
        }
        
        return score
    }
    
    private func calculateActionUrgency(content: String) -> Double {
        var score = 0.0
        
        // Direct action requests
        let actionPhrases = [
            "please respond", "please reply", "let me know", "need your",
            "waiting for", "blocked on", "can you", "could you",
            "please review", "please approve", "sign off"
        ]
        
        for phrase in actionPhrases {
            if content.contains(phrase) {
                score += 0.5
            }
        }
        
        return min(score, 1.5) // Cap contribution
    }
    
    private func fallbackSentimentAnalysis(_ email: Email) -> String {
        let content = email.content.lowercased()
        var positiveScore = 0
        var negativeScore = 0
        
        // Positive indicators
        let positiveWords = [
            "thank", "thanks", "appreciate", "great", "excellent", "wonderful",
            "perfect", "amazing", "fantastic", "love", "excited", "happy",
            "pleased", "delighted", "congratulations", "well done"
        ]
        
        // Negative indicators
        let negativeWords = [
            "problem", "issue", "concern", "disappointed", "frustrated", "angry",
            "unacceptable", "terrible", "horrible", "complaint", "fail", "error",
            "mistake", "wrong", "broken", "bug", "crash"
        ]
        
        // Critical indicators
        let criticalWords = [
            "urgent", "emergency", "critical", "severe", "immediate", "escalate",
            "unacceptable", "lawsuit", "legal action", "breach"
        ]
        
        // Count occurrences
        for word in positiveWords {
            if content.contains(word) {
                positiveScore += 1
            }
        }
        
        for word in negativeWords {
            if content.contains(word) {
                negativeScore += 1
            }
        }
        
        // Check for critical situations first
        for word in criticalWords {
            if content.contains(word) && negativeScore > 0 {
                return "Critical"
            }
        }
        
        // Determine sentiment
        if positiveScore > negativeScore * 2 {
            return "Positive"
        } else if negativeScore > positiveScore * 2 {
            return "Negative"
        } else {
            return "Neutral"
        }
    }
    
    private func fallbackEmailClassification(_ email: Email) -> [String] {
        var labels: [String] = []
        let content = email.content.lowercased()
        let subject = email.subject.lowercased()
        let combined = "\(subject) \(content)"
        
        // Meeting indicators
        if combined.contains("meeting") || combined.contains("schedule") ||
           combined.contains("calendar") || combined.contains("invite") ||
           combined.contains("conference") || combined.contains("call") ||
           combined.contains("setup a meeting") || combined.contains("discuss") ||
           combined.contains("collaboration") || combined.contains("availability") {
            labels.append("Meeting")
        }
        
        // Project indicators
        if combined.contains("project") || combined.contains("milestone") ||
           combined.contains("deliverable") || combined.contains("sprint") ||
           combined.contains("task") || combined.contains("jira") {
            labels.append("Project")
        }
        
        // Finance indicators
        if combined.contains("invoice") || combined.contains("payment") ||
           combined.contains("budget") || combined.contains("expense") ||
           combined.contains("purchase") || combined.contains("cost") {
            labels.append("Finance")
        }
        
        // Support indicators
        if combined.contains("support") || combined.contains("help") ||
           combined.contains("issue") || combined.contains("problem") ||
           combined.contains("ticket") || combined.contains("troubleshoot") {
            labels.append("Support")
        }
        
        // Client indicators
        if combined.contains("client") || combined.contains("customer") ||
           combined.contains("account") || email.senderEmail.contains("external") {
            labels.append("Client")
        }
        
        // HR indicators
        if combined.contains("hr") || combined.contains("human resources") ||
           combined.contains("benefits") || combined.contains("policy") ||
           combined.contains("leave") || combined.contains("vacation") {
            labels.append("HR")
        }
        
        // Newsletter indicators
        if combined.contains("newsletter") || combined.contains("digest") ||
           combined.contains("update") || combined.contains("announcement") {
            labels.append("Newsletter")
        }
        
        // Marketing indicators
        if combined.contains("marketing") || combined.contains("campaign") ||
           combined.contains("promotion") || combined.contains("sale") {
            labels.append("Marketing")
        }
        
        // Social/Personal indicators
        if combined.contains("game") || combined.contains("party") || combined.contains("dinner") ||
           combined.contains("lunch") || combined.contains("coffee") || combined.contains("drinks") ||
           combined.contains("hang out") || combined.contains("get together") || combined.contains("invitation") {
            labels.append("Social")
        }
        
        return labels.isEmpty ? ["General"] : Array(labels.prefix(3))
    }
    
    private func fallbackActionAnalysis(_ email: Email) -> EmailAction? {
        let content = email.content.lowercased()
        let subject = email.subject.lowercased()
        
        // Check for reply indicators
        let replyIndicators = [
            "please reply", "please respond", "let me know", "your thoughts",
            "feedback", "opinion", "what do you think", "can you confirm",
            "please advise", "waiting for your", "need your input",
            "rsvp", "please answer", "reply by"
        ]
        
        for indicator in replyIndicators {
            if content.contains(indicator) || subject.contains(indicator) {
                return .reply
            }
        }
        
        // Check for questions
        if content.contains("?") && email.suggestedAction != .reply {
            return .reply
        }
        
        // Check for forward indicators
        let forwardIndicators = [
            "please forward", "share with", "pass along", "distribute",
            "send to", "loop in", "add", "include"
        ]
        
        for indicator in forwardIndicators {
            if content.contains(indicator) {
                return .forward
            }
        }
        
        // Check for delete indicators
        if isMarketingEmail(subject: subject, content: content, sender: email.sender.lowercased(),
                           senderEmail: email.senderEmail.lowercased(),
                           domain: extractDomain(from: email.senderEmail)) {
            return .delete
        }
        
        // Check for archive indicators
        if content.contains("fyi") || content.contains("for your information") ||
           content.contains("no action needed") || content.contains("informational") {
            return .archive
        }
        
        return nil
    }
    
    // Keep existing generation methods...
    private func fallbackReplyGeneration(for email: Email, tone: EmailTone) -> String {
        let baseReply = generateBaseReply(for: email)
        return applyTone(to: baseReply, tone: tone)
    }
    
    private func fallbackForwardGeneration(for email: Email, tone: EmailTone) -> String {
        let baseForward = generateBaseForward(for: email)
        return applyTone(to: baseForward, tone: tone)
    }
    
    private func fallbackEmailFromPromptGeneration(prompt: String, tone: EmailTone) -> String {
        let baseEmail = generateBaseEmailFromPrompt(prompt)
        return applyTone(to: baseEmail, tone: tone)
    }
    
    private func fallbackCustomFilterGeneration(for userRequest: String, emails: [Email]) -> CustomFilterResult {
        let lowercased = userRequest.lowercased()
        
        // Analyze email patterns for better fallback
        let commonSenders = extractCommonSenders(from: emails)
        let commonSubjects = extractCommonSubjects(from: emails)
        
        // Generate smart title
        let title = generateSmartTitle(from: userRequest)
        
        // Generate query based on patterns
        var query = ""
        if lowercased.contains("purchase") || lowercased.contains("order") || lowercased.contains("receipt") {
            query = "subject:(purchase OR order OR receipt OR confirmation) OR from:(amazon.com OR ebay.com OR etsy.com)"
        } else if lowercased.contains("boss") || lowercased.contains("manager") {
            query = "from:(boss@company.com OR manager@company.com)"
        } else if lowercased.contains("important") || lowercased.contains("urgent") {
            query = "subject:(urgent OR important OR priority) OR has:priority"
        } else if lowercased.contains("work") || lowercased.contains("project") {
            query = "subject:(project OR work OR meeting) OR from:(work.com OR company.com)"
        } else {
            // Use common patterns from the user's emails
            let subjectTerms = commonSubjects.prefix(3).joined(separator: " OR ")
            let senderTerms = commonSenders.prefix(3).joined(separator: " OR ")
            query = "subject:(\(subjectTerms)) OR from:(\(senderTerms))"
        }
        
        return CustomFilterResult(
            title: title,
            query: query,
            description: "Fallback filter based on your request and email patterns",
            confidence: 0.6
        )
    }
    
    private func extractCommonSenders(from emails: [Email]) -> [String] {
        let senderCounts = emails.reduce(into: [String: Int]()) { counts, email in
            let domain = extractDomain(from: email.senderEmail)
            counts[domain, default: 0] += 1
        }
        
        return senderCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func extractCommonSubjects(from emails: [Email]) -> [String] {
        let words = emails.flatMap { email in
            email.subject.components(separatedBy: .whitespacesAndNewlines)
                .map { $0.lowercased() }
                .filter { $0.count > 3 } // Only meaningful words
        }
        
        let wordCounts = words.reduce(into: [String: Int]()) { counts, word in
            counts[word, default: 0] += 1
        }
        
        return wordCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func generateSmartTitle(from userRequest: String) -> String {
        let words = userRequest.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.capitalized }
        
        if words.count == 1 {
            return "\(words[0]) Emails"
        } else if words.count <= 3 {
            return words.joined(separator: " ")
        } else {
            return "Custom Filter"
        }
    }
    
    // MARK: - Legacy Helper Methods (for fallbacks)
    
    private func generateBaseReply(for email: Email) -> String {
        let content = email.content.lowercased()
        
        if content.contains("meeting") {
            return "Thank you for the meeting invitation. I'll review the details and confirm my availability shortly."
        } else if content.contains("project") {
            return "Thank you for the project update. I've reviewed the information and will provide my feedback soon."
        } else if content.contains("question") {
            return "Thank you for your question. I'll look into this and provide you with a detailed response."
        } else if content.contains("deadline") {
            return "Thank you for the deadline information. I'll ensure this is completed by the specified date."
        } else if content.contains("urgent") {
            return "I've received your urgent message and am looking into this immediately. I'll update you as soon as possible."
        } else {
            return "Thank you for your email. I've received your message and will respond accordingly."
        }
    }
    
    private func generateBaseForward(for email: Email) -> String {
        return "I'm forwarding this email for your review and consideration. Please let me know if you have any questions or need additional context."
    }
    
    private func generateBaseEmailFromPrompt(_ prompt: String) -> String {
        return """
        Subject: [Generated Email]
        
        Based on your request, here's the email content. Please review and customize as needed before sending.
        
        [Your message content here based on: '\(prompt)']
        """
    }
    
    private func applyTone(to content: String, tone: EmailTone) -> String {
        switch tone {
        case .professional:
            return content
        case .friendly:
            return "Hi there! \(content) Looking forward to hearing from you!"
        case .casual:
            return "Hey! \(content) Thanks!"
        case .formal:
            return "Dear Sir/Madam,\n\n\(content)\n\nSincerely,\n[Your Name]"
        case .persuasive:
            return "I believe this is important: \(content) I hope you'll consider this carefully."
        case .apologetic:
            return "I sincerely apologize, but \(content) I appreciate your understanding."
        case .enthusiastic:
            return "Great news! \(content) I'm really excited about this!"
        case .urgent:
            return "URGENT: \(content) Please respond as soon as possible."
        case .humorous:
            return "Well, well, well... \(content) 😄"
        case .angry:
            return "I'm very disappointed that \(content) This needs to be addressed immediately."
        case .original:
            return content
        }
    }
    
    // MARK: - OpenAI API Models
    
    struct OpenAIRequest: Codable {
        let model: String
        let messages: [Message]
        let max_tokens: Int
        let temperature: Double
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct OpenAIResponse: Codable {
        let choices: [Choice]
    }
    
    struct Choice: Codable {
        let message: Message
    }
    
    // MARK: - Custom Filter Models
    
    struct CustomFilterResult {
        let title: String
        let query: String
        let description: String
        let confidence: Double
    }
    
    enum AIError: Error {
        case invalidURL
        case apiError(String)
        case decodingError
    }
}
