#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
mkdir -p ../reports
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M ftp -t 8 | tee ../reports/medusa-ftp-$(echo $TARGET).txt
