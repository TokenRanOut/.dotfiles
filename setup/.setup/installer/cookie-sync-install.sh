#!/bin/bash

set -o pipefail

python3 -m pip install --user --upgrade cryptography websockets
python3 -m pip install --user 'ccl_chromium_reader @ https://github.com/cclgroupltd/ccl_chromium_reader/archive/ef840de30221c4d65bc96d2f4d9057e9ef2f526d.zip'
