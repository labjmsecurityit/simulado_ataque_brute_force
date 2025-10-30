#!/bin/bash
TARGET=$1
mkdir -p ../reports
nmap -sS -sV -p- "$TARGET" -oN ../reports/nmap-full-$(echo $TARGET).txt
