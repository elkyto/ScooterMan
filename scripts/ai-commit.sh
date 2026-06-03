#!/bin/bash
# scripts/ai-commit.sh
# @purpose: Generate and commit with Ollama AI (Fixed)

set -e

# @config
OLLAMA_MODEL="codellama:7b"
OLLAMA_URL="http://localhost:11434"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# @function: print_color
print_color() {
    echo -e "${2}${1}${NC}"
}

# @function: check_ollama
check_ollama() {
    print_color "🔍 Checking Ollama..." "$BLUE"
    
    if ! curl -s "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
        print_color "❌ Ollama not running. Start with: ollama serve" "$RED"
        exit 1
    fi
    
    print_color "✅ Ollama ready" "$GREEN"
}

# @function: get_staged_files
get_staged_files() {
    git diff --cached --name-only 2>/dev/null || echo ""
}

# @function: analyze_changes
analyze_changes() {
    local files=$(get_staged_files)
    
    if [ -z "$files" ]; then
        print_color "\n❌ No staged changes detected!" "$RED"
        print_color "📝 Stage files first:" "$YELLOW"
        echo "  git add <file>"
        echo "  git add src/main.c"
        echo ""
        print_color "📊 Current git status:" "$BLUE"
        git status --short
        exit 1
    fi
    
    local file_count=$(echo "$files" | wc -l | tr -d ' ')
    
    # FIXED: Proper integer comparison
    local c_files=0
    local sh_files=0
    local md_files=0
    local hook_files=0
    
    # Count file types safely
    while IFS= read -r file; do
        if [[ "$file" =~ \.[ch]$ ]]; then
            ((c_files++))
        elif [[ "$file" =~ \.sh$ ]]; then
            ((sh_files++))
        elif [[ "$file" =~ \.md$ ]]; then
            ((md_files++))
        elif [[ "$file" =~ ^(pre-|post-|commit-|prepare-) ]]; then
            ((hook_files++))
        fi
    done <<< "$files"
    
    print_color "📊 Analyzing staged changes..." "$BLUE"
    print_color "Found $file_count changed file(s)" "$GREEN"
    
    if [ "$file_count" -gt 0 ]; then
        echo "📝 File breakdown:"
        [ "$c_files" -gt 0 ] && echo "   - C files: $c_files"
        [ "$sh_files" -gt 0 ] && echo "   - Shell scripts: $sh_files"
        [ "$md_files" -gt 0 ] && echo "   - Docs: $md_files"
        [ "$hook_files" -gt 0 ] && echo "   - Git hooks: $hook_files"
        echo ""
        print_color "Staged files:" "$YELLOW"
        echo "$files" | head -10
        [ "$file_count" -gt 10 ] && echo "   ... and $(($file_count - 10)) more"
    fi
}

# @function: get_diff_summary
get_diff_summary() {
    local diff=$(git diff --cached --stat 2>/dev/null)
    local additions=$(echo "$diff" | tail -1 | grep -o '[0-9]* insertion' | grep -o '[0-9]*' || echo "0")
    local deletions=$(echo "$diff" | tail -1 | grep -o '[0-9]* deletion' | grep -o '[0-9]*' || echo "0")
    
    echo "📈 Changes: +$additions lines added, -$deletions lines removed"
}

# @function: generate_commit_message
generate_commit_message() {
    local files=$(get_staged_files)
    local file_list=$(echo "$files" | head -10 | tr '\n' ', ' | sed 's/,$//')
    local diff_stats=$(git diff --cached --stat)
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    
    print_color "🦙 Generating commit message with AI..." "$BLUE"
    
    # Create a clean prompt based on what changed
    local prompt="Generate a git commit message for these changes.

Branch: $branch
Files changed: $file_list

Changes:
$diff_stats

Output EXACTLY this format with NO extra text, NO markdown, NO explanation:

@type: [feat|fix|docs|style|refactor|perf|test|chore|ci]
@scope: [single word]
@subject: [Short description under 50 chars]

@body:
- [Bullet point 1]
- [Bullet point 2]

Rules:
- @type: 'feat' for new features, 'fix' for bugs, 'docs' for docs, 'chore' for maintenance
- @scope: affected area (scripts, hooks, build, src, docs)
- @subject: Present tense, no period
- @body: 2-4 specific bullet points"

    # Call Ollama
    local response=$(curl -s "$OLLAMA_URL/api/generate" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"prompt\": $(echo "$prompt" | jq -sR .),
            \"stream\": false,
            \"temperature\": 0.2,
            \"num_predict\": 300
        }")
    
    local commit_msg=$(echo "$response" | jq -r '.response' 2>/dev/null | head -20)
    
    if [ -z "$commit_msg" ] || [ "$commit_msg" = "null" ]; then
        print_color "⚠️  AI generation failed" "$YELLOW"
        return 1
    fi
    
    # Clean up the message
    commit_msg=$(echo "$commit_msg" | sed '/```/d' | sed '/^Rules:/d' | sed '/^Requirements:/d' | sed '/^Output/d')
    
    echo "$commit_msg"
    return 0
}

