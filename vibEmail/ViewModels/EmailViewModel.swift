import Foundation
import SwiftUI
import Combine
import GoogleSignIn
import UIKit

// MARK: - Enhanced Email Category Filter

enum EmailCategoryFilter: String, CaseIterable, Hashable, Codable {
    case inbox = "inbox"
    case starred = "starred"
    case sent = "sent"
    case trash = "trash"
    case archive = "archive"
    case unread = "unread"
    case important = "important"
    
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .starred: return "Starred"
        case .sent: return "Sent"
        case .trash: return "Trash"
        case .archive: return "Archive"
        case .unread: return "Unread"
        case .important: return "Important"
        }
    }
    
    var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .starred: return "star.fill"
        case .sent: return "paperplane.fill"
        case .trash: return "trash.fill"
        case .archive: return "archivebox.fill"
        case .unread: return "envelope.badge"
        case .important: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .inbox: return .blue
        case .starred: return .yellow
        case .sent: return .green
        case .trash: return .red
        case .archive: return .orange
        case .unread: return .purple
        case .important: return .pink
        }
    }
}

struct CustomEmailFilter: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let query: String // This could be a Gmail query or a description
    let createdAt: Date
    
    init(title: String, query: String) {
        self.id = UUID()
        self.title = title
        self.query = query
        self.createdAt = Date()
    }
}

// MARK: - Filter Suggestion Types

enum FilterSuggestion: Hashable {
    case category(EmailCategoryFilter)
    case custom(CustomEmailFilter)
    
    var displayName: String {
        switch self {
        case .category(let filter):
            return filter.displayName
        case .custom(let filter):
            return filter.title
        }
    }
    
    var icon: String {
        switch self {
        case .category(let filter):
            return filter.icon
        case .custom:
            return "wand.and.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .category(let filter):
            return filter.color
        case .custom:
            return .purple
        }
    }
}

class EmailViewModel: ObservableObject {
    @Published var emails: [Email] = []
    @Published var filteredEmails: [Email] = []
    @Published var selectedEmail: Email?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOption: SortOption = .priority
    @Published var showingSideMenu = false

    @Published var accounts: [EmailAccount] = [] // <-- Multi-account support
    @Published var currentAccount: EmailAccount? = nil
    @Published var draftEmail: EmailDraft?
    @Published var currentlyReadEmailID: String? = nil
    @Published var playbackSpeed: Float = UserDefaults.standard.float(forKey: "playbackSpeed") == 0 ? 1.0 : UserDefaults.standard.float(forKey: "playbackSpeed")
    @Published var analyzingEmails: Set<String> = []
    @Published var activeFilters: Set<EmailCategoryFilter> = []
    @Published var filterRecency: [EmailCategoryFilter: Date] = [:]
    @Published var currentCustomFilter: CustomEmailFilter? = nil // Temporary filter from AI chat
    @Published var activeSavedFilter: CustomEmailFilter? = nil // Currently active saved filter
    @Published var savedCustomFilters: [CustomEmailFilter] = []
    
    // MARK: - First-time Setup & Loading
    @Published var isFirstTimeSetup = false
    @Published var setupProgress: Double = 0.0
    @Published var setupCurrentStep = ""
    @Published var showingFirstTimeLoading = false
    @Published var needsReAuthentication = false
    @Published var reAuthenticationMessage = ""
    @Published var refreshMessage: String? = nil
    
    // MARK: - Smart Caching System
    private let cacheManager = EmailCacheManager.shared
    private var lastFetchTime: [String: Date] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Pre-computed filter results
    private var filterCache: [String: [Email]] = [:]
    
    // MARK: - Persistent Cache Management
    private let persistentCacheKey = "CachedEmailsData"
    private let setupCompletionKey = "AccountSetupCompletion"
    private let priorityAnalysisKey = "PriorityAnalysisCache"
    
    // Background refresh timer
    private var backgroundRefreshTimer: Timer?
    private var backgroundRefreshTask: Task<Void, Never>?
    private let backgroundRefreshInterval: TimeInterval = 30.0 // 30 seconds (adjustable)
    private let quickRefreshInterval: TimeInterval = 5.0 // 5 seconds for initial quick refreshes
    private var quickRefreshCount = 0
    private let maxQuickRefreshes = 3 // Do 3 quick refreshes when view appears
    
    // Prevent refresh spam
    private var lastBackgroundRefresh = Date.distantPast
    private let minimumRefreshInterval: TimeInterval = 3.0 // Minimum 3 seconds between refreshes
    
    // Track if we're in foreground
    private var isAppActive = true
    
    // Cache key generator
    private func cacheKey(for filter: EmailCategoryFilter?) -> String {
        return filter?.rawValue ?? "inbox"
    }
    
    // Clear cache when user actions modify emails
    private func invalidateCache() {
        filterCache.removeAll()
        lastFetchTime.removeAll()
        print("🗑️ Filter cache invalidated")
    }
    
    // Invalidate filter cache when emails change
    private func invalidateFilterCache() {
        filterCache.removeAll()
        print("🗑️ Filter cache invalidated")
    }
    
    // MARK: - Account Setup State Management
    
    func isAccountSetupComplete(for account: EmailAccount) -> Bool {
        let key = "\(setupCompletionKey)_\(account.email)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    func markAccountSetupComplete(for account: EmailAccount) {
        let key = "\(setupCompletionKey)_\(account.email)"
        UserDefaults.standard.set(true, forKey: key)
        
        // Save emails to persistent cache
        saveToPersistentCache(for: account)
        
        print("✅ Account setup marked complete for: \(account.email)")
    }
    
    // MARK: - Persistent Cache Operations
    
    private func saveToPersistentCache(for account: EmailAccount) {
        let key = "\(persistentCacheKey)_\(account.email)"
        
        do {
            let emailData = try JSONEncoder().encode(emails)
            UserDefaults.standard.set(emailData, forKey: key)
            
            // Also save priority analysis cache
            let priorityKey = "\(priorityAnalysisKey)_\(account.email)"
            let priorityData = try JSONEncoder().encode(emails.map { 
                ["id": $0.id, "priority": $0.priority.rawValue, "timestamp": String($0.timestamp.timeIntervalSince1970)] 
            })
            UserDefaults.standard.set(priorityData, forKey: priorityKey)
            
            print("💾 Saved \(emails.count) emails to persistent cache for \(account.email)")
        } catch {
            print("❌ Failed to save emails to persistent cache: \(error)")
        }
    }
    
    private func loadFromPersistentCache(for account: EmailAccount) -> [Email]? {
        let key = "\(persistentCacheKey)_\(account.email)"
        
        guard let emailData = UserDefaults.standard.data(forKey: key) else {
            print("📋 No persistent cache found for \(account.email)")
            return nil
        }
        
        do {
            let cachedEmails = try JSONDecoder().decode([Email].self, from: emailData)
            print("📋 Loaded \(cachedEmails.count) emails from persistent cache for \(account.email)")
            return cachedEmails
        } catch {
            print("❌ Failed to load emails from persistent cache: \(error)")
            return nil
        }
    }
    
    private func clearPersistentCache(for account: EmailAccount) {
        let emailKey = "\(persistentCacheKey)_\(account.email)"
        let priorityKey = "\(priorityAnalysisKey)_\(account.email)"
        let setupKey = "\(setupCompletionKey)_\(account.email)"
        
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: priorityKey)
        UserDefaults.standard.removeObject(forKey: setupKey)
        
