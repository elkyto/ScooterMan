#!/bin/bash
# scripts/auto-commit.sh
# @purpose: Watch directory and auto-commit changes (with conditions)

WATCH_DIR="src/"
AUTO_COMMIT_INTERVAL=300  # 5 minutes
LAST_COMMIT_FILE=".last_auto_commit"

# @function: check_for_changes
check_for_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        return 0  # Changes exist
    fi
    return 1  # No changes
}

# @function: auto_commit
auto_commit() {
    local changes=$(git status --porcelain | wc -l)
    local files=$(git status --porcelain | cut -c4- | tr '\n' ', ')
    
    git add -A
    
    git commit -m "@type: chore
@scope: auto
@subject: Auto-commit $changes changed files

@body:
Automated commit from watch script
Files changed: $files

@auto-generated: true
@signed-off-by: Auto Commit Bot <bot@elkyto.com>"
    
    echo "[$(date)] Auto-committed $changes files" >> .auto_commit_log
    touch "$LAST_COMMIT_FILE"
}

# @function: main_loop
main_loop() {
    echo "🤖 Auto-commit daemon started (interval: ${AUTO_COMMIT_INTERVAL}s)"
    
    while true; do
        if check_for_changes; then
            # Check if enough time has passed
            if [ ! -f "$LAST_COMMIT_FILE" ] || [ $(($(date +%s) - $(stat -c %Y "$LAST_COMMIT_FILE"))) -ge $AUTO_COMMIT_INTERVAL ]; then
                echo "[$(date)] Changes detected, committing..."
                auto_commit
            fi
        fi
        sleep 10  # Check every 10 seconds
    done
}

# @run: Start daemon
main_loop