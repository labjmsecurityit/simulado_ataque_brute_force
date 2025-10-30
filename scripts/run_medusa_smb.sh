#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
mkdir -p ../reports
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M smbnt -t 6 | tee ../reports/medusa-smb-$(echo $TARGET).txt
