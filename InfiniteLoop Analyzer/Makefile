# InfiniteLoop Analyzer Makefile
#
# Usage:
#   make analyze FILE=path/to/file.py    Analyze a Python file
#   make test                            Run the test suite
#   make install                         Install Python dependencies
#   make clean                           Remove generated files
#   make help                            Show this help message

.PHONY: analyze test install clean help

# Default target
help:
	@echo "InfiniteLoop Analyzer - Prolog-powered Python static analyzer"
	@echo ""
	@echo "Usage:"
	@echo "  make analyze FILE=<file.py>  Analyze a Python file"
	@echo "  make test                    Run the test suite"
	@echo "  make install                 Install Python dependencies"
	@echo "  make clean                   Remove generated files"
	@echo "  make help                    Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make analyze FILE=examples/demo/lot_of_bad_patterns.py"
	@echo "  make test"

# Analyze a Python file
analyze:
ifndef FILE
	@echo "Error: FILE parameter required"
	@echo "Usage: make analyze FILE=path/to/file.py"
	@exit 1
endif
	@./src/analyze.sh $(FILE)

# Run tests
test:
	@echo "Running InfiniteLoop Analyzer test suite..."
	@swipl -g "consult('src/tests.pl'), run_tests" -t halt

# Install dependencies
install:
	@echo "Installing Python dependencies..."
	@pip install -r requirements.txt

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f facts.pl
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Done."
