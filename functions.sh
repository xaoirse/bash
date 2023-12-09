#!/bin/bash

# SA https://github.com/xaoirse/bash

argparse() {
    unset opts
    unset args
    declare -gA opts
    declare -ga args

    params="$2"

    # set a: to value if -a <value>
    for token in $(printf "%s" "$1" | grep -Eo '[[:alpha:]]{1}:'); do
        token=${token/:/}
        value=$(printf "%s" "$params" | grep -oP "(^|\s)-[[:alpha:]]*?$token\s*\K(\S+)")
        if [ -n "$value" ]; then
            opts["$token"]="$value"
            # shellcheck disable=SC2001
            params="$(printf "%s" "$params" | sed -e "s/\(\(^\|\s\)\-[[:alpha:]]*\?\)\($token\s*$value\)/\1/")"
        else
            printf "%s\n" "-$token must have a value"
            return 2
        fi
    done

    # set a to true if -a
    for token in $(printf "%s" "$1" | grep -Po '\K[[:alpha:]](?=[^:]|$)'); do
        if printf "%s" "$params" | grep -Pq "(^|\s)-[[:alpha:]]*?$token"; then
            opts[$token]="true"
            params="$(printf "%s" "$params" | sed -e "/\(^\|\s\)-[[:alpha:]]*/s/$token//g")"
        fi
    done

    # return on unknown options
    if printf "%s" "$params" | grep -Pq "(^|\s)-[[:alpha:]]+?"; then
        printf "%s\n" "Unknown option"
        return 3
    fi

    # shellcheck disable=SC2001
    params="$(printf "%s" "$params" | sed 's,\(^\|\s\)-\+, ,g')"
    # shellcheck disable=SC2206
    args=($params)
}

_test_argparse() {

    argparse "p:v" "-p jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" ""
    assert_eq "${args}" ""
    unset opts
    unset args

    argparse "p:v" "-vp jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" ""
    unset opts
    unset args

    argparse "p:v" "-vp jisoo lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"
    unset opts
    unset args

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"
    unset opts
    unset args

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args}" "lisa"
    unset opts
    unset args

    argparse "p:v" "rose -p jisoo -v lisa jennie"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "rose"
    assert_eq "${args[1]}" "lisa"
    assert_eq "${args[2]}" "jennie"
    unset opts
    unset args

    argparse "p:n:v" "rose -p jisoo -v lisa jennie -n blackpink"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[n]}" "blackpink"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "rose"
    assert_eq "${args[1]}" "lisa"
    assert_eq "${args[2]}" "jennie"
    unset opts
    unset args

    # Special case
    argparse "p:n:v" "-vnp blackpink jisoo jennie"
    assert_eq "${opts[p]}" "blackpink"
    assert_eq "${opts[n]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${args[0]}" "jennie"
    unset opts
    unset args

    assert_eq "$(argparse "p:" "-p")" "-p must have a value"
    assert_eq "$(argparse "p:v" "-p")" "-p must have a value"
    assert_eq "$(argparse "p:v" "-vp")" "-p must have a value"
    assert_eq "$(argparse "v:p:" "-v blckpink -p")" "-p must have a value"

    assert_eq "$(argparse "v" "-n")" "Unknown option"
    assert_eq "$(argparse "v:p:" "-v blckpink -np bp")" "Unknown option"
}

assert_eq() {
    if [ "$1" != "$2" ]; then
        printf "%s\n" "right: $1"
        printf "%s\n\n" "left : $2"
        return 2
    fi
}
