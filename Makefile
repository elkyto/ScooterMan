# ============================================================================
# @file:        Makefile
# @project:     ScooterMan
# @company:     Elkyto
# @author:      Allexander Bergmans
# @date:        2026-06-03
# @version:     1.0.0
# @brief:       Build automation for Scooter Management System
# @description:
#   This Makefile handles compilation, testing, cleaning, and deployment
#   of the ScooterMan application. It supports multiple targets for
#   different build configurations (debug, release, test).
# ============================================================================

# ----------------------------------------------------------------------------
#  @section: Project Configuration
# ----------------------------------------------------------------------------

# @const: PROJECT_NAME - Name of the application
PROJECT_NAME := scooterman

# @const: VERSION - Current version (follows semver)
VERSION := 1.0.0

# @const: COMPANY - Copyright holder
COMPANY := Elkyto

# @const: AUTHOR - Lead developer
AUTHOR := Allexander Bergmans

# ----------------------------------------------------------------------------
#  @section: Compiler and Tool Configuration
# ----------------------------------------------------------------------------

# @tool: CC - C compiler (prefer gcc, fallback to cc)
CC := gcc

# @tool: AR - Archiver for static libraries
AR := ar

# @tool: RM - Remove command (cross-platform safe)
RM := rm -f

# @tool: MKDIR - Create directory command
MKDIR := mkdir -p

# @tool: INSTALL - Install command
INSTALL := install

# @tool: DOXYGEN - Documentation generator (optional)
DOXYGEN := doxygen

# ----------------------------------------------------------------------------
#  @section: Compiler Flags
# ----------------------------------------------------------------------------

# @flag: WARN_FLAGS - Enable comprehensive warnings
WARN_FLAGS := -Wall -Wextra -Wpedantic -Wshadow -Wconversion

# @flag: DEBUG_FLAGS - Debugging symbols and sanitizers
DEBUG_FLAGS := -g -O0 -fsanitize=address -fsanitize=undefined

# @flag: RELEASE_FLAGS - Optimization for production
RELEASE_FLAGS := -O3 -DNDEBUG -flto

# @flag: CFLAGS - Base compiler flags
CFLAGS := -std=c11 $(WARN_FLAGS)

# @flag: LDFLAGS - Linker flags
LDFLAGS := -lm

# @flag: CPPFLAGS - Preprocessor flags (includes, defines)
CPPFLAGS := -D_GNU_SOURCE -D_VERSION=\"$(VERSION)\"

# @define: BUILD_MODE - Set based on target (debug or release)
BUILD_MODE ?= release

# ----------------------------------------------------------------------------
#  @section: Directory Structure
# ----------------------------------------------------------------------------

# @dir: SRCDIR - Source code directory
SRCDIR := src

# @dir: INCDIR - Header files directory
INCDIR := include

# @dir: OBJDIR - Object files directory (build artifacts)
OBJDIR := obj

# @dir: BINDIR - Binary output directory
BINDIR := bin

# @dir: LIBDIR - Library output directory
LIBDIR := lib

# @dir: TESTDIR - Test files directory
TESTDIR := tests

# @dir: DOCDIR - Documentation output directory
DOCDIR := docs

# @dir: DISTDIR - Distribution package directory
DISTDIR := dist

# ----------------------------------------------------------------------------
#  @section: Source Files Discovery
# ----------------------------------------------------------------------------

