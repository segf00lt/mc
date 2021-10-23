#!/usr/bin/env python3

import sys
import math as m

# position in expression
i = 0

def expr(e) -> float:
    global i
    r = term(e)

    while (i < len(e)) and e[i] == " ":
        i += 1

    if (i < len(e)) and e[i].isalpha():
        print(f"error: expected operator at character {i}", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] == "+" or e[i] == "-"):
        if e[i] == "+":
            i += 1
            r += term(e)
        elif e[i] == "-":
            i += 1
            r -= term(e)
        while (i < len(e)) and e[i] == " ":
            i += 1

    return r

def term(e) -> float:
    global i
    r = factor(e)

    while (i < len(e)) and e[i] == " ":
        i += 1

    if (i < len(e)) and e[i].isalpha():
        print(f"error: expected operator at character {i}", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] == "*" or e[i] == "/"):
        if e[i] == "*":
            i += 1
            if e[i] == "*":
                i += 1
                r **= factor(e)
            else:
                r *= factor(e)

        elif e[i] == "/":
            i += 1
            r /= factor(e)

        while (i < len(e)) and e[i] == " ":
            i += 1

    return r

def factor(e) -> float:
    global i
    while (i < len(e)) and e[i] == " ":
        i += 1

    check = lambda: (i < len(e)) and (e[i].isdigit() or e[i] == "-" or e[i] == "+" or e[i] == ".")

    if check():
        buf = ""
        while check():
            buf += e[i]
            i += 1

        try:
            r = float(buf)
        except ValueError:
            print(f"error: unexpected syntax", file=sys.stderr)
            exit(1)

        return r

    elif (i < len(e)) and (e[i] == "("):
        i += 1
        r = expr(e)
        if e[i] != ")":
            print(f"error: missing ) at character {i}", file=sys.stderr)
            exit(1)
        i += 1
        return r

    else:
        print(f"error: expected number or ( at character {i}", file=sys.stderr)
        exit(1)

if __name__ == '__main__':
    e = sys.argv[1]
    r = expr(e)
    print(f"result = {r}")
