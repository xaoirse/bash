#!/bin/bash

# SA https://github.com/xaoirse/bash

# Function to parse command-line arguments
# Usage: argparser "$@"
# Example: argparser -rvk -o out -st --verbous --in intake --nocpr -yc jisoo heydari --bp jennie love you -r -r -r
# Output:
# ARGS[r]=1
# ARGS[v]=1
# ARGS[k]=1
# ARGS[o]=out
# ARGS[s]=1
# ARGS[t]=1
# ARGS[verbous]=1
# ARGS[in]=intake
# ARGS[nocpr]=1
# ARGS[y]=1
# ARGS[c]=jisoo
# ARGS[bp]=jennie
# args=mehrnoosh heydari love you
argparser() {
    # ARGS: An array that Includes options, arguments, and flags.
    #       Flags are represented with a value of 1 for presence and 0 for absence.
    unset ARGS

    # shellcheck disable=SC2034
    declare -gA ARGS

    # All other parameters
    args=""

    string="$*"
    len=${#string}

    var_name=""
    var_val=""
    state=" "
    save=0

    for ((i = 0; i < len; i++)); do
        c="${string:i:1}"
        case "$state" in
        "-")
            case "$c" in
            [a-zA-Z])
                if [ -n "$var_name" ]; then
                    declare -g "ARGS[$var_name]"="1"
                fi
                var_name="$c"
                ;;
            "-")
                state="--"
                ;;
            " ")
                state="val"
                ;;
            *)
                echo >&2 " Any other character except [- a-zA-Z] after '-' is invalid"
                return 2
                ;;
            esac
            ;;
        "--")
            case "$c" in
            " ")
                echo >&2 "Space after '--' is invalid"
                return 3
                ;;
            *)
                var_name="$c"
                state="name"
                ;;

            esac
            ;;
        "name")
            case "$c" in
            [a-zA-Z0-9_])
                var_name="$var_name$c"
                state="name"
                ;;
            " ")
                state="val"
                ;;
            *)
                echo >&2 "Invalid character for name"
                return 4
                ;;
            esac
            ;;
        "val")
            case "$c" in
            "-")
                if [ -z "$var_val" ]; then
                    declare -g "ARGS[$var_name]"="1"
                    var_name=""
                    state="-"
                else
                    var_val="$var_val$c"
                fi
                ;;
            " ")
                args="$args "
                save=1
                ;;
            *)
                var_val="$var_val$c"

                ;;
            esac
            ;;
        " ")
            case "$c" in
            "-")
                state="-"
                ;;
            *)
                args="$args$c"
                ;;
            esac
            ;;
        *)
            echo >&2 "Invalid character for set state"
            return 6
            ;;
        esac

        if [ $save -eq 1 ]; then
            declare -g "ARGS[$var_name]"="${var_val:=1}"
            save=0
            state=" "
            var_val=""
            var_name=""
        fi

    done

    if [ -n "$var_name" ]; then
        declare -g "ARGS[$var_name]"="${var_val:=1}"
        save=0
        state=" "
        var_val=""
        var_name=""
    fi

    # Get piped values
    if [ ! -t 0 ]; then
        while read -r line; do
            args="$args $line"
        done
    fi
}

# Function to filter words by length
# Usage: echo word | filter_len -m 3 -x 5
# Options:
#   -m: minimum length (default: 0)
#   -x: maximum length (default: 9999999999)
# Example: echo "hello world" | filter_len -m 3 -x 5
# Output: hello world
filter_len() {
    argparser "$@" || return 1

    for arg in $args; do
        len="${#arg}"
        min="${ARGS[m]:-0}"
        max="${ARGS[x]:-$(printf '%d' 0xFFFFFFFF)}"
        ((len >= min && len <= max)) && echo "$arg"
    done
}

# TODO delete this function.
# Function to parse command-line arguments
# Usage: argparse "options" "$@"
# Options format: "a:b::c" where:
#   - c: single character option without value
#   - b: single character option with a required value
#   - a:: single character option with an optional value
# Example: argparse "a:b::c" "$@"
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

# Function to join elements by a separator
# Usage: join_by <separator> <element1> <element2> ...
# Example: join_by , a b c
# Output: a,b,c
join_by() {
    local separator="$1"
    shift
    local result="$1"
    shift
    for arg in "$@"; do
        result="${result}${separator}${arg}"
    done
    echo "${result}"
}

# Function to add unique lines to a file
# Usage: echo "line" | anew <file>
# Example: echo "line" | anew file.txt
# Output: line
anew() {
    # Create the file if it does not exist
    if [ ! -f "$1" ]; then
        touch "$1"
    fi

    # Ensure the file is writable
    if [ ! -w "$1" ]; then
        echo "Error: File '$1' is not writable." >&2
        return 1
    fi

    # Read from standard input line by line
    while IFS= read -r line; do
        # Check if the exact line already exists in the file using grep
        if ! grep -Fxq "$line" "$1"; then
            echo "$line" | tee -a "$1"
        fi
    done
}

# Function to count the frequency of lines
# Usage: echo "line" | tops -v
tops() {
    if [ ! -t 0 ]; then
        if [ "$1" = "-v" ]; then
            sort | grep . | uniq -c | sort -rgk 1
        else
            sort | grep . | uniq -c | sort -rgk 1 | sed 's,^\s*,,' | cut -d " " -f2-
        fi
    fi
}

# Function to trim whitespace characters
# Usage: trim "  hello  "
# Output: hello
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Function to unwrap a value or return a default
# Usage: unwrap_or "value" "default"
# Example: unwrap_or "" "default"
# Output: default
unwrap_or() {
    local value
    value="$(trim "$1")"
    local default="$2"

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Function to assert equality of two values
# Usage: assert_eq "expected" "actual" "message"
# Example: assert_eq "apple" "apple" "fruits are equal"
# Output: ✔ apple == apple
assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" != "$actual" ]; then
        printf "$(tput setaf 1 bold)%s ✖$(tput sgr0)$(tput setaf 1) $expected $(tput setaf 5)!= $(tput sgr0)$(tput setaf 1)$actual$(tput sgr0)\n" "$([ -n "$message" ] && printf '%s' ":: $message")"
        return 1
    else
        printf "$(tput setaf 2 bold)%s ✔$(tput sgr0)$(tput setaf 2) $expected $(tput setaf 6)== $(tput sgr0)$(tput setaf 2)$actual$(tput sgr0)\n" "$([ -n "$message" ] && printf '%s' ":: $message")"
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
