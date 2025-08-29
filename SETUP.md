# Setup Guide for vibEmail

This guide will help you set up and run the vibEmail project locally.

## 📋 Prerequisites

### System Requirements
- **macOS**: 12.0+ (Monterey or later)
- **Xcode**: 14.0+ 
- **iOS Simulator**: iOS 15.0+ or physical device
- **Swift**: 5.7+

### Apple Developer Account
- Required for device testing
- Free account sufficient for local development
- Paid account needed for App Store distribution

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/bryanopenemr/vibEmail.git
cd vibEmail
```

### 2. Open in Xcode
```bash
open vibEmail.xcodeproj
```

### 3. Configure Gmail API (Required)

#### Step 3.1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the Gmail API for your project

#### Step 3.2: Create OAuth2 Credentials
1. Navigate to "Credentials" in the Google Cloud Console
2. Click "Create Credentials" → "OAuth client ID"
3. Select "iOS" as the application type
4. Enter your bundle identifier: `com.bryansun.vibEmail`
5. Download the `GoogleService-Info.plist` file

#### Step 3.3: Add Configuration File
1. Download the `GoogleService-Info.plist` file from Google Cloud Console
2. Copy the downloaded file to your project root directory, or create from example:
   ```bash
   cp GoogleService-Info.plist.example GoogleService-Info.plist
   ```
3. If using the example template, replace all placeholder values with your actual credentials
4. Drag `GoogleService-Info.plist` into your Xcode project
5. Ensure it's added to the target
6. Verify it appears in the project navigator

**Note**: The `GoogleService-Info.plist` file is ignored by git for security. Never commit your actual API credentials.

### 4. Configure OpenAI API Key (Optional)

For AI features to work, you need an OpenAI API key:

1. **Get OpenAI API Key**
   - Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key (starts with `sk-`)

2. **Configure in Info.plist**
   ```xml
   <key>OPENAI_API_KEY</key>
   <string>your-openai-api-key-here</string>
   ```

3. **Alternative: Environment Variable**
   ```bash
   export OPENAI_API_KEY="your-openai-api-key-here"
   ```

**Note**: If no API key is configured, AI features will show simulated responses for demo purposes.

### 5. Configure URL Scheme

Update `Info.plist` with your OAuth2 URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>vibEmail</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_CLIENT_ID` with the value from your `GoogleService-Info.plist`.

### 5. Build and Run
1. Select your target device or simulator
2. Press `Cmd+R` to build and run
3. The app should launch successfully

## 🔧 Configuration Options

### Development vs Production

#### Development Setup
- Use development Google Cloud project
- Enable additional logging in debug builds
- Test with simulator or development device

#### Production Considerations
- Create separate Google Cloud project for production
- Configure proper OAuth2 scopes
- Test on multiple devices and iOS versions

### Bundle Identifier
Default: `com.bryansun.vibEmail`

To change:
1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Update the bundle identifier
4. Update Google OAuth2 configuration accordingly

## 📱 Testing

### Simulator Testing
- Works for most functionality
- Gmail authentication will open Safari for OAuth2
- Full email functionality available

### Device Testing
- Recommended for final testing
- Better performance representation
- Real-world network conditions

### Test Accounts
- Use your personal Gmail account for testing
- Consider creating a separate test Gmail account
- Ensure test account has varied email content

## 🛠 Troubleshooting

### Common Issues

#### "GoogleService-Info.plist not found"
**Solution**: Ensure the file is properly added to the Xcode project target.

#### "OAuth2 redirect failed"
**Solutions**:
- Verify URL scheme in Info.plist matches Google configuration
- Check bundle identifier consistency
- Ensure Gmail API is enabled in Google Cloud Console

#### "Network request failed"
**Solutions**:
- Check internet connectivity
- Verify Gmail API credentials
- Check Google Cloud Console for API quotas

#### "Build failed with signing errors"
**Solutions**:
- Ensure you have a valid Apple Developer account
- Check code signing configuration in Xcode
- Update provisioning profiles if needed

### Debug Logging

Enable detailed logging by setting log level in `EmailViewModel.swift`:

```swift
// Add this for additional debugging
print("🔍 DEBUG: [Additional debugging information]")
```

### Performance Issues

If experiencing slow performance:
1. Test on a physical device instead of simulator
2. Check available storage space
3. Clear app data and restart
4. Verify network connectivity

## 🔒 Security Setup

### Keychain Configuration
The app automatically configures keychain access for secure token storage.

### App Transport Security
The project includes proper ATS configuration for secure network communication.

### Permissions
The app requests minimal permissions:
- Internet access for Gmail API
- Keychain access for secure storage

## 📚 Development Tips

### Code Organization
- Models: Data structures and business logic
- ViewModels: MVVM pattern with Combine
- Views: SwiftUI components
- Services: API and business services

### Best Practices
- Follow Swift style guidelines
- Use meaningful commit messages
- Test on multiple devices and iOS versions
- Keep sensitive data out of version control

### Debugging
- Use Xcode debugger for runtime issues
- Console logs for API debugging
- Network debugging with proxy tools if needed

## 🚀 Deployment

### TestFlight Distribution
1. Archive the project in Xcode
2. Upload to App Store Connect
3. Configure TestFlight testing
4. Invite test users

### App Store Release
1. Complete App Store Connect setup
2. Provide required metadata and screenshots
3. Submit for review
4. Release upon approval

## 📞 Support

If you encounter issues not covered in this guide:

### Resources
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Gmail API Documentation](https://developers.google.com/gmail/api)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

### Contact
- **Email**: hsiaochengsun@gmail.com
- **GitHub Issues**: For bug reports and feature requests
- **LinkedIn**: [linkedin.com/in/brya](https://linkedin.com/in/brya)

---

**Note**: This project is configured for educational and portfolio purposes. Ensure you have proper rights and permissions for any commercial use.
