import Foundation

// MARK: - Email Cache Manager
class EmailCacheManager {
    static let shared = EmailCacheManager()
    
    private let cacheQueue = DispatchQueue(label: "com.vibemail.cache", attributes: .concurrent)
    private var memoryCache: [String: CachedEmailData] = [:]
    private let maxMemoryCacheSize = 500 // emails
    
    struct CachedEmailData {
        let emails: [Email]
        let timestamp: Date
        let etag: String? // For detecting changes
        let categories: [String: Set<EmailCategoryFilter>]
    }
    
    private init() {}
    
    // Load persistent cache into memory cache on app startup
    func loadPersistentCacheIntoMemory(for account: EmailAccount) {
        let persistentCacheKey = "CachedEmailsData_\(account.email)"
        
        guard let emailData = UserDefaults.standard.data(forKey: persistentCacheKey) else {
            print("📋 No persistent cache found for \(account.email)")
            return
        }
        
        do {
            let cachedEmails = try JSONDecoder().decode([Email].self, from: emailData)
            print("📋 Loading \(cachedEmails.count) emails from persistent cache into memory for \(account.email)")
            
            // Update memory cache with persistent data
            cacheQueue.async(flags: .barrier) {
                let key = self.cacheKey(for: account)
                self.memoryCache[key] = CachedEmailData(
                    emails: cachedEmails,
                    timestamp: Date(),
                    etag: nil,
                    categories: [:]
                )
                print("✅ Persistent cache loaded into memory cache for \(account.email)")
            }
        } catch {
            print("❌ Failed to load emails from persistent cache: \(error)")
        }
    }
    
    // Get cached emails for an account
    func getCachedEmails(for account: EmailAccount) -> [Email]? {
        let key = cacheKey(for: account)
        return cacheQueue.sync {
            return memoryCache[key]?.emails
        }
    }
    
    // Update cache with new emails
    func updateCache(newEmails: [Email], for account: EmailAccount) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                let key = self.cacheKey(for: account)
                let existing = self.memoryCache[key]?.emails ?? []
                
                // Create lookup for existing emails
                var existingLookup = [String: Email]()
                for email in existing {
                    existingLookup[email.messageId ?? email.id] = email
                }
                
                // Merge new emails, preserving local state
                var merged: [Email] = []
                for newEmail in newEmails {
                    let id = newEmail.messageId ?? newEmail.id
                    if let existingEmail = existingLookup[id] {
                        // Preserve local state (isRead, priority if AI-analyzed)
                        merged.append(self.mergeEmails(existing: existingEmail, new: newEmail))
                        existingLookup.removeValue(forKey: id)
                    } else {
                        merged.append(newEmail)
                    }
                }
                
                // Add emails that exist locally but weren't in the new fetch
                for (_, email) in existingLookup {
                    if email.syncStatus == .local {
                        merged.append(email) // Keep local changes
                    }
                }
                
                // Sort by timestamp
                merged.sort { $0.timestamp > $1.timestamp }
                
                // Update cache
                self.memoryCache[key] = CachedEmailData(
                    emails: merged,
                    timestamp: Date(),
                    etag: nil,
                    categories: [:] // Will be computed separately
                )
                
                continuation.resume()
            }
        }
    }
    
    private func mergeEmails(existing: Email, new: Email) -> Email {
        // Preserve AI-analyzed priority if it exists
        // If the existing email has a non-default priority, keep it
        // If the existing email has medium priority but the new email has a different priority, use it
        // This handles both AI-analyzed priorities and manual priority changes
        let priority: EmailPriority
        if existing.priority != .medium {
            // Existing email has a non-default priority (likely AI-analyzed), preserve it
            priority = existing.priority
            print("🔒 Preserving existing AI priority: \(existing.priority.rawValue) for email: \(existing.subject)")
        } else if new.priority != .medium {
            // New email has a non-default priority, use it
            priority = new.priority
            print("🆕 Using new priority: \(new.priority.rawValue) for email: \(new.subject)")
        } else {
            // Both have medium priority, keep existing
            priority = existing.priority
            print("⚖️ Both emails have medium priority, keeping existing for: \(existing.subject)")
        }
        
        // Preserve local changes when merging with remote data
        // If existing email has local changes (.local syncStatus), preserve those changes
        // Otherwise, use the new email's data (which comes from Gmail)
        
        let isRead: Bool
        let isStarred: Bool
        let isTrash: Bool
        let isArchived: Bool
        let labels: [String]
        
        if existing.syncStatus == .local {
            // Preserve local changes that haven't been synced yet
            isRead = existing.isRead
            isStarred = existing.isStarred
            isTrash = existing.isTrash
            isArchived = existing.isArchived
            labels = existing.labels
            print("🔒 Preserving local changes for email: \(existing.subject)")
        } else {
            // Use remote data (Gmail is the source of truth)
            isRead = new.isRead
            isStarred = new.isStarred
            isTrash = new.isTrash
            isArchived = new.isArchived
            labels = new.labels
            print("📧 Using remote data for email: \(new.subject)")
        }
        
        return Email(
            subject: new.subject,
            sender: new.sender,
            senderEmail: new.senderEmail,
            recipients: new.recipients,
            content: new.content,
            timestamp: new.timestamp,
            isRead: isRead,
            isStarred: isStarred,
            isTrash: isTrash,
            isArchived: isArchived,
            priority: priority,
            requiresAction: new.requiresAction,
            suggestedAction: new.suggestedAction,
            attachments: new.attachments,
            messageId: new.messageId,
            threadId: new.threadId,
            labels: labels,
            senderProfileImageURL: existing.senderProfileImageURL ?? new.senderProfileImageURL,
            version: new.version + 1,
            lastModified: Date(),
            syncStatus: existing.syncStatus == .local ? .local : .synced
        )
    }
    
    private func cacheKey(for account: EmailAccount) -> String {
        return "cache_\(account.email)"
    }
    
    // Clear cache for an account
    func clearCache(for account: EmailAccount) {
        cacheQueue.async(flags: .barrier) {
            let key = self.cacheKey(for: account)
            self.memoryCache.removeValue(forKey: key)
        }
    }
    
    // Clear all caches
    func clearAllCaches() {
        cacheQueue.async(flags: .barrier) {
            self.memoryCache.removeAll()
        }
    }
} 