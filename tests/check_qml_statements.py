"""No line of QML script opens with a bracket after a finished statement.

JavaScript has no semicolon to end a line on unless one is written, so a
line opening with ( or [ runs on from the one before: `loader.active = true`
then `(loader.item as Menu).popup()` is read as `true(loader.item ...)`, which
throws "true is not a function" and opens nothing. Nothing fails until the
code runs. This names each such line with where it is.

    check_qml_statements.py <qml directory>
"""

import pathlib
import sys

# a line ending in one of these goes on into the next, as meant
CONTINUES = tuple("{([,;:=+-*/%?&|!<>")


def suspects(path):
    previous = ""
    for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), start=1):
        code = line.split("//")[0].strip()
        if not code:
            continue
        if code[0] in "([" and previous and not previous.endswith(CONTINUES):
            yield number, code
        previous = code


def main():
    qml = pathlib.Path(sys.argv[1])
    found = 0
    for path in sorted(qml.rglob("*.qml")):
        for number, code in suspects(path):
            print(f"{path.relative_to(qml)}:{number}: runs on from the line before: {code}")
            found += 1
    if found:
        print(f"{found} line(s) open with a bracket after a finished statement; go through a name instead")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
