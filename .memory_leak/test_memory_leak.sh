#!/bin/bash

echo "Running tests without valgrind"
TEST_NGINX_USE_VALGRIND=1 prove -r t 2>&1 | tee /tmp/result.TEST_NGINX_USE_VALGRIND
awk -f /valgrind.awk /tmp/result.TEST_NGINX_USE_VALGRIND > /tmp/has-valgrind.log
if [[ -s /tmp/has-valgrind.log ]]; then
  cat /tmp/has-valgrind.log >&2
  exit 1
fi
echo "No valgrind errors found"
exit 0