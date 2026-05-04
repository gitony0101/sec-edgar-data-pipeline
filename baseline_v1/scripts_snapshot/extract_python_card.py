#!/usr/bin/env python
import ast
import sys
from pathlib import Path

path = Path(sys.argv[1])
src = path.read_text(encoding="utf-8")
tree = ast.parse(src)

imports = []
functions = []
classes = []

for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            imports.append(alias.name)
    elif isinstance(node, ast.ImportFrom):
        mod = node.module or ""
        for alias in node.names:
            imports.append(f"{mod}.{alias.name}" if mod else alias.name)
    elif isinstance(node, ast.FunctionDef):
        functions.append(node.name)
    elif isinstance(node, ast.AsyncFunctionDef):
        functions.append(node.name)
    elif isinstance(node, ast.ClassDef):
        classes.append(node.name)

def uniq(items):
    seen = set()
    out = []
    for x in items:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out

imports = uniq(imports)
functions = uniq(functions)
classes = uniq(classes)

print(f"### {path}")
print()
print(f"- path: {path}")
print(f"- line_count: {len(src.splitlines())}")
print("- imports:")
for x in imports[:30]:
    print(f"  - {x}")
if not imports:
    print("  - none")
print("- functions:")
for x in functions[:30]:
    print(f"  - {x}")
if not functions:
    print("  - none")
print("- classes:")
for x in classes[:30]:
    print(f"  - {x}")
if not classes:
    print("  - none")
