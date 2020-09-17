#!/bin/bash
# This script runs a test parse on each test file, failing the CI if any files fail to parse.

# Check if stdout is a tty and supports color
# If not, they will be undefined and hence resolve to empty strings
if test -t 1
then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test "$ncolors" -ge 8
    then
        C_RED='\033[1;31m'
        C_GREEN='\033[1;32m'
        C_BLUE='\033[1;34m'
        C_YELLOW='\033[1;33m'
        C_NC='\033[0m'
    fi
fi

# Add antlr.jar to the classpath
CLASSPATH=".:$(realpath scripts/antlr.jar):$CLASSPATH"
export CLASSPATH

# ANTLR can only handle local class files
cd tmp/wizards || exit

num_tests=$(find ../../tests -type f -name '*.txt' -printf x | wc -c)
echo -e "${C_BLUE}==>${C_NC} Testing $num_tests wizards"

for rel_test in ../../tests/*.txt
do
    # Get rid of the .., looks better in logs
    real_test=$(realpath "$rel_test")
    echo -e "   ${C_BLUE}::${C_NC} ${C_YELLOW}Current test wizard:${C_NC} $real_test"
    # TestRig doesn't set an abnormal return code, so analyze its stderr output
    java org.antlr.v4.gui.TestRig wizard parseWizard "$real_test" 2> parseErrors.txt
    if [ -s parseErrors.txt ] # exists and is not empty
    then
        # Since we swallowed the stderr output, print it back out
        echo -e "${C_BLUE}==>${C_NC} ${C_RED}Test failed, error message follows${C_NC}"
        echo "$(<parseErrors.txt)"
        exit 1 # fail the CI
    fi
    echo -e "   ${C_BLUE}::${C_NC} ${C_GREEN}Test passed${C_NC}"
done

echo -e "${C_BLUE}==>${C_NC} ${C_GREEN}All test passed${C_NC}"