# @function: generate_fallback_message
generate_fallback_message() {
    local files=$(get_staged_files)
    local file_count=$(echo "$files" | wc -l | tr -d ' ')
    
    # Check what type of changes
    if echo "$files" | grep -q "\.sh$"; then
        local type="feat"
        local scope="scripts"
        local subject="Add shell script improvements"
        local body="- Updated $(echo "$files" | grep "\.sh$" | wc -l | tr -d ' ') script(s)\n- Enhanced automation functionality"
    elif echo "$files" | grep -q "hooks/"; then
        local type="feat"
        local scope="hooks"
        local subject="Add git hooks configuration"
        local body="- Added $(echo "$files" | wc -l | tr -d ' ') git hook(s)\n- Improved development workflow"
    else
        local type="chore"
        local scope="misc"
        local subject="Update $(echo "$files" | head -1 | xargs basename) and related files"
        local body="- Modified $(file_count) file(s)\n- Changes in: $(echo "$files" | head -3 | tr '\n' ', ' | sed 's/,$//')"
    fi
    
    cat << EOF
@type: $type
@scope: $scope
@subject: $subject

@body:
$body

@auto-generated: true
@signed-off-by: $(git config user.name) <$(git config user.email)>
EOF
}

# @function: interactive_edit
interactive_edit() {
    local msg_file=$(mktemp)
    echo "$1" > "$msg_file"
    
    print_color "\n✏️  Edit commit message (${EDITOR:-nano} will open)" "$YELLOW"
    print_color "Press Enter to continue..." "$YELLOW"
    read
    
    ${EDITOR:-nano} "$msg_file"
    
    local final_msg=$(cat "$msg_file")
    rm "$msg_file"
    echo "$final_msg"
}

# @function: main
main() {
    print_color "\n🦙 Ollama AI Commit Generator v2.1" "$GREEN"
    print_color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$BLUE"
    
    # Check for staged changes
    analyze_changes
    
    # Check Ollama
    check_ollama
    
    # Show diff summary
    get_diff_summary
    echo ""
    
    # Try AI generation (with timeout)
    COMMIT_MSG=""
    if timeout 10s bash -c "COMMIT_MSG=$(generate_commit_message)" 2>/dev/null; then
        COMMIT_MSG=$(generate_commit_message)
    fi
    
    if [ -z "$COMMIT_MSG" ] || [ $? -ne 0 ]; then
        print_color "\n⚠️  Using fallback message template" "$YELLOW"
        COMMIT_MSG=$(generate_fallback_message)
    fi
    
    # Show generated message
    print_color "\n📝 Generated Commit Message:" "$GREEN"
    print_color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$BLUE"
    echo "$COMMIT_MSG"
    print_color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$BLUE"
    
    # Options
    echo ""
    print_color "Options:" "$YELLOW"
    echo "  📝 1) Commit with this message"
    echo "  ✏️  2) Edit message"
    echo "  🔄 3) Regenerate"
    echo "  ❌ 4) Cancel"
    echo ""
    read -p "Choice [1-4]: " choice
    
    case $choice in
        1)
            echo "$COMMIT_MSG" | git commit -F -
            local commit_hash=$(git rev-parse --short HEAD)
            print_color "\n✅ Committed successfully! ($commit_hash)" "$GREEN"
            git log -1 --oneline
            ;;
        2)
            FINAL_MSG=$(interactive_edit "$COMMIT_MSG")
            echo "$FINAL_MSG" | git commit -F -
            print_color "\n✅ Committed with edits!" "$GREEN"
            git log -1 --oneline
            ;;
        3)
            print_color "🔄 Regenerating..." "$BLUE"
            exec "$0"
            ;;
        4)
            print_color "❌ Cancelled" "$RED"
            exit 0
            ;;
        *)
            print_color "❌ Invalid choice" "$RED"
            exit 1
            ;;
    esac
}

# Run main
main "$@"