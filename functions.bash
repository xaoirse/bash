#!/bin/bash

# SA https://github.com/xaoirse/bash

argparse() {

    unset opts
    unset args
    declare -gA opts
    declare -ga args

    params="${*:2}"
    params=$(printf '%s' "$params" | tr '\n' ' ')

    for token in $(printf "%s" "$1" | grep -Po '[[:alpha:]]:*'); do
        # a:: must set value if -a <value>
        if [[ "$token" = ?:: ]]; then
            token=${token/::/}
            value=$(printf "%s" "$params" | grep -Po "(^|\s)-[[:alpha:]]*?$token\s*\K[^-\s]\S*")
            if [ -n "$value" ]; then
                opts[$token]="$value"
                # shellcheck disable=SC2001
                params="$(printf "%s" "$params" | sed -e "s!\(\(^\|\s\)\-[[:alpha:]]*\?\)\($token\s*$value\)!\1!")"

            else
                printf "%s\n" "The option -$token must be specified and have a value"
                return 2
            fi

        # a: set value if -a <value>
        elif [[ "$token" = ?: ]]; then
            token="${token/:/}"
            value="$(printf '%s' "$params" | grep -Po "(^|\s)-[[:alpha:]]*?$token\s*\K(\S+)")"
            opts[$token]="$value"
            # shellcheck disable=SC2001
            params="$(printf '%s' "$params" | sed -e "s!\(\(^\|\s\)\-[[:alpha:]]*\?\)\($token\s*$value\)!\1!")"

        # a set true if -a
        else
            if printf "%s" "$params" | grep -Pq "(^|\s)-[[:alpha:]]*?$token"; then
                opts[$token]="true"
                params="$(printf "%s" "$params" | sed -r "s,(^|\s)(-\w*)($token)(.*),\1\2\4,g")"
            fi
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
    set -f && args=($params) && set +f

    if [ ! -t 0 ]; then
        while read line; do
            args+=("$line")
        done
    fi
}

_test_argparse() {
    argparse "p:v" "-p jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" ""
    assert_eq "${args[0]}" ""
    unset opts
    unset args

    argparse "p:v" "-vp jisoo"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" ""
    unset opts
    unset args

    argparse "p:v" "-vp jisoo lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "lisa"
    unset opts
    unset args

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "lisa"
    unset opts
    unset args

    argparse "p:v" "-p jisoo -v lisa"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "lisa"
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

    assert_eq "$(argparse "p:" "-p")" ""
    assert_eq "$(argparse "p:v" "-p")" ""
    assert_eq "$(argparse "p:v" "-vp")" ""
    assert_eq "$(argparse "v:p:" "-v blckpink -p")" ""

    assert_eq "$(argparse "v" "-n")" "Unknown option"
    assert_eq "$(argparse "v:p:" "-v blckpink -np bp")" "Unknown option"

    assert_eq "$(argparse "b::" "-p")" "The option -b must be specified and have a value"
    argparse "b::" "-p" >/dev/null
    assert_eq "$?" "2"
    unset opts
    unset args

    argparse "b::p:v" "-p jisoo -b blackpink babymonster"
    assert_eq "${opts[p]}" "jisoo"
    assert_eq "${opts[b]}" "blackpink"
    assert_eq "${opts[v]}" ""
    assert_eq "${args[0]}" "babymonster"
    unset opts
    unset args

    # Careful
    argparse "b::p:v" "-bp jisoo"
    assert_eq "${opts[b]}" "p"
    assert_eq "${opts[p]}" ""
    assert_eq "${opts[v]}" ""
    assert_eq "${args[0]}" "jisoo"
    assert_eq "${args[1]}" ""
    unset opts
    unset args

    argparse "b::p:v" "-b -p" >/dev/null || assert_eq $? 2

    argparse "" "*"
    assert_eq "${args[0]}" "*"

    argparse "u:" "-u http://domain.tld/home-index"
    assert_eq "${opts[u]}" "http://domain.tld/home-index"

    argparse '' a b <<<c
    assert_eq "${args[0]}" "a"
    assert_eq "${args[1]}" "b"
    assert_eq "${args[2]}" "c"

    _test_argparse_helper <<<c

    argparse "s" "https://domain.tld -s"
    assert_eq "${args[0]}" "https://domain.tld"
    assert_eq "${opts[s]}" "true"

    argparse "qsr" "-qsr https://domain.tld "
    assert_eq "${args[0]}" "https://domain.tld"
    assert_eq "${opts[q]}" "true"
    assert_eq "${opts[s]}" "true"
    assert_eq "${opts[r]}" "true"

    argparse "s" "-s https://domain.tld -s"
    assert_eq "${args[0]}" "https://domain.tld"
    assert_eq "${opts[s]}" "true"
}

_test_argparse_helper() {
    argparse '' a b

    assert_eq "${args[0]}" "a"
    assert_eq "${args[1]}" "b"
    assert_eq "${args[2]}" "c"
}

# join_by , a b
join_by() {
    separator="$1" # e.g. constructing regex, pray it does not contain %s
    regex="$(printf "%s${separator}" "${@:2}")"
    echo "${regex}"
}

anew() {
    local file="$1"

    if [ ! -t 0 ]; then
        while read line; do
            if ! test -f "$file" || ! grep -Fxq "$line" "$file"; then
                echo "$line" >>"$file"
                echo "$line"
            fi
        done
    fi
}

tops() {
    if [ ! -t 0 ]; then
        if [ "$1" = "-v" ]; then
            sort <"/dev/stdin" | grep . | uniq -c | sort -rgk 1
        else
            sort <"/dev/stdin" | grep . | uniq -c | sort -rgk 1 | sed 's,^\s*,,' | cut -d " " -f2-
        fi
    fi
}

unwrap_or() {
    if [ -n "$1" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

assert_eq() {
    if [ "$1" != "$2" ]; then
        printf "$(tput setaf 1 bold)%s ✖$(tput sgr0)$(tput setaf 1) $1 $(tput setaf 5)!= $(tput sgr0)$(tput setaf 1)$2$(tput sgr0)\n" "$([ -n "$3" ] && printf '%s' ":: $3")"
        return 1
    else
        printf "$(tput setaf 2 bold)%s ✔$(tput sgr0)$(tput setaf 2) $1 $(tput setaf 6)== $(tput sgr0)$(tput setaf 2)$2$(tput sgr0)\n" "$([ -n "$3" ] && printf '%s' ":: $3")"
    fi
}

# Text mode commands

# tput bold    # Select bold mode
# tput dim     # Select dim (half-bright) mode
# tput smul    # Enable underline mode
# tput rmul    # Disable underline mode
# tput rev     # Turn on reverse video mode
# tput smso    # Enter standout (bold) mode
# tput rmso    # Exit standout mode

# tput sgr0    # Reset text format to the terminal's default
# tput bel     # Play a bell

# tput setab [1-7] # Set the background colour using ANSI escape
# tput setaf [1-7] # Set the foreground colour using ANSI escape

# Num  Colour    #define         R G B
# 0    black     COLOR_BLACK     0,0,0
# 1    red       COLOR_RED       1,0,0
# 2    green     COLOR_GREEN     0,1,0
# 3    yellow    COLOR_YELLOW    1,1,0
# 4    blue      COLOR_BLUE      0,0,1
# 5    magenta   COLOR_MAGENTA   1,0,1
# 6    cyan      COLOR_CYAN      0,1,1
# 7    white     COLOR_WHITE     1,1,1
