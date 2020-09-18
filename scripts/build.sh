#!/bin/bash
# This script generates and builds wizparse using ANTLR.

if [ ! -f scripts/antlr.jar ]
then
    echo "$(realpath scripts/antlr.jar) is missing. Run scripts/prereq.sh to download it."
    exit 1
fi

# Add antlr.jar to the classpath
CLASSPATH=".:$(realpath scripts/antlr.jar):$CLASSPATH"
export CLASSPATH

# Generate the parser and compile it
java org.antlr.v4.Tool -o tmp wizards/wizard.g4
# We rely on none of the .java files having spaces, so ignore this
# shellcheck disable=SC2046
javac $(find tmp -type f -iname "*.java" -printf '%p ') # separates with spaces
