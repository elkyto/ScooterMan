#!/bin/bash
# scripts/ollama-watcher.sh
# @purpose: Watch directory and auto-commit with AI messages
# @usage:   ./ollama-watcher.sh [--interval 60]

# @config
WATCH_INTERVAL=${1:-30}  # seconds
OLLAMA_MODEL="codellama:7b"
AUTO_COMMIT_BRANCHES=("main" "develop" "feature/*")
LAST_STATE_FILE="/tmp/ollama_watch_state"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# @function: get_filesystem_hash
get_filesystem_hash() {
    find src/ include/ -type f -name "*.c" -o -name "*.h" 2>/dev/null | xargs md5sum 2>/dev/null | sort | md5sum | cut -d' ' -f1
}

# @function: has_changes
has_changes() {
    local current_hash=$(get_filesystem_hash)
    local last_hash=$(cat "$LAST_STATE_FILE" 2>/dev/null || echo "")
    
    if [ "$current_hash" != "$last_hash" ]; then
        echo "$current_hash" > "$LAST_STATE_FILE"
        return 0  # Has changes
    fi
    return 1  # No changes
}

# @function: quick_ai_message
quick_ai_message() {
    local changes=$(git diff --stat)
    
    curl -s "http://localhost:11434/api/generate" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"prompt\": \"Generate a one-line git commit subject for: $changes. Format: @type: X @scope: Y @subject: Z\",
            \"stream\": false,
            \"temperature\": 0.2
        }" | jq -r '.response'
}

# @function: auto_commit
auto_commit() {
    echo -e "${BLUE}📝 Changes detected, generating AI message...${NC}"
    
    # Stage all changes
    git add -A
    
    # Generate AI message
    local ai_msg=$(quick_ai_message)
    
    if [ -n "$ai_msg" ] && [ "$ai_msg" != "null" ]; then
        local full_msg=$(cat << EOF
$ai_msg

@body:
Auto-commit from watcher at $(date '+%Y-%m-%d %H:%M:%S')

@generated-by: Ollama ($OLLAMA_MODEL)
@signed-off-by: Auto Commit Bot <bot@elkyto.com>
EOF
)
        echo "$full_msg" | git commit -F -
        echo -e "${GREEN}✅ Auto-committed: $(echo "$ai_msg" | head -1)${NC}"
    else
        # Fallback
        git commit -m "@type: chore @scope: auto @subject: Auto-save changes $(date +%H:%M:%S)"
        echo -e "${GREEN}✅ Auto-committed (fallback)${NC}"
    fi
}

# @function: main_loop
main_loop() {
    echo -e "${GREEN}🦙 Ollama Auto-Commit Watcher${NC}"
    echo -e "${BLUE}Watching directory every ${WATCH_INTERVAL}s...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    
    while true; do
        if has_changes; then
            auto_commit
        fi
        sleep "$WATCH_INTERVAL"
    done
}

# @run
main_loop