        print("🗑️ Cleared persistent cache for \(account.email)")
    }
    
    // MARK: - Persistent Account Management
    private let accountsKey = "ConnectedAccounts"
    private let currentAccountKey = "CurrentAccountEmail"
    private let keychainService = "com.vibemail.accounts"

    // Load accounts from persistent storage on app launch
    func loadPersistedAccounts() {
        print("📱 Loading persisted accounts...")
        
        // Load account metadata from UserDefaults
        if let accountsData = UserDefaults.standard.data(forKey: accountsKey) {
            do {
                let decodedAccounts = try JSONDecoder().decode([EmailAccount].self, from: accountsData)
                
                DispatchQueue.main.async {
                    self.accounts = decodedAccounts
                    print("✅ Loaded \(decodedAccounts.count) persisted accounts")
                    
                    // Restore current account
                    let currentEmail = UserDefaults.standard.string(forKey: self.currentAccountKey)
                    if let currentEmail = currentEmail,
                       let account = decodedAccounts.first(where: { $0.email == currentEmail }) {
                        self.currentAccount = account
                        print("✅ Restored current account: \(currentEmail)")
                        
                        // Load persistent cache into memory immediately for instant startup
                        self.cacheManager.loadPersistentCacheIntoMemory(for: account)
                    } else if !decodedAccounts.isEmpty {
                        // Fallback to first account if current account not found
                        self.currentAccount = decodedAccounts.first!
                        print("✅ Set first account as current: \(decodedAccounts.first?.email ?? "Unknown")")
                        
                        // Load persistent cache into memory immediately for instant startup
                        self.cacheManager.loadPersistentCacheIntoMemory(for: decodedAccounts.first!)
                    }
                    
                    // Restore Google Sign-In session and validate accounts
                    Task {
                        await self.restoreGoogleSignInAndValidate()
                    }
                }
            } catch {
                print("❌ Failed to decode persisted accounts: \(error)")
                clearAllPersistedAccounts()
            }
        } else {
            print("📋 No persisted accounts found")
        }
    }

    // Restore Google Sign-In session and validate accounts
    private func restoreGoogleSignInAndValidate() async {
        print("🔄 Restoring Google Sign-In session...")
        
        // First, try to restore previous Google Sign-In session
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            do {
                try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                print("✅ Google Sign-In session restored successfully")
                
                // For multi-account support, we'll preserve all accounts but validate the current one
                await validatePersistedAccountsFlexibly()
            } catch {
                print("❌ Failed to restore Google Sign-In session: \(error)")
                // If restore fails, still preserve accounts but mark them as needing re-authentication
                await preserveAccountsWithReAuthRequired()
            }
        } else {
            print("❌ No previous Google Sign-In session found")
            // Preserve accounts but mark them as needing re-authentication
            await preserveAccountsWithReAuthRequired()
        }
    }

    // Validate accounts more flexibly - preserve all accounts but validate the current session
    private func validatePersistedAccountsFlexibly() async {
        print("🔍 Validating persisted accounts flexibly...")
        
        // Check if the current Google session matches any of our accounts
        var currentSessionAccount: EmailAccount? = nil
        
        if let currentUser = GIDSignIn.sharedInstance.currentUser,
           let currentEmail = currentUser.profile?.email {
            currentSessionAccount = accounts.first { $0.email == currentEmail }
            print("✅ Current Google session matches account: \(currentEmail)")
            
            // Validate the current session account
            if let account = currentSessionAccount {
                do {
                    try await currentUser.refreshTokensIfNeeded()
                    print("✅ Token refresh successful for current account: \(account.email)")
                } catch {
                    print("❌ Token refresh failed for current account: \(account.email)")
                    currentSessionAccount = nil
                }
            }
        }
        
        await MainActor.run {
            // Preserve all accounts - they were valid when last used
            print("📋 Preserving all \(self.accounts.count) accounts")
            
            // Set the current account to the one with active Google session if available
            if let validCurrentAccount = currentSessionAccount {
                self.currentAccount = validCurrentAccount
                print("✅ Set current account to active session: \(validCurrentAccount.email)")
            } else if let firstAccount = self.accounts.first {
                // Fallback to first account if no active session matches
                self.currentAccount = firstAccount
                print("⚠️ No active session found, using first account: \(firstAccount.email)")
            }
            
            // Save the preserved accounts
            self.saveAccountsToPersistence()
        }
    }

    // Preserve accounts but mark that they need re-authentication
    private func preserveAccountsWithReAuthRequired() async {
        print("⚠️ Preserving accounts but Google session needs restoration...")
        
        await MainActor.run {
            // Keep all accounts - user can re-authenticate when needed
            print("📋 Preserving all \(self.accounts.count) accounts (re-auth required)")
            
            // Keep the current account selection
            if self.currentAccount == nil && !self.accounts.isEmpty {
                self.currentAccount = self.accounts.first
                print("✅ Set current account to first preserved account: \(self.accounts.first?.email ?? "Unknown")")
            }
            
            // Save the preserved accounts
            self.saveAccountsToPersistence()
        }
    }

    // Check if an account is still valid with Google (more flexible)
    private func isAccountStillValid(_ account: EmailAccount) async -> Bool {
        // Check if we have a current Google user and if it matches the account
        guard let user = GIDSignIn.sharedInstance.currentUser,
              user.profile?.email == account.email else {
            print("⚠️ No active Google session for account: \(account.email) (account preserved)")
            // Don't invalidate the account just because there's no active session
            // The user can re-authenticate when they try to use this account
            return true
        }
        
        // Try to refresh the access token for the active session
        do {
            try await user.refreshTokensIfNeeded()
            print("✅ Token refresh successful for \(account.email)")
            return true
        } catch {
            print("❌ Failed to refresh tokens for \(account.email): \(error)")
            // Even if token refresh fails, preserve the account for later re-auth
            return true
        }
    }

    // Save accounts to persistent storage
    private func saveAccountsToPersistence() {
        do {
            let accountsData = try JSONEncoder().encode(accounts)
            UserDefaults.standard.set(accountsData, forKey: accountsKey)
            
            // Save current account email
            if let currentAccount = currentAccount {
                UserDefaults.standard.set(currentAccount.email, forKey: currentAccountKey)
            }
            
            print("💾 Saved \(accounts.count) accounts to persistent storage")
        } catch {
            print("❌ Failed to save accounts to persistent storage: \(error)")
        }
    }

    // Validate that persisted accounts are still authenticated with Google (fallback method)
    private func validatePersistedAccounts() async {
        print("🔍 Validating persisted accounts...")
        
        var validAccounts: [EmailAccount] = []
        
        for account in accounts {
            // Check if the account is still valid by attempting to refresh tokens
            if await isAccountStillValid(account) {
                validAccounts.append(account)
                print("✅ Account valid: \(account.email)")
            } else {
                print("❌ Account invalid, removing: \(account.email)")
                // Clear cached data for invalid account
                clearPersistentCache(for: account)
            }
        }
        
        await MainActor.run {
            self.accounts = validAccounts
            
            // Update current account if it was invalidated
            if let currentAccount = self.currentAccount,
               !validAccounts.contains(where: { $0.id == currentAccount.id }) {
                self.currentAccount = validAccounts.first
                print("🔄 Updated current account after validation")
            }
            
            // Save the validated accounts
            self.saveAccountsToPersistence()
        }
    }

    // Clear all persisted account data
    private func clearAllPersistedAccounts() {
        UserDefaults.standard.removeObject(forKey: accountsKey)
        UserDefaults.standard.removeObject(forKey: currentAccountKey)
        
        // Clear all account caches
        for account in accounts {
            clearPersistentCache(for: account)
        }
        
        print("🗑️ Cleared all persisted account data")
    }
    
    // Suggestions: up to 3 most recently used filters, or all filters if none used yet
    var filterSuggestions: [EmailCategoryFilter] {
        let sorted = filterRecency.sorted { $0.value > $1.value }.map { $0.key }
        if sorted.isEmpty {
            // If no filters have been used yet, show all available filters
            return Array(EmailCategoryFilter.allCases.prefix(3))
        }
        return Array(sorted.prefix(3))
    }
    
    // Combined filter suggestions including saved custom filters
    var allFilterSuggestions: [FilterSuggestion] {
        var suggestions: [FilterSuggestion] = []
        
        // Add category filter suggestions
        for filter in filterSuggestions {
            suggestions.append(.category(filter))
        }
        
        // Add saved custom filter suggestions (up to 2 to keep total under 3)
        let customFilterCount = min(2, savedCustomFilters.count)
        for i in 0..<customFilterCount {
            suggestions.append(.custom(savedCustomFilters[i]))
        }
        
        return Array(suggestions.prefix(3))
    }
    
    // MARK: - Filter Management
    
    func toggleFilter(_ filter: EmailCategoryFilter) {
        print("🔄 Toggling filter: \(filter.displayName)")
        
        DispatchQueue.main.async {
            let wasActive = self.activeFilters.contains(filter)
            
            if wasActive {
                self.activeFilters.remove(filter)
                print("❌ Removed filter: \(filter.displayName)")
            } else {
                self.activeFilters.insert(filter)
                print("✅ Added filter: \(filter.displayName)")
            }
            
            // Update filter recency for suggestions
            self.filterRecency[filter] = Date()
            
            // Clear custom filters when category filters are used
            self.currentCustomFilter = nil
            self.activeSavedFilter = nil
            
            // Re-filter emails
            self.filterEmails()
        }
    }
    
    func clearAllFilters() {
        print("🧹 Clearing all filters")
        
        DispatchQueue.main.async {
            self.activeFilters.removeAll()
            self.currentCustomFilter = nil
            self.activeSavedFilter = nil
            self.searchText = ""
            self.filterEmails()
        }
    }
    
    func setFilter(_ filter: EmailCategoryFilter) {
        print("🎯 Setting single filter: \(filter.displayName)")
        
        DispatchQueue.main.async {
            self.activeFilters = [filter]
            self.filterRecency[filter] = Date()
            self.currentCustomFilter = nil
            self.activeSavedFilter = nil
            self.filterEmails()
        }
    }
    



    
    // MARK: - Improved Duplicate Removal

    private func removeDuplicatesAndPreserveTimestamps(from emails: [Email]) -> [Email] {
        var emailDict: [String: Email] = [:]
        
        for email in emails {
            let key = email.id
            
            if let existingEmail = emailDict[key] {
                // Keep the email with the more recent timestamp or more complete data
                // In case of same timestamp, prefer the one with more labels (more complete)
                if email.timestamp > existingEmail.timestamp || 
                   (email.timestamp == existingEmail.timestamp && email.labels.count >= existingEmail.labels.count) {
                    emailDict[key] = email
                    print("🔄 Updated duplicate email: \(email.subject) with better timestamp/data")
                }
            } else {
                emailDict[key] = email
            }
        }
        
        // Convert back to array and sort by timestamp to maintain order
        let uniqueEmails = Array(emailDict.values).sorted { $0.timestamp > $1.timestamp }
        
        return uniqueEmails
    }
    
    // MARK: - Debug Methods
    
    private func debugFilterResults() {
        print("📊 Filter Results Debug:")
        print("   📧 Total emails: \(emails.count)")
        print("   ✅ Filtered emails: \(filteredEmails.count)")
        print("   🏷️ Active filters: \(activeFilters.map { $0.displayName }.joined(separator: ", "))")
        
        if !activeFilters.isEmpty {
            let categoryCounts = countEmailsByCategory()
            print("   📈 Category breakdown:")
            for (category, count) in categoryCounts {
                print("      \(category): \(count)")
            }
        }
    }
    
    private func countEmailsByCategory() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        for email in emails {
            if isInboxEmail(email) { counts["Inbox", default: 0] += 1 }
            if isStarredEmail(email) { counts["Starred", default: 0] += 1 }
            if isSentEmail(email) { counts["Sent", default: 0] += 1 }
            if isTrashEmail(email) { counts["Trash", default: 0] += 1 }
            if isArchivedEmail(email) { counts["Archive", default: 0] += 1 }
            if isUnreadEmail(email) { counts["Unread", default: 0] += 1 }
            if isImportantEmail(email) { counts["Important", default: 0] += 1 }
        }
        
        return counts
    }
    
    private let aiService = AIService()
    private let emailService = EmailService()
    private let gmailAPIService = GmailAPIService.shared
    private let speechService = SpeechService()
    private let translationService = TranslationService()
    let textToSpeechService = TextToSpeechService()
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case date = "Date"
    }
    
    init() {
        $playbackSpeed
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "playbackSpeed")
            }
            .store(in: &cancellables)
        setupBindings()
        
        // Load persisted accounts on app launch
        loadPersistedAccounts()
        
        // Don't load sample emails by default - wait for authentication
        
        // Setup lifecycle observers for background refresh
        setupLifecycleObservers()
    }
    
    deinit {
        // Clean up background refresh timer
        stopBackgroundRefresh()

        // Remove all notification observers
        NotificationCenter.default.removeObserver(self)

        print("🗑️ EmailViewModel deinitialized")
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterEmails()
            }
            .store(in: &cancellables)
    }
    
    func loadSampleEmails() {
        isLoading = true
        
        // Simulate loading emails
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.emails = [
                Email(
                    subject: "Project Update - Q4 Goals",
                    sender: "Sarah Johnson",
                    senderEmail: "sarah.johnson@microsoft.com",
                    recipients: ["team@microsoft.com"],
                    content: "Hi team, I wanted to share our Q4 goals and priorities. We need to focus on the new product launch and customer acquisition. Please review the attached document and let me know your thoughts.",
                    timestamp: Date().addingTimeInterval(-3600),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .high,
                    requiresAction: true,
                    suggestedAction: .reply,
                    messageId: "sample_message_1",
                    threadId: "sample_thread_1",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "Meeting Tomorrow at 2 PM",
                    sender: "Mike Chen",
                    senderEmail: "mike.chen@apple.com",
                    recipients: ["all@apple.com"],
                    content: "Reminder: We have our weekly team meeting tomorrow at 2 PM. Agenda includes project updates and planning for next week.",
                    timestamp: Date().addingTimeInterval(-7200),
                    isRead: true,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .medium,
                    requiresAction: false,
                    messageId: "sample_message_2",
                    threadId: "sample_thread_2",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "URGENT: Server Maintenance",
                    sender: "IT Support",
                    senderEmail: "support@github.com",
                    recipients: ["all@github.com"],
                    content: "URGENT: We need to perform emergency server maintenance tonight at 10 PM. The system will be down for approximately 2 hours.",
                    timestamp: Date().addingTimeInterval(-1800),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .urgent,
                    requiresAction: true,
                    suggestedAction: .reply,
                    messageId: "sample_message_3",
                    threadId: "sample_thread_3",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "Happy Birthday!",
                    sender: "HR Team",
                    senderEmail: "hr@meta.com",
                    recipients: ["all@meta.com"],
                    content: "Happy Birthday to our amazing team member! We hope you have a wonderful day filled with joy and celebration.",
                    timestamp: Date().addingTimeInterval(-14400),
                    isRead: true,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .low,
                    requiresAction: false,
                    messageId: "sample_message_4",
                    threadId: "sample_thread_4",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "URGENT: FLASH SALE - 70% OFF Everything!",
                    sender: "Urban Outfitters",
                    senderEmail: "marketing@urbanoutfitters.com",
                    recipients: ["customer@email.com"],
                    content: "URGENT: Don't miss our biggest flash sale ever! Get 70% off everything in store. Limited time offer - ACT NOW before it's gone! Use code FLASH70 at checkout. Free shipping on orders over $50.",
                    timestamp: Date().addingTimeInterval(-43200),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .low,
                    requiresAction: false,
                    messageId: "sample_message_5",
                    threadId: "sample_thread_5",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "CRITICAL: Limited Time Offer - Buy One Get One Free",
                    sender: "Nike Marketing",
                    senderEmail: "offers@nike.com",
                    recipients: ["customer@email.com"],
                    content: "CRITICAL: This offer expires in 24 hours! Buy one get one free on all running shoes. Don't miss out on this exclusive deal. Limited quantities available. Act now!",
                    timestamp: Date().addingTimeInterval(-86400),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .low,
                    requiresAction: false,
                    messageId: "sample_message_6",
                    threadId: "sample_thread_6",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "Weekly Deals Newsletter",
                    sender: "Amazon Deals",
                    senderEmail: "deals@amazon.com",
                    recipients: ["customer@email.com"],
                    content: "This week's best deals: Electronics up to 50% off, clothing clearance, and exclusive Prime member offers. Don't miss these limited-time savings!",
                    timestamp: Date().addingTimeInterval(-7200),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .low,
                    requiresAction: false,
                    messageId: "sample_message_7",
                    threadId: "sample_thread_7",
                    senderProfileImageURL: nil
                ),
                Email(
                    subject: "Immediate Response Required",
                    sender: "Hsiao C Sun",
                    senderEmail: "hsiao.sun@google.com",
                    recipients: ["bryan@google.com"],
                    content: "Hi Bryan, please get back to me as soon as possible. Best, Hsiao C Sun",
                    timestamp: Date().addingTimeInterval(-1800),
                    isRead: false,
                    isStarred: false,
                    isTrash: false,
                    isArchived: false,
                    priority: .urgent,
                    requiresAction: true,
                    suggestedAction: .reply,
                    messageId: "sample_message_8",
                    threadId: "sample_thread_8",
                    senderProfileImageURL: nil
                )
            ]
            self.filterEmails()
            // Create some sample archived emails for testing
            self.createSampleArchivedEmails()
            self.isLoading = false
        }
    }
    
    func loadRealEmails() async {
        print("📧 loadRealEmails called - delegating to proven system")
        
        guard let currentAccount = currentAccount else {
            print("❌ No current account available for loading emails")
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        // Use our proven account loading system
        await loadEmailsForAccount(currentAccount)
    }

    private func performFirstTimeSetup(for account: EmailAccount) async {
        await updateSetupProgress(0.1, step: "Connecting to Gmail")
        
        do {
            // Step 1: Fetch ALL emails from Gmail API (inbox, sent, trash, archive, etc.)
            await updateSetupProgress(0.2, step: "Fetching All Emails")
            print("📧 Starting first-time email fetch for \(account.email)")
            
            // Fetch all email types to create a complete source of truth
            let inboxEmails = try await gmailAPIService.fetchEmails(maxResults: 100)
            let sentEmails = try await gmailAPIService.fetchSentEmails(maxResults: 50)
            let starredEmails = try await gmailAPIService.fetchStarredEmails(maxResults: 50)
            let trashEmails = try await gmailAPIService.fetchTrashEmails(maxResults: 50)
            let archivedEmails = try await gmailAPIService.fetchArchivedEmails(maxResults: 50)
            
            // Combine all emails into one source of truth
            var allEmails: [Email] = []
            allEmails.append(contentsOf: inboxEmails)
            allEmails.append(contentsOf: sentEmails)
            allEmails.append(contentsOf: starredEmails)
            allEmails.append(contentsOf: trashEmails)
            allEmails.append(contentsOf: archivedEmails)
            
            // Remove duplicates based on messageId
            let uniqueEmails = removeDuplicatesAndPreserveTimestamps(from: allEmails)
            
            await MainActor.run {
                self.emails = uniqueEmails
            }
            
            // Update cache with new emails
            await cacheManager.updateCache(newEmails: uniqueEmails, for: account)
            
            // Update categories and debug
            await MainActor.run {
                self.updateEmailCategories()
                self.debugEmailCategories()
                
                // Start real-time updates after first load
                self.setupRealTimeUpdates()
            }
            
            await updateSetupProgress(0.5, step: "Analyzing Priority")
            
            // Step 2: Analyze email priorities (this is the time-consuming part)
            await analyzeAllEmailPriorities()
            
            await updateSetupProgress(0.8, step: "Building Cache")
            
            // Step 3: Save to persistent cache
            await MainActor.run {
                self.markAccountSetupComplete(for: account)
                self.filterEmails()
            }
            
            await updateSetupProgress(0.9, step: "Loading Profile Images")
            
            // Step 4: Load profile images in background
            Task {
                await self.loadProfileImages()
            }
            
            await updateSetupProgress(1.0, step: "Complete")
            
            // Step 4: Finish setup
            await MainActor.run {
                self.isLoading = false
                self.isFirstTimeSetup = false
                
                // Delay hiding the loading screen to show completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showingFirstTimeLoading = false
                }
            }
            
            print("✅ First-time setup complete for \(account.email) - loaded \(uniqueEmails.count) total emails")
            
        } catch {
            print("❌ Error during first-time setup: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.isFirstTimeSetup = false
                self.showingFirstTimeLoading = false
            }
        }
    }

    private func updateSetupProgress(_ progress: Double, step: String) async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.setupProgress = progress
                self.setupCurrentStep = step
            }
        }
        
        // Add some realistic delay to show progress
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }

    private func analyzeAllEmailPriorities() async {
        await MainActor.run {
            self.setupCurrentStep = "AI is analyzing email importance..."
        }
        
        let batchSize = 10
        let totalEmails = emails.count
        var processedCount = 0
        
        // Process emails in batches to show progress
        for i in stride(from: 0, to: totalEmails, by: batchSize) {
            let endIndex = min(i + batchSize, totalEmails)
            let batch = Array(emails[i..<endIndex])
            
            // Analyze this batch
            for email in batch {
                await analyzeSingleEmailPriority(email)
                processedCount += 1
                
                // Update progress within the analysis step (0.5 to 0.8)
                let analysisProgress = 0.5 + (0.3 * Double(processedCount) / Double(totalEmails))
                await MainActor.run {
                    self.setupProgress = analysisProgress
                }
            }
            
            // Small delay between batches to prevent overwhelming the UI
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    func filterEmails() {
        // Ensure categories are computed first
        if emailCategories.isEmpty && !emails.isEmpty {
            print("⚠️ Categories not computed, computing now...")
            updateEmailCategories()
        }
        
        let filterKey = computeFilterKey()
        
        // Check if we have cached results for this filter combination
        if let cached = filterCache[filterKey] {
            print("🚀 Using cached filter results: \(cached.count) emails")
            self.filteredEmails = cached
            return
        }
        
        print("🔍 Computing filter results...")
        print("📧 Total emails: \(emails.count)")
        print("🏷️ Active filters: \(activeFilters)")
        
        var filtered = emails
        
        // Apply filters
        if let customFilter = currentCustomFilter {
            print("🔧 Applying custom filter: \(customFilter.title)")
            filtered = applyCustomFilterLogic(to: filtered, query: customFilter.query)
        } else if let savedFilter = activeSavedFilter {
            print("💾 Applying saved filter: \(savedFilter.title)")
            filtered = applyCustomFilterLogic(to: filtered, query: savedFilter.query)
        } else if !activeFilters.isEmpty {
            print("🏷️ Applying category filters")
            filtered = applyCategoryFilters(to: filtered)
        } else {
            print("📥 Showing all emails (default view)")
            // Default: show all emails (no filtering)
            filtered = emails
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { email in
                email.subject.lowercased().contains(searchLower) ||
                email.sender.lowercased().contains(searchLower) ||
                email.content.lowercased().contains(searchLower)
            }
        }
        
        // Cache and update
        DispatchQueue.main.async {
            self.filterCache[filterKey] = filtered
            self.filteredEmails = filtered
            self.sortEmails()
            print("✅ Filtering complete: \(self.filteredEmails.count) emails displayed")
        }
    }
    
    private func computeFilterKey() -> String {
        let filterPart = activeFilters.sorted { $0.rawValue < $1.rawValue }
            .map { $0.rawValue }
            .joined(separator: ",")
        let searchPart = searchText.lowercased()
        return "\(filterPart)|\(searchPart)"
    }
    
    // MARK: - Category Filter Application
    
    private func applyCategoryFilters(to emails: [Email]) -> [Email] {
        // OR logic: if multiple filters are active, show emails that match ANY filter
        var results: Set<Email> = []
        
        print("🔍 Applying category filters to \(emails.count) emails")
        
        for filter in activeFilters {
            let matchingEmails = emails.filter { email in
                // Use pre-computed categories for fast filtering
                guard let categories = emailCategories[email.id] else { 
                    return false 
                }
                return categories.contains(filter)
            }
            
            print("🏷️ Filter '\(filter.displayName)' matched \(matchingEmails.count) emails")
            results.formUnion(matchingEmails)
        }
        
        return Array(results).sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Email Category Detection
    
    private func isInboxEmail(_ email: Email) -> Bool {
        return email.labels.contains("INBOX") && 
               !email.isTrash && 
               !email.isArchived
    }
    
    private func isStarredEmail(_ email: Email) -> Bool {
        return email.isStarred || email.labels.contains("STARRED")
    }
    
    private func isSentEmail(_ email: Email) -> Bool {
        return email.labels.contains("SENT")
    }
    
    private func isTrashEmail(_ email: Email) -> Bool {
        return email.isTrash || email.labels.contains("TRASH")
    }
    
    private func isArchivedEmail(_ email: Email) -> Bool {
        // Email is archived if:
        // 1. Explicitly marked as archived, OR
        // 2. Has no INBOX label but isn't SENT or TRASH (Gmail's archive behavior)
        return email.isArchived || 
               email.labels.contains("ARCHIVED") ||
               (!email.labels.contains("INBOX") && 
                !email.labels.contains("SENT") && 
                !email.labels.contains("TRASH") &&
                !email.labels.isEmpty) // Don't catch emails with no labels
    }
    
    private func isUnreadEmail(_ email: Email) -> Bool {
        return !email.isRead || email.labels.contains("UNREAD")
    }
    
    private func isImportantEmail(_ email: Email) -> Bool {
        return email.priority == .high || 
               email.priority == .urgent ||
               email.labels.contains("IMPORTANT")
    }
    
    // MARK: - Enhanced Custom Filter Logic
    
    private func applyCustomFilterLogic(to emails: [Email], query: String) -> [Email] {
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return emails.filter { email in
            // Gmail-style query parsing
            if lowercasedQuery.contains("subject:") {
                return parseSubjectQuery(lowercasedQuery, email: email)
            } else if lowercasedQuery.contains("from:") {
                return parseFromQuery(lowercasedQuery, email: email)
            } else if lowercasedQuery.contains("to:") {
                return parseToQuery(lowercasedQuery, email: email)
            } else if lowercasedQuery.contains("has:") {
                return parseHasQuery(lowercasedQuery, email: email)
            } else if lowercasedQuery.contains("is:") {
                return parseIsQuery(lowercasedQuery, email: email)
            } else if lowercasedQuery.contains("label:") {
                return parseLabelQuery(lowercasedQuery, email: email)
            } else {
                // Generic search across all text fields
                return searchAllFields(lowercasedQuery, email: email)
            }
        }
    }
    
    // MARK: - Query Parsers
    
    private func parseSubjectQuery(_ query: String, email: Email) -> Bool {
        let terms = extractTermsAfterPrefix(query, prefix: "subject:")
        return terms.allSatisfy { term in
            email.subject.lowercased().contains(term)
        }
    }
    
    private func parseFromQuery(_ query: String, email: Email) -> Bool {
        let terms = extractTermsAfterPrefix(query, prefix: "from:")
        return terms.allSatisfy { term in
            email.senderEmail.lowercased().contains(term) || 
            email.sender.lowercased().contains(term)
        }
    }
    
    private func parseToQuery(_ query: String, email: Email) -> Bool {
        let terms = extractTermsAfterPrefix(query, prefix: "to:")
        return terms.allSatisfy { term in
            email.recipients.joined(separator: " ").lowercased().contains(term)
        }
    }
    
    private func parseHasQuery(_ query: String, email: Email) -> Bool {
        if query.contains("has:attachment") {
            return !email.attachments.isEmpty
        } else if query.contains("has:star") {
            return email.isStarred
        } else if query.contains("has:priority") {
            return email.priority == .high || email.priority == .urgent
        }
        return false
    }
    
    private func parseIsQuery(_ query: String, email: Email) -> Bool {
        if query.contains("is:unread") {
            return !email.isRead
        } else if query.contains("is:read") {
            return email.isRead
        } else if query.contains("is:starred") {
            return email.isStarred
        } else if query.contains("is:important") {
            return email.priority == .high || email.priority == .urgent
        }
        return false
    }
    
    private func parseLabelQuery(_ query: String, email: Email) -> Bool {
        let terms = extractTermsAfterPrefix(query, prefix: "label:")
        return terms.allSatisfy { term in
            email.labels.contains { $0.lowercased().contains(term) }
        }
    }
    
    private func searchAllFields(_ query: String, email: Email) -> Bool {
        let searchTerms = query.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return searchTerms.allSatisfy { term in
            email.subject.lowercased().contains(term) ||
            email.sender.lowercased().contains(term) ||
            email.senderEmail.lowercased().contains(term) ||
            email.content.lowercased().contains(term) ||
            email.recipients.joined(separator: " ").lowercased().contains(term)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractTermsAfterPrefix(_ query: String, prefix: String) -> [String] {
        // Find the prefix and extract terms after it
        guard let range = query.range(of: prefix) else { return [] }
        
        let afterPrefix = String(query[range.upperBound...])
        
        // Handle quoted strings like subject:"meeting tomorrow"
        if afterPrefix.hasPrefix("\"") {
            let pattern = "\"([^\"]+)\""
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(location: 0, length: afterPrefix.count)
            
            if let match = regex?.firstMatch(in: afterPrefix, options: [], range: nsRange),
               let range = Range(match.range(at: 1), in: afterPrefix) {
                return [String(afterPrefix[range]).lowercased()]
            }
        }
        
        // Handle space-separated terms
        let terms = afterPrefix.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(3) // Limit to first 3 terms to avoid processing entire email
        
        return Array(terms).map { $0.lowercased() }
    }
    
    // Helper to extract terms from Gmail query syntax (legacy method)
    private func extractTerms(from query: String, prefix: String) -> [String] {
        let pattern = "\(prefix)\\(([^)]+)\\)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: query.count)
        
        guard let match = regex?.firstMatch(in: query, options: [], range: range),
              let range = Range(match.range(at: 1), in: query) else {
            return []
        }
        
        let termsString = String(query[range])
        return termsString.components(separatedBy: " OR ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func sortEmails() {
        switch sortOption {
        case .priority:
            // Sort by priority level (high to low) and then by date for same priority
            filteredEmails.sort { email1, email2 in
                if email1.priority.priorityLevel != email2.priority.priorityLevel {
                    return email1.priority.priorityLevel > email2.priority.priorityLevel
                } else {
                    // For same priority, sort by date (newest first)
                    return email1.timestamp > email2.timestamp
                }
            }
        case .date:
            filteredEmails.sort { $0.timestamp > $1.timestamp }
        }
    }
    
    // MARK: - Email Update Helper Functions
    
    // Helper function to update email properties efficiently
    private func updateEmailInPlace(
        emailId: String,
        isRead: Bool? = nil,
        isStarred: Bool? = nil,
        isTrash: Bool? = nil,
        isArchived: Bool? = nil,
        labels: [String]? = nil,
        syncStatus: Email.SyncStatus? = nil,
        updateSelectedEmail: Bool = true
    ) {
        guard let index = emails.firstIndex(where: { $0.id == emailId }) else {
            print("❌ Email not found for update: \(emailId)")
            return
        }
        
        let currentEmail = emails[index]
        
        emails[index] = Email(
            subject: currentEmail.subject,
            sender: currentEmail.sender,
            senderEmail: currentEmail.senderEmail,
            recipients: currentEmail.recipients,
            content: currentEmail.content,
            timestamp: currentEmail.timestamp,
            isRead: isRead ?? currentEmail.isRead,
            isStarred: isStarred ?? currentEmail.isStarred,
            isTrash: isTrash ?? currentEmail.isTrash,
            isArchived: isArchived ?? currentEmail.isArchived,
            priority: currentEmail.priority,
            requiresAction: currentEmail.requiresAction,
            suggestedAction: currentEmail.suggestedAction,
            attachments: currentEmail.attachments,
            messageId: currentEmail.messageId,
            threadId: currentEmail.threadId,
            labels: labels ?? currentEmail.labels,
            senderProfileImageURL: currentEmail.senderProfileImageURL,
            version: currentEmail.version + (syncStatus == .synced ? 0 : 1),
            lastModified: Date(),
            syncStatus: syncStatus ?? currentEmail.syncStatus
        )
        
        if updateSelectedEmail && selectedEmail?.id == emailId {
            selectedEmail = emails[index]
        }
        
        invalidateFilterCache()
        updateEmailCategories()
        filterEmails()
    }
    
    // Helper function to revert email to original state
    private func revertEmailToOriginal(_ originalEmail: Email) {
        guard let index = emails.firstIndex(where: { $0.id == originalEmail.id }) else {
            print("❌ Email not found for revert: \(originalEmail.id)")
            return
        }
        
        emails[index] = originalEmail
        if selectedEmail?.id == originalEmail.id {
            selectedEmail = originalEmail
        }
        invalidateFilterCache()
        updateEmailCategories()
        filterEmails()
    }

    
    func markAsRead(_ email: Email) {
        print("📧 markAsRead called for: \(email.subject)")
        print("📧 Current email isRead: \(email.isRead)")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Update local state immediately for responsive UI
        DispatchQueue.main.async {
            // Update both isRead property and UNREAD label
            var newLabels = email.labels
            newLabels.removeAll { $0 == "UNREAD" } // Remove UNREAD label when marking as read
            
            self.updateEmailInPlace(
                emailId: email.id, 
                isRead: true, 
                labels: newLabels,
                syncStatus: .local
            )
            print("✅ Email successfully marked as read in local state, labels updated: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API call")
                return 
            }
            do {
                let success = try await gmailAPIService.markAsRead(messageId)
                if success {
                    print("✅ Successfully marked email as read in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to mark email as read in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error marking email as read: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func markAsUnread(_ email: Email) {
        print("📧 markAsUnread called for: \(email.subject)")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Update local state immediately for responsive UI
        DispatchQueue.main.async {
            // Update both isRead property and UNREAD label
            var newLabels = email.labels
            if !newLabels.contains("UNREAD") {
                newLabels.append("UNREAD") // Add UNREAD label when marking as unread
            }
            
            self.updateEmailInPlace(
                emailId: email.id, 
                isRead: false, 
                labels: newLabels,
                syncStatus: .local
            )
            print("✅ Email successfully marked as unread in local state, labels updated: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API call")
                return 
            }
            do {
                let success = try await gmailAPIService.markAsUnread(messageId)
                if success {
                    print("✅ Successfully marked email as unread in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to mark email as unread in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error marking email as unread: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func toggleStar(_ email: Email) async {
        print("⭐ toggleStar called for: \(email.subject), current starred: \(email.isStarred)")
        guard let messageId = email.messageId else { 
            print("⚠️ No messageId available for Gmail API call")
            return 
        }
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Update local state immediately for responsive UI
        await MainActor.run {
            // Update both isStarred property and STARRED label
            var newLabels = email.labels
            if email.isStarred {
                // Unstarring: remove STARRED label
                newLabels.removeAll { $0 == "STARRED" }
            } else {
                // Starring: add STARRED label if not present
                if !newLabels.contains("STARRED") {
                    newLabels.append("STARRED")
                }
            }
            
            self.updateEmailInPlace(
                emailId: email.id, 
                isStarred: !email.isStarred, 
                labels: newLabels,
                syncStatus: .local
            )
            
            print("⭐ Updated email starred status: \(!email.isStarred), labels: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        do {
            let success: Bool
            if email.isStarred {
                success = try await gmailAPIService.unstarEmail(messageId)
            } else {
                success = try await gmailAPIService.starEmail(messageId)
            }
            
            if success {
                print("✅ Successfully toggled star in Gmail API")
                // Update sync status to indicate successful sync
                await MainActor.run {
                    self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                }
                // Update persistent cache after successful API call
                if let currentAccount = self.currentAccount {
                    self.saveToPersistentCache(for: currentAccount)
                }
            } else {
                print("⚠️ Failed to toggle star in Gmail API - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        } catch {
            print("❌ Error toggling star: \(error) - reverting local state")
            // Revert local state if API call fails
            await MainActor.run {
                self.revertEmailToOriginal(originalEmail)
            }
        }
    }
    
    func deleteEmail(_ email: Email) {
        print("🗑️ deleteEmail called for: \(email.subject)")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Move to trash in local state immediately for responsive UI
        DispatchQueue.main.async {
            // Update both isTrash property and labels (add TRASH, remove INBOX)
            var newLabels = email.labels
            if !newLabels.contains("TRASH") {
                newLabels.append("TRASH")
            }
            newLabels.removeAll { $0 == "INBOX" }
            
            self.updateEmailInPlace(
                emailId: email.id,
                isTrash: true,
                labels: newLabels,
                syncStatus: .local
            )
            
            // Clear selectedEmail if it matches the trashed email
            if self.selectedEmail?.id == email.id {
                self.selectedEmail = nil
            }
            
            print("🗑️ Email moved to trash locally: \(email.subject), labels: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API delete call")
                return 
            }
            do {
                let success = try await gmailAPIService.deleteEmail(messageId)
                if success {
                    print("✅ Successfully moved email to trash in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to move email to trash in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error moving email to trash: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func restoreFromTrash(_ email: Email) {
        print("♻️ restoreFromTrash called for: \(email.subject)")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Restore from trash in local state immediately for responsive UI
        DispatchQueue.main.async {
            // Update both isTrash property and labels (remove TRASH, add INBOX)
            var newLabels = email.labels
            newLabels.removeAll { $0 == "TRASH" }
            if !newLabels.contains("INBOX") {
                newLabels.append("INBOX")
            }
            
            self.updateEmailInPlace(
                emailId: email.id,
                isTrash: false,
                labels: newLabels,
                syncStatus: .local
            )
            
            print("♻️ Email restored from trash locally: \(email.subject), labels: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API untrash call")
                return 
            }
            do {
                let success = try await gmailAPIService.untrashEmail(messageId)
                if success {
                    print("✅ Successfully restored email from trash in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to restore email from trash in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error restoring email from trash: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func archiveEmail(_ email: Email) {
        print("📤 Archiving email: \(email.subject) (isArchived: \(email.isArchived))")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Update local state immediately for responsive UI
        DispatchQueue.main.async {
            // Remove INBOX label when archiving
            let newLabels = email.labels.filter { $0 != "INBOX" }
            self.updateEmailInPlace(
                emailId: email.id, 
                isArchived: true, 
                labels: newLabels, 
                syncStatus: .local
            )
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API archive call")
                return 
            }
            do {
                let success = try await gmailAPIService.archiveEmail(messageId)
                if success {
                    print("✅ Successfully archived email in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to archive email in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error archiving email: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func unarchiveEmail(_ email: Email) {
        print("📥 Unarchiving email: \(email.subject) (isArchived: \(email.isArchived))")
        
        // Store original state for potential rollback
        let originalEmail = email
        
        // Update local state immediately for responsive UI
        DispatchQueue.main.async {
            // Update both isArchived property and INBOX label
            var newLabels = email.labels
            if !newLabels.contains("INBOX") {
                newLabels.append("INBOX") // Add INBOX label when unarchiving
            }
            
            self.updateEmailInPlace(
                emailId: email.id,
                isArchived: false,
                labels: newLabels,
                syncStatus: .local
            )
            
            print("✅ Email successfully unarchived in local state, labels updated: \(newLabels)")
        }
        
        // Communicate with Gmail API and update cache
        Task {
            guard let messageId = email.messageId else { 
                print("⚠️ No messageId available for Gmail API unarchive call")
                return 
            }
            do {
                let success = try await gmailAPIService.unarchiveEmail(messageId)
                if success {
                    print("✅ Successfully unarchived email in Gmail API")
                    // Update sync status to indicate successful sync
                    await MainActor.run {
                        self.updateEmailInPlace(emailId: email.id, syncStatus: .synced)
                    }
                    // Update persistent cache after successful API call
                    if let currentAccount = self.currentAccount {
                        self.saveToPersistentCache(for: currentAccount)
                    }
                } else {
                    print("⚠️ Failed to unarchive email in Gmail API - reverting local state")
                    // Revert local state if API call fails
                    await MainActor.run {
                        self.revertEmailToOriginal(originalEmail)
                    }
                }
            } catch {
                print("❌ Error unarchiving email: \(error) - reverting local state")
                // Revert local state if API call fails
                await MainActor.run {
                    self.revertEmailToOriginal(originalEmail)
                }
            }
        }
    }
    
    func generateAIReply(for email: Email, tone: EmailTone) async -> String {
        return await aiService.generateReply(for: email, tone: tone)
    }
    
    func generateAIForward(for email: Email, tone: EmailTone) async -> String {
        return await aiService.generateForward(for: email, tone: tone)
    }
    
    func analyzeEmailPriority(_ email: Email) async -> EmailPriority {
        return await aiService.analyzePriority(email)
    }
    
    func generateHelpResponse(for userQuery: String) async throws -> String {
        let systemPrompt = """
        You are a helpful assistant for vibEmail, an AI-powered email app. Provide concise, helpful answers about the app's features:

        KEY FEATURES:
        - Multi-account Gmail support with easy switching
        - Smart filtering (Inbox, Starred, Sent, Trash, Archive, Unread)
        - Custom AI filters with voice input
        - Email priority analysis and smart replies
        - Text-to-speech with speed control
        - Swipe actions (reply, archive, delete)
        - Star/unstar emails, mark read/unread
        - AI-powered compose and reply assistance
        - Voice commands and speech recognition
        - Modern UI with animations and haptic feedback

        Keep responses helpful, friendly, and under 3 paragraphs. If asked about features not listed, politely explain that feature may not be available yet.
        """
        
        let prompt = "\(systemPrompt)\n\nUser Question: \(userQuery)\n\nAssistant:"
        return try await aiService.generateTextResponse(prompt, maxTokens: 300)
    }
    
    func analyzeEmailPriorities() async {
        // Analyze priorities for all emails that don't have AI-determined priorities
        for (index, email) in emails.enumerated() {
            await MainActor.run {
                self.analyzingEmails.insert(email.id)
            }
            
            // Skip if already analyzed (you could add a flag to track this)
            let newPriority = await aiService.analyzePriority(email)
            
            await MainActor.run {
                self.analyzingEmails.remove(email.id)
                
                if index < self.emails.count && self.emails[index].id == email.id {
                    self.emails[index] = Email(
                        subject: email.subject,
                        sender: email.sender,
                        senderEmail: email.senderEmail,
                        recipients: email.recipients,
                        content: email.content,
                        timestamp: email.timestamp,
                        isRead: email.isRead,
                        isStarred: email.isStarred,
                        isTrash: email.isTrash,
                        isArchived: email.isArchived,
                        priority: newPriority,
                        requiresAction: email.requiresAction,
                        suggestedAction: email.suggestedAction,
                        attachments: email.attachments,
                        messageId: email.messageId,
                        threadId: email.threadId,
                        labels: email.labels,
                        senderProfileImageURL: email.senderProfileImageURL
                    )
                }
            }
            
            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        await MainActor.run {
            self.filterEmails()
        }
    }
    
    func analyzeSingleEmailPriority(_ email: Email) async {
        await MainActor.run {
            self.analyzingEmails.insert(email.id)
        }
        
        let newPriority = await aiService.analyzePriority(email)
        
        await MainActor.run {
            self.analyzingEmails.remove(email.id)
            
            if let index = self.emails.firstIndex(where: { $0.id == email.id }) {
                self.emails[index] = Email(
                    subject: email.subject,
                    sender: email.sender,
                    senderEmail: email.senderEmail,
                    recipients: email.recipients,
                    content: email.content,
                    timestamp: email.timestamp,
                    isRead: email.isRead,
                    isStarred: email.isStarred,
                    isTrash: email.isTrash,
                    isArchived: email.isArchived,
                    priority: newPriority,
                    requiresAction: email.requiresAction,
                    suggestedAction: email.suggestedAction,
                    attachments: email.attachments,
                    messageId: email.messageId,
                    threadId: email.threadId,
                    labels: email.labels,
                    senderProfileImageURL: email.senderProfileImageURL
                )
                self.filterEmails()
            }
        }
    }
    
    func translateEmail(_ content: String, to language: String) async -> String {
        return await translationService.translate(text: content, to: language)
    }
    
    func readEmailAloud(_ email: Email) {
        // Always use the stored playback speed
        let rate = mappedRate(for: playbackSpeed)
        // If the same email is being read, restart from the beginning
        textToSpeechService.stopSpeaking()
        currentlyReadEmailID = email.id
        textToSpeechService.speak(email.content, rate: rate)
    }
    
    // Map UI speed to AVSpeechUtterance rate
    func mappedRate(for uiSpeed: Float) -> Float {
        switch uiSpeed {
        case 0.5: return 0.35
        case 1.0: return 0.5
        case 1.5: return 0.65
        default: return 0.5
        }
    }
    
    func startSpeechToEmail() {
        speechService.startRecording()
    }
    
    func stopSpeechToEmail() -> String {
        speechService.stopRecording()
        return speechService.transcribedText
    }
    
    func sendEmail(_ draft: EmailDraft) async -> Bool {
        return await emailService.sendEmail(draft)
    }
    
    func createSampleArchivedEmails() {
        // Mark a couple of the sample emails as archived for testing
        let archivedEmailIds = ["sample_message_5", "sample_message_6"] // Marketing emails
        
        for (index, email) in emails.enumerated() {
            if archivedEmailIds.contains(email.messageId ?? "") {
                emails[index] = Email(
                    subject: email.subject,
                    sender: email.sender,
                    senderEmail: email.senderEmail,
                    recipients: email.recipients,
                    content: email.content,
                    timestamp: email.timestamp,
                    isRead: email.isRead,
                    isStarred: email.isStarred,
                    isTrash: email.isTrash,
                    isArchived: true, // Mark as archived
                    priority: email.priority,
                    requiresAction: email.requiresAction,
                    suggestedAction: email.suggestedAction,
                    attachments: email.attachments,
                    messageId: email.messageId,
                    threadId: email.threadId,
                    labels: email.labels.filter { $0 != "INBOX" } // Remove INBOX label
                )
            }
        }
        filterEmails()
    }
    
    // MARK: - Multi-Account Management
    func addAccount(_ account: EmailAccount) {
        DispatchQueue.main.async {
            // Check if account already exists
            if !self.accounts.contains(where: { $0.email == account.email }) {
                self.accounts.append(account)
                print("✅ Added account: \(account.email)")
                
                // Save to persistence
                self.saveAccountsToPersistence()
            } else {
                print("⚠️ Account already exists: \(account.email)")
            }
        }
    }

    func removeAccount(_ account: EmailAccount) {
        DispatchQueue.main.async {
            // Remove from accounts array
            self.accounts.removeAll { $0.id == account.id }
            
            // If this was the current account, switch to another or clear
            if self.currentAccount?.id == account.id {
                self.currentAccount = self.accounts.first
                self.emails.removeAll()
                self.filteredEmails.removeAll()
            }
            
            // Clear persistent cache for this account
            self.clearPersistentCache(for: account)
            
            // Clear memory cache
            self.invalidateCache()
            
            // Save updated accounts to persistence
            self.saveAccountsToPersistence()
            
            print("🗑️ Removed account: \(account.email)")
        }
    }

    
    func setCurrentAccount(_ account: EmailAccount) {
        print("🔄 Switching to account: \(account.email)")
        
        // Stop background services for previous account
        stopBackgroundRefresh()
        stopRealTimeUpdates()
        
        // Immediately update UI state
        DispatchQueue.main.async {
            self.currentAccount = account
            self.emails = []
            self.filteredEmails = []
            self.activeFilters.removeAll()
            self.currentCustomFilter = nil
            self.needsReAuthentication = false
            self.reAuthenticationMessage = ""
            self.isLoading = true
            
            // Save current account to persistence
            self.saveAccountsToPersistence()
        }
        
        // Load emails for the new account using our proven system
        Task {
            await self.loadEmailsForAccount(account)
        }
    }
    
    // MARK: - Clean Account Email Loading System
    
    private func loadEmailsForAccount(_ account: EmailAccount) async {
        print("📧 Loading emails for account: \(account.email)")
        
        // Step 1: Show loading state immediately
        await MainActor.run {
            self.isLoading = true
        }
        
        // Step 2: Load persistent cache into memory cache
        cacheManager.loadPersistentCacheIntoMemory(for: account)
        
        // Step 3: Try to show cached emails with brief loading delay
        if let cachedEmails = cacheManager.getCachedEmails(for: account) {
            print("✅ Found \(cachedEmails.count) cached emails, showing with loading transition")
            
            await MainActor.run {
                self.emails = cachedEmails
                self.updateEmailCategories()
                self.filterEmails()
            }
            
            // Small delay to ensure loading screen is visible (industry standard)
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            await MainActor.run {
                self.isLoading = false
                print("🚀 Account switch completed with loading transition!")
            }
            
            // Start background services
            setupRealTimeUpdates()
            startBackgroundRefresh()
            
            // Load profile images in background
            Task {
                await self.loadProfileImages()
            }
            
            // Step 4: Refresh in background (no UI blocking)
            Task {
                await self.refreshInBackground(for: account)
            }
            
        } else {
            print("📋 No cached emails found, doing fresh load")
            
            // Step 4: No cache available, need fresh load (keeps loading = true)
            await self.loadFreshEmails(for: account)
        }
    }
    
    private func refreshInBackground(for account: EmailAccount) async {
        print("🔄 Background refresh for \(account.email)")
        
        // Check if we have a valid Google session
        guard let currentUser = GIDSignIn.sharedInstance.currentUser,
              currentUser.profile?.email == account.email else {
            print("⚠️ No valid Google session for background refresh")
            await MainActor.run {
                self.needsReAuthentication = true
                self.reAuthenticationMessage = "Tap to sign in for latest emails"
            }
            return
        }
        
        // Do incremental refresh using our proven fetch system
        await fetchNewEmailsOnly()
    }
    
    private func loadFreshEmails(for account: EmailAccount) async {
        print("📧 Loading fresh emails for \(account.email)")
        
        // Check if we have a valid Google session
        guard let currentUser = GIDSignIn.sharedInstance.currentUser,
              currentUser.profile?.email == account.email else {
            print("❌ No valid Google session for fresh load")
            await MainActor.run {
                self.emails = []
                self.filteredEmails = []
                self.isLoading = false
                self.needsReAuthentication = true
                self.reAuthenticationMessage = "Sign in required to load emails"
            }
            return
        }
        
        // Use our proven first-time setup system
        await performFirstTimeSetup(for: account)
        
        // Start background services after successful load
        setupRealTimeUpdates()
        startBackgroundRefresh()
    }

    func allAccounts() -> [EmailAccount] {
        return accounts
    }

    // Add a new custom filter to history
    func saveCustomFilter(_ filter: CustomEmailFilter) {
        savedCustomFilters.insert(filter, at: 0)
    }

    // Remove a saved custom filter
    func removeCustomFilter(_ filter: CustomEmailFilter) {
        savedCustomFilters.removeAll { $0.id == filter.id }
    }

    // Apply a custom filter (temporary or from history)
    func applyCustomFilter(_ filter: CustomEmailFilter) {
        DispatchQueue.main.async {
            // Check if this is a saved filter
            if self.savedCustomFilters.contains(where: { $0.id == filter.id }) {
                // This is a saved filter - set it as active saved filter
                self.activeSavedFilter = filter
                self.currentCustomFilter = nil // Clear any temporary filter
            } else {
                // This is a temporary filter from AI chat
                self.currentCustomFilter = filter
                self.activeSavedFilter = nil // Clear any active saved filter
            }
            self.filterEmails()
        }
    }

    // Clear the current custom filter
    func clearCustomFilter() {
        currentCustomFilter = nil
        activeSavedFilter = nil
        
        // Just re-filter the existing emails - no need to reload
        self.filterEmails()
    }
    

    






    // Show a subtle re-authentication status instead of immediate popup
    private func showReAuthenticationStatus(for account: EmailAccount) async {
        print("ℹ️ Showing re-authentication status for: \(account.email)")
        
        // Set a flag that we need re-authentication for this account
        await MainActor.run {
            self.needsReAuthentication = true
            self.reAuthenticationMessage = "Using cached emails. Tap to refresh with latest data."
        }
        
        // DO NOT attempt background re-authentication automatically
        print("✅ DEBUG: Status set, NOT triggering automatic re-authentication")
    }

    // This should only be called manually by user action
    private func delayedReAuthentication(for account: EmailAccount) async {
        print("🔐 Manual re-authentication triggered")
        
        // DO NOT automatically trigger re-authentication
        // This method should only be called when user explicitly requests it
        print("⚠️ DEBUG: Skipping automatic delayed re-authentication")
    }

    // Manual re-authentication - only call this when user explicitly requests it
    func manualReAuthentication() async {
        guard let currentAccount = currentAccount else {
            print("❌ DEBUG: No current account for manual re-authentication")
            return
        }
        
        print("🔐 DEBUG: Manual re-authentication triggered by user for: \(currentAccount.email)")
        await promptForReAuthentication(account: currentAccount)
    }

    // Prompt for re-authentication when switching to an account that needs it
    private func promptForReAuthentication(account: EmailAccount) async {
        print("🔐 Prompting for re-authentication: \(account.email)")
        
        await MainActor.run {
            self.isLoading = true
            self.needsReAuthentication = false
            self.reAuthenticationMessage = ""
        }
        
        print("🔐 DEBUG: About to call GoogleSignInService.shared.signInWithHint")
        
        // Use Google Sign-In with hint for the specific account
        GoogleSignInService.shared.signInWithHint(email: account.email) { [weak self] success in
            print("✅ DEBUG: Google Sign-In completed with success: \(success)")
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if success {
                    if let user = GIDSignIn.sharedInstance.currentUser,
                       user.profile?.email == account.email {
                        print("✅ Re-authentication successful for: \(account.email)")
                        // Load fresh emails now that we're authenticated
                        Task {
                            await self?.loadRealEmails()
                        }
                    } else if let user = GIDSignIn.sharedInstance.currentUser,
                             let email = user.profile?.email {
                        print("⚠️ Re-authentication was for different account: \(email)")
                        // User signed in with different account, check if we have it
                        if let existingAccount = self?.accounts.first(where: { $0.email == email }) {
                            // Switch to the account they actually signed in with
                            self?.setCurrentAccount(existingAccount)
                        } else {
                            // This is a new account, add it
                            let newAccount = EmailAccount(
                                email: email,
                                provider: "Gmail",
                                displayName: user.profile?.name ?? "",
                                isActive: true,
                                lastSync: Date(),
                                profileImageURL: user.profile?.imageURL(withDimension: 80)
                            )
                            self?.addAccount(newAccount)
                            self?.setCurrentAccount(newAccount)
                        }
                    }
                } else {
                    print("❌ Re-authentication failed for: \(account.email)")
                    // Stay with cached data if available
                    print("📋 Continuing with cached data for: \(account.email)")
                    self?.needsReAuthentication = true
                    self?.reAuthenticationMessage = "Re-authentication failed. Using cached emails."
                }
            }
        }
    }
    
    // MARK: - Unified Category System
    
    // Pre-computed categories for all emails
    @Published var emailCategories: [String: Set<EmailCategoryFilter>] = [:]
    
    // Single source of truth for email categorization
    private func categorizeEmail(_ email: Email) -> Set<EmailCategoryFilter> {
        var categories: Set<EmailCategoryFilter> = []
        
        // Primary categories based on Gmail labels
        if email.labels.contains("INBOX") && !email.isTrash && !email.isArchived {
            categories.insert(.inbox)
        }
        
        if email.labels.contains("SENT") {
            categories.insert(.sent)
        }
        
        if email.isStarred || email.labels.contains("STARRED") {
            categories.insert(.starred)
        }
        
        if email.isTrash || email.labels.contains("TRASH") {
            categories.insert(.trash)
        }
        
        // Archive: Not in INBOX, not SENT-only, not TRASH
        if !email.labels.contains("INBOX") && 
           !email.labels.contains("TRASH") &&
           !email.labels.isEmpty &&
           email.labels != ["SENT"] {
            categories.insert(.archive)
        }
        
        if !email.isRead || email.labels.contains("UNREAD") {
            categories.insert(.unread)
        }
        
        if email.priority == .high || email.priority == .urgent || 
           email.labels.contains("IMPORTANT") {
            categories.insert(.important)
        }
        
        // Log emails with no categories for debugging
        if categories.isEmpty {
            print("⚠️ Email '\(email.subject)' has no categories assigned")
        }
        
        return categories
    }
    
    // Pre-compute categories for all emails
    private func updateEmailCategories() {
        print("🔄 Updating email categories for \(emails.count) emails")
        emailCategories.removeAll()
        
        var categoryCounts: [EmailCategoryFilter: Int] = [:]
        
        for email in emails {
            let categories = categorizeEmail(email)
            emailCategories[email.id] = categories
            
            // Count categories for debugging
            for category in categories {
                categoryCounts[category, default: 0] += 1
            }
        }
        
        print("✅ Updated categories for \(emailCategories.count) emails")
        print("📊 Category breakdown:")
        for (category, count) in categoryCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("   \(category.displayName): \(count)")
        }
        
        // Test category assignment for first email if available
        if let firstEmail = emails.first {
            testCategoryAssignment(for: firstEmail)
        }
        
        // Debug: Check if categories are actually stored
        print("🔍 DEBUG: Verifying category storage...")
        var storedCount = 0
        for email in emails {
            if let categories = emailCategories[email.id] {
                storedCount += 1
                if storedCount <= 3 { // Show first 3 for debugging
                    print("   Email '\(email.subject)' has \(categories.count) categories: \(categories.map { $0.displayName })")
                }
            }
        }
        print("   Total emails with stored categories: \(storedCount)/\(emails.count)")
    }
    
    // MARK: - Email Category Debugging
    
    /// Debug method to verify all email categories are loaded properly
    func debugEmailCategories() {
        print("🔍 DEBUG: Email Categories Analysis")
        print("📧 Total emails loaded: \(emails.count)")
        print("📧 Emails with categories: \(emailCategories.count)")
        
        var categoryCounts: [String: Int] = [:]
        var labelCounts: [String: Int] = [:]
        
        for email in emails {
            // Count by email properties
            if email.isRead { categoryCounts["READ", default: 0] += 1 }
            if !email.isRead { categoryCounts["UNREAD", default: 0] += 1 }
            if email.isStarred { categoryCounts["STARRED", default: 0] += 1 }
            if email.isTrash { categoryCounts["TRASH", default: 0] += 1 }
            if email.isArchived { categoryCounts["ARCHIVED", default: 0] += 1 }
            
            // Count by labels
            for label in email.labels {
                labelCounts[label, default: 0] += 1
            }
        }
        
        print("📊 Email Categories:")
        for (category, count) in categoryCounts.sorted(by: { $0.key < $1.key }) {
            print("   \(category): \(count)")
        }
        
        print("🏷️ Gmail Labels:")
        for (label, count) in labelCounts.sorted(by: { $0.key < $1.key }) {
            print("   \(label): \(count)")
        }
        
        // Show first few emails with their categories
        print("📧 First 5 emails with their categories:")
        for (index, email) in emails.prefix(5).enumerated() {
            let categories = emailCategories[email.id] ?? Set<EmailCategoryFilter>()
            print("   \(index + 1). '\(email.subject)' - Categories: \(categories.map { $0.displayName })")
        }
        
        print("✅ Email category analysis complete")
    }
    
    // Force refresh categories and filters
    func forceRefreshCategories() {
        print("🔄 Force refreshing email categories...")
        updateEmailCategories()
        invalidateFilterCache()
        filterEmails()
        print("✅ Categories and filters refreshed")
    }
    
    // Test category assignment for a specific email
    func testCategoryAssignment(for email: Email) {
        print("🧪 Testing category assignment for: \(email.subject)")
        print("   Labels: \(email.labels)")
        print("   isRead: \(email.isRead), isStarred: \(email.isStarred), isTrash: \(email.isTrash), isArchived: \(email.isArchived)")
        print("   Priority: \(email.priority)")
        
        let categories = categorizeEmail(email)
        print("   Assigned categories: \(categories.map { $0.displayName })")
    }
    
    // MARK: - Profile Image Management
    
    /// Fetch and populate profile images for all emails
    func loadProfileImages() async {
        print("🖼️ Starting to load profile images for \(emails.count) emails")
        
        // Process emails in batches to avoid overwhelming the service
        let batchSize = 10
        let batches = emails.chunked(into: batchSize)
        
        for batch in batches {
            await withTaskGroup(of: Void.self) { group in
                for email in batch {
                    group.addTask {
                        await self.loadProfileImage(for: email)
                    }
                }
            }
            
            // Small delay between batches to be respectful to external services
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        print("✅ Completed loading profile images")
    }
    
    /// Load profile image for a specific email
    private func loadProfileImage(for email: Email) async {
        guard email.senderProfileImageURL == nil else {
            // Already has a profile image URL
            return
        }
        
        print("🖼️ Fetching profile image for: \(email.senderEmail)")
        
        if let profileImageURL = await ProfileImageService.shared.getProfileImageURL(for: email.senderEmail, displayName: email.sender) {
            print("✅ Found profile image for: \(email.senderEmail)")
            
            // Update the email with the profile image URL
            await MainActor.run {
                if let index = self.emails.firstIndex(where: { $0.id == email.id }) {
                    self.emails[index] = Email(
                        subject: email.subject,
                        sender: email.sender,
                        senderEmail: email.senderEmail,
                        recipients: email.recipients,
                        content: email.content,
                        timestamp: email.timestamp,
                        isRead: email.isRead,
                        isStarred: email.isStarred,
                        isTrash: email.isTrash,
                        isArchived: email.isArchived,
                        priority: email.priority,
                        requiresAction: email.requiresAction,
                        suggestedAction: email.suggestedAction,
                        attachments: email.attachments,
                        messageId: email.messageId,
                        threadId: email.threadId,
                        labels: email.labels,
                        senderProfileImageURL: profileImageURL
                    )
                    
                    // Also update selectedEmail if it matches
                    if self.selectedEmail?.id == email.id {
                        self.selectedEmail = self.emails[index]
                    }
                    
                    // clear out the old “no-filter” snapshot
                    self.invalidateFilterCache()
                    // Trigger UI update
                    self.filterEmails()
                }
            }
        } else {
            print("❌ No profile image found for: \(email.senderEmail)")
        }
    }
    
    // MARK: - Enhanced Filter UI Helper
    
    // Get count for a specific filter
    func getFilterCount(_ filter: EmailCategoryFilter) -> Int {
        switch filter {
        case .inbox:
            return emails.filter { isInboxEmail($0) }.count
        case .starred:
            return emails.filter { isStarredEmail($0) }.count
        case .sent:
            return emails.filter { isSentEmail($0) }.count
        case .trash:
            return emails.filter { isTrashEmail($0) }.count
        case .archive:
            return emails.filter { isArchivedEmail($0) }.count
        case .unread:
            return emails.filter { isUnreadEmail($0) }.count
        case .important:
            return emails.filter { isImportantEmail($0) }.count
        }
    }
    
    // Check if a filter is currently active
    func isFilterActive(_ filter: EmailCategoryFilter) -> Bool {
        return activeFilters.contains(filter)
    }
    
    // Get display text for current filter state
    var currentFilterDisplayText: String {
        if let customFilter = currentCustomFilter {
            return "Custom: \(customFilter.title)"
        } else if let savedFilter = activeSavedFilter {
            return "Saved: \(savedFilter.title)"
        } else if activeFilters.isEmpty {
            return "Inbox"
        } else if activeFilters.count == 1 {
            return activeFilters.first!.displayName
        } else {
            return "\(activeFilters.count) filters"
        }
    }
    
    // MARK: - Real-time Update Pipeline
    
    func setupRealTimeUpdates() {
        print("🔄 Setting up real-time updates")
        
        // Listen for email updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEmailUpdates),
            name: .emailsUpdated,
            object: nil
        )
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: .appDidBecomeActive,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: .appWillResignActive,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: .appDidEnterBackground,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: .appWillEnterForeground,
            object: nil
        )
        
        // Start background sync
        if let account = currentAccount {
            EmailSyncService.shared.startBackgroundSync(for: account)
        }
    }
    
    func stopRealTimeUpdates() {
        print("⏹️ Stopping real-time updates")
        
        NotificationCenter.default.removeObserver(self, name: .emailsUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appWillEnterForeground, object: nil)
        
        EmailSyncService.shared.stopBackgroundSync()
    }
    
    @objc private func handleEmailUpdates(_ notification: Notification) {
        guard let info = notification.userInfo,
              let account = info["account"] as? EmailAccount,
              account.id == currentAccount?.id else { return }
        
        print("📧 Received email update notification for \(account.email)")
        
        Task {
            await refreshEmailsInBackground()
        }
    }
    
    private func refreshEmailsInBackground() async {
        // Fetch only new/changed emails
        guard let account = currentAccount else { return }
        
        do {
            let updates = try await gmailAPIService.fetchRecentChanges(
                since: lastFetchTime[cacheKey(for: nil)] ?? Date().addingTimeInterval(-300)
            )
            
            if !updates.isEmpty {
                print("📧 Found \(updates.count) new emails in background")
                
                // Run AI analysis on new emails
                let analyzedUpdates = await analyzeNewEmails(updates)
                
                await MainActor.run {
                    // Merge updates efficiently
                    self.mergeEmailUpdates(analyzedUpdates)
                    
                    // Update categories
                    self.updateEmailCategories()
                    
                    // Refresh current filter
                    self.invalidateFilterCache()
                    self.filterEmails()
                    
                    // Show subtle notification
                    self.showBackgroundUpdateNotification(count: updates.count)
                    
                    // now also load profile images for any newly merged emails
                    Task { await self.loadProfileImages() }
                }
                
                print("✅ Background refresh completed with AI analysis")
            } else {
                print("✅ No new emails in background refresh")
            }
        } catch {
            print("❌ Background refresh failed: \(error)")
        }
    }
    
    private func showBackgroundUpdateNotification(count: Int) {
        // Show a subtle notification for background updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshMessage = "\(count) new emails"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.refreshMessage == "\(count) new emails" {
                    self.refreshMessage = nil
                }
            }
        }
    }
    
    private func mergeEmailUpdates(_ updates: [Email]) {
        var emailLookup = Dictionary(uniqueKeysWithValues: emails.map { ($0.id, $0) })
        
        for update in updates {
            let key = update.id
            emailLookup[key] = update
        }
        
        self.emails = Array(emailLookup.values).sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - App Lifecycle Management
    
    @objc func handleAppDidBecomeActive() {
        print("📱 App became active - resuming real-time updates")
        if let account = currentAccount {
            EmailSyncService.shared.startBackgroundSync(for: account)
        }
    }
    
    @objc func handleAppWillResignActive() {
        print("📱 App will resign active - pausing real-time updates")
        EmailSyncService.shared.stopBackgroundSync()
    }
    
    @objc func handleAppDidEnterBackground() {
        print("📱 App entered background - stopping real-time updates")
        EmailSyncService.shared.stopBackgroundSync()
    }
    
    @objc func handleAppWillEnterForeground() {
        print("📱 App will enter foreground - resuming real-time updates")
        if let account = currentAccount {
            EmailSyncService.shared.startBackgroundSync(for: account)
        }
    }
    
    // MARK: - Enhanced Email Refresh System
    
    func refreshEmails() async {
        print("🔄 Starting email refresh...")
        
        guard let currentAccount = currentAccount else {
            print("❌ No current account for refresh")
            await MainActor.run {
                self.showError("No account selected")
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.needsReAuthentication = false
            self.refreshMessage = "Refreshing emails..."
        }
        
        // Check authentication status
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            print("❌ No authenticated user")
            await MainActor.run {
                self.isLoading = false
                self.needsReAuthentication = true
                self.reAuthenticationMessage = "Sign in required to refresh emails"
            }
            return
        }
        
        print("✅ User authenticated: \(currentUser.profile?.email ?? "unknown")")
        
        // Try to refresh access token if needed
        do {
            try await currentUser.refreshTokensIfNeeded()
            print("✅ Access token refreshed if needed")
        } catch {
            print("⚠️ Token refresh failed: \(error)")
            // Continue anyway - the token might still be valid
        }
        
        // Perform full refresh
        await performFullRefresh(for: currentAccount)
    }
    
    private func performFullRefresh(for account: EmailAccount) async {
        print("🔄 Performing optimized full refresh for \(account.email)")
        
        do {
            await MainActor.run {
                self.refreshMessage = "Loading emails..."
            }
            
            // Use the optimized approach: fetch all emails but only analyze new ones
            print("📧 Fetching all emails for initial load...")
            
            let allEmails = try await gmailAPIService.fetchAllEmailsForRefresh(maxResults: 100)
            print("📧 Fetched \(allEmails.count) total emails")
            
            // Update cache with all emails
            await cacheManager.updateCache(newEmails: allEmails, for: account)
            
            // Update UI immediately with all emails
            await MainActor.run {
                self.emails = allEmails
                
                // Update categories
                self.updateEmailCategories()
                
                // Save to persistent cache
                self.saveToPersistentCache(for: account)
                
                // Update last fetch time
                self.lastFetchTime[self.cacheKey(for: nil)] = Date()
                
                // Clear and reapply filters
                self.invalidateFilterCache()
                self.filterEmails()
                
                self.isLoading = false
                self.refreshMessage = "All emails loaded"
                
                // Clear message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.refreshMessage == "All emails loaded" {
                        self.refreshMessage = nil
                    }
                }
            }
            
            print("✅ Full refresh completed successfully")
            
            // Run AI analysis on emails that don't have priority analysis yet
            await analyzeUnanalyzedEmails()
            
        } catch {
            print("❌ Full refresh failed: \(error)")
            
            // Check if it's a cancellation error
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("⚠️ Request was cancelled - this is normal if app went to background")
                await MainActor.run {
                    self.isLoading = false
                    self.refreshMessage = "Refresh cancelled"
                    
                    // Clear message after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.refreshMessage == "Refresh cancelled" {
                            self.refreshMessage = nil
                        }
                    }
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.refreshMessage = "Failed to load emails"
                    
                    // Clear error message after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if self.refreshMessage == "Failed to load emails" {
                            self.refreshMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    private func analyzeUnanalyzedEmails() async {
        print("🔍 Checking for unanalyzed emails...")
        
        // Find emails that still have default priority (medium)
        let unanalyzedEmails = emails.filter { $0.priority == .medium }
        
        if unanalyzedEmails.isEmpty {
            print("✅ All emails already analyzed")
            return
        }
        
        print("🤖 Running AI analysis on \(unanalyzedEmails.count) unanalyzed emails...")
        
        var updatedEmails = emails
        
        for (index, email) in unanalyzedEmails.enumerated() {
            // Check if task was cancelled
            if Task.isCancelled {
                print("⚠️ AI analysis cancelled")
                break
            }
            
            do {
                // Analyze priority
                let priority = await aiService.analyzePriority(email)
                
                // Analyze if action is required
                let action = await aiService.determineActionRequired(email)
                
                // Create analyzed email with AI insights
                let analyzedEmail = Email(
                    subject: email.subject,
                    sender: email.sender,
                    senderEmail: email.senderEmail,
                    recipients: email.recipients,
                    content: email.content,
                    timestamp: email.timestamp,
                    isRead: email.isRead,
                    isStarred: email.isStarred,
                    isTrash: email.isTrash,
                    isArchived: email.isArchived,
                    priority: priority,
                    requiresAction: action != nil,
                    suggestedAction: action,
                    attachments: email.attachments,
                    messageId: email.messageId,
                    threadId: email.threadId,
                    labels: email.labels,
                    senderProfileImageURL: email.senderProfileImageURL,
                    version: email.version + 1,
                    lastModified: Date(),
                    syncStatus: .synced
                )
                
                // Update the email in the array
                if let emailIndex = updatedEmails.firstIndex(where: { $0.id == email.id }) {
                    updatedEmails[emailIndex] = analyzedEmail
                }
                
                print("✅ Analyzed email \(index + 1)/\(unanalyzedEmails.count): \(email.subject) - Priority: \(priority.rawValue)")
                
            } catch {
                print("❌ Failed to analyze email \(email.subject): \(error)")
                // Keep the original email if analysis fails
            }
        }
        
        // Update the emails array with analyzed results
        await MainActor.run {
            self.emails = updatedEmails
            self.updateEmailCategories()
            self.invalidateFilterCache()
            self.filterEmails()
            
            if let account = self.currentAccount {
                self.saveToPersistentCache(for: account)
            }
        }
        
        print("✅ AI analysis complete for unanalyzed emails")
    }
    
    private func fetchAdditionalCategories(for account: EmailAccount) async {
        print("🔄 Fetching additional email categories in background...")
        
        do {
            var allEmails = self.emails // Start with current emails
            
            // Fetch sent emails
            let sentEmails = try await gmailAPIService.fetchSentEmails(maxResults: 30)
            print("📤 Fetched \(sentEmails.count) sent emails")
            allEmails.append(contentsOf: sentEmails)
            
            // Fetch starred emails
            let starredEmails = try await gmailAPIService.fetchStarredEmails(maxResults: 20)
            print("⭐ Fetched \(starredEmails.count) starred emails")
            allEmails.append(contentsOf: starredEmails)
            
            // Remove duplicates
            let uniqueEmails = removeDuplicatesAndPreserveTimestamps(from: allEmails)
            print("📧 Total unique emails after additional categories: \(uniqueEmails.count)")
            
            // Update cache and UI
            await cacheManager.updateCache(newEmails: uniqueEmails, for: account)
            
            await MainActor.run {
                self.emails = uniqueEmails
                self.updateEmailCategories()
                self.invalidateFilterCache()
                self.filterEmails()
                
                print("✅ Additional categories loaded successfully")
            }
            
        } catch {
            print("⚠️ Failed to fetch additional categories: \(error)")
            // Don't show error to user since we already have inbox emails
        }
    }
    

    
    func handlePullToRefresh() async {
        print("⬇️ Pull to refresh triggered")
        
        // Check authentication status
        if needsReAuthentication && GIDSignIn.sharedInstance.currentUser == nil {
            print("⚠️ Re-authentication needed")
            await manualReAuthentication()
        } else {
            print("✅ Refreshing emails")
            await fetchNewEmailsOnly()
        }
    }

    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        print("❌ Error: \(message)")
        // For now, just log the error
        // In a full implementation, you might want to show an alert or toast
    }
    
    // MARK: - Task Management
    
    private var activeEmailFetchTask: Task<Void, Never>? = nil
    
    func refreshEmailsSafely() {
        // Cancel any in-flight fetch
        activeEmailFetchTask?.cancel()
        
        // Start new fetch
        activeEmailFetchTask = Task {
            await fetchNewEmailsOnly()
        }
    }

    private func fetchNewEmailsOnly() async {
        guard let account = currentAccount else {
            print("❌ No account selected for refresh")
            return
        }

        print("🔄 Refreshing emails for: \(account.email)")
        
        // Create a set of existing email IDs for O(1) lookup performance
        let existingIds = Set(emails.compactMap { $0.messageId })
        print("📊 Current cache: \(emails.count) emails")
        
        do {
            await MainActor.run {
                self.isLoading = true
                self.refreshMessage = "Checking for new emails..."
            }
            
            // Fetch recent emails using relative time (industry standard approach)
            // Use 2 hours for pull-to-refresh to catch any recent emails
            let recentEmails = try await gmailAPIService.fetchRecentEmails(hoursAgo: 2)
            print("📥 Fetched \(recentEmails.count) recent emails")
            
            // Filter to only truly new emails (critical for preventing duplicates)
            let newEmails = recentEmails.filter { email in
                guard let messageId = email.messageId else { return true }
                return !existingIds.contains(messageId)
            }
            
            print("🆕 Found \(newEmails.count) new emails")
            
            if newEmails.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                    self.refreshMessage = "No new emails"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if self.refreshMessage == "No new emails" {
                            self.refreshMessage = nil
                        }
                    }
                    
                    // Restart background refresh after manual refresh
                    if !self.emails.isEmpty {
                        self.startBackgroundRefresh()
                    }
                }
                return
            }
            
            // Analyze new emails with AI
            await MainActor.run {
                self.refreshMessage = "Analyzing \(newEmails.count) new \(newEmails.count == 1 ? "email" : "emails")..."
            }
            
            let analyzedEmails = await analyzeNewEmails(newEmails)
            
            // Merge new emails with existing ones (new emails at the top)
            let updatedEmails = mergeEmails(new: analyzedEmails, existing: emails)
            
            // Update everything
            await MainActor.run {
                self.emails = updatedEmails
                self.updateEmailCategories()
                self.saveToPersistentCache(for: account)
                self.invalidateFilterCache()
                self.filterEmails()
                Task { await self.loadProfileImages() }
                self.isLoading = false
                
                let message = "\(newEmails.count) new \(newEmails.count == 1 ? "email" : "emails")"
                self.refreshMessage = message
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.refreshMessage == message {
                        self.refreshMessage = nil
                    }
                }
                
                // Restart background refresh after manual refresh completes
                if !self.emails.isEmpty {
                    self.startBackgroundRefresh()
                }
            }
            
            print("✅ Refresh complete: added \(newEmails.count) new emails")
            
        } catch {
            print("❌ Refresh failed: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.refreshMessage = "Failed to refresh"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.refreshMessage == "Failed to refresh" {
                        self.refreshMessage = nil
                    }
                }
                
                // Still restart background refresh even after error
                if !self.emails.isEmpty {
                    self.startBackgroundRefresh()
                }
            }
        }
    }
    
    private func mergeEmails(new: [Email], existing: [Email]) -> [Email] {
        // Use dictionary for O(1) lookups and automatic de-duplication
        var emailMap: [String: Email] = [:]
        
        // Add existing emails first
        for email in existing {
            let key = email.messageId ?? email.id
            emailMap[key] = email
        }
        
        // Add or update with new emails (newer data takes precedence)
        for email in new {
            let key = email.messageId ?? email.id
            emailMap[key] = email
        }
        
        // Sort by timestamp (newest first) - standard email client behavior
        return emailMap.values.sorted { $0.timestamp > $1.timestamp }
    }

    private func analyzeNewEmails(_ newEmails: [Email]) async -> [Email] {
        print("🤖 Running AI analysis on \(newEmails.count) new emails...")
        
        var analyzedEmails: [Email] = []
        
        for email in newEmails {
            // Check if task was cancelled
            if Task.isCancelled {
                print("⚠️ AI analysis cancelled")
                break
            }
            
            do {
                // Analyze priority
                let priority = await aiService.analyzePriority(email)
                
                // Analyze if action is required
                let action = await aiService.determineActionRequired(email)
                
                // Create analyzed email with AI insights
                let analyzedEmail = Email(
                    subject: email.subject,
                    sender: email.sender,
                    senderEmail: email.senderEmail,
                    recipients: email.recipients,
                    content: email.content,
                    timestamp: email.timestamp,
                    isRead: email.isRead,
                    isStarred: email.isStarred,
                    isTrash: email.isTrash,
                    isArchived: email.isArchived,
                    priority: priority,
                    requiresAction: action != nil,
                    suggestedAction: action,
                    attachments: email.attachments,
                    messageId: email.messageId,
                    threadId: email.threadId,
                    labels: email.labels,
                    senderProfileImageURL: email.senderProfileImageURL,
                    version: email.version + 1,
                    lastModified: Date(),
                    syncStatus: .synced
                )
                
                analyzedEmails.append(analyzedEmail)
                
                print("✅ Analyzed email: \(email.subject) - Priority: \(priority.rawValue)")
                
            } catch {
                print("❌ Failed to analyze email \(email.subject): \(error)")
                // Keep the original email if analysis fails
                analyzedEmails.append(email)
            }
        }
        
        print("✅ AI analysis complete for \(analyzedEmails.count) emails")
        return analyzedEmails
    }
    
    private func checkAndReanalyzePriorities() async {
        print("🔍 Checking if priorities need re-analysis...")
        
        // Count emails with medium priority (default)
        let mediumPriorityCount = emails.filter { $0.priority == .medium }.count
        let totalCount = emails.count
        
        print("📊 Priority breakdown: \(mediumPriorityCount)/\(totalCount) emails have medium priority")
        
        // If more than 50% of emails have medium priority, we might need to re-analyze
        if mediumPriorityCount > totalCount / 2 {
            print("⚠️ Many emails have default priority, considering re-analysis")
            
            // For now, just log this. In a full implementation, you might want to trigger re-analysis
            // await analyzeEmailPriorities()
        } else {
            print("✅ Priority distribution looks good")
        }
    }
    
    func startBackgroundRefresh() {
        print("🔄 Starting background refresh system")
        print("   Current account: \(currentAccount?.email ?? "none")")
        print("   Email count: \(emails.count)")
        print("   Is app active: \(isAppActive)")
        
        // Stop any existing timer
        stopBackgroundRefresh()
        
        // Don't start if no emails or no account
        guard currentAccount != nil, !emails.isEmpty else {
            print("⚠️ Cannot start background refresh - missing account or emails")
            return
        }
        
        // Reset quick refresh count
        quickRefreshCount = 0
        
        // Start with quick refreshes (every 5 seconds for the first 3 refreshes)
        print("⏱️ Starting quick refresh cycle (every \(Int(quickRefreshInterval)) seconds)")
        scheduleNextRefresh(interval: quickRefreshInterval)
    }

    func stopBackgroundRefresh() {
        print("⏹️ Stopping background refresh")
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = nil
        backgroundRefreshTask?.cancel()
        backgroundRefreshTask = nil
        quickRefreshCount = 0
    }

    private func scheduleNextRefresh(interval: TimeInterval) {
        // Cancel existing timer
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = nil
        
        // Don't schedule if app is not active
        guard isAppActive else {
            print("📱 App not active, skipping background refresh scheduling")
            return
        }
        
        // Verify we still have an account and emails
        guard currentAccount != nil, !emails.isEmpty else {
            print("⚠️ Cannot schedule refresh - missing account or emails")
            return
        }
        
        print("⏰ Scheduling next refresh in \(Int(interval)) seconds at \(Date().addingTimeInterval(interval))")
        
        // Use DispatchQueue instead of Timer for more reliable execution
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self = self else { return }
            
            // Double-check conditions before performing refresh
            guard self.isAppActive, self.currentAccount != nil, !self.emails.isEmpty else {
                print("⚠️ Conditions changed, skipping scheduled refresh")
                return
            }
            
            print("⏰ Timer fired - starting background refresh task")
            
            Task { [weak self] in
                await self?.performBackgroundRefresh()
            }
        }
    }

    private func performBackgroundRefresh() async {
        print("🔄 performBackgroundRefresh called")
        
        // Check if we're already loading
        guard !isLoading else {
            print("⏭️ Skipping background refresh - already loading")
            scheduleNextRefresh(interval: backgroundRefreshInterval)
            return
        }
        
        // Check minimum time between refreshes
        let timeSinceLastRefresh = Date().timeIntervalSince(lastBackgroundRefresh)
        guard timeSinceLastRefresh >= minimumRefreshInterval else {
            print("⏭️ Skipping background refresh - too soon (only \(Int(timeSinceLastRefresh))s since last)")
            scheduleNextRefresh(interval: backgroundRefreshInterval)
            return
        }
        
        guard let account = currentAccount else {
            print("❌ No account for background refresh")
            return
        }
        
        print("🔄 Performing background refresh #\(quickRefreshCount + 1) at \(Date())")
        lastBackgroundRefresh = Date()
        
        // Cancel any existing background task
        backgroundRefreshTask?.cancel()
        
        // Perform the silent refresh
        await performSilentRefresh()
        
        // Schedule next refresh
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            
            if self.quickRefreshCount < self.maxQuickRefreshes {
                // Still in quick refresh period
                self.quickRefreshCount += 1
                print("📊 Quick refresh #\(self.quickRefreshCount) completed, scheduling next in \(Int(self.quickRefreshInterval))s")
                self.scheduleNextRefresh(interval: self.quickRefreshInterval)
            } else {
                // Switch to normal refresh interval
                print("📊 Quick refreshes done, switching to normal interval (\(Int(self.backgroundRefreshInterval))s)")
                self.scheduleNextRefresh(interval: self.backgroundRefreshInterval)
            }
        }
    }

    private func performSilentRefresh() async {
        guard let account = currentAccount else {
            print("❌ No current account for silent refresh")
            return
        }
        
        print("🤫 Starting silent refresh at \(Date())")
        
        // Store existing email IDs for comparison
        let existingIds = Set(emails.compactMap { $0.messageId })
        print("   Existing emails: \(existingIds.count)")
        
        do {
            // Fetch recent emails (last 1 hour for background refresh)
            print("   Fetching emails from last hour...")
            let recentEmails = try await gmailAPIService.fetchRecentEmails(hoursAgo: 1)
            print("   Fetched \(recentEmails.count) recent emails")
            
            // Filter to only new emails
            let newEmails = recentEmails.filter { email in
                guard let messageId = email.messageId else { return true }
                return !existingIds.contains(messageId)
            }
            
            if !newEmails.isEmpty {
                print("📬 Found \(newEmails.count) new emails in background")
                
                // Analyze new emails
                let analyzedEmails = await analyzeNewEmails(newEmails)
                
                // Merge with existing emails
                let updatedEmails = mergeEmails(new: analyzedEmails, existing: emails)
                
                await MainActor.run {
                    // Update emails without showing loading indicator
                    self.emails = updatedEmails
                    self.updateEmailCategories()
                    self.saveToPersistentCache(for: account)
                    self.invalidateFilterCache()
                    self.filterEmails()
                    
                    // Show subtle notification
                    self.showNewEmailNotification(count: newEmails.count)
                    
                    print("✅ Silent refresh completed - added \(newEmails.count) new emails")
                }
            } else {
                print("✅ No new emails in background refresh")
            }
        } catch {
            print("❌ Silent refresh failed: \(error)")
            // Don't show error to user for background refreshes
        }
    }

    private func showNewEmailNotification(count: Int) {
        // Only show notification if we're not already showing a message
        guard refreshMessage == nil else { return }
        
        let message = "\(count) new \(count == 1 ? "email" : "emails")"
        refreshMessage = message
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.refreshMessage == message {
                self.refreshMessage = nil
            }
        }
        
        // Optional: Play a subtle sound or haptic feedback
        playNewEmailSound()
    }

    private func playNewEmailSound() {
        // Play subtle haptic feedback for new emails
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func setupLifecycleObservers() {
        // App became active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // App will resign active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // App entered background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // App will enter foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        print("📱 App became active at \(Date())")
        isAppActive = true
        
        // Start background refresh when app becomes active
        if currentAccount != nil && !emails.isEmpty {
            print("✅ Conditions met - starting background refresh system")
            startBackgroundRefresh()
        } else {
            print("⚠️ Not starting background refresh:")
            print("   Current account: \(currentAccount?.email ?? "nil")")
            print("   Email count: \(emails.count)")
        }
    }

    @objc private func appWillResignActive() {
        print("📱 App will resign active at \(Date())")
        isAppActive = false
        stopBackgroundRefresh()
    }

    @objc private func appDidEnterBackground() {
        print("📱 App entered background at \(Date())")
        isAppActive = false
        stopBackgroundRefresh()
    }

    @objc private func appWillEnterForeground() {
        print("📱 App will enter foreground at \(Date())")
        isAppActive = true
        
        // Perform immediate refresh when coming back to foreground
        if currentAccount != nil && !emails.isEmpty {
            print("🔄 Performing immediate refresh on foreground")
            Task {
                await performBackgroundRefresh()
            }
        }
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
} 
