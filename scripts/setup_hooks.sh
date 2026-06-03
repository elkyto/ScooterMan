#!/bin/bash
# scripts/setup_hooks.sh
# @purpose: Install all custom hooks for ScooterMan

PROJECT_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔧 Installing Git hooks for ScooterMan..."

# @task: Create hooks directory if missing
mkdir -p "$HOOKS_DIR"

# @task: Install pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for ScooterMan

echo "🎨 Checking code style..."
make format > /dev/null 2>&1

echo "🔍 Running linter..."
make check > /dev/null 2>&1

echo "🔨 Compiling..."
make debug > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

echo "✅ Ready to commit!"
EOF

# @task: Make all hooks executable
chmod +x "$HOOKS_DIR"/*

echo "✅ Hooks installed successfully!"

# @task: List installed hooks
echo "📋 Installed hooks:"
ls -la "$HOOKS_DIR" | grep -v "\.sample$"