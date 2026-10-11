"""Every Material Symbols name the QML asks for exists in the pinned font.

A misspelt name does not fail anywhere: the font's ligatures miss and the
name shows as text. This reads the font's codepoints list and the QML, and
names each miss with where it is.

    check_icon_names.py <codepoints file> <qml directory>
"""

import pathlib
import re
import sys

LITERAL = re.compile(r'"([a-z][a-z0-9_]+)"')


def symbol_literals(path):
    """string literals on lines that set a symbol, or a MaterialSymbol's text"""
    lines = path.read_text(encoding="utf-8").split("\n")
    for number, line in enumerate(lines, start=1):
        recent = lines[max(0, number - 7):number]
        in_symbol = any("MaterialSymbol {" in previous for previous in recent) and "text:" in line
        if re.search(r"[sS]ymbol", line) or in_symbol:
            for literal in LITERAL.findall(line):
                yield number, literal


def main():
    codepoints, qml = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    names = {line.split()[0] for line in codepoints.read_text().splitlines() if line.strip()}
    misses = [
        f"{path.relative_to(qml.parent)}:{number}: {literal}"
        for path in sorted(qml.rglob("*.qml"))
        for number, literal in symbol_literals(path)
        if literal not in names
    ]
    for miss in misses:
        print(f"not in the font: {miss}")
    return 1 if misses else 0


if __name__ == "__main__":
    sys.exit(main())
