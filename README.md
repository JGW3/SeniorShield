# SeniorShield

An app that helps seniors stay informed about the latest scams and consumer protection issues by displaying Federal Trade Commission (FTC) consumer alerts.

## Features

- User authentication with Google Sign-In
- Displays FTC consumer alerts in a clean, readable interface
- Shows alert titles, publication dates, and summaries
- Provides "Read More" links to full articles
- Sorts alerts by date (newest first)
- Caches data to minimize server requests (once per day)
- Chatbot functionality (coming soon)

## Technical Details

- Built with Flutter
- Google authentication integration
- Implements ethical web scraping practices (once-daily fetching)
- Uses in-memory caching to reduce load on FTC servers
- Properly identifies itself with a user agent string

## Setup

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to launch the app

## Dependencies

- http: ^1.1.0
- html: ^0.15.4
- intl: ^0.20.2
- url_launcher: ^6.1.14
- shared_preferences: ^2.2.0
- flutter_local_notifications: ^19.0.0
- android_alarm_manager_plus: ^4.0.7
- google_sign_in: ^6.2.1

## Legal Considerations

This app fetches publicly available information from the FTC website. It implements responsible scraping practices to minimize server load by:

- Limiting requests to once per day
- Including proper user agent identification
- Caching results between sessions

## License