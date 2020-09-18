#!/bin/bash
# Collection of useful functions and aliases when working on wizparse.
# Use via `source scripts/aliases.sh` from the top level.

CLASSPATH=".:$(realpath scripts/antlr.jar)"
export CLASSPATH

WIZ_TMP_DIR="$(realpath tmp/wizards)"

# Parses a wizard provided as the command line argument, regardless of
# what your cwd is.
function wizparse() {
    test_wizard="$1"
    if [ -z "$test_wizard" ]
    then
        echo "Missing argument: path to wizard"
        return 1
    fi

    real_wizard=$(realpath "$test_wizard")
    if [ ! -f "$real_wizard" ]
    then
        echo "$real_wizard does not exist or is not a file."
        return 2
    fi

    cwd="$(pwd)"
    if [ ! -d "$WIZ_TMP_DIR" ]
    then
        echo "$WIZ_TMP_DIR does not exist. Run scripts/build.sh to create it."
        return 3
    fi

    cd "$WIZ_TMP_DIR" || return
    java org.antlr.v4.gui.TestRig wizard parseWizard "$real_wizard" "${@:2}"
    cd "$cwd" || return
}
