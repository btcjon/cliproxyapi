# Gemini OAuth Setup - Quick Reference

## Problem
Getting error: "Access blocked: Authorization Error - Required parameter is missing: response_type"

## Root Cause
The hardcoded OAuth client in CLIProxyAPI is misconfigured or restricted.

## Solution
Create your own Google Cloud OAuth Desktop app credentials.

---

## Quick Start (Automated)

Run the setup script - it will guide you through everything:

```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/setup-gemini-oauth.sh
```

The script will:
1. Show you the exact URLs to visit
2. Guide you through creating the OAuth client
3. Prompt for your credentials
4. Update the CLIProxyAPI source code
5. Rebuild the binary automatically

---

## Manual Steps (if needed)

### 1. Enable API
https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
- Click "Enable"

### 2. Configure OAuth Consent Screen
https://console.cloud.google.com/apis/credentials/consent
- User Type: External
- App name: Gemini CLI Client
- Add scope: `https://www.googleapis.com/auth/generative-language.retriever`
- Add test user: <account-email>

### 3. Create OAuth Client
https://console.cloud.google.com/apis/credentials
- Create Credentials → OAuth client ID
- Application type: **Desktop app**
- Name: Gemini Desktop OAuth Client
- Copy the Client ID and Client Secret

### 4. Update CLIProxyAPI
Edit `~/CLIProxyAPI/internal/auth/gemini/gemini_auth.go` lines 31-32:
```go
const (
    geminiOauthClientID     = "YOUR_CLIENT_ID_HERE"
    geminiOauthClientSecret = "YOUR_CLIENT_SECRET_HERE"
)
```

### 5. Rebuild
```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/build.sh
```

---

## Test OAuth Flow

### 1. Set up SSH tunnel (from local machine)
```bash
ssh -L 8085:localhost:8085 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N
```

### 2. Run OAuth renewal (on VPS)
```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/oauth-renew.sh gemini
```

### 3. Complete authentication in browser
The script will show an authorization URL - open it and authenticate.

---

## Troubleshooting

**Error: "invalid_request"**
- Check OAuth client type is "Desktop app" (not Web application)
- Verify test user email is added to OAuth consent screen

**Error: "redirect_uri_mismatch"**
- Desktop apps automatically allow localhost - no configuration needed
- Ensure SSH tunnel is on the correct port (8085)

**Can't access CLIProxyAPI source**
- Run `./scripts/build.sh` first to clone the repository

---

## Files Modified
- `~/CLIProxyAPI/internal/auth/gemini/gemini_auth.go` - OAuth credentials
- `/usr/local/bin/cli-proxy-api` - Rebuilt binary

## Backup Location
Original file is backed up with timestamp:
`~/CLIProxyAPI/internal/auth/gemini/gemini_auth.go.backup.YYYYMMDD_HHMMSS`