# @sources: All C source files in src directory
SOURCES := $(wildcard $(SRCDIR)/*.c)

# @sources: Main source file (entry point)
MAIN_SRC := $(SRCDIR)/main.c

# @sources: Library sources (excluding main)
LIB_SOURCES := $(filter-out $(MAIN_SRC), $(SOURCES))

# @headers: All header files
HEADERS := $(wildcard $(INCDIR)/*.h)

# @objects: Object files corresponding to sources
OBJECTS := $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SOURCES))

# @objects: Library objects (excluding main)
LIB_OBJECTS := $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(LIB_SOURCES))

# @binary: Final executable path
TARGET := $(BINDIR)/$(PROJECT_NAME)

# @library: Static library path (if needed)
LIBRARY := $(LIBDIR)/lib$(PROJECT_NAME).a

# ----------------------------------------------------------------------------
#  @section: Conditional Flag Selection
# ----------------------------------------------------------------------------

# @conditional: Add debug or release flags based on BUILD_MODE
ifeq ($(BUILD_MODE), debug)
    CFLAGS += $(DEBUG_FLAGS)
    CPPFLAGS += -DDEBUG
else ifeq ($(BUILD_MODE), release)
    CFLAGS += $(RELEASE_FLAGS)
    CPPFLAGS += -DRELEASE
else
    $(error BUILD_MODE must be 'debug' or 'release'. Current: $(BUILD_MODE))
endif

# ----------------------------------------------------------------------------
#  @section: Platform Detection
# ----------------------------------------------------------------------------

# @platform: Detect operating system for platform-specific flags
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S), Linux)
    LDFLAGS += -lrt
endif

ifeq ($(UNAME_S), Darwin)
    # macOS specific flags
endif

ifeq ($(OS), Windows_NT)
    TARGET := $(TARGET).exe
    RM := del /Q
    MKDIR := mkdir
endif

# ----------------------------------------------------------------------------
#  @section: Build Targets
# ----------------------------------------------------------------------------

# @target: all - Default target (builds release executable)
.PHONY: all
all: directories $(TARGET)
	@echo "✅ Build complete: $(TARGET)"
	@echo "📊 Version: $(VERSION)"
	@echo "🏢 Company: $(COMPANY)"

# ----------------------------------------------------------------------------
#  @target: directories - Create required directory structure
# ----------------------------------------------------------------------------
.PHONY: directories
directories:
	@$(MKDIR) $(OBJDIR) $(BINDIR) $(LIBDIR) $(TESTDIR) $(DOCDIR) $(DISTDIR)
	@echo "📁 Directory structure created"

# ----------------------------------------------------------------------------
#  @target: $(TARGET) - Link object files into final executable
#  @depends: $(OBJECTS) - All compiled object files
# ----------------------------------------------------------------------------
$(TARGET): $(OBJECTS)
	@echo "🔗 Linking $@..."
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)
	@echo "✅ Executable created: $@"

# ----------------------------------------------------------------------------
#  @target: $(LIBRARY) - Create static library (without main)
#  @depends: $(LIB_OBJECTS) - Library object files
# ----------------------------------------------------------------------------
$(LIBRARY): $(LIB_OBJECTS)
	@echo "📚 Creating static library $@..."
	$(AR) rcs $@ $^
	@echo "✅ Library created: $@"

# ----------------------------------------------------------------------------
#  @pattern: $(OBJDIR)/%.o - Compile C source to object file
#  @depends: $(SRCDIR)/%.c $(HEADERS) - Source and headers
# ----------------------------------------------------------------------------
$(OBJDIR)/%.o: $(SRCDIR)/%.c $(HEADERS)
	@echo "⚙️  Compiling $<..."
	$(CC) $(CPPFLAGS) $(CFLAGS) -I$(INCDIR) -c $< -o $@

# ----------------------------------------------------------------------------
#  @target: debug - Build with debugging symbols and sanitizers
#  @usage:   make debug
# ----------------------------------------------------------------------------
.PHONY: debug
debug: BUILD_MODE := debug
debug: clean directories $(TARGET)
	@echo "🐛 Debug build completed with address sanitizer"
	@echo "💡 Run with: ./$(TARGET)"

# ----------------------------------------------------------------------------
#  @target: release - Build optimized production version
#  @usage:   make release
# ----------------------------------------------------------------------------
.PHONY: release
release: BUILD_MODE := release
release: clean directories $(TARGET)
	@echo "🏭 Release build completed with optimizations"
	@echo "📦 Run with: ./$(TARGET)"

# ----------------------------------------------------------------------------
#  @target: clean - Remove all build artifacts
#  @usage:   make clean
# ----------------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	$(RM) $(OBJECTS) $(TARGET) $(LIBRARY)
	@echo "✅ Clean complete"

# ----------------------------------------------------------------------------
#  @target: distclean - Remove all generated files (including directories)
#  @usage:   make distclean
# ----------------------------------------------------------------------------
.PHONY: distclean
distclean: clean
	@echo "🗑️  Performing deep clean..."
	$(RM) -r $(OBJDIR) $(BINDIR) $(LIBDIR) $(DOCDIR) $(DISTDIR)
	@echo "✅ Deep clean complete"

# ----------------------------------------------------------------------------
#  @target: run - Build and run the application
#  @usage:   make run
# ----------------------------------------------------------------------------
.PHONY: run
run: $(TARGET)
	@echo "🚀 Running $(PROJECT_NAME) v$(VERSION)..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	./$(TARGET)

# ----------------------------------------------------------------------------
#  @target: test - Build and run unit tests
#  @usage:   make test
# ----------------------------------------------------------------------------
.PHONY: test
test: CFLAGS += -DTESTING
test: $(TARGET)
	@echo "🧪 Running test suite..."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	./$(TARGET) --test
	@echo "✅ All tests passed"

# ----------------------------------------------------------------------------
#  @target: install - Install binary to system location
#  @requires: root/sudo for system directories
#  @usage:   sudo make install
# ----------------------------------------------------------------------------
.PHONY: install
install: $(TARGET)
	@echo "📦 Installing $(PROJECT_NAME) to /usr/local/bin..."
	$(INSTALL) -m 755 $(TARGET) /usr/local/bin/$(PROJECT_NAME)
	@echo "✅ Installation complete"

# ----------------------------------------------------------------------------
#  @target: uninstall - Remove installed binary
#  @requires: root/sudo
#  @usage:   sudo make uninstall
# ----------------------------------------------------------------------------
.PHONY: uninstall
uninstall:
	@echo "🗑️  Uninstalling $(PROJECT_NAME)..."
	$(RM) /usr/local/bin/$(PROJECT_NAME)
	@echo "✅ Uninstall complete"

# ----------------------------------------------------------------------------
#  @target: docs - Generate Doxygen documentation
#  @requires: doxygen installed
#  @usage:   make docs
# ----------------------------------------------------------------------------
.PHONY: docs
docs:
	@echo "📚 Generating documentation..."
	@if command -v $(DOXYGEN) > /dev/null 2>&1; then \
		$(DOXYGEN) Doxyfile; \
		echo "✅ Documentation generated in $(DOCDIR)/html"; \
	else \
		echo "❌ Doxygen not found. Install with: brew install doxygen"; \
		exit 1; \
	fi

# ----------------------------------------------------------------------------
#  @target: format - Format source code with clang-format
#  @requires: clang-format installed
#  @usage:   make format
# ----------------------------------------------------------------------------
.PHONY: format
format:
	@echo "🎨 Formatting source code..."
	@if command -v clang-format > /dev/null 2>&1; then \
		clang-format -i $(SOURCES) $(HEADERS) 2>/dev/null || true; \
		echo "✅ Code formatting complete"; \
	else \
		echo "❌ clang-format not found. Install with: brew install clang-format"; \
		exit 1; \
	fi

# ----------------------------------------------------------------------------
#  @target: check - Run static analysis tools
#  @requires: cppcheck installed
#  @usage:   make check
# ----------------------------------------------------------------------------
.PHONY: check
check:
	@echo "🔍 Running static code analysis..."
	@if command -v cppcheck > /dev/null 2>&1; then \
		cppcheck --enable=all --suppress=missingIncludeSystem $(SRCDIR) $(INCDIR); \
		echo "✅ Static analysis complete"; \
	else \
		echo "❌ cppcheck not found. Install with: brew install cppcheck"; \
		exit 1; \
	fi

# ----------------------------------------------------------------------------
#  @target: profile - Build with profiling flags for performance analysis
#  @usage:   make profile && ./$(TARGET) && gprof $(TARGET) gmon.out
# ----------------------------------------------------------------------------
.PHONY: profile
profile: CFLAGS += -pg
profile: clean $(TARGET)
	@echo "📊 Profiling build complete"
	@echo "💡 Run: ./$(TARGET) && gprof $(TARGET) gmon.out > analysis.txt"

# ----------------------------------------------------------------------------
#  @target: size - Display binary size information
#  @usage:   make size
# ----------------------------------------------------------------------------
.PHONY: size
size: $(TARGET)
	@echo "📏 Binary size analysis:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@size $(TARGET) 2>/dev/null || echo "⚠️  size command not available"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ----------------------------------------------------------------------------
#  @target: package - Create distribution tarball
#  @usage:   make package
# ----------------------------------------------------------------------------
.PHONY: package
package: distclean $(TARGET) docs
	@echo "📦 Creating distribution package..."
	@mkdir -p $(DISTDIR)/$(PROJECT_NAME)-$(VERSION)
	@cp -r $(SRCDIR) $(INCDIR) $(BINDIR) $(DOCDIR) Makefile README.md LICENSE $(DISTDIR)/$(PROJECT_NAME)-$(VERSION) 2>/dev/null || true
	@cd $(DISTDIR) && tar -czf $(PROJECT_NAME)-$(VERSION).tar.gz $(PROJECT_NAME)-$(VERSION) 2>/dev/null || true
	@echo "✅ Package created: $(DISTDIR)/$(PROJECT_NAME)-$(VERSION).tar.gz"

# ----------------------------------------------------------------------------
#  @target: help - Display all available targets with descriptions
#  @usage:   make help
# ----------------------------------------------------------------------------
.PHONY: help
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 $(PROJECT_NAME) v$(VERSION) - Build System"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📋 Available targets:"
	@echo ""
	@echo "  @build:"
	@echo "    make all         - Build release executable (default)"
	@echo "    make debug       - Build with debugging symbols"
	@echo "    make release     - Build optimized production version"
	@echo "    make clean       - Remove build artifacts"
	@echo "    make distclean   - Deep clean (remove all generated files)"
	@echo ""
	@echo "  @run:"
	@echo "    make run         - Build and run the application"
	@echo "    make test        - Build and run unit tests"
	@echo "    make profile     - Build for performance profiling"
	@echo ""
	@echo "  @tools:"
	@echo "    make docs        - Generate Doxygen documentation"
	@echo "    make format      - Format code with clang-format"
	@echo "    make check       - Run static code analysis"
	@echo "    make size        - Display binary size information"
	@echo ""
	@echo "  @distribution:"
	@echo "    make install     - Install to /usr/local/bin"
	@echo "    make uninstall   - Remove installed binary"
	@echo "    make package     - Create distribution tarball"
	@echo ""
	@echo "  @info:"
	@echo "    make help        - Show this help message"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📖 Examples:"
	@echo "  make debug run     # Build debug version and run"
	@echo "  make release       # Build optimized version"
	@echo "  sudo make install  # Install system-wide"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ----------------------------------------------------------------------------
#  @section: Default Target
# ----------------------------------------------------------------------------
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------------
#  @section: Special Targets (phony declarations)
# ----------------------------------------------------------------------------
.PHONY: all debug release clean distclean run test install uninstall \
        docs format check profile size package help directories

# ----------------------------------------------------------------------------
#  @footer: Makefile ends here
#  @copyright: (c) Elkyto, 2026
#  @license: Proprietary - All rights reserved
# ----------------------------------------------------------------------------