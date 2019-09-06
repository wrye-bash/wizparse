# wizparse

A new parser / interpreter for BAIN wizards based on [ANTLR](https://www.antlr.org/).

## Parser
The parser is generated from an ANTLR4 grammar.
This should hopefully also make it easier for other projects to use it.
It is found in [wizards/wizard.g4](wizards/wizard.g4).

It supports everything listed in the [BAIN wizard documentation](https://wrye-bash.github.io/docs/Wrye%20Bash%20Technical%20Readme.html#wizards), but has some breaking changes since the previous parser was *very* lax.
See [Breaking Changes](Breaking%20Changes.md) for more information.

## AST Converter
Not yet implemented

## Interpreter
Not yet implemented

## License
wizparse is licensed under the MIT license. See [LICENSE](LICENSE) for the full text.
