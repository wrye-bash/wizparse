#!/bin/bash
# This script downloads all build prerequisites for wizparse.

# Currently only the latest ANTLR release.
curl https://www.antlr.org/download/antlr-4.9.3-complete.jar --output scripts/antlr.jar
