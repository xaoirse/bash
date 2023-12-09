#!/bin/bash

argparse() {
    local OPTIND
    local OPTARG
    unset opts
    unset args
    declare -gA opts
    declare -ga args

    params="$2"

    # set a: to value if -a <value>
    for token in $(echo "$1" | grep -Eo '[[:alpha:]]{1}:'); do
        token=${token/:/}
        value=$(echo "$2" | grep -oP "(^|\s)-[[:alpha:]]*?$token\s*\K(\S+)")
        if [ -n "$value" ]; then
            opts["$token"]="$value"
            # shellcheck disable=SC2001
            params="$(echo "$params" | sed -e "s/\(^\|\s\)-[[:alpha:]]*\?\($token\s*\($value\)\)/\1/")"
            # params="$(echo "$params" | sed -e "/\(^\|\s\)-[[:alpha:]]*/s/$token//g")"
        else
            echo "-$token should have a value"
            return 2
        fi
    done

    # set a to set if -a
    for token in $(echo "$1" | grep -Po '\K[[:alpha:]](?=[^:]|$)'); do
        if echo "$2" | grep -Pq "(^|\s)-[[:alpha:]]*?$token"; then
            opts[$token]="true"
            params="$(echo "$params" | sed -e "/\(^\|\s\)-[[:alpha:]]*/s/$token//g")"
        fi
    done

    # return on unknown options
    if echo "$params" | grep -Pq "(^|\s)-[[:alpha:]]+?"; then
        echo "Unknown option"
        return 3
    fi

    # shellcheck disable=SC2001
    params="$(echo "$params" | sed 's,\(^\|\s\)-\+, ,g')"
    # shellcheck disable=SC2206
    args=($params)
}

test_argparse() {

    argparse "p:v" "-p jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" ""
    assert_eq "${args}" ""

    argparse "p:v" "-vp jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" ""

    argparse "p:v" "-vp jisoo lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"

    argparse "p:v" "rose -p jisoo -v lisa jennie"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "rose"
    assert_eq "${args[1]}" "lisa"
    assert_eq "${args[2]}" "jennie"

    argparse "p:n:v" "rose -p jisoo -v lisa jennie -n blackpink"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[n]}" "blackpink"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "rose"
    assert_eq "${args[1]}" "lisa"
    assert_eq "${args[2]}" "jennie"

}

assert_eq() {
    if [ "$1" != "$2" ]; then
        echo "right: $1"
        echo "left : $2"
        echo "Not equal"
        return 2
    fi
}
