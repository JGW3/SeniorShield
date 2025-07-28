# 🛡️ SeniorShield - Scam Prevention App

**Protecting seniors from online and phone scams through education and awareness.**

SeniorShield is a Flutter mobile application designed specifically to help seniors identify, avoid, and report common scams. The app combines real-time FTC alert monitoring with an intelligent local chatbot and community-driven scam reporting.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

## ✨ Features

### 🔍 **Smart Scam Detection**
- **AI-Powered Chatbot**: Local chatbot that provides personalized scam awareness guidance
- **Pattern Recognition**: Identifies common scam tactics (IRS, tech support, romance, prize scams)
- **Real-time Analysis**: Instant feedback on suspicious calls, emails, and messages

### 📞 **Phone Number Protection**
- **Scam Number Database**: Check phone numbers against known scam databases
- **Community Reports**: Report and check numbers reported by other users
- **Pattern Detection**: Identifies suspicious number patterns and fake area codes
- **Local Storage**: All data stored locally on device for privacy

### 📰 **FTC Alert Integration**
- **Real-time Alerts**: Automatically fetches latest consumer alerts from FTC.gov
- **Smart Scraping**: Ethical web scraping with rate limiting and caching
- **Push Notifications**: Optional notifications for new scam alerts
- **Offline Access**: Cached alerts available without internet connection

### 👥 **Senior-Friendly Design**
- **Large Text & Buttons**: Optimized for easy reading and navigation
- **Voice Features**: Text-to-speech for chatbot responses
- **Dark Mode**: Eye-friendly dark theme option
- **Simple Navigation**: Intuitive interface designed for seniors

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Android Studio or VS Code
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YourUsername/SeniorShield.git
   cd SeniorShield
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

That's it! No server setup required - everything runs locally on the device.

## 📱 How to Use

### For Seniors
1. **Browse FTC Alerts**: Stay informed about the latest scam warnings
2. **Chat with Assistant**: Ask questions about suspicious calls, emails, or messages
3. **Check Phone Numbers**: Verify if a phone number has been reported as a scam
4. **Report Scams**: Help protect others by reporting suspicious numbers
5. **Enable Voice**: Turn on text-to-speech to hear responses

### Example Conversations
- "Someone called saying I owe back taxes"
- "I got an email about my bank account being suspended"
- "A pop-up said my computer is infected"
- "Someone I met online needs money for an emergency"

## 🛠️ Technical Architecture

### Local-First Design
- **No External APIs**: All processing happens on-device
- **Privacy-Focused**: No personal data sent to external servers
- **Offline Capable**: Core features work without internet
- **Fast Response**: Instant chatbot responses

### Smart Scam Detection Engine
```dart
// Example scam pattern detection
if (message.contains("IRS") && message.contains("arrest")) {
  return "🚨 IRS SCAM ALERT: The IRS never threatens arrest by phone...";
}
```

### Components
- **Local Chat Service**: Rule-based conversational AI for scam detection
- **FTC Scraper**: Ethical web scraping of official consumer alerts
- **Phone Database**: Local storage of scam reports and known numbers
- **Notification System**: Background alerts for new scam warnings

## 🔒 Privacy & Security

- ✅ **All data stored locally** on your device
- ✅ **No personal information** sent to external servers
- ✅ **Open source** - inspect all code
- ✅ **No tracking** or analytics
- ✅ **GDPR compliant** by design

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues**: Found a bug? Report it in Issues
2. **Suggest Features**: Ideas for new scam detection patterns
3. **Update Scam Database**: Add new known scam numbers
4. **Improve Documentation**: Help make instructions clearer
5. **Submit Pull Requests**: Code improvements and new features

### Development Setup
```bash
# Fork the repo and clone your fork
git clone https://github.com/YourUsername/SeniorShield.git

# Create a feature branch
git checkout -b feature/your-feature-name

# Make changes and test
flutter test

# Commit and push
git add .
git commit -m "Add: your feature description"
git push origin feature/your-feature-name

# Create a Pull Request
```

## 📊 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── chat_message.dart
│   ├── ftc_alert.dart
│   └── phone_check_result.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── ftc_alerts_screen.dart
│   ├── check_number_screen.dart
│   └── report_number_screen.dart
├── services/                 # Business logic
│   ├── local_chat_service.dart    # Local AI chatbot
│   ├── local_phone_service.dart   # Phone number checking
│   ├── ftc_scraper_service.dart   # FTC alert scraping
│   └── background_service.dart    # Notifications
└── widgets/                  # Reusable components
```

## 🌟 Roadmap

- [ ] **Multi-language support** (Spanish, Chinese, etc.)
- [ ] **Voice input** for chatbot conversations
- [ ] **Enhanced scam patterns** based on user feedback
- [ ] **Family notifications** to alert relatives of scam attempts
- [ ] **Integration with government databases**
- [ ] **Machine learning** for improved scam detection

## 📞 Support

If you need help or have questions:

- 📖 **Documentation**: Check our [Wiki](../../wiki)
- 🐛 **Bug Reports**: [Create an Issue](../../issues)
- 💬 **Discussions**: [GitHub Discussions](../../discussions)
- 📧 **Contact**: [your-email@example.com]

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Federal Trade Commission**: For providing public consumer alert data
- **Flutter Team**: For the amazing cross-platform framework
- **Senior Community**: For feedback and feature requests
- **Security Researchers**: For scam pattern identification

## ⚠️ Disclaimer

SeniorShield is an educational tool designed to help identify common scam patterns. It should not be considered a substitute for professional advice or official government resources. Always verify suspicious activity through official channels and report scams to appropriate authorities.

---

**Built with ❤️ for the senior community**

*"Empowering seniors with knowledge to stay safe in the digital age"*