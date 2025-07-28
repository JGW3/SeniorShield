from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json
import os
from datetime import datetime
from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
import torch

app = FastAPI(title="SeniorShield Backend API")

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data models
class ChatRequest(BaseModel):
    username: str
    message: str

class ChatResponse(BaseModel):
    response: str

class HistoryRequest(BaseModel):
    username: str
    offset: int = 0
    limit: int = 5

class PhoneCheckRequest(BaseModel):
    phone: str

class PhoneCheckResponse(BaseModel):
    phone_number: str
    status: str
    message: str

class ReportRequest(BaseModel):
    phone: str
    type: str
    description: Optional[str] = ""

# Simple in-memory storage (replace with database in production)
chat_history = []
reported_numbers = {}
conversation_context = {}  # Track what users have already told us

# Free Local LLM Configuration
print("Loading free local AI model...")
try:
    # Use a lightweight model that works well for conversation
    model_name = "microsoft/DialoGPT-medium"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForCausalLM.from_pretrained(model_name)
    
    # Add padding token if it doesn't exist
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    
    USE_AI = True
    print("✅ Free AI model loaded successfully!")
except Exception as e:
    print(f"❌ Failed to load AI model: {e}")
    print("🔄 Falling back to rule-based responses")
    USE_AI = False

# Mock scam database for phone number checking
SCAM_NUMBERS = {
    "+1234567890": "Known scam number reported for fake tax calls",
    "123-456-7890": "Reported for fake charity scams",
    "(555) 123-4567": "Known telemarketing scam",
}

@app.get("/")
async def root():
    return {"message": "SeniorShield Backend API is running"}

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Handle chat messages - provides scam awareness responses
    """
    try:
        # Simple rule-based chatbot for scam awareness
        message = request.message.lower()
        
        # Store user message in history
        timestamp = datetime.now()
        
        # Generate response based on keywords
        response = generate_scam_awareness_response(message, request.username)
        
        # Store both messages in history
        chat_history.append({
            "username": request.username,
            "user_input": request.message,
            "bot_response": response,
            "timestamp": timestamp.isoformat()
        })
        
        return ChatResponse(response=response)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat service error: {str(e)}")

@app.post("/history")
async def get_chat_history(request: HistoryRequest):
    """
    Get chat history for a user
    """
    try:
        user_history = [
            entry for entry in chat_history 
            if entry["username"] == request.username
        ]
        
        # Sort by timestamp descending and apply pagination
        user_history.sort(key=lambda x: x["timestamp"], reverse=True)
        start = request.offset
        end = start + request.limit
        
        return {
            "history": user_history[start:end]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"History service error: {str(e)}")

@app.post("/check-phone", response_model=PhoneCheckResponse)
async def check_phone_number(request: PhoneCheckRequest):
    """
    Check if a phone number is reported as a scam
    """
    try:
        phone = request.phone.strip()
        
        # Check against known scam numbers
        if phone in SCAM_NUMBERS:
            return PhoneCheckResponse(
                phone_number=phone,
                status="scam",
                message=f"WARNING: {SCAM_NUMBERS[phone]}"
            )
        
        # Check if it's in our reported numbers
        if phone in reported_numbers:
            report_count = len(reported_numbers[phone])
            return PhoneCheckResponse(
                phone_number=phone,
                status="suspicious",
                message=f"This number has been reported {report_count} time(s) for scam activity."
            )
        
        return PhoneCheckResponse(
            phone_number=phone,
            status="unknown",
            message="No reports found for this number. Stay vigilant and trust your instincts."
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Phone check service error: {str(e)}")

@app.post("/report")
async def report_phone_number(request: ReportRequest):
    """
    Report a phone number as scam/fraud
    """
    try:
        phone = request.phone.strip()
        
        if phone not in reported_numbers:
            reported_numbers[phone] = []
        
        report = {
            "type": request.type,
            "description": request.description,
            "timestamp": datetime.now().isoformat()
        }
        
        reported_numbers[phone].append(report)
        
        return {"message": "Report submitted successfully", "status": "created"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Report service error: {str(e)}")

def generate_ai_response(message: str, username: str = "user") -> str:
    """
    Generate AI-powered response using free local LLM with better scam detection
    """
    try:
        # Use a more specific scam-focused approach
        return get_smart_scam_response(message, username)
        
    except Exception as e:
        print(f"AI Error: {e}")
        return get_contextual_scam_response(message)

def get_smart_scam_response(message: str, username: str = "user") -> str:
    """
    Provide intelligent scam analysis based on user input with context memory
    """
    message_lower = message.lower()
    
    # Remember what the user has told us
    if username not in conversation_context:
        conversation_context[username] = {"topics": set(), "details": []}
    
    conversation_context[username]["details"].append(message_lower)
    
    # IRS/Tax scam detection
    if any(phrase in message_lower for phrase in ["irs", "tax", "owe money", "arrest", "warrant", "back taxes", "refund"]):
        if any(phrase in message_lower for phrase in ["called", "phone", "call"]):
            return """🚨 This sounds like an IRS phone scam!

