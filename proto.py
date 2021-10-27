#!/usr/bin/env python3

import sys
import re
from enum import Enum
import math as m

# position in expression
i = 0

def parse(e) -> int or float:
    global i
    e = e.replace(" ", "")
    r = sentence(e)

    if i < len(e) and e[i] == ")":
        print(f"error: mismatched parenthesis", file=sys.stderr)
        exit(1)

    return r

class COMPARE(Enum):
    LT = 1
    GT = 2
    LEQ = 3
    GEQ = 4
    EQ = 5
    NEQ = 6

def sentence(e) -> int or float:
    global i
    r = operation(e)
    v = []
    c = []

    while i < len(e) and e[i] in "><=!":
        v.append(r)

        if e[i] == ">":
            i += 1
            if i >= len(e):
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)
            if e[i] == "=":
                i += 1
                r = operation(e)
                c.append(COMPARE.GEQ)
            else:
                r = operation(e)
                c.append(COMPARE.GT)

        elif e[i] == "<":
            i += 1
            if i >= len(e):
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)
            if e[i] == "=":
                i += 1
                r = operation(e)
                c.append(COMPARE.LEQ)
            else:
                r = operation(e)
                c.append(COMPARE.LT)

        elif e[i] == "=":
            i += 1
            if i >= len(e):
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)
            if e[i] == "=":
                i += 1
                r = operation(e)
                c.append(COMPARE.EQ)
            else:
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)

        elif e[i] == "!":
            i += 1
            if i >= len(e):
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)
            if e[i] == "=":
                i += 1
                r = operation(e)
                c.append(COMPARE.NEQ)
            else:
                print(f"error: incomplete comparison", file=sys.stderr)
                exit(1)

    if len(v) > 0:
        v.append(r)
        r = 1

    for i in range(len(c)):
        op = 0
        if c[i] == COMPARE.GT:
            op = int(v[i] > v[i + 1])
        elif c[i] == COMPARE.GEQ:
            op = int(v[i] >= v[i + 1])
        elif c[i] == COMPARE.LT:
            op = int(v[i] < v[i + 1])
        elif c[i] == COMPARE.LEQ:
            op = int(v[i] <= v[i + 1])
        elif c[i] == COMPARE.EQ:
            op = int(v[i] == v[i + 1])
        elif c[i] == COMPARE.NEQ:
            op = int(v[i] != v[i + 1])
        r &= op

    return r

def operation(e) -> int or float:
    global i

    r = expression(e)

    while i < len(e) and e[i] in "|&^><":
        # get unsigned int working

        if e[i] == "|":
            i += 1
            if isinstance(r, float):
                print(f"error: attempted bitwise operation on float", file=sys.stderr)
                exit(1)
            r |= expression(e)

        elif e[i] == "&":
            i += 1
            if isinstance(r, float):
                print(f"error: attempted bitwise operation on float", file=sys.stderr)
                exit(1)
            r &= expression(e)

        elif e[i] == "^":
            i += 1
            if isinstance(r, float):
                print(f"error: attempted bitwise operation on float", file=sys.stderr)
                exit(1)
            r ^= expression(e)

        elif e[i] == ">":
            i += 1
            if i >= len(e) or e[i] != ">":
                i -= 1
                return r
            if isinstance(r, float):
                print(f"error: attempted bitwise operation on float", file=sys.stderr)
                exit(1)
            i += 1
            r >>= expression(e)

        elif e[i] == "<":
            i += 1
            if i >= len(e) or e[i] != "<":
                i -= 1
                return r
            if isinstance(r, float):
                print(f"error: attempted bitwise operation on float", file=sys.stderr)
                exit(1)
            i += 1
            r <<= expression(e)

    if i < len(e) and e[i] == "(":
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

    return r

def expression(e) -> int or float:
    global i
    r = term(e)

    while i < len(e) and e[i] in "+-":
        if e[i] == "+":
            i += 1
            r += term(e)
        elif e[i] == "-":
            i += 1
            r -= term(e)

    return r

