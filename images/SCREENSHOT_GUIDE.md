# 📸 Screenshot & Branding Guide

## 🎯 **Screenshots Needed for README**

### **Essential Screenshots (Priority 1)**
Take these screenshots to showcase core functionality:

1. **Email List View** (`screenshots/email-list.png`)
   - Show the main email list with AI priority indicators
   - Include different priority levels (high, medium, low)
   - Show star/unstar, archive icons
   - Recommended size: 390x844 (iPhone 14)

2. **Email Detail View** (`screenshots/email-detail.png`)
   - Open email with AI analysis visible
   - Show action buttons (reply, forward, archive, etc.)
   - Include priority indicator and AI insights
   - Recommended size: 390x844 (iPhone 14)

3. **AI Features Demo** (`screenshots/ai-features.png`)
   - Show AI-generated reply or email composition
   - Highlight smart suggestions or priority analysis
   - Demonstrate the AI-powered features
   - Recommended size: 390x844 (iPhone 14)

### **Nice-to-Have Screenshots (Priority 2)**
4. **Multi-Account Switching** (`screenshots/account-switching.png`)
5. **Email Composition** (`screenshots/compose-email.png`)
6. **Settings/Filters** (`screenshots/settings.png`)

## 📱 **How to Take Perfect Screenshots**

### **iOS Simulator Method (Recommended)**
1. **Open iOS Simulator**
   ```bash
   # Run your app in simulator
   open vibEmail.xcodeproj
   # Build and run (Cmd+R)
   ```

2. **Take Screenshots**
   - Use `Cmd+S` in simulator to save screenshot
   - Screenshots save to Desktop by default
   - Choose iPhone 14 for best compatibility

3. **Optimize Size**
   ```bash
   # Optional: Resize for web (recommended 800px width max)
   sips -Z 800 screenshot.png --out screenshot.png
   ```

### **Physical Device Method**
1. **Take Screenshots**
   - Volume Up + Power button simultaneously
   - Screenshots save to Photos app

2. **Transfer to Computer**
   - AirDrop, iCloud Photos, or cable transfer
   - Save to `images/screenshots/` folder

## 🎨 **Branding Assets Available**

### **Logos** (in `images/branding/`)
- `logo.png` - Full app icon (1024x1024)
- `logo-no-text.png` - Icon without text (180x180)
- `logo-rounded.png` - Rounded version (180x180)

### **Usage Guidelines**
- **Header Logo**: Use `logo-no-text.png` (smaller, cleaner)
- **App Store Links**: Use `logo.png` (full resolution)
- **Social Media**: Use `logo-rounded.png` (friendly rounded edges)

## 🖼️ **Image Optimization Best Practices**

### **File Sizes**
- Screenshots: Keep under 1MB each
- Logos: Keep under 200KB each
- Use PNG for screenshots (crisp UI elements)
- Use JPEG for photos (if any)

### **Dimensions**
- **Mobile Screenshots**: 390x844 (iPhone 14) or 375x812 (iPhone 13)
- **README Width**: Max 800px wide for GitHub readability
- **Logos**: Square format preferred (1:1 aspect ratio)

## 🚀 **Quick Commands for Screenshot Setup**

```bash
# Navigate to project root
cd /Users/bryansun/git/vibEmail

# Take screenshots and move them:
# 1. Take screenshots using simulator (Cmd+S)
# 2. Move from Desktop to project:
mv ~/Desktop/Simulator*.png images/screenshots/

# Rename appropriately:
mv images/screenshots/Simulator*.png images/screenshots/email-list.png
# Repeat for other screenshots

# Optimize sizes (optional):
sips -Z 800 images/screenshots/*.png
```

## ✅ **Checklist Before Adding to README**

- [ ] Screenshots show app in best light (clean UI, good data)
- [ ] Images are properly sized (not too large for GitHub)
- [ ] File names are descriptive and consistent
- [ ] All images are in correct folders
- [ ] Test images display correctly in README preview

## 🔗 **Ready to Update README?**

Once you have screenshots, update the README with:

```markdown
![vibEmail Logo](images/branding/logo-no-text.png)

## 📱 Screenshots

<p align="center">
  <img src="images/screenshots/email-list.png" width="250" alt="Email List">
  <img src="images/screenshots/email-detail.png" width="250" alt="Email Detail">
  <img src="images/screenshots/ai-features.png" width="250" alt="AI Features">
</p>
```
