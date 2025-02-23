# Simple Arg Parser for Bash
This function is easy to use in scripts. It doesn't rely on any binary or temporary files.

### USAGE

```bash
source <(curl -s https://raw.githubusercontent.com/xaoirse/bash/main/functions.sh)

# Examples
    argparser "rose -j jisoo -v -g blackpink lisa jennie"
    
    assert_eq "${ARGS[j]}" "jisoo"
    assert_eq "${ARGS[g]}" "blackpink"
    assert_eq "${ARGS[v]}" "true"
    assert_eq "${ARGS[u]}" ""
    assert_eq "$args" "rose   lisa jennie"
    ...
    argparser "-b -p" >/dev/null || assert_eq $? 2

```