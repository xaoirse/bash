#!/bin/bash

# SA https://github.com/xaoirse/bash

parseargs() {
    unset ARGS
    declare -gA ARGS
    args=""

    string="$*"
    len=${#string}

    var_name=""
    var_val=""
    state=" "
    save=0
    for ((i=0; i < len; i++)); do
        c="${string:i:1}"
        case "$state" in
            "-")
                case "$c" in
                    [a-zA-Z])
                        if [ -n "$var_name" ]; then
                            declare -g "ARGS[$var_name]"="1"
                            echo "+ ARGS[$var_name]"="1"
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
                    return 2
                    ;;
                esac
            ;; 
            "--")
                case "$c" in
                    " ")
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
                        return 4 
                    ;;
                esac
            ;;
            "val")
                case "$c" in
                    "-")
                        if [ -z "$var_val" ]; then
                            declare -g "ARGS[$var_name]"="1"
                            echo "- ARGS[$var_name]"="1"
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
                return 6
            ;; 
        esac

        if [ $save -eq 1 ]; then 
            declare -g "ARGS[$var_name]"="${var_val:=1}"
            echo  "/ ARGS[$var_name]"="${var_val:=1}"
            save=0
            state=" "
            var_val=""
            var_name=""
        fi

    done

    if [ -n "$var_name" ]; then 
        declare -g "ARGS[$var_name]"="${var_val:=1}"
        echo  "= ARGS[$var_name]"="${var_val:=1}"
        save=0
        state=" "
        var_val=""
        var_name=""
    fi
}

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

# Function to unwrap a value or return a default
unwrap_or() {
    local value="$1"
    local default="$2"
    
    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Function to assert equality of two values
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
