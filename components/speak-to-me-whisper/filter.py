#!/usr/bin/env python3
import sys, re

while True:
    x = sys.stdin.readline()

    # Apply substitutions
    x = re.sub(".*\r", "", x)
    x = re.sub("\[.*?\]", "", x)
    x = re.sub("\(.*?\)", "", x)
    x = re.sub("\*.*?\*", "", x)

    # Remove leading and trailing whitespaces, including newlines
    x = x.strip()

    # Check if the resulting string is not empty before printing
    if x:
        sys.stdout.write("%s\n" % x)
        sys.stdout.flush()


