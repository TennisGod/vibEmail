import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isSearching = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search emails...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .font(.system(size: 16))
                .onChange(of: text) { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching = !newValue.isEmpty
                    }
                }
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false
                        isSearching = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.blue.opacity(0.3) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBarView(text: .constant(""))
        SearchBarView(text: .constant("meeting"))
    }
    .padding()
} 