import Foundation

// MARK: - Email Sync Service
class EmailSyncService {
    static let shared = EmailSyncService()
    
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 30 // seconds
    private var lastSyncToken: String?
    private var isSyncing = false
    
    private init() {}
    
    func startBackgroundSync(for account: EmailAccount) {
        stopBackgroundSync()
        
        print("🔄 Starting background sync for \(account.email)")
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task {
                await self.performIncrementalSync(for: account)
            }
        }
    }
    
    func stopBackgroundSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏹️ Stopped background sync")
    }
    
    private func performIncrementalSync(for account: EmailAccount) async {
        guard !isSyncing else {
            print("⚠️ Sync already in progress, skipping")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Fetch only changes since last sync
        do {
            let changes = try await fetchDeltaChanges(since: lastSyncToken)
            
            if !changes.isEmpty {
                await processDeltaChanges(changes, for: account)
                
                // Notify UI of updates
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .emailsUpdated,
                        object: nil,
                        userInfo: ["account": account, "changeCount": changes.count]
                    )
                }
            }
        } catch {
            print("❌ Incremental sync failed: \(error)")
        }
    }
    
    private func fetchDeltaChanges(since token: String?) async throws -> [EmailChange] {
        // For now, return empty array
        // In a real implementation, this would use Gmail's History API
        return []
    }
    
    private func processDeltaChanges(_ changes: [EmailChange], for account: EmailAccount) async {
        // Process the changes
        print("📧 Processing \(changes.count) email changes")
    }
}

struct EmailChange {
    enum ChangeType {
        case added
        case modified
        case deleted
        case labelsChanged
    }
    
    let type: ChangeType
    let messageId: String
    let email: Email?
}

// MARK: - Notification Names
extension Notification.Name {
    static let emailsUpdated = Notification.Name("emailsUpdated")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let appWillResignActive = Notification.Name("appWillResignActive")
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
} 