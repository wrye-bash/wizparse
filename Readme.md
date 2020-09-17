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

## Building & Testing
Still a bit rough because it was designed for CI, but see the [scripts](scripts) folder.
In short:
 1. Make sure you're on Linux. You're on your own on Windows.
 1. Make sure you have Java 8 and that it's the one you're currently using.
    For example, on Arch Linux, check with `archlinux-java status` and switch with `archlinux-java set`.
 1. Run `./scripts/prereq.sh`. This will download a copy of ANTLR.
 1. Run `./scripts/build.sh`. This will generate a Java parser and compile it.
 1. Run `./scripts/test.sh`. This will run all tests in the tests folder.
 1. If it worked, yo

## License
wizparse is licensed under the MIT license. See [LICENSE](LICENSE) for the full text.

The exception is [tests](tests). All files in there have their own accompanying license file, which applies to that file only.
The vast majority of those files are licensed under Nexus' weird permission system, with most having terms similar to a CC-BY-NC license.
