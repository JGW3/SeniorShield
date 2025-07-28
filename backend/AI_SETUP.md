# AI-Powered Chatbot Setup

The SeniorShield chatbot can now use real AI (OpenAI GPT) for intelligent, contextual responses instead of just rule-based matching.

## 🧠 How It Works

- **With AI**: Uses OpenAI GPT-3.5-turbo for intelligent, conversational responses
- **Without AI**: Falls back to the rule-based keyword matching system

## 🔑 Setting Up AI (Optional)

### Step 1: Get OpenAI API Key
1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Click "Create new secret key"
4. Copy your API key (starts with `sk-`)

### Step 2: Set Environment Variable

#### Windows:
```bash
# Option A: Set for current session
set OPENAI_API_KEY=your_api_key_here

# Option B: Set permanently
setx OPENAI_API_KEY "your_api_key_here"
```

#### macOS/Linux:
```bash
export OPENAI_API_KEY="your_api_key_here"
```

### Step 3: Install Requirements
```bash
cd backend
pip install -r requirements.txt
```

### Step 4: Start Server
```bash
python main.py
```

## 💰 Cost Information

OpenAI charges per token (roughly per word):
- GPT-3.5-turbo: ~$0.002 per 1K tokens
- Average response: ~200-300 tokens
- Cost per conversation: ~$0.001-0.002

For testing/light use, costs are minimal (a few dollars per month).

## 🔄 AI vs Rule-Based Comparison

### AI-Powered Response:
**User**: "I got a weird email about my Amazon account"
**AI**: "I understand your concern about that Amazon email. Let me help you determine if it's legitimate. Can you tell me:

- Does it address you by your real name or just say 'Dear Customer'?
- Is it asking you to click a link to 'verify' or 'update' your account?
- Does the sender's email address actually end with @amazon.com?

Real Amazon emails will always use your actual name and won't ask you to click links to verify accounts. If you're unsure, log into your Amazon account directly through their website instead of clicking any links in the email."

### Rule-Based Response:
**User**: "I got a weird email about my Amazon account"
**Rule-Based**: "Email Phishing Protection: Scammers send fake emails pretending to be from banks, stores, or services you use..."

## 🛠️ Switching Between Modes

The system automatically detects if you have an API key:
- **API key set**: Uses AI responses
- **No API key**: Uses rule-based responses

You can test both by:
1. Running without API key (rule-based)
2. Setting API key and restarting (AI-powered)

## 🚨 Important Notes

- Keep your API key secret and never commit it to code
- Monitor your OpenAI usage to avoid unexpected charges
- The rule-based system works fine without any API key
- AI responses are more natural but cost money