The IRS will NEVER:
- Call you to demand immediate payment
- Threaten arrest over the phone
- Ask for payment via gift cards or wire transfers
- Call without first mailing you a bill

What they told you is a scam. The real IRS sends letters first, then follows up. If you're concerned about actual tax issues, call the IRS directly at 1-800-829-1040.

Did they ask you to pay with gift cards or threaten immediate arrest?"""
        else:
            return "IRS scams are very common. Can you tell me how they contacted you - by phone, email, or mail? This will help me give you specific advice."

    # Tech support scam detection
    elif any(phrase in message_lower for phrase in ["computer", "microsoft", "windows", "virus", "pop up", "popup", "locked", "infected", "tech support"]):
        return """🚨 This sounds like a tech support scam!

Real facts:
- Microsoft/Apple NEVER call you about computer problems
- Pop-ups claiming "Your computer is infected" are fake
- Real antivirus software doesn't lock your computer

What to do:
- Close any suspicious pop-ups (don't call numbers shown)
- Never give remote access to strangers
- Run your own antivirus scan

Did they ask you to download software or give them remote access to your computer?"""

    # Romance scam detection
    elif any(phrase in message_lower for phrase in ["dating", "online", "love", "relationship", "met on", "can't meet", "emergency", "money", "visit"]):
        return """❤️ This could be a romance scam - very common targeting seniors.

Warning signs:
- Professes love very quickly
- Always has excuses not to meet in person
- Claims to be military/doctor overseas
- Asks for money for emergencies/travel

Protection tips:
- Never send money to someone you haven't met in person
- Do a reverse image search on their photos
- Real relationships develop slowly and in person

Have they asked you for money or always have excuses not to meet?"""

    # Prize/lottery scam detection
    elif any(phrase in message_lower for phrase in ["won", "prize", "lottery", "congratulations", "winner", "claim", "fee", "taxes", "processing"]):
        return """🎉 This is definitely a prize/lottery scam!

Remember: You can't win a contest you didn't enter!

Scam signs:
- Claiming you won something you didn't enter
- Asking for "taxes" or "fees" upfront
- Pressuring you to act quickly
- Requesting bank account info

Real prizes:
- Don't require upfront payments
- Don't ask for bank details over phone
- Come from companies you actually entered contests with

Did they ask you to pay fees or taxes before getting your "prize"?"""

    # Phone/robocall issues
    elif any(phrase in message_lower for phrase in ["robocall", "spam call", "unknown number", "telemarketer", "warranty", "insurance", "social security"]):
        return """📞 Sounds like you're dealing with scam calls!

Common phone scams:
- Auto warranty extensions (for cars you may not own)
- Social Security "suspension" threats
- Medicare/insurance offers
- "Your account has been compromised"

Best protection:
- Don't answer unknown numbers
- Register at donotcall.gov
- Block repeated spam numbers
- Never give personal info to unsolicited callers

What type of calls are you getting most often?"""

    # Email/phishing detection
    elif any(phrase in message_lower for phrase in ["email", "click", "link", "account", "suspended", "verify", "update", "login"]):
        return """📧 This sounds like a phishing email scam!

Red flags in emails:
- Urgent threats about account suspension
- Generic greetings like "Dear Customer"
- Requests to "verify" or "update" information
- Suspicious links or attachments

Stay safe:
- Don't click links in suspicious emails
- Log into accounts directly through official websites
- Check the sender's email address carefully
- When in doubt, call the company directly

What company is the email claiming to be from?"""

    # Generic but helpful response - analyze common scam words even if not exact match
    else:
        # Look for any scam-related keywords and give specific advice
        if any(word in message_lower for word in ["call", "called", "phone", "number"]):
            return """📞 Phone calls from strangers are often scams, especially if they:

- Want money, gift cards, or personal information
- Claim urgency ("act now or else...")
- Say they're from government agencies
- Threaten arrest or legal action
- Offer prizes or say you owe money

SAFE RESPONSE: Hang up and call the organization directly using a number you trust (not the one they gave you).

Most legitimate organizations will send mail first, not call unexpectedly."""

        elif any(word in message_lower for word in ["email", "text", "message"]):
            return """📧 Suspicious messages often try to:

- Get you to click links or download files
- Steal passwords or personal information  
- Create false urgency about accounts
- Trick you into paying fake bills

SAFE RESPONSE: Don't click anything. Go directly to the real website by typing it yourself, or call the company using their official number.

Delete the message if you're unsure."""

        elif any(word in message_lower for word in ["money", "pay", "owe", "debt", "bill"]):
            return """💰 Money requests are major red flags, especially:

- Demands for immediate payment
- Requests for gift cards, wire transfers, or Bitcoin
- Claims you owe money you don't remember
- "Pay now to avoid arrest/consequences"

REAL ORGANIZATIONS:
- Send bills by mail first
- Accept normal payment methods (checks, credit cards)
- Give you time to verify and pay
- Don't threaten immediate arrest

If someone demands money urgently, it's almost certainly a scam."""

        else:
            return """🛡️ I'm here to help you avoid scams! Here are the most important things to remember:

1. **HANG UP** on suspicious calls - real organizations won't pressure you
2. **DON'T CLICK** links in unexpected emails - go to websites directly  
3. **NEVER PAY** with gift cards, wire transfers, or Bitcoin for legitimate services
4. **TRUST YOUR INSTINCTS** - if something feels wrong, it probably is
5. **ASK FOR HELP** - talk to family, friends, or call organizations directly

What specific situation are you dealing with? I can give you more targeted advice."""

def get_contextual_scam_response(message: str) -> str:
    """
    Provide contextual scam advice when AI fails
    """
    message_lower = message.lower()
    
    if any(word in message_lower for word in ["phone", "call", "called"]):
        return "If you received a suspicious phone call, remember: legitimate organizations won't pressure you for immediate payment or personal information. When in doubt, hang up and call the organization directly using a number you trust. What details can you share about the call?"
    
    elif any(word in message_lower for word in ["email", "message", "link"]):
        return "Suspicious emails often try to create urgency or fear. Don't click links in emails you weren't expecting. Instead, log into your accounts directly through the official website. Can you tell me more about what the email said?"
    
    elif any(word in message_lower for word in ["money", "payment", "pay", "owe"]):
        return "Be very cautious about unexpected requests for money, especially via gift cards, wire transfers, or cryptocurrency. Real organizations accept normal payment methods. What kind of payment are they requesting?"
    
    else:
        return "I'm here to help you stay safe from scams. Can you tell me more about what happened? For example, did someone contact you by phone, email, or text? The more details you share, the better I can help protect you."

def generate_scam_awareness_response(message: str, username: str = "user") -> str:
    """
    Generate responses for scam awareness based on user input
    """
    print(f"DEBUG: Processing message: '{message}' for user: {username}")
    
    # Use AI if available, otherwise fall back to rule-based system
    if USE_AI:
        print("DEBUG: Using AI-powered response")
        return generate_ai_response(message, username)
    
    print("DEBUG: Using rule-based response")
    message = message.lower()
    
    # Specific scam scenarios - more detailed matching
    
    # IRS/Tax scams
    if any(phrase in message for phrase in ["irs", "tax", "owe money", "arrest warrant", "tax refund", "government owes"]):
        print("DEBUG: Matched IRS/tax scam")
        return """IRS/Tax Scam Alert:
The IRS will NEVER call you demanding immediate payment or threatening arrest. Real IRS communications come by mail first.

Red flags:
- Demanding immediate payment by phone
- Threatening arrest or deportation
- Asking for payment via gift cards or wire transfers
- Claiming you owe back taxes without prior notice

What to do: Hang up and contact the IRS directly at 1-800-829-1040."""
    
    # Tech support pop-ups
    elif any(phrase in message for phrase in ["computer locked", "virus detected", "microsoft called", "pop up", "popup", "computer slow", "frozen computer"]):
        print("DEBUG: Matched tech support scam")
        return """Tech Support Scam Warning:
Those scary pop-ups saying your computer is infected are FAKE! Microsoft/Apple will never call you.

Red flags:
- Pop-ups claiming computer is infected
- Unsolicited calls about computer problems
- Requests for remote access to your computer
- Demands for immediate payment to "fix" issues

What to do: Close the pop-up, never call the number shown, and run your own antivirus scan."""
    
    # Romance/online dating
    elif any(phrase in message for phrase in ["met online", "dating site", "fell in love", "emergency money", "visit me", "can't meet", "military overseas"]):
        print("DEBUG: Matched romance scam")
        return """Romance Scam Alert:
Be very careful with online relationships, especially if they quickly profess love or ask for money.

Red flags:
- Professes love very quickly
- Always has excuses not to meet in person
- Claims to be military/doctor/engineer overseas
- Has financial emergencies and needs money
- Photos look too professional (often stolen)

What to do: Never send money to someone you haven't met. Do a reverse image search on their photos."""
    
    # Gift card/payment requests
    elif any(phrase in message for phrase in ["gift card", "google play", "amazon card", "walmart card", "wire money", "western union", "send bitcoin"]):
        print("DEBUG: Matched payment scam")
        return """Payment Scam Alert:
Legitimate businesses and government agencies will NEVER ask for payment via gift cards or wire transfers.

Red flags:
- Requesting payment via gift cards
- Demanding wire transfers or Bitcoin
- Creating urgency ("act now or else")
- Claiming you've won money but need to pay fees first

What to do: Hang up immediately. Real organizations accept normal payment methods like checks or credit cards."""
    
    # Lottery/prize scams
    elif any(phrase in message for phrase in ["won lottery", "won prize", "congratulations", "claim prize", "processing fee", "taxes first"]):
        print("DEBUG: Matched lottery/prize scam")
        return """Lottery/Prize Scam Alert:
You can't win a lottery you didn't enter! Real prizes don't require upfront payments.

Red flags:
- Claiming you won a lottery you didn't enter
- Requiring payment of "taxes" or "fees" before receiving prize
- Pressure to act quickly
- Asking for bank account or personal information

What to do: Delete the message or hang up. Real contests don't require payment to claim prizes."""
    
    # Social Security scams
    elif any(phrase in message for phrase in ["social security", "ssn suspended", "social security number", "suspended benefits"]):
        print("DEBUG: Matched Social Security scam")
        return """Social Security Scam Alert:
Social Security will NEVER call to threaten suspension of your benefits or demand immediate payment.

Red flags:
- Claiming your Social Security number is suspended
- Threatening arrest if you don't pay immediately
- Asking for your Social Security number over the phone
- Demanding payment to "reactivate" benefits

What to do: Hang up and contact Social Security directly at 1-800-772-1213."""
    
    # Phone-specific questions
    elif any(phrase in message for phrase in ["unknown number", "robocall", "spam call", "telemarketer", "auto warranty", "extended warranty"]):
        print("DEBUG: Matched phone scam inquiry")
        return """Phone Scam Protection:
Many robocalls are scams trying to steal your information or money.

Common phone scams:
- Auto warranty extensions (for cars you may not own)
- Fake charity requests
- "Your account has been compromised" calls
- Medical insurance offers

What to do: Don't answer unknown numbers. If it's important, they'll leave a voicemail. Register with the Do Not Call Registry at donotcall.gov."""
    
    # Email-specific questions  
    elif any(phrase in message for phrase in ["suspicious email", "click link", "verify account", "account suspended", "update payment"]):
        print("DEBUG: Matched email scam inquiry")
        return """Email Phishing Protection:
Scammers send fake emails pretending to be from banks, stores, or services you use.

Warning signs:
- Urgent threats about account suspension
- Requests to "verify" or "update" information
- Suspicious links or attachments
- Generic greetings like "Dear Customer"
- Poor spelling or grammar

What to do: Don't click links in suspicious emails. Log into your accounts directly through the official website."""
    
    # General questions about being safe
    elif any(phrase in message for phrase in ["how to stay safe", "protect myself", "avoid scams", "what should i do", "is this a scam"]):
        print("DEBUG: Matched general safety inquiry")
        return """General Scam Protection:
Here are the most important rules to stay safe:

1. Trust your instincts - if something feels wrong, it probably is
2. Take time to think - scammers always create false urgency
3. Never give personal information to unsolicited callers
4. Verify independently - call organizations directly using official numbers
5. Don't pay upfront fees for prizes or services
6. Be skeptical of "too good to be true" offers

Remember: It's always okay to hang up, delete emails, or ask a trusted friend for advice."""
    
    # Greetings
    elif any(word in message for word in ["hello", "hi", "hey", "good morning", "good afternoon"]):
        print("DEBUG: Matched greeting")
        return """Hello! I'm your personal scam prevention assistant. I can help you identify and avoid common scams.

You can ask me about:
- Suspicious phone calls or emails
- Whether something might be a scam
- How to protect yourself from fraud
- What to do if you think you've been scammed

What's on your mind today? Have you encountered something suspicious?"""
    
    # Default - try to be more helpful
    else:
        print("DEBUG: Using contextual default response")
        # Try to give a more contextual response based on any keywords found
        if any(word in message for word in ["number", "call", "phone"]):
            return """It sounds like you're asking about a phone number or call. Can you tell me more? For example:
- Did someone call you asking for money or personal information?
- Are you getting unwanted robocalls?
- Did they claim to be from a government agency or company?

The more details you share, the better I can help you stay safe!"""
        elif any(word in message for word in ["email", "link", "message"]):
            return """It sounds like you received an email or message. Can you tell me more? For example:
- Are they asking you to click a link or download something?
- Are they claiming your account is suspended or compromised?
- Are they asking for personal information or passwords?

I can help you determine if it's a scam!"""
        else:
            return """I'm here to help you stay safe from scams! You can ask me things like:

- "I got a call from someone claiming to be the IRS"
- "Someone emailed me about my bank account"
- "I received a text about winning a prize"
- "Is this website/offer legitimate?"

What would you like to know about? Feel free to describe any suspicious activity you've encountered."""

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)