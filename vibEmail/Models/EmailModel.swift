import Foundation

struct Email: Identifiable, Codable, Hashable {
    let id: String
    let subject: String
    let sender: String
    let senderEmail: String
    let recipients: [String]
    let content: String
    let timestamp: Date
    let isRead: Bool
    let isStarred: Bool
    let isTrash: Bool
    let isArchived: Bool
    let priority: EmailPriority
    let requiresAction: Bool
    let suggestedAction: EmailAction?
    let attachments: [EmailAttachment]
    let messageId: String? // Gmail message ID for API operations
    let threadId: String? // Gmail thread ID for grouping
    let labels: [String]
    let senderProfileImageURL: URL? // Profile image URL for the sender
    
    // New properties for better tracking
    let version: Int // Increment on each update
    let lastModified: Date // Track when email was last modified
    let syncStatus: SyncStatus // Track sync state
    
    enum SyncStatus: String, Codable, Hashable {
        case synced = "synced"
        case pending = "pending"
        case error = "error"
        case local = "local" // Local changes not yet synced
    }
    
    init(subject: String, sender: String, senderEmail: String, recipients: [String], content: String, timestamp: Date = Date(), isRead: Bool = false, isStarred: Bool = false, isTrash: Bool = false, isArchived: Bool = false, priority: EmailPriority = .medium, requiresAction: Bool = false, suggestedAction: EmailAction? = nil, attachments: [EmailAttachment] = [], messageId: String? = nil, threadId: String? = nil, labels: [String] = [], senderProfileImageURL: URL? = nil, version: Int = 1, lastModified: Date = Date(), syncStatus: SyncStatus = .synced) {
        // Use messageId as the identifier, or generate a unique string if not available
        self.id = messageId ?? UUID().uuidString
        
        self.subject = subject
        self.sender = sender
        self.senderEmail = senderEmail
        self.recipients = recipients
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.isStarred = isStarred
        self.isTrash = isTrash
        self.isArchived = isArchived
        self.priority = priority
        self.requiresAction = requiresAction
        self.suggestedAction = suggestedAction
        self.attachments = attachments
        self.messageId = messageId
        self.threadId = threadId
        self.labels = labels
        self.senderProfileImageURL = senderProfileImageURL
        self.version = version
        self.lastModified = lastModified
        self.syncStatus = syncStatus
    }
}

enum EmailPriority: String, CaseIterable, Codable, Hashable {
    case urgent = "Urgent"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case update = "Update"
    
    var priorityLevel: Int {
        switch self {
        case .urgent: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .update: return 1
        }
    }
    
    var color: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "green"
        case .update: return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "circle.fill"
        case .low: return "minus.circle.fill"
        case .update: return "info.circle.fill"
        }
    }
}

enum EmailAction: String, CaseIterable, Codable, Hashable {
    case reply = "Reply"
    case forward = "Forward"
    case archive = "Archive"
    case delete = "Delete"
    case markAsRead = "Mark as Read"
    case star = "Star"
}

struct EmailAttachment: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let size: Int64
    let type: String
    let url: URL?
}

struct EmailDraft: Identifiable, Codable {
    let id = UUID()
    var subject: String
    var recipients: [String]
    var content: String
    var attachments: [EmailAttachment]
    var tone: EmailTone
    var isReply: Bool
    var originalEmailId: String?
    var timestamp: Date
    
    init(subject: String = "", recipients: [String] = [], content: String = "", attachments: [EmailAttachment] = [], tone: EmailTone = .professional, isReply: Bool = false, originalEmailId: String? = nil) {
        self.subject = subject
        self.recipients = recipients
        self.content = content
        self.attachments = attachments
        self.tone = tone
        self.isReply = isReply
        self.originalEmailId = originalEmailId
        self.timestamp = Date()
    }
}

enum EmailTone: String, CaseIterable, Codable {
    case professional = "Professional"
    case friendly = "Friendly"
    case casual = "Casual"
    case formal = "Formal"
    case persuasive = "Persuasive"
    case apologetic = "Apologetic"
    case enthusiastic = "Enthusiastic"
    case urgent = "Urgent"
    case humorous = "Humorous"
    case angry = "Angry"
    case original = "Original Transcript"
    
    var description: String {
        switch self {
        case .professional: return "Business-like and formal"
        case .friendly: return "Warm and approachable"
        case .casual: return "Relaxed and informal"
        case .formal: return "Very formal and structured"
        case .persuasive: return "Convincing and compelling"
        case .apologetic: return "Sincere and regretful"
        case .enthusiastic: return "Excited and positive"
        case .urgent: return "Time-sensitive and important"
        case .humorous: return "Light-hearted and funny"
        case .angry: return "Firm and direct"
        case .original: return "Keep original transcript"
        }
    }
}

struct EmailAccount: Identifiable, Codable {
    let id = UUID()
    let email: String
    let provider: String
    let displayName: String
    let isActive: Bool
    let lastSync: Date?
    var profileImageURL: URL?
} 