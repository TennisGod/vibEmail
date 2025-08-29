import SwiftUI

struct PriorityTagView: View {
    let priority: EmailPriority
    let isAnalyzing: Bool
    @State private var isAnimated = false
    
    init(priority: EmailPriority, isAnalyzing: Bool = false) {
        self.priority = priority
        self.isAnalyzing = isAnalyzing
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if isAnalyzing {
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: .vibPrimary))
                
                Text("AI Analyzing...")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } else {
                Image(systemName: priority.icon)
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Text(priority.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(backgroundColor.opacity(0.3), lineWidth: 0.5)
                )
        )
        .foregroundColor(backgroundColor)
        .scaleEffect(isAnimated ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: isAnimated)
        .onAppear {
            if !isAnalyzing && (priority == .urgent || priority == .high) {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isAnimated = true
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isAnalyzing {
            return .vibPrimary
        }
        
        switch priority {
        case .urgent:
            return .vibError
        case .high:
            return .vibWarning
        case .medium:
            return .vibPrimary
        case .low:
            return .vibGrayMedium
        case .update:
            return .vibInfo
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        PriorityTagView(priority: .urgent)
        PriorityTagView(priority: .high)
        PriorityTagView(priority: .medium)
        PriorityTagView(priority: .low)
        PriorityTagView(priority: .update)
        PriorityTagView(priority: .medium, isAnalyzing: true)
    }
    .padding()
} 
