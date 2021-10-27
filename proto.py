#!/usr/bin/env python3

import sys
import math as m

# position in expression
i = 0

def parse(e) -> int or float:
    global i
    e = e.replace(" ", "")
    r = operation(e)

    if (i < len(e)) and (e[i] == ")"):
        print(f"error: mismatched parenthesis", file=sys.stderr)
        exit(1)

    return r

def operation(e) -> int or float:
    global i

    r = expression(e)

    if (i < len(e)) and e[i].isalpha():
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] in "|&^><"):
        if isinstance(r, float):
            print(f"error: attempted bitwise operation on float", file=sys.stderr)
            exit(1)

        # get unsigned int working
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
            if i >= len(e) or e[i] != ">":
                print(f"error: incomplete bitwise shift", file=sys.stderr)
                exit(1)
            i += 1
            r >>= expression(e)

        elif e[i] == "<":
            i += 1
            if i >= len(e) or e[i] != "<":
                print(f"error: incomplete bitwise shift", file=sys.stderr)
                exit(1)
            i += 1
            r <<= expression(e)

    if (i < len(e)) and (e[i] == "("):
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

    return r

def expression(e) -> int or float:
    global i
    r = term(e)

    if (i < len(e)) and e[i].isalpha():
        print(f"error: invalid syntax", file=sys.stderr)
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

    if (i > len(e)) and e[i].isalpha():
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

    while (i < len(e)) and (e[i] in "*/%"):
        if e[i] == "*":
            i += 1
            if e[i] == "*":
                i += 1
                r **= factor(e)
            else:
                r *= factor(e)

        elif e[i] == "/":
            i += 1
            try:
                r /= factor(e)
            except ZeroDivisionError:
                print(f"error: divided by zero", file=sys.stderr)
                exit(1)

        elif e[i] == "%":
            i += 1
            r %= factor(e)

    return r

def factor(e) -> int or float:
    global i

    check = lambda: (i < len(e)) and (e[i].isdigit() or e[i] in ".")

    if check():
        buf = ""
        while check():
            buf += e[i]
            i += 1

        try:
            r = float(buf)
        except ValueError:
            print(f"error: invalid syntax", file=sys.stderr)
            exit(1)

        return int(r) if r.is_integer() else float(r)

    elif (i < len(e)) and (e[i] == "("):
        i += 1
        r = operation(e)
        if (i >= len(e)) or (e[i] != ")"):
            print(f"error: mismatched parenthesis", file=sys.stderr)
            exit(1)
        i += 1

        return r

    elif (i < len(e)) and (e[i] in "+-~!"):
        r = unary(e)
        return r

    else:
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

def unary(e) -> int or float:
    global i

    op = e[i]
    i += 1

    if i >= len(e):
        print(f"error: expected number or ( at index {i}", file=sys.stderr)
        exit(1)

    if op == "+":
        r = +factor(e)

    elif op == "-":
        r = -factor(e)

    elif op == "~":
        r = factor(e)
        if isinstance(r, float):
            print(f"error: attempted bitwise operation on float", file=sys.stderr)
            exit(1)
        r = ~r

    elif op == "!":
        r = factor(e)
        if isinstance(r, float) or (r < 0):
            print(f"error: attempted factorial on non positive integer", file=sys.stderr)
            exit(1)
        r = m.factorial(r)

    return r

if __name__ == '__main__':
    r = parse(sys.argv[1])
    print(f"result = {r}")
