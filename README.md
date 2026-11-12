# FLA-InfiniteLoop-Analyzer

<h1 align="center">InfiniteLoop Analyzer</h1>

<p align="center">
  <i>Static analyzer for Python code focused on infinite-loop and anti-pattern detection using declarative AST analysis.</i>
</p>

<p align="center">
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/Python-3.x-blue?logo=python&logoColor=white" alt="Python 3.x"></a>
  <a href="https://www.swi-prolog.org/"><img src="https://img.shields.io/badge/SWI--Prolog-9.x-orange?logo=prolog" alt="SWI-Prolog"></a>
  <img src="https://img.shields.io/badge/License-Academic-green" alt="Academic License">
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#usage">Usage</a> •
  <a href="#detected-patterns">Detected Patterns</a> •
  <a href="#testing">Testing</a>
</p>

---

## About

**InfiniteLoop Analyzer** uses Prolog-based logical inference to inspect Python source code. It converts Python's Abstract Syntax Tree (AST) into Prolog facts, then applies declarative pattern matching to detect loop problems, code smells, and anti-patterns.

### How It Works

```
Python Source (.py)  →  JSON AST  →  Prolog Facts (.pl)  →  Pattern Analysis
       ↓                    ↓              ↓                      ↓
  ast_parser.py        ast2json     json_to_prolog.pl        analyzer.pl
```

---

## Features

### Core Capabilities
- **AST Parsing** — Converts Python code to structured Prolog facts
- **Tree Navigation** — Hierarchical traversal with `parent/2`, `children/2`, `ancestor/2`
- **Tree Visualization** — Pretty-print AST with configurable verbosity
- **Pattern Detection** — 13+ code smell detectors

### Advanced Analysis
- **Accumulator Pattern Detection** — Identifies proper accumulator usage in loops
- **Infinite Loop Detection** — Catches always-true conditions and unmodified loop variables
- **Complexity Analysis** — Flags excessive nesting, long functions, too many parameters

---

## Quick Start

### Prerequisites
- Python 3.x
- SWI-Prolog 9.x
- `ast2json` Python package

### Installation

```bash
# Clone the repository
git clone https://github.com/your-user/infiniteloop-analyzer.git
cd infiniteloop-analyzer

# Install Python dependencies
pip install -r requirements.txt
```

### Analyze Your First File

```bash
# Option 1: Using the automation script
./src/analyze.sh path/to/your_file.py

# Option 2: Using Make
make analyze FILE=path/to/your_file.py

# Option 3: Step by step (see Usage section)
```

---

## Usage

### Automated Pipeline

The easiest way to analyze a Python file:

```bash
./src/analyze.sh examples/demo/lot_of_bad_patterns.py
```

This will:
1. Parse the Python file to JSON
2. Convert JSON to Prolog facts
3. Launch SWI-Prolog with the analysis loaded

### Manual Step-by-Step

#### Step 1: Convert Python to JSON

```bash
python3 src/ast_parser.py examples/demo/lot_of_bad_patterns.py
# Output: examples/demo/lot_of_bad_patterns.json
```

#### Step 2: Convert JSON to Prolog Facts

```bash
swipl -g "consult('src/json_to_prolog.pl'), load_and_save_python('examples/demo/lot_of_bad_patterns.json')" -t halt
mv facts.pl examples/demo/lot_of_bad_patterns.pl
```

#### Step 3: Analyze the Code

```bash
swipl src/analyzer.pl examples/demo/lot_of_bad_patterns.pl
```

### Analysis Commands

Once in the Prolog REPL:

```prolog
% Check all patterns at once
?- check_all_patterns_respected.

% Visualize the AST
?- print_tree.              % Condensed view
?- print_tree(verbose).     % Detailed view
?- print_tree(12).          % Subtree from node 12

% Specific pattern checks
?- has_accumulator_patterns.
?- has_all_functions_have_return_as_last_statement.
?- has_all_loop_have_used_vars.
```

---

## Detected Patterns

| Pattern | Description | Predicate |
|---------|-------------|-----------|
| Empty Constructor | `__init__` with only `pass` | `has_empty_constructor/0` |
| Constructor Returns | `__init__` returning a value | `has_constructor_return/0` |
| Parameter Reassignment | Reassigning function parameters | `has_parameters_reassignement/0` |
| Increment in For-Loop | Manual loop variable modification | `has_increment_in_forloop/0` |
| Early Return | Return statements inside loops | `has_early_return/0` |
| Too Much Indentation | 3+ levels of nesting | `has_too_much_indent/0` |
| Print Instead of Return | Functions ending with print | `has_print_instead_return/0` |
| Infinite Loop | Always-true while conditions | `has_infinite_loop/0` |
| Too Long Function | Functions exceeding 15 statements | `has_too_long_function/0` |
| Too Many Parameters | Functions with 5+ parameters | `has_too_many_parameters/0` |
| Unused Loop Variables | Loop variables never used | `has_all_loop_have_used_vars/0` |
| Missing Return | Functions not ending with return | `has_all_functions_have_return_as_last_statement/0` |
| Accumulator Pattern | Proper accumulator usage | `has_accumulator_patterns/0` |

---

## Repository Structure

```
infiniteloop-analyzer/
├── src/
│   ├── analyzer.pl       # Main analysis engine (pattern detection)
│   ├── json_to_prolog.pl # JSON to Prolog facts converter
│   ├── ast_parser.py     # Python AST to JSON parser
│   ├── tests.pl          # Test suite (76 tests)
│   └── analyze.sh        # Automation script
├── examples/
│   ├── demo/                    # Good/bad practice demonstrations
│   ├── basic_predicates/        # Tree navigation examples
│   ├── accumulator_patterns/    # Accumulator pattern tests
│   ├── constructor_empty/       # Empty constructor tests
│   ├── constructor_return/      # Constructor return tests
│   ├── early_return/            # Early return tests
│   ├── increment_in_forloop/    # For-loop increment tests
│   ├── infinite_loop/           # Infinite loop tests
│   ├── parameters_reassignement/# Parameter reassignment tests
│   ├── print_instead_return/    # Print vs return tests
│   ├── return_last_statement/   # Return placement tests
│   ├── too_long_function/       # Function length tests
│   ├── too_many_parameters/     # Parameter count tests
│   ├── too_much_indent/         # Indentation depth tests
│   └── unused_loop_vars/        # Unused variable tests
├── Makefile             # Build automation
├── requirements.txt     # Python dependencies
└── README.md
```

---

## Testing

Run the complete test suite:

```bash
make test
# or
swipl -g "consult('src/tests.pl'), run_tests" -t halt
```

The test suite includes **76 tests** covering:
- Basic predicates (`parent/2`, `children/2`, `ancestor/2`)
- Tree visualization (`print_tree/0`, `print_tree/1`)
- All 13 pattern detection predicates
- Both positive (`yes.pl`) and negative (`no.pl`) test cases


---

## Author

<div align="center">

<table>
  <tr>
    <td width="180" align="left">
      <img src="https://img.shields.io/badge/GitHub-mathisdelsart-black?logo=github" valign="middle"/>
    </td>
    <td align="left">
      <strong>Mathis DELSART</strong>
    </td>
  </tr>
</table>

</div>


<div align="center">

**Built for LINFO2335 - Programming Paradigms @ UCLouvain** (Université catholique de Louvain).

*Leveraging declarative programming for smarter code analysis*

</div>
