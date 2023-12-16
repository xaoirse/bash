# Simple Arg Parser for Bash
Easy to use in functions. It's a straightforward function without any binary files or temporary files.

### USAGE

```bash
source <(curl -s https://raw.githubusercontent.com/xaoirse/bash/main/functions.sh)

# Examples
    argparse "j:g::v" "rose -j jisoo -v lisa jennie -g blackpink"
    
    assert_eq "${opts[j]}" "jisoo"
    assert_eq "${opts[g]}" "blackpink"
    assert_eq "${opts[v]}" "true"
    assert_eq "${opts[u]}" ""
    assert_eq "${args[0]}" "rose"
    assert_eq "${args[1]}" "lisa"
    assert_eq "${args[2]}" "jennie"
    ...
    argparse "b::p:v" "-b -p" >/dev/null || assert_eq $? 2

```