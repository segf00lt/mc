# mc

`mc` is a command line tool loosely inspired by the Unix tools `expr` and `bc`,
and designed to enhance the numerical capabilities of the shell.

Unlike `bc`, `mc` is not a language. The user cannot define variables
or functions, create loops or do any kind of control flow (beyond a ternary conditional
operator). The rational behind this choice is that the shell already has these capabilities,
and therefor they need not be duplicated in a program designed purely to deal with numbers
and simple logic.

A rough but comprehensive description of `mc`'s syntax is available in `mc.1`,
and the full specification of grammar and terminal symbols can be found in
`parser.y` and `lexer.l` respectively.

## Installation
First make sure `yacc` and `flex` are installed on your system,
then simply run the following command line.

`git clone https://github.com/segf00lt/mc && cd mc/ && sudo make install`

To uninstall simply run `sudo make uninstall` in the `mc/` directory.

## TODO

- Improve error reports from parser
