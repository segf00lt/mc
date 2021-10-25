#!/usr/bin/env python3

import sys
import math as m

# position in expression
i = 0

def operation(e) -> int or float:
    global i

    if e[i] == "~":
        i += 1
        try:
            e[i]
        except IndexError:
            print(f"error: expected number or ( at index {i}", file=sys.stderr)
            exit(1)

        r = operation(e)
        if isinstance(r, float):
            print(f"error: attempted bitwise operation on float", file=sys.stderr)
            exit(1)

        return ~r

    r = expression(e)

    if (i < len(e)) and e[i].isalpha():
        print(f"error: expected operator at index {i}", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] in "|&^><"):
        if isinstance(r, float):
            print(f"error: attempted bitwise operation on float", file=sys.stderr)
            exit(1)

        b = bin(r)
        r = int(b[1 if b[0] == "-" else 0:], base=2)

        if e[i] == "|":
            i += 1
            r |= expression(e)

        elif e[i] == "&":
            i += 1
            r &= expression(e)

        elif e[i] == "^":
            i += 1
            r ^= expression(e)

        elif e[i] == ">":
            i += 1
            try:
                if e[i] == ">":
                    i += 1
                    r >>= expression(e)
                else:
                    print(f"error: incomplete bitwise shift at index {i}", file=sys.stderr)
                    exit(1)
            except IndexError:
                print(f"error: incomplete bitwise shift at index {i}", file=sys.stderr)
                exit(1)

        elif e[i] == "<":
            i += 1
            try:
                if e[i] == "<":
                    i += 1
                    r <<= expression(e)
                else:
                    print(f"error: incomplete bitwise shift at index {i}", file=sys.stderr)
                    exit(1)
            except IndexError:
                print(f"error: incomplete bitwise shift at index {i}", file=sys.stderr)
                exit(1)

    return r

def expression(e) -> int or float:
    global i
    r = term(e)

    if (i < len(e)) and e[i].isalpha():
        print(f"error: expected operator at index {i}", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] in "+-"):
        if e[i] == "+":
            i += 1
            r += term(e)
        elif e[i] == "-":
            i += 1
            r -= term(e)
        while (i < len(e)) and e[i] == " ":
            i += 1

    return r

def term(e) -> int or float:
    global i
    r = factor(e)

    if (i < len(e)) and e[i].isalpha():
        print(f"error: expected operator at index {i}", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] in "*/"):
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

    return r

def factor(e) -> int or float:
    global i

    check = lambda: (i < len(e)) and (e[i].isdigit() or e[i] in ".")

    count = 0
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

        return int(r) if r.is_integer() else float(r)

    elif (i < len(e)) and (e[i] == "("):
        i += 1
        r = expression(e)
        if e[i] != ")":
            print(f"error: missing ) at index {i}", file=sys.stderr)
            exit(1)
        i += 1

        return r

    else:
        print(f"error: expected number or ( at index {i}", file=sys.stderr)
        exit(1)

if __name__ == '__main__':
    e = sys.argv[1]
    e = e.replace(" ", "")
    r = operation(e)
    print(f"result = {r}")
