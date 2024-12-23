#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC1091
. "$SCRIPT_DIR"/functions.bash


parseargs mehrnoosh -rvk -o out -st --verbous --in intake --nocpr -yc jisoo heydari --bp jennie love you -r -r -r

assert_eq "${ARGS[r]}" 1
assert_eq "${ARGS[v]}" 1
assert_eq "${ARGS[k]}" 1
assert_eq "${ARGS[o]}" "out"
assert_eq "${ARGS[s]}" 1
assert_eq "${ARGS[t]}" 1
assert_eq "${ARGS[verbous]}" 1
assert_eq "${ARGS[in]}" "intake"
assert_eq "${ARGS[nocpr]}" 1
assert_eq "${ARGS[y]}" 1
assert_eq "${ARGS[c]}" jisoo
assert_eq "${ARGS[bp]}" "jennie"
assert_eq "$args" "mehrnoosh    heydari  love you "