def term(e) -> int or float:
    global i
    r = factor(e)

    while i < len(e) and e[i] in "*/%!":
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

        elif e[i] == "!":
            if isinstance(r, float) or r < 0:
                print(f"error: attempted factorial on non positive integer", file=sys.stderr)
                exit(1)
            r = m.factorial(r)
            i += 1

    return r

def factor(e) -> int or float:
    global i

    if i < len(e) and (e[i].isdigit() or e[i] in "."):
        r = number(e)
        return r

    elif i < len(e) and e[i] == "(":
        r = paren(e)
        return r

    elif i < len(e) and e[i] in "+-~":
        r = unary(e)
        return r

    elif i < len(e) and re.match("[a-z]+[0-9]*\.?[0-9]*\(", e[i:]):
        r = function(e)
        return r

    elif i < len(e) and e[i].isalpha():
        r = constant(e)
        return r

    else:
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

def number(e) -> int or float:
    global i

    check = lambda: i < len(e) and (e[i].isdigit() or e[i] in ".")

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

    else:
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

def paren(e) -> int or float:
    global i

    if i < len(e) and e[i] == "(":
        i += 1
        r = operation(e)
        if i >= len(e) or e[i] != ")":
            print(f"error: mismatched parenthesis", file=sys.stderr)
            exit(1)
        i += 1

        return r

    else:
        print(f"error: invalid syntax", file=sys.stderr)
        exit(1)

def unary(e) -> int or float:
    global i

    op = e[i]
    i += 1

    if i >= len(e):
        print(f"error: invalid syntax", file=sys.stderr)
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

    return r

def constant(e) -> int or float:
    global i

    if e[i:].find("pi") == 0:
        r = m.pi
        i += 2

        return r
    
    elif e[i:].find("e") == 0:
        r = m.e
        i += 1

        return r

    else:
        print(f"error: unrecognized constant", file=sys.stderr)
        exit(1)

def function(e) -> int or float:
    global i

    if e[i:].find("sin") == 0:
        i += 3
        r = paren(e)
        r = m.sin(r)
        return r

    elif e[i:].find("cos") == 0:
        i += 3
        r = paren(e)
        r = m.cos(r)
        return r

    elif e[i:].find("tan") == 0:
        i += 3
        r = paren(e)
        r = m.tan(r)
        return r

    elif e[i:].find("asin") == 0:
        i += 4
        r = paren(e)
        r = m.asin(r)
        return r

    elif e[i:].find("acos") == 0:
        i += 4
        r = paren(e)
        r = m.acos(r)
        return r

    elif e[i:].find("atan") == 0:
        i += 4
        r = paren(e)
        r = m.atan(r)
        return r

    elif e[i:].find("root") == 0:
        i += 4
        n = 1
        if i < len(e) and e[i].isdigit():
            n = factor(e)
        if n == 0:
            print(f"error: attempted 0 root", file=sys.stderr)
            exit(1)
        r = paren(e)
        r = r ** (1 / n)
        return r

    elif e[i:].find("ln") == 0:
        i += 2
        r = paren(e)
        r = m.log(r, m.e)
        return r

    elif e[i:].find("abs") == 0:
        i += 3
        r = paren(e)
        r = m.fabs(r)
        return r

    elif e[i:].find("log") == 0:
        i += 3
        if i < len(e) and e[i] == "(":
            r = paren(e)
            r = m.log10(r)
            return r
        elif i < len(e) and e[i].isdigit():
            n = number(e)
            r = paren(e)
            r = m.log(r, n)
            return r
        else:
            print(f"error: invalid syntax", file=sys.stderr)
            exit(1)

    else:
        print(f"error: unrecognized function", file=sys.stderr)
        exit(1)

if __name__ == '__main__':
    r = parse(sys.argv[1])
    print(f"result = {r}")
