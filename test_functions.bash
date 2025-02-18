#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck disable=SC1091
. "$SCRIPT_DIR"/functions.bash

_test_argparser() {
    argparser mehrnoosh -rvk -o out -st --verbous --in intake --nocpr -yc jisoo heydari --bp jennie love you -r -r -r

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
}

_test_join_by() {
    local result

    result=$(join_by , a b c)
    assert_eq "a,b,c" "$result" "join_by with comma separator"

    result=$(join_by - 1 2 3)
    assert_eq "1-2-3" "$result" "join_by with dash separator"

    result=$(join_by "" a b c)
    assert_eq "abc" "$result" "join_by with empty separator"

    result=$(join_by , a)
    assert_eq "a" "$result" "join_by with single element"

    result=$(join_by ,)
    assert_eq "" "$result" "join_by with no elements"
}

_test_anew() {
    local test_file
    test_file=$(mktemp)

    echo -e "line1\nline2\nline3" | anew "$test_file"
    assert_eq "$(cat "$test_file")" "line1
line2
line3" "anew with new lines"

    echo -e "line2\nline4" | anew "$test_file"
    assert_eq "$(cat "$test_file")" "line1
line2
line3
line4" "anew with some existing lines"

    rm "$test_file"
}

_test_tops() {
    local result

    result=$(echo -e "apple\nbanana\napple\napple\nbanana\ncherry" | tops)
    assert_eq "$result" "apple
banana
cherry" "tops with default behavior"

    result=$(echo -e "apple\nbanana\napple\napple\nbanana\ncherry" | tops -v)
    assert_eq "$result" "      3 apple
      2 banana
      1 cherry" "tops with verbose flag"
}

_test_trim() {
    local result

    result=$(trim "  hello  ")
    assert_eq "hello" "$result" "trim with leading and trailing spaces"

    result=$(trim "hello")
    assert_eq "hello" "$result" "trim with no spaces"

    result=$(trim "  hello")
    assert_eq "hello" "$result" "trim with leading spaces"

    result=$(trim "hello  ")
    assert_eq "hello" "$result" "trim with trailing spaces"

    result=$(trim "  ")
    assert_eq "" "$result" "trim with only spaces"

    result=$(trim "")
    assert_eq "" "$result" "trim with empty string"
}

_test_unwrap_or() {
    local result

    result=$(unwrap_or "value" "default")
    assert_eq "value" "$result" "unwrap_or with non-empty value"

    result=$(unwrap_or "" "default")
    assert_eq "default" "$result" "unwrap_or with empty value"

    result=$(unwrap_or "  " "default")
    assert_eq "default" "$result" "unwrap_or with spaces only"

    result=$(unwrap_or "value" "")
    assert_eq "value" "$result" "unwrap_or with empty default"
}

_test_filter_len() {
    result=$(echo "hello world" | filter_len -m 3 -x 5)
    assert_eq "$result" "hello
world" "Filter words between 3 and 5 characters"

    result=$(echo "hello world" | filter_len -m 6)
    assert_eq "$result" "" "Filter words with minimum length 6"

    result=$(echo "hello world" | filter_len -x 4)
    assert_eq "$result" "" "Filter words with maximum length 4"

    result=$(echo "hello myworld" | filter_len -m 5 -x 5)
    assert_eq "$result" "hello" "Filter words with length exactly 5"
}

printf "Running tests for argparser\n"
_test_argparser

printf "\nRunning tests for join_by\n"
_test_join_by

printf "\nRunning tests for anew\n"
_test_anew

printf "\nRunning tests for tops\n"
_test_tops

printf "\nRunning tests for trim\n"
_test_trim

printf "\nRunning tests for unwrap_or\n"
_test_unwrap_or

printf "\nRunning tests for filter_len\n"
_test_filter_len
