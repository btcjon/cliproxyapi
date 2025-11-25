#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Gemini OAuth Client Setup for CLIProxyAPI"
echo "=========================================="
echo ""

# Show current credentials
echo "Current hardcoded credentials in CLIProxyAPI:"
echo "  Client ID: <YOUR_GOOGLE_CLIENT_ID>.apps.googleusercontent.com"
echo "  Client Secret: GOCSPX-<YOUR_SECRET>"
echo ""
echo "These will be replaced with your own credentials."
echo ""

# Step-by-step instructions
echo "=== STEP 1: Enable Generative Language API ==="
echo "URL: https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com"
echo "  1. Click the link above (or copy/paste into browser)"
echo "  2. Click the blue 'Enable' button"
echo "  3. Wait for confirmation"
echo ""

read -p "Press ENTER when you've enabled the API..."
echo ""

echo "=== STEP 2: Configure OAuth Consent Screen ==="
echo "URL: https://console.cloud.google.com/apis/credentials/consent"
echo "  1. Select User Type: 'External'"
echo "  2. Click 'Create'"
echo "  3. Fill in App Information:"
echo "     - App name: Gemini CLI Client (or your choice)"
echo "     - User support email: Select your email"
echo "     - Developer contact: Enter your email"
echo "  4. Click 'Save and Continue'"
echo "  5. Add Scopes:"
echo "     - Click 'Add or Remove Scopes'"
echo "     - Search for: generative-language.retriever"
echo "     - Check the box next to it"
echo "     - Click 'Update' then 'Save and Continue'"
echo "  6. Add Test Users:"
echo "     - Click '+ Add Users'"
echo "     - Enter your email (jonebennett@gmail.com)"
echo "     - Click 'Add' then 'Save and Continue'"
echo "  7. Review and click 'Back to Dashboard'"
echo ""

read -p "Press ENTER when you've configured the consent screen..."
echo ""

echo "=== STEP 3: Create OAuth Client ID ==="
echo "URL: https://console.cloud.google.com/apis/credentials"
echo "  1. Click '+ Create Credentials' at the top"
echo "  2. Select 'OAuth client ID'"
echo "  3. Application type: Select 'Desktop app'"
echo "  4. Name: Gemini Desktop OAuth Client (or your choice)"
echo "  5. Click 'Create'"
echo "  6. A modal will show your Client ID and Client Secret"
echo "  7. Copy both values - you'll need them in the next step"
echo ""

read -p "Press ENTER when you've created the OAuth client..."
echo ""

# Get credentials from user
echo "=== STEP 4: Enter Your Credentials ==="
echo ""
read -p "Paste your Client ID: " CLIENT_ID
echo ""
read -p "Paste your Client Secret: " CLIENT_SECRET
echo ""

# Basic validation
if [[ ! "$CLIENT_ID" =~ \.apps\.googleusercontent\.com$ ]]; then
    echo "WARNING: Client ID doesn't look like a valid Google OAuth client ID"
    echo "It should end with '.apps.googleusercontent.com'"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

if [[ ! "$CLIENT_SECRET" =~ ^GOCSPX- ]]; then
    echo "WARNING: Client Secret doesn't look like a valid Google OAuth secret"
    echo "It should start with 'GOCSPX-'"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Update the source code
echo ""
echo "=== STEP 5: Updating CLIProxyAPI Source ==="
AUTH_FILE="$HOME/CLIProxyAPI/internal/auth/gemini/gemini_auth.go"

if [[ ! -f "$AUTH_FILE" ]]; then
    echo "ERROR: CLIProxyAPI source not found at $AUTH_FILE"
    echo "Please run ./scripts/build.sh first to clone the repository"
    exit 1
fi

# Backup original file
BACKUP_FILE="${AUTH_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$AUTH_FILE" "$BACKUP_FILE"
echo "✓ Backed up original file to: $BACKUP_FILE"

# Replace credentials
sed -i "s|geminiOauthClientID     = \".*\"|geminiOauthClientID     = \"$CLIENT_ID\"|" "$AUTH_FILE"
sed -i "s|geminiOauthClientSecret = \".*\"|geminiOauthClientSecret = \"$CLIENT_SECRET\"|" "$AUTH_FILE"

echo "✓ Updated credentials in source code"
echo ""

# Verify the changes
echo "=== Verifying Changes ==="
grep -A 1 "geminiOauthClientID" "$AUTH_FILE" | head -2
echo ""

# Rebuild
echo "=== STEP 6: Rebuilding CLIProxyAPI ==="
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/build.sh

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Your CLIProxyAPI has been updated with your own OAuth credentials."
echo ""
echo "Next steps:"
echo "  1. Make sure you have an SSH tunnel running:"
echo "     ssh -L 8085:localhost:8085 dev@91.98.43.93"
echo ""
echo "  2. Run the OAuth renewal:"
echo "     ./scripts/oauth-renew.sh gemini"
echo ""
echo "  3. Complete the authentication in your browser"
echo ""
