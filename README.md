# Kiroku

Very simple Receipts management system.

We use CarrierWave instead of ActiveStorage because we care about file paths.

## Slack Bot Setup

Users can send receipt images/PDFs directly to a Slack bot via DM. The bot automatically creates a receipt in Kiroku,
matching the Slack user by email (or creating a new account if none exists).

### 1. Create a Slack App

Go to https://api.slack.com/apps and create a new app for your workspace.
Get the SLACK_SIGNING_SECRET and set it in the app. Then restart it.

### 2. Enable the Messages Tab

Under **App Home** → **Show Tabs**:

1. Enable **Messages Tab**
2. Check **"Allow users to send Slash commands and messages from the messages tab"**

Without this, users will see "Sending messages to this app has been turned off."

### 3. Configure Bot Token Scopes

Under **OAuth & Permissions**, add these Bot Token Scopes:

- `chat:write` — post confirmation messages
- `files:read` — download files shared with the bot
- `im:history` — read DM messages (required for Event Subscriptions)
- `users:read` — look up user profiles
- `users:read.email` — retrieve user email addresses

### 4. Enable Event Subscriptions

Under **Event Subscriptions**:

1. Toggle **Enable Events** on
2. Set the **Request URL** to `https://<your-domain>/slack/events`
3. Subscribe to the bot event: `message.im`

Slack will send a verification challenge to the URL — the app handles this automatically.

### 5. Install the App

Install (or reinstall) the app to your workspace. Copy:

- **Bot User OAuth Token** (`xoxb-...`) from OAuth & Permissions
- **Signing Secret** from Basic Information

**Note:** If you change scopes or settings after the initial install, you must reinstall the app for changes to take effect.

### 6. Store Credentials

```sh
bin/rails credentials:edit
```

Add:

```yaml
slack:
  bot_token: "xoxb-your-bot-token"
  signing_secret: "your-signing-secret"
```

For local development, you can also set `SLACK_BOT_TOKEN` and `SLACK_SIGNING_SECRET` in your `.env` file.

### 7. Usage

Send a file (JPG, PNG, HEIC, WebP, or PDF, max 10MB) as a DM to the bot. Optionally include a date in the message (e.g.
`2026-01-15` or `15.01.2026`) to set the `spent_on` date. The bot will reply confirming the receipt was saved.

## Copyright

Copyright (c) 2026 [Renuo AG](https://www.renuo.ch). All rights reserved.
