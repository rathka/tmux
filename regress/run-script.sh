#!/bin/sh

# run-script command tests
# Tests argument passing, shell-quoting, alias, minimum args enforcement,
# and working directory (-c flag).

PATH=/bin:/usr/bin
TERM=screen

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
TMUX="$TEST_TMUX -Ltest"
$TMUX kill-server 2>/dev/null

TMP=$(mktemp)
SCRIPT=$(mktemp)
trap "rm -f $TMP $SCRIPT" 0 1 15

# Script that writes its arguments to TMP, one per line.
cat > $SCRIPT << 'EOF'
#!/bin/sh
for arg; do echo "$arg"; done
EOF
chmod +x $SCRIPT

# Test 1: basic argument passing - single argument
$TMUX -f/dev/null new -d "$TMUX run-script $SCRIPT hello >$TMP; sleep 10" || exit 1
sleep 1 && [ "$(cat $TMP)" = "hello" ] || exit 1

$TMUX kill-server 2>/dev/null

# Test 2: multiple arguments passed correctly
$TMUX -f/dev/null new -d "$TMUX run-script $SCRIPT foo bar baz >$TMP; sleep 10" || exit 1
sleep 1 && [ "$(cat $TMP)" = "$(printf 'foo\nbar\nbaz')" ] || exit 1

$TMUX kill-server 2>/dev/null

# Test 3: argument with spaces is passed as a single argument (shell-quoting)
$TMUX -f/dev/null new -d "$TMUX run-script $SCRIPT 'hello world' >$TMP; sleep 10" || exit 1
sleep 1 && [ "$(cat $TMP)" = "hello world" ] || exit 1

$TMUX kill-server 2>/dev/null

# Test 4: 'script' alias works identically
$TMUX -f/dev/null new -d "$TMUX script $SCRIPT hello >$TMP; sleep 10" || exit 1
sleep 1 && [ "$(cat $TMP)" = "hello" ] || exit 1

$TMUX kill-server 2>/dev/null

# Test 5: no arguments produces an error (minimum 1 required)
$TMUX -f/dev/null new -d "sleep 10" || exit 1
$TMUX run-script 2>/dev/null && exit 1

$TMUX kill-server 2>/dev/null

# Test 6: -c sets working directory, script receives it as $PWD
WDSCRIPT=$(mktemp)
cat > $WDSCRIPT << 'EOF'
#!/bin/sh
echo "$PWD"
EOF
chmod +x $WDSCRIPT
TMPDIR=$(mktemp -d)
trap "rm -f $TMP $SCRIPT $WDSCRIPT; rm -rf $TMPDIR" 0 1 15
$TMUX -f/dev/null new -d "$TMUX run-script -c $TMPDIR $WDSCRIPT >$TMP; sleep 10" || exit 1
sleep 1 && [ "$(cat $TMP)" = "$TMPDIR" ] || exit 1

$TMUX kill-server 2>/dev/null

exit 0
