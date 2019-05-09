#!/bin/bash

# 1) start server:
#   without caching:
#       REDIS_HOST=None CHEATSH_PORT=50000 python bin/srv.py
#       (recommended)
#   with caching:
#       REDIS_PREFIX=TEST1 CHEATSH_PORT=50000 python bin/srv.py 
#       (for complex search queries + to test caching)
# 2) configure CHTSH_URL
# 3) run the script

TMP=$(mktemp /tmp/cht.sh.tests-XXXXXXXXXXXXXX)
TMP2=$(mktemp /tmp/cht.sh.tests-XXXXXXXXXXXXXX)
TMP3=$(mktemp /tmp/cht.sh.tests-XXXXXXXXXXXXXX)
trap 'rm -rf $TMP $TMP2 $TMP3' EXIT

export CHTSH_URL=http://cht.sh:50000
CHTSH_SCRIPT=$(dirname "$(dirname "$(readlink -f "$0")")")/share/cht.sh.txt

i=0
failed=0
{
  if [ -z "$1" ]; then
    cat -n tests.txt
  else
    cat -n tests.txt | sed -n "$(echo "$*" | sed 's/ /p; /g;s/$/p/')"
  fi
} > "$TMP3"

skip_online=NO
test_standalone=YES
show_details=YES

while read -r number test_line; do
  if [ "$skip_online" = YES ]; then
    if [[ $test_line = *\[online\]* ]]; then
      echo "$number is [online]; skipping"
      continue
    fi
  fi

  test_line=$(echo $test_line | sed 's@ *#.*@@')

  if [ "$test_standalone" = YES ]; then
    python ../lib/standalone.py "$test_line" > "$TMP" 2> /dev/null
  elif [[ $test_line = "cht.sh "* ]]; then
    test_line="${test_line//cht.sh /}"
    eval "bash $CHTSH_SCRIPT $test_line" > "$TMP"
  else
    eval "curl -s $CHTSH_URL/$test_line" > "$TMP"
  fi

  if ! diff results/"$number" "$TMP" > "$TMP2"; then
    if [ "$show_details" = YES ]; then
      echo "$ CHEATSH_CACHE_TYPE=none python ../lib/standalone.py $test_line"
      cat "$TMP2"
    fi
    echo "FAILED: [$number] $test_line"
    ((failed++))
  fi
  ((i++))
done < "$TMP3"

echo TESTS/OK/FAILED "$i/$((i-failed))/$failed"


