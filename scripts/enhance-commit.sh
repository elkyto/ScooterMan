#!/bin/bash
# scripts/enhance-commit.sh
# @purpose: Take existing commit and enhance with AI
# @usage:   ./enhance-commit.sh [commit-hash]

COMMIT_HASH=${1:-HEAD}

# @function: get_original_message
get_original_message() {
    git log -1 --pretty=%B "$COMMIT_HASH"
}

# @function: enhance_with_ollama
enhance_with_ollama() {
    local original_msg=$(get_original_message)
    local diff=$(git show "$COMMIT_HASH" --stat)
    
    local prompt="Enhance this commit message with proper structure:

Original message:
$original_msg

Changes:
$diff

Output the enhanced version following @type, @scope, @subject, @body format.
Keep the core meaning but make it more professional and structured."

    curl -s "http://localhost:11434/api/generate" \
        -d "{
            \"model\": \"codellama:7b\",
            \"prompt\": $(echo "$prompt" | jq -sR .),
            \"stream\": false,
            \"temperature\": 0.3
        }" | jq -r '.response'
}

# @main
echo "🔍 Analyzing commit $COMMIT_HASH..."
echo ""
echo "Original:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
get_original_message
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🦙 Enhanced version:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
enhance_with_ollama
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"