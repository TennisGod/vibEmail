import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let vibBlack = Color(red: 0.0, green: 0.0, blue: 0.0) // Pure black
    static let vibWhite = Color(red: 1.0, green: 1.0, blue: 1.0) // Pure white
    static let vibYellow = Color(red: 1.0, green: 0.843, blue: 0.0) // Bright yellow from logo
    static let vibGray = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray
    
    // MARK: - Gray Scale
    static let vibGrayLight = Color(red: 0.95, green: 0.95, blue: 0.95) // Very light gray
    static let vibGrayMedium = Color(red: 0.6, green: 0.6, blue: 0.6) // Medium gray
    static let vibGrayDark = Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray
    
    // MARK: - Semantic Colors
    static let vibPrimary = vibYellow // Primary brand color
    static let vibSecondary = vibGray // Secondary brand color
    static let vibBackground = vibBlack // Main background
    static let vibSurface = vibGrayDark // Surface elements
    static let vibText = vibWhite // Primary text
    static let vibTextSecondary = vibGrayMedium // Secondary text
    
    // MARK: - Status Colors
    static let vibSuccess = Color(red: 0.2, green: 0.8, blue: 0.2) // Green for success
    static let vibWarning = vibYellow // Yellow for warnings
    static let vibError = Color(red: 0.9, green: 0.2, blue: 0.2) // Red for errors
    static let vibInfo = Color(red: 0.2, green: 0.6, blue: 0.9) // Blue for info
}

// MARK: - Color Theme
struct VibEmailTheme {
    static let primary = Color.vibPrimary
    static let secondary = Color.vibSecondary
    static let background = Color.vibBackground
    static let surface = Color.vibSurface
    static let text = Color.vibText
    static let textSecondary = Color.vibTextSecondary
    
    // Priority colors
    static let urgent = Color.vibError
    static let high = Color.vibWarning
    static let medium = Color.vibYellow
    static let low = Color.vibGrayMedium
} 