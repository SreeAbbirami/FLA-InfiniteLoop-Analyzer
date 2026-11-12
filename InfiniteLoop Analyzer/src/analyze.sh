#!/bin/bash
#
# InfiniteLoop Analyzer - Automated Python code analysis pipeline
#
# Usage: ./analyze.sh <python_file.py>
#
# This script:
#   1. Parses the Python file to JSON AST
#   2. Converts JSON to Prolog facts
#   3. Launches SWI-Prolog with the analysis loaded
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <python_file.py>${NC}"
    echo ""
    echo "Example:"
    echo "  $0 examples/demo/lot_of_bad_patterns.py"
    exit 1
fi

INPUT_FILE="$1"
BASENAME="${INPUT_FILE%.py}"
JSON_FILE="${BASENAME}.json"
PL_FILE="${BASENAME}.pl"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: File '$INPUT_FILE' not found.${NC}"
    exit 1
fi

# Check if input is a Python file
if [[ ! "$INPUT_FILE" == *.py ]]; then
    echo -e "${RED}Error: File must be a .py file.${NC}"
    exit 1
fi

echo -e "${BLUE}=== InfiniteLoop Analyzer Analysis Pipeline ===${NC}"
echo ""

# Step 1: Parse Python to JSON
echo -e "${GREEN}[1/3]${NC} Parsing Python to JSON..."
python3 "$SCRIPT_DIR/ast_parser.py" "$INPUT_FILE"

# Step 2: Convert JSON to Prolog facts
echo -e "${GREEN}[2/3]${NC} Converting JSON to Prolog facts..."
swipl -g "consult('$SCRIPT_DIR/json_to_prolog.pl'), load_and_save_python('$JSON_FILE')" -t halt

# Move facts.pl to the correct location
if [ -f "facts.pl" ]; then
    mv facts.pl "$PL_FILE"
    echo "Generated: $PL_FILE"
elif [ -f "$SCRIPT_DIR/facts.pl" ]; then
    mv "$SCRIPT_DIR/facts.pl" "$PL_FILE"
    echo "Generated: $PL_FILE"
fi

# Step 3: Launch Prolog with analysis
echo -e "${GREEN}[3/3]${NC} Launching SWI-Prolog analysis..."
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "  ?- check_all_patterns_respected.    % Run all checks"
echo "  ?- print_tree.                      % Visualize AST"
echo "  ?- print_tree(verbose).             % Detailed AST"
echo "  ?- halt.                            % Exit"
echo ""
echo -e "${BLUE}Starting Prolog REPL...${NC}"
echo ""

swipl "$SCRIPT_DIR/analyzer.pl" "$PL_FILE"
