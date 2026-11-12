#!/usr/bin/env python3
"""
InfiniteLoop Analyzer Parser - Converts Python source files to JSON AST representation.

Usage:
    python3 parser.py <input_file.py> [output_file.json]

If output_file is not specified, it defaults to <input_file>.json
"""

import ast
import json
import sys
import os
from ast2json import ast2json


def parse_python_to_json(input_file: str, output_file: str = None) -> str:
    """
    Parse a Python file and convert its AST to JSON.

    Args:
        input_file: Path to the Python file to parse
        output_file: Optional path for the output JSON file

    Returns:
        Path to the generated JSON file
    """
    if not os.path.exists(input_file):
        print(f"Error: File '{input_file}' not found.", file=sys.stderr)
        sys.exit(1)

    if not input_file.endswith('.py'):
        print(f"Error: File '{input_file}' is not a Python file.", file=sys.stderr)
        sys.exit(1)

    if output_file is None:
        output_file = input_file.rsplit('.py', 1)[0] + '.json'

    with open(input_file, 'r') as f:
        source_code = f.read()

    try:
        tree = ast.parse(source_code)
    except SyntaxError as e:
        print(f"Error: Syntax error in '{input_file}': {e}", file=sys.stderr)
        sys.exit(1)

    json_tree = ast2json(tree)

    with open(output_file, 'w') as f:
        json.dump(json_tree, f, indent=2)

    print(f"Parsed: {input_file} -> {output_file}")
    return output_file


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    parse_python_to_json(input_file, output_file)


if __name__ == '__main__':
    main()
