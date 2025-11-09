# 🏠 LATAM Real Estate Bot

**Conversational AI bot for automating property information collection from non-digital sellers**

**⏱️ Build time:** ~2 hours  
**🤖 Built with:** n8n, OpenAI GPT-4o-mini, Supabase, Telegram  
**🎯 Purpose:** Streamline property listing data collection for traditional LATAM sellers using physical signs

## What It Does

This conversational bot automates the process of collecting real estate property information from sellers who aren't comfortable with digital platforms. It conducts natural conversations via Telegram/WhatsApp, gathers property details including photos, normalizes messy user input, and stores structured data in a database.

**Key capabilities:**
- 🤖 Natural conversation flow using OpenAI GPT-4o-mini
- 📸 Collects minimum 3 property photos with automatic storage
- 🔄 Smart data normalization ("COP $500.000.000" → 500000000)
- 💭 Maintains conversation context to avoid repeating questions
- 🗄️ Stores structured data in PostgreSQL (Supabase)
- 📱 Works with Telegram (MVP) and WhatsApp Business API ready

## Tech Stack

- **n8n** - Workflow automation and orchestration
- **OpenAI API (GPT-4o-mini)** - Conversational AI engine
- **Supabase** - PostgreSQL database and file storage
- **Telegram Bot API** - Messaging platform (WhatsApp compatible)

## Quick Start

### Prerequisites

- n8n account (Cloud or self-hosted)
- Supabase account (free tier works)
- OpenAI API key
- Telegram bot token (from @BotFather)

### Setup

**1. Clone and configure database**

```bash
git clone https://github.com/irivelez/inmuebles_col_bot.git
cd inmuebles_col_bot
```

Create Supabase project and run `database_schema.sql`

**2. Create Telegram bot**

- Open Telegram, find @BotFather
- Send `/newbot` and follow instructions
- Save your bot token

**3. Import workflow to n8n**

- Download the file `My-workflow-2.json` from this repo
- In n8n: Click "Workflows" → "Import from File"
- Select the downloaded file

> **⚠️ Important:** The workflow file does NOT contain your API keys or passwords. You'll need to add your own credentials in the next step.

**4. Configure credentials in n8n**

**Telegram:**
- Credential Type: Telegram API
- Access Token: Your bot token

**OpenAI:**
- Credential Type: OpenAI API  
- API Key: Your OpenAI key

**Supabase:**
- Credential Type: Supabase API
- Host: Your Supabase URL
- Service Role Secret: Your Supabase API key

- > **💡 Note:** After importing, n8n will show warnings on nodes that need credentials. Click each node and select "Create New Credential" to add your keys.


**5. Activate and test**

- Toggle workflow to "Active"
- Send a message to your Telegram bot
- Expected response: Under 3 seconds

## How It Works

### The System

**Workflow Pipeline:**

1. **Telegram Trigger** - Receives user message
2. **Message Router** - Detects text vs photo
3. **Context Manager** - Loads conversation history from DB
4. **OpenAI Integration** - Sends context + user input to GPT
5. **Response Processor** - Checks for completion marker
6. **Data Normalizer** - Cleans prices, areas, phone numbers
7. **Database Writer** - Stores normalized property data
8. **Photo Handler** - Downloads and stores images in Supabase Storage

### Conversation Flow

The bot asks for:
- Property type (house, apartment, lot, farm)
- Location (city, neighborhood)
- Price and area
- Rooms, bathrooms, stratum (for Colombia)
- Features (parking, balcony, etc.)
- Minimum 3 photos
- Owner name and contact

### Data Normalization

**Automatic cleaning:**
- Prices: "COP $500.000.000" → 500000000
- Areas: "200 m²" → 200
- Phone: "+57 300 123 4567" → "3001234567"

## Output

The system produces:

1. **Structured database records** in `propiedades` table
2. **Stored photos** in Supabase Storage with URLs
3. **Conversation history** maintained in `conversaciones` table
4. **Normalized data** ready for export to listing platforms

## Features

✅ **Context-aware conversations** - Never repeats questions  
✅ **Smart data normalization** - Handles messy user input  
✅ **Photo management** - Automatic download and storage  
✅ **Multi-property tracking** - One conversation per user  
✅ **Error handling** - Graceful fallbacks for failed uploads  
✅ **Bilingual ready** - Spanish with English structure  
✅ **WhatsApp compatible** - Easy migration from Telegram  

## Limitations

- **No historical analysis** - Current version doesn't track property updates
- **Single language** - Spanish only (easily extensible)
- **MVP scope** - No admin dashboard or analytics yet
- **Manual export** - Data must be manually exported to listing sites
- **Rate limits** - Subject to OpenAI API rate limits

> **Note:** This is an MVP focused on data collection. For production use, add duplicate detection, dashboard, and listing platform integrations.

⚡️ Built in 2 hours • Part of thexperiment.dev
