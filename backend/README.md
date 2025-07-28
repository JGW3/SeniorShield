# SeniorShield Backend Server

This is the backend API server for the SeniorShield Flutter app, providing AI chatbot functionality, phone number checking, and scam reporting features.

## Features

- **AI Chatbot**: Rule-based scam awareness chatbot that provides safety tips
- **Phone Number Checking**: Check if phone numbers are reported as scams
- **Scam Reporting**: Report suspicious phone numbers
- **Chat History**: Store and retrieve conversation history

## Setup and Installation

### Prerequisites
- Python 3.7 or higher
- pip (Python package installer)

### Quick Start

1. **Windows Users**: Simply double-click `start_server.bat`
2. **Manual Setup**:
   ```bash
   # Install dependencies
   pip install -r requirements.txt
   
   # Start the server
   python main.py
   ```

The server will start on `http://localhost:8000`

## API Endpoints

- `GET /` - Health check
- `POST /chat` - Send message to chatbot
- `POST /history` - Get chat history
- `POST /check-phone` - Check if phone number is a scam
- `POST /report` - Report a phone number as scam

## Testing the API

Visit `http://localhost:8000/docs` to access the interactive API documentation (Swagger UI).

## Integration with Flutter App

The Flutter app expects the backend to run on `http://10.0.2.2:8000` (Android emulator localhost). Make sure the server is running before using the app features.

## Security Note

This is a basic implementation for demonstration purposes. In production, you should:
- Use a proper database instead of in-memory storage
- Implement authentication and authorization
- Add rate limiting
- Use HTTPS
- Validate and sanitize all inputs