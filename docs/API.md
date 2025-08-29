# API Documentation

This document outlines the API architecture and integration patterns used in vibEmail.

## 🌐 External APIs

### Gmail API Integration

#### Authentication
```swift
// OAuth2 Flow
GoogleSignInService.shared.signIn { success in
    // Handle authentication result
}
```

#### Core Email Operations
```swift
// Fetch emails
let emails = try await gmailAPIService.fetchEmails(maxResults: 50)

// Send email
let success = try await gmailAPIService.sendEmail(draft)

// Modify email labels
try await gmailAPIService.modifyLabels(messageId: id, addLabels: ["STARRED"])
```

#### Supported Operations
- **Read Operations**: Fetch inbox, sent, trash, archive, starred emails
- **Write Operations**: Send, reply, forward emails
- **Label Management**: Star, archive, trash, mark as read/unread
- **Search**: Query-based email search
- **Attachments**: Download and upload attachments

## 🏗 Internal Service Architecture

### Service Layer Pattern

#### EmailViewModel (Controller)
```swift
class EmailViewModel: ObservableObject {
    @Published var emails: [Email] = []
    @Published var isLoading = false
    
    func loadEmails() async {
        // Orchestrates data loading
    }
}
```

#### GmailAPIService (Network Layer)
```swift
class GmailAPIService {
    func fetchEmails(maxResults: Int) async throws -> [Email]
    func sendEmail(_ draft: EmailDraft) async throws -> Bool
    func modifyLabels(messageId: String, addLabels: [String]) async throws -> Bool
}
```

#### EmailCacheManager (Data Layer)
```swift
class EmailCacheManager {
    func getCachedEmails(for account: EmailAccount) -> [Email]?
    func updateCache(newEmails: [Email], for account: EmailAccount) async
}
```

#### AIService (Intelligence Layer)
```swift
class AIService {
    func analyzePriority(for email: Email) async -> EmailPriority
    func generateActionSuggestions(for email: Email) async -> [EmailAction]
}
```

## 🤖 AI/ML API Design

### Priority Analysis Engine

#### Input Processing
```swift
struct EmailAnalysisInput {
    let subject: String
    let content: String
    let sender: String
    let timestamp: Date
    let labels: [String]
}
```

#### Analysis Pipeline
```swift
func analyzeEmail(_ input: EmailAnalysisInput) async -> EmailAnalysis {
    let contentScore = analyzeContent(input.content)
    let senderScore = analyzeSender(input.sender)
    let urgencyScore = analyzeUrgency(input.subject, input.content)
    
    return EmailAnalysis(
        priority: calculatePriority(contentScore, senderScore, urgencyScore),
        suggestedActions: generateActions(input),
        confidence: calculateConfidence(scores)
    )
}
```

#### Output Format
```swift
struct EmailAnalysis {
    let priority: EmailPriority
    let suggestedActions: [EmailAction]
    let confidence: Double
    let processingTime: TimeInterval
}
```

## 📱 Internal APIs

### Cache Management API

#### Memory Cache
```swift
// Fast access for frequently used data
func getCachedEmails(for account: EmailAccount) -> [Email]?
func setCachedEmails(_ emails: [Email], for account: EmailAccount)
```

#### Persistent Cache
```swift
// Survives app restarts
func loadFromPersistentCache(for account: EmailAccount) -> [Email]?
func saveToPersistentCache(_ emails: [Email], for account: EmailAccount)
```

#### Cache Invalidation
```swift
func invalidateCache(for account: EmailAccount)
func invalidateAllCaches()
```

### State Management API

#### Account Management
```swift
func setCurrentAccount(_ account: EmailAccount)
func addAccount(_ account: EmailAccount)
func removeAccount(_ account: EmailAccount)
```

#### Email Actions
```swift
func markAsRead(_ email: Email)
func toggleStar(_ email: Email) async
func archiveEmail(_ email: Email)
func deleteEmail(_ email: Email)
```

#### Filter Management
```swift
func applyFilter(_ filter: EmailCategoryFilter)
func clearFilters()
func searchEmails(query: String)
```

## 🔄 Data Flow Architecture

### Read Operations
```
User Request → ViewModel → Cache Check → API Call → Data Processing → UI Update
```

### Write Operations
```
User Action → Optimistic UI Update → API Call → Success/Failure → Confirmation/Rollback
```

### Background Sync
```
Timer → Background Task → API Delta → Cache Update → UI Notification
```

## 🛡 Error Handling

### Error Types
```swift
enum EmailError: Error {
    case networkError(Error)
    case authenticationError
    case rateLimitExceeded
    case invalidEmailFormat
    case cacheCorruption
}
```

### Error Recovery
```swift
func handleError(_ error: EmailError) {
    switch error {
    case .networkError:
        // Retry with exponential backoff
    case .authenticationError:
        // Prompt for re-authentication
    case .rateLimitExceeded:
        // Wait and retry
    case .invalidEmailFormat:
        // Show user error
    case .cacheCorruption:
        // Clear cache and reload
    }
}
```

## 📊 Performance Considerations

### Rate Limiting
- Gmail API: 250 quota units per user per 100 seconds
- Implemented intelligent batching and caching
- Exponential backoff for rate limit errors

### Caching Strategy
- **L1 Cache**: In-memory for active data
- **L2 Cache**: Persistent storage for offline access
- **Cache Invalidation**: Smart invalidation based on data age and user actions

### Background Processing
- Incremental sync to minimize data transfer
- Intelligent scheduling based on user patterns
- Power-efficient background refresh

## 🔐 Security Considerations

### Authentication
- OAuth2 with secure token storage
- Automatic token refresh
- Secure logout and token revocation

### Data Protection
- Encrypted local storage
- HTTPS-only communication
- No sensitive data in logs

### Privacy
- Minimal data collection
- Local AI processing when possible
- Clear data deletion policies

## 📈 Monitoring and Analytics

### Performance Metrics
```swift
struct PerformanceMetrics {
    let apiResponseTime: TimeInterval
    let cacheHitRate: Double
    let emailProcessingTime: TimeInterval
    let uiRenderingTime: TimeInterval
}
```

### Error Tracking
```swift
func trackError(_ error: Error, context: String) {
    // Log error for debugging (development only)
    // No user data included in logs
}
```

## 🔄 API Versioning

### Current Version: v1.0
- Gmail API v1
- Internal service interfaces stable
- Backward compatibility maintained

### Future Considerations
- API versioning strategy for breaking changes
- Migration paths for data format changes
- Feature flag system for gradual rollouts

---

*This API documentation reflects the current architecture and will be updated as the project evolves.*
