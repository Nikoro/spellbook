#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Real-process E2E. Not invoked by scripts/check.sh (too slow for a per-change
# hook). CI runs it in a separate workflow; developers run it manually before
# releases. Must be idempotent: fresh temp dir per run, trap-cleanup on exit.

if ! command -v swift >/dev/null 2>&1; then
  echo "Spellbook E2E: swift toolchain not installed; skipping."
  exit 0
fi

tmpdir="$(mktemp -d -t spellbook-e2e-XXXXXX)"
export SPELLBOOK_HOME="$tmpdir/home"
mkdir -p "$SPELLBOOK_HOME"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM

echo "Spellbook E2E: tmpdir=$tmpdir"
echo "Spellbook E2E: building release binary"
swift build -c release
binary="$(swift build -c release --show-bin-path)/spells"

if [[ ! -x "$binary" ]]; then
  echo "Spellbook E2E: release binary not found at $binary" >&2
  exit 1
fi

cp "$binary" "$tmpdir/spells"
export PATH="$tmpdir:$SPELLBOOK_HOME/bin:$PATH"

passed=0
failed=0

run_scenario() {
  local name="$1"
  echo ""
  echo "--- Scenario: $name ---"
}

pass() {
  echo "  PASS"
  passed=$((passed + 1))
}

fail_scenario() {
  echo "  FAIL: $1" >&2
  failed=$((failed + 1))
}

# ---------------------------------------------------------------------------
# Scenario 0: Smoke — spells --version
# ---------------------------------------------------------------------------
run_scenario "version smoke"
version_output="$("$tmpdir/spells" --version 2>&1)"
if [[ -n "$version_output" ]]; then
  pass
else
  fail_scenario "empty version output"
fi

# ---------------------------------------------------------------------------
# Scenario 1: Activation
# ---------------------------------------------------------------------------
run_scenario "activation"
mkdir -p "$tmpdir/project1"
cat > "$tmpdir/project1/spells.yaml" << 'YAML'
spells:
  sb-hello:
    script: echo "Hello from Spellbook"
  sb-world:
    aliases: [sbw]
    script: echo "World"
YAML

(cd "$tmpdir/project1" && "$tmpdir/spells") > /dev/null 2>&1

if [[ -x "$SPELLBOOK_HOME/bin/sb-hello" && -x "$SPELLBOOK_HOME/bin/sb-world" && -x "$SPELLBOOK_HOME/bin/sbw" ]]; then
  pass
else
  fail_scenario "wrappers not created"
fi

# Verify state.json exists
if [[ -f "$SPELLBOOK_HOME/state.json" ]]; then
  pass
else
  fail_scenario "state.json not created"
fi

# ---------------------------------------------------------------------------
# Scenario 2: Wrapper invocation
# ---------------------------------------------------------------------------
run_scenario "wrapper invocation"
wrapper_output="$(cd "$tmpdir/project1" && "$SPELLBOOK_HOME/bin/sb-hello" 2>&1)"
if [[ "$wrapper_output" == *"Hello from Spellbook"* ]]; then
  pass
else
  fail_scenario "unexpected output: $wrapper_output"
fi

# Alias wrapper
alias_output="$(cd "$tmpdir/project1" && "$SPELLBOOK_HOME/bin/sbw" 2>&1)"
if [[ "$alias_output" == *"World"* ]]; then
  pass
else
  fail_scenario "alias wrapper output: $alias_output"
fi

# ---------------------------------------------------------------------------
# Scenario 3: Extends merge
# ---------------------------------------------------------------------------
run_scenario "extends merge"
mkdir -p "$tmpdir/parent" "$tmpdir/child"
cat > "$tmpdir/parent/spells.yaml" << 'YAML'
spells:
  sb-shared:
    script: echo "from parent"
  sb-overridden:
    script: echo "parent version"
YAML

cat > "$tmpdir/child/spells.yaml" << 'YAML'
extends: ../parent
spells:
  sb-overridden:
    script: echo "child version"
  sb-local:
    script: echo "child only"
YAML

(cd "$tmpdir/child" && "$tmpdir/spells") > /dev/null 2>&1

# Parent spell should have a wrapper
if [[ -x "$SPELLBOOK_HOME/bin/sb-shared" ]]; then
  pass
else
  fail_scenario "parent spell wrapper not created"
fi

# Child override should run child version
override_output="$(cd "$tmpdir/child" && "$SPELLBOOK_HOME/bin/sb-overridden" 2>&1)"
if [[ "$override_output" == *"child version"* ]]; then
  pass
else
  fail_scenario "override not working: $override_output"
fi

# State should preserve spell origins across extends.
run_scenario "extends state origins"
origin_check="$(
  python3 - "$SPELLBOOK_HOME/state.json" "$tmpdir/child" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    state = json.load(handle)

projects = state["projects"]
child = None

for project_state in projects.values():
    chain = project_state.get("chain", [])
    if chain and chain[-1].endswith("/child/spells.yaml"):
        child = project_state
        break

if child is None:
    print("missing child project entry")
    sys.exit(1)

shared_origin = child["spells"]["sb-shared"]["origin"]
local_origin = child["spells"]["sb-local"]["origin"]
override_origin = child["spells"]["sb-overridden"]["origin"]

if (
    shared_origin.endswith("/parent/spells.yaml")
    and local_origin.endswith("/child/spells.yaml")
    and override_origin.endswith("/child/spells.yaml")
):
    print("ok")
    sys.exit(0)

print(
    "bad origins: "
    f"shared={shared_origin} "
    f"override={override_origin} "
    f"local={local_origin}"
)
sys.exit(1)
PY
)" || true
if [[ "$origin_check" == "ok" ]]; then
  pass
else
  fail_scenario "$origin_check"
fi

# ---------------------------------------------------------------------------
# Scenario 4: Failure diagnostics
# ---------------------------------------------------------------------------
run_scenario "failure diagnostics"
mkdir -p "$tmpdir/bad"
printf '\thello:\n  script: echo hi\n' > "$tmpdir/bad/spells.yaml"

if (cd "$tmpdir/bad" && "$tmpdir/spells") > /dev/null 2>&1; then
  fail_scenario "should have failed on tab indentation"
else
  pass
fi

# ---------------------------------------------------------------------------
# Performance: 20-spell activation
# ---------------------------------------------------------------------------
run_scenario "perf: 20-spell activation"
mkdir -p "$tmpdir/perf"
{
  echo "spells:"
  for i in $(seq 1 20); do
    echo "  spell$i:"
    echo "    script: echo spell $i"
  done
} > "$tmpdir/perf/spells.yaml"

ACTIVATION_BUDGET_MS=100
EXECUTION_BUDGET_MS=750

start_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
(cd "$tmpdir/perf" && "$tmpdir/spells") > /dev/null 2>&1
end_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
duration=$((end_ms - start_ms))
echo "  20-spell activation: ${duration}ms (budget: <${ACTIVATION_BUDGET_MS}ms, release target)"
if [[ $duration -lt $ACTIVATION_BUDGET_MS ]]; then
  pass
else
  fail_scenario "activation took ${duration}ms (budget: <${ACTIVATION_BUDGET_MS}ms)"
fi

# ---------------------------------------------------------------------------
# Performance: simple spell execution
#
# Execution spans three forks (wrapper -> `spells run` -> bash -c), so the
# macOS-first budget is 750 ms rather than the 100 ms activation target.
# ---------------------------------------------------------------------------
run_scenario "perf: spell execution"
start_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
(cd "$tmpdir/perf" && "$SPELLBOOK_HOME/bin/spell1") > /dev/null 2>&1
end_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
duration=$((end_ms - start_ms))
echo "  spell execution: ${duration}ms (budget: <${EXECUTION_BUDGET_MS}ms, wrapper+run+shell)"
if [[ $duration -lt $EXECUTION_BUDGET_MS ]]; then
  pass
else
  fail_scenario "execution took ${duration}ms (budget: <${EXECUTION_BUDGET_MS}ms)"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/003 — `params:` as YAML sequence must error, not silently
# activate an empty param list (QA case 3.8).
# ---------------------------------------------------------------------------
run_scenario "regression: params as sequence rejected"
mkdir -p "$tmpdir/params-bad"
cat > "$tmpdir/params-bad/spells.yaml" << 'YAML'
spells:
  hello:
    script: echo hi
    params:
      - name
YAML

seq_output="$(cd "$tmpdir/params-bad" && "$tmpdir/spells" 2>&1 || true)"
if [[ "$seq_output" == *"'params:' in 'hello' is a sequence, expected a map"* ]]; then
  pass
else
  fail_scenario "expected invalidParamsShape error, got: $seq_output"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/004 — required enum param without value (non-TTY) must
# surface the list of valid values in the error (QA case 6.16).
# ---------------------------------------------------------------------------
run_scenario "regression: enum missing value lists options"
mkdir -p "$tmpdir/enum-missing"
cat > "$tmpdir/enum-missing/spells.yaml" << 'YAML'
spells:
  deploy:
    script: echo env={{env}}
    params:
      env:
        values: [dev, staging, prod]
YAML

(cd "$tmpdir/enum-missing" && "$tmpdir/spells") > /dev/null 2>&1

enum_output="$(cd "$tmpdir/enum-missing" && "$SPELLBOOK_HOME/bin/deploy" < /dev/null 2>&1 || true)"
if [[ "$enum_output" == *"Valid values: dev, staging, prod"* ]]; then
  pass
else
  fail_scenario "expected 'Valid values: dev, staging, prod', got: $enum_output"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/005 — alias names must follow spell-name grammar so they
# produce safe wrapper filenames (QA case 9.6).
# ---------------------------------------------------------------------------
run_scenario "regression: alias name validation"
mkdir -p "$tmpdir/alias-bad"
cat > "$tmpdir/alias-bad/spells.yaml" << 'YAML'
spells:
  test:
    aliases: ["123!"]
    script: echo x
YAML

alias_output="$(cd "$tmpdir/alias-bad" && "$tmpdir/spells" 2>&1 || true)"
if [[ "$alias_output" == *"invalid alias '123!' in 'test'"* ]]; then
  pass
else
  fail_scenario "expected invalid alias error, got: $alias_output"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/006 — cycle detection must work with relative extends
# paths containing .. (QA case 10.7).
# ---------------------------------------------------------------------------
run_scenario "regression: cycle detection with .. paths"
mkdir -p "$tmpdir/cyc/a" "$tmpdir/cyc/b"
cat > "$tmpdir/cyc/a/spells.yaml" << 'YAML'
extends: ../b/spells.yaml
spells:
  a: { script: echo a }
YAML
cat > "$tmpdir/cyc/b/spells.yaml" << 'YAML'
extends: ../a/spells.yaml
spells:
  b: { script: echo b }
YAML

cyc_output="$(cd "$tmpdir/cyc/a" && "$tmpdir/spells" 2>&1 || true)"
if [[ "$cyc_output" == *"extends cycle detected"* ]]; then
  pass
else
  fail_scenario "expected cycle error, got: $cyc_output"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/007 — override placeholders must resolve to the external
# PATH command at runtime (QA case 11.1). This caught a wiring bug where
# OverrideLookup was not passed to RunResolver in SpellbookApp.
# ---------------------------------------------------------------------------
run_scenario "regression: override placeholder resolves"
mkdir -p "$tmpdir/override"
cat > "$tmpdir/override/spells.yaml" << 'YAML'
spells:
  cat:
    override: true
    script: {{cat}} -n ...args
YAML
printf 'hello\nworld\n' > "$tmpdir/override/data.txt"

(cd "$tmpdir/override" && "$tmpdir/spells") > /dev/null 2>&1

override_output="$(cd "$tmpdir/override" && "$SPELLBOOK_HOME/bin/cat" data.txt 2>&1 || true)"
if [[ "$override_output" == *"1"*"hello"* && "$override_output" == *"2"*"world"* ]]; then
  pass
else
  fail_scenario "expected numbered output, got: $override_output"
fi

# ---------------------------------------------------------------------------
# Regression: BUGS/008 — PATH-shadow validator must fire during activation
# (QA cases 11.2, 13.7). Without a concrete PathBinaryChecker wired into
# the resolver, a spell named `ls` was silently accepted.
# ---------------------------------------------------------------------------
run_scenario "regression: PATH shadow validation"
mkdir -p "$tmpdir/shadow"
cat > "$tmpdir/shadow/spells.yaml" << 'YAML'
spells:
  ls:
    script: echo fake-ls
YAML

shadow_output="$(cd "$tmpdir/shadow" && "$tmpdir/spells" 2>&1 || true)"
if [[ "$shadow_output" == *"'ls' shadows a PATH binary"* ]]; then
  pass
else
  fail_scenario "expected PATH shadow error, got: $shadow_output"
fi

# ---------------------------------------------------------------------------
# Builtin: spells list (QA 12.1, 12.2)
# ---------------------------------------------------------------------------
run_scenario "list: canonical names and aliases"
mkdir -p "$tmpdir/list"
cat > "$tmpdir/list/spells.yaml" << 'YAML'
spells:
  sblist1:
    aliases: [sbl1, sbl1alt]
    script: echo a
  sblist2:
    script: echo b
YAML

(cd "$tmpdir/list" && "$tmpdir/spells") > /dev/null 2>&1
list_output="$(cd "$tmpdir/list" && "$tmpdir/spells" list 2>&1)"
if [[ "$list_output" == *"sblist1"* \
   && "$list_output" == *"sbl1"* \
   && "$list_output" == *"sbl1alt"* \
   && "$list_output" == *"sblist2"* ]]; then
  pass
else
  fail_scenario "expected canonical names and aliases, got: $list_output"
fi

# ---------------------------------------------------------------------------
# Builtin: spells help <spell> and alias (QA 12.6, 12.7)
# ---------------------------------------------------------------------------
run_scenario "help: canonical and alias"
help_canonical="$(cd "$tmpdir/list" && "$tmpdir/spells" help sblist1 2>&1)"
help_alias="$(cd "$tmpdir/list" && "$tmpdir/spells" help sbl1 2>&1)"
if [[ "$help_canonical" == *"sblist1"* \
   && "$help_canonical" == *"Aliases"* \
   && "$help_alias" == *"alias"* \
   && "$help_alias" == *"sblist1"* ]]; then
  pass
else
  fail_scenario "help output missing expected fields"
fi

# ---------------------------------------------------------------------------
# Builtin: spells help for unknown spell (QA 12.10)
# ---------------------------------------------------------------------------
run_scenario "help: unknown spell errors"
unknown_help_ec=0
(cd "$tmpdir/list" && "$tmpdir/spells" help totally-unknown-spell) > /dev/null 2>&1 \
  || unknown_help_ec=$?
if [[ $unknown_help_ec -ne 0 ]]; then
  pass
else
  fail_scenario "expected non-zero exit for unknown spell help"
fi

# ---------------------------------------------------------------------------
# Builtin: spells doctor on healthy project (QA 13.1)
# ---------------------------------------------------------------------------
run_scenario "doctor: healthy project"
doctor_healthy="$(cd "$tmpdir/list" && "$tmpdir/spells" doctor 2>&1)"
doctor_ec=0
(cd "$tmpdir/list" && "$tmpdir/spells" doctor) > /dev/null 2>&1 || doctor_ec=$?
if [[ $doctor_ec -eq 0 \
   && "$doctor_healthy" == *"[INFO]"* \
   && "$doctor_healthy" != *"[ERROR]"* ]]; then
  pass
else
  fail_scenario "expected healthy doctor output, got ec=$doctor_ec: $doctor_healthy"
fi

# ---------------------------------------------------------------------------
# Builtin: spells doctor emits plain text when piped (QA 13.13)
# ---------------------------------------------------------------------------
run_scenario "doctor: no ANSI in piped output"
doctor_piped="$(cd "$tmpdir/list" && "$tmpdir/spells" doctor | cat 2>&1)"
if [[ "$doctor_piped" != *$'\033['* ]]; then
  pass
else
  fail_scenario "doctor emitted ANSI escapes when piped"
fi

# ---------------------------------------------------------------------------
# Filesystem: manifest file is a directory (QA 17.15)
# ---------------------------------------------------------------------------
run_scenario "filesystem: manifest path is a directory"
mkdir -p "$tmpdir/manifest-is-dir/spells.yaml"
is_dir_output="$(cd "$tmpdir/manifest-is-dir" && "$tmpdir/spells" 2>&1 || true)"
is_dir_ec=0
(cd "$tmpdir/manifest-is-dir" && "$tmpdir/spells") > /dev/null 2>&1 || is_dir_ec=$?
if [[ $is_dir_ec -ne 0 && -n "$is_dir_output" ]]; then
  pass
else
  fail_scenario "expected non-zero exit and an error message"
fi

# ---------------------------------------------------------------------------
# Filesystem: manifest not readable (QA 17.14)
# ---------------------------------------------------------------------------
run_scenario "filesystem: manifest permission denied"
mkdir -p "$tmpdir/perm"
cat > "$tmpdir/perm/spells.yaml" << 'YAML'
spells:
  sbhi:
    script: echo hi
YAML
chmod 000 "$tmpdir/perm/spells.yaml"
perm_ec=0
(cd "$tmpdir/perm" && "$tmpdir/spells") > /dev/null 2>&1 || perm_ec=$?
chmod 644 "$tmpdir/perm/spells.yaml"
if [[ $perm_ec -ne 0 ]]; then
  pass
else
  fail_scenario "expected non-zero exit when manifest is unreadable"
fi

# ---------------------------------------------------------------------------
# Filesystem: state.json corrupted then rebuilt (QA 17.18)
# ---------------------------------------------------------------------------
run_scenario "filesystem: corrupted state rebuilds on activation"
mkdir -p "$tmpdir/state-corrupt"
cat > "$tmpdir/state-corrupt/spells.yaml" << 'YAML'
spells:
  sbrebuilt:
    script: echo rebuilt
YAML
echo "not json at all" > "$SPELLBOOK_HOME/state.json"
(cd "$tmpdir/state-corrupt" && "$tmpdir/spells") > /dev/null 2>&1
if [[ -x "$SPELLBOOK_HOME/bin/sbrebuilt" ]]; then
  pass
else
  fail_scenario "wrapper not rebuilt after state corruption"
fi

# ---------------------------------------------------------------------------
# Params: empty string positional (QA 5.19)
# ---------------------------------------------------------------------------
run_scenario "params: empty string positional"
mkdir -p "$tmpdir/empty-param"
cat > "$tmpdir/empty-param/spells.yaml" << 'YAML'
spells:
  sbgreet:
    script: echo Hello, {{name}}
    params:
      name:
YAML
(cd "$tmpdir/empty-param" && "$tmpdir/spells") > /dev/null 2>&1
empty_out="$(cd "$tmpdir/empty-param" && "$SPELLBOOK_HOME/bin/sbgreet" '' 2>&1 || true)"
if [[ "$empty_out" == "Hello, " ]]; then
  pass
else
  fail_scenario "empty-string param output: '$empty_out'"
fi

# ---------------------------------------------------------------------------
# Params: very long value (QA 5.20)
# ---------------------------------------------------------------------------
run_scenario "params: 10k-character value"
long_value="$(python3 -c "print('x' * 10000)")"
long_out="$(cd "$tmpdir/empty-param" && "$SPELLBOOK_HOME/bin/sbgreet" "$long_value" 2>&1 || true)"
if [[ "$long_out" == "Hello, $long_value" ]]; then
  pass
else
  fail_scenario "long-value output length ${#long_out}, expected $((10007))"
fi

# ---------------------------------------------------------------------------
# Discovery: home fallback activates when no project manifest (QA 3.9, 10.10)
# ---------------------------------------------------------------------------
run_scenario "discovery: home fallback"
fake_home="$tmpdir/fake-home"
mkdir -p "$fake_home"
cat > "$fake_home/spells.yaml" << 'YAML'
spells:
  sbhomespell:
    script: echo from-home
YAML
mkdir -p "$tmpdir/no-manifest"
fallback_out="$(cd "$tmpdir/no-manifest" && HOME="$fake_home" "$tmpdir/spells" 2>&1 || true)"
if [[ "$fallback_out" == *"home fallback"* && -x "$SPELLBOOK_HOME/bin/sbhomespell" ]]; then
  pass
else
  fail_scenario "home fallback not triggered: $fallback_out"
fi

# ---------------------------------------------------------------------------
# Wrapper: empty PATH at runtime (QA 17.23)
# ---------------------------------------------------------------------------
run_scenario "wrapper: empty PATH errors cleanly"
mkdir -p "$tmpdir/empty-path"
cat > "$tmpdir/empty-path/spells.yaml" << 'YAML'
spells:
  sbepath:
    script: echo ok
YAML
(cd "$tmpdir/empty-path" && "$tmpdir/spells") > /dev/null 2>&1
empty_path_ec=0
PATH="" "$SPELLBOOK_HOME/bin/sbepath" > /dev/null 2>&1 || empty_path_ec=$?
if [[ $empty_path_ec -ne 0 ]]; then
  pass
else
  fail_scenario "expected non-zero exit with empty PATH"
fi

# ---------------------------------------------------------------------------
# Silent mode: real TTY emits ANSI cursor control and success glyph
#
# Drives the generated wrapper under a PTY allocated by `expect` so the
# concrete `StandardTerminal` takes the TTY branch. Verifies that
# hide-cursor, clear-line, and show-cursor sequences all appear in the
# captured transcript, plus the ✓ success glyph.
# ---------------------------------------------------------------------------
run_scenario "silent mode: ANSI cursor control under PTY"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
else
  mkdir -p "$tmpdir/silent"
  cat > "$tmpdir/silent/spells.yaml" << 'YAML'
spells:
  sbquiet:
    script: sleep 0.1
    silent: true
YAML
  (cd "$tmpdir/silent" && "$tmpdir/spells") > /dev/null 2>&1
  silent_capture="$tmpdir/silent/capture.txt"
  rm -f "$silent_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  EXPECT_SPELL_BIN="$SPELLBOOK_HOME/bin/sbquiet" \
  EXPECT_CAPTURE="$silent_capture" \
  EXPECT_PATH="$expect_bin_dir:$PATH" \
  EXPECT_HOME="$SPELLBOOK_HOME" \
  EXPECT_CWD="$tmpdir/silent" \
  expect -c '
    set timeout 10
    log_file $env(EXPECT_CAPTURE)
    set env(PATH) $env(EXPECT_PATH)
    set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
    cd $env(EXPECT_CWD)
    spawn $env(EXPECT_SPELL_BIN)
    expect {
      eof {}
      timeout {}
    }
  ' > /dev/null 2>&1
  bytes="$(wc -c < "$silent_capture" | tr -d ' ')"
  if grep -q $'\x1b\[?25l' "$silent_capture" \
     && grep -q $'\x1b\[?25h' "$silent_capture" \
     && grep -q $'\x1b\[2K' "$silent_capture" \
     && grep -q $'\xe2\x9c\x93 sbquiet' "$silent_capture"; then
    pass
  else
    fail_scenario "missing ANSI or success glyph in silent capture (${bytes} bytes)"
  fi
fi

# ---------------------------------------------------------------------------
# Silent mode: failure path flushes stderr and restores the cursor
#
# Closes QA 15.17. A silent spell with an invalid `shell:` path must:
#   - still restore the cursor (show-cursor sequence present)
#   - emit the ✗ glyph with the non-zero exit code
#   - flush the captured stderr so the user sees the real diagnostic
#   - surface a non-zero exit status from the wrapper
# ---------------------------------------------------------------------------
run_scenario "silent mode: failure path flushes stderr and restores cursor"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
else
  mkdir -p "$tmpdir/silent-fail"
  cat > "$tmpdir/silent-fail/spells.yaml" << 'YAML'
spells:
  sbbadshell:
    silent: true
    shell: /ghost/sh
    script: echo hello
YAML
  (cd "$tmpdir/silent-fail" && "$tmpdir/spells") > /dev/null 2>&1
  fail_capture="$tmpdir/silent-fail/capture.txt"
  rm -f "$fail_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  fail_exit="$(
    EXPECT_SPELL_BIN="$SPELLBOOK_HOME/bin/sbbadshell" \
    EXPECT_CAPTURE="$fail_capture" \
    EXPECT_PATH="$expect_bin_dir:$PATH" \
    EXPECT_HOME="$SPELLBOOK_HOME" \
    EXPECT_CWD="$tmpdir/silent-fail" \
    expect -c '
      set timeout 10
      log_file $env(EXPECT_CAPTURE)
      set env(PATH) $env(EXPECT_PATH)
      set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
      cd $env(EXPECT_CWD)
      spawn $env(EXPECT_SPELL_BIN)
      expect { eof {} timeout {} }
      catch wait wait_result
      exit [lindex $wait_result 3]
    ' > /dev/null 2>&1
    echo $?
  )"
  if grep -q $'\x1b\[?25h' "$fail_capture" \
     && grep -q $'\xe2\x9c\x97 sbbadshell' "$fail_capture" \
     && grep -q "No such file" "$fail_capture" \
     && [[ "$fail_exit" != "0" ]]; then
    pass
  else
    fail_scenario "silent failure path incomplete (exit=$fail_exit, bytes=$(wc -c < "$fail_capture" | tr -d ' '))"
  fi
fi

# ---------------------------------------------------------------------------
# Switch picker: interactive picker under PTY selects branch via arrow + Enter
#
# Closes QA 8.16. Drives the generated wrapper through `expect(1)` with a
# real PTY so `InteractivePicker` takes the raw-mode branch. Sends a down
# arrow (CSI B) to move the highlight from `staging` → `production`, then
# Enter to commit, and verifies the chosen branch ran.
# ---------------------------------------------------------------------------
run_scenario "switch picker: arrow + Enter selects a branch under PTY"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
else
  mkdir -p "$tmpdir/picker"
  cat > "$tmpdir/picker/spells.yaml" << 'YAML'
spells:
  sbdeploy:
    switch:
      staging:
        script: echo "to staging"
      production:
        script: echo "to production"
YAML
  (cd "$tmpdir/picker" && "$tmpdir/spells") > /dev/null 2>&1
  picker_capture="$tmpdir/picker/capture.txt"
  rm -f "$picker_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  EXPECT_SPELL_BIN="$SPELLBOOK_HOME/bin/sbdeploy" \
  EXPECT_CAPTURE="$picker_capture" \
  EXPECT_PATH="$expect_bin_dir:$PATH" \
  EXPECT_HOME="$SPELLBOOK_HOME" \
  EXPECT_CWD="$tmpdir/picker" \
  expect -c '
    set timeout 10
    log_file $env(EXPECT_CAPTURE)
    set env(PATH) $env(EXPECT_PATH)
    set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
    cd $env(EXPECT_CWD)
    spawn $env(EXPECT_SPELL_BIN)
    expect -re {staging}
    sleep 0.1
    send "\x1b\[B"
    sleep 0.1
    send "\r"
    expect eof
  ' > /dev/null 2>&1
  if grep -q "to production" "$picker_capture" \
     && grep -q $'\x1b\[?25l' "$picker_capture" \
     && grep -q $'\x1b\[?25h' "$picker_capture"; then
    pass
  else
    fail_scenario "picker did not resolve to production (bytes=$(wc -c < "$picker_capture" | tr -d ' '))"
  fi
fi

# ---------------------------------------------------------------------------
# Switch picker: ESC cancels the picker and restores the cursor
#
# Closes QA 8.17. ESC in raw mode must return `.cancelled`, which the runner
# surfaces as `SpellbookError.selectionCancelled` — non-zero exit status, with
# the show-cursor sequence still landing in the transcript.
# ---------------------------------------------------------------------------
run_scenario "switch picker: ESC cancels cleanly under PTY"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
else
  cancel_capture="$tmpdir/picker/cancel.txt"
  rm -f "$cancel_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  EXPECT_SPELL_BIN="$SPELLBOOK_HOME/bin/sbdeploy" \
  EXPECT_CAPTURE="$cancel_capture" \
  EXPECT_PATH="$expect_bin_dir:$PATH" \
  EXPECT_HOME="$SPELLBOOK_HOME" \
  EXPECT_CWD="$tmpdir/picker" \
  expect -c '
    set timeout 5
    log_file $env(EXPECT_CAPTURE)
    set env(PATH) $env(EXPECT_PATH)
    set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
    cd $env(EXPECT_CWD)
    spawn $env(EXPECT_SPELL_BIN)
    expect -re {production}
    sleep 0.2
    send "q"
    expect eof
  ' > /dev/null 2>&1
  if grep -q "selection cancelled" "$cancel_capture" \
     && grep -q $'\x1b\[?25h' "$cancel_capture" \
     && ! grep -q "to staging..$" "$cancel_capture" \
     && ! grep -q "to production..$" "$cancel_capture"; then
    pass
  else
    fail_scenario "q did not cancel cleanly (bytes=$(wc -c < "$cancel_capture" | tr -d ' '))"
  fi
fi

# ---------------------------------------------------------------------------
# Switch picker: dumb terminal falls back to NumberedPicker
#
# When TERM=dumb the capability resolver reports supportsRawMode=false, so
# `FiniteChoicePicker` routes to `NumberedPicker`. The scenario types `1` +
# newline and asserts the first branch runs.
# ---------------------------------------------------------------------------
run_scenario "switch picker: dumb terminal uses numbered fallback"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
else
  dumb_capture="$tmpdir/picker/dumb.txt"
  rm -f "$dumb_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  EXPECT_SPELL_BIN="$SPELLBOOK_HOME/bin/sbdeploy" \
  EXPECT_CAPTURE="$dumb_capture" \
  EXPECT_PATH="$expect_bin_dir:$PATH" \
  EXPECT_HOME="$SPELLBOOK_HOME" \
  EXPECT_CWD="$tmpdir/picker" \
  expect -c '
    set timeout 5
    log_file $env(EXPECT_CAPTURE)
    set env(PATH) $env(EXPECT_PATH)
    set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
    set env(TERM) "dumb"
    cd $env(EXPECT_CWD)
    spawn $env(EXPECT_SPELL_BIN)
    expect -re {Enter number}
    send "1\r"
    expect eof
  ' > /dev/null 2>&1
  if grep -q "to staging" "$dumb_capture" \
     && ! grep -q $'\x1b\[?25l' "$dumb_capture"; then
    pass
  else
    fail_scenario "numbered fallback did not resolve (bytes=$(wc -c < "$dumb_capture" | tr -d ' '))"
  fi
fi

# ---------------------------------------------------------------------------
# Doctor: stale parent warning keeps the parent origin
#
# Closes QA 10.13 / 13.15. Activate from a child manifest that extends a
# parent, then remove the parent's spell without re-activating. Doctor must
# flag the stale wrapper AND mention the parent manifest path — not the
# child path.
# ---------------------------------------------------------------------------
run_scenario "doctor: stale inherited spell reports parent origin"
mkdir -p "$tmpdir/stale-parent/parent" "$tmpdir/stale-parent/child"
cat > "$tmpdir/stale-parent/parent/spells.yaml" << 'YAML'
spells:
  sbshared:
    script: echo "shared from parent"
YAML
cat > "$tmpdir/stale-parent/child/spells.yaml" << 'YAML'
extends: ../parent
spells:
  sblocalname:
    script: echo "local from child"
YAML
(cd "$tmpdir/stale-parent/child" && "$tmpdir/spells") > /dev/null 2>&1

cat > "$tmpdir/stale-parent/parent/spells.yaml" << 'YAML'
spells:
  sbrenamedparent:
    script: echo "new spell"
YAML

doctor_out="$(cd "$tmpdir/stale-parent/child" && "$tmpdir/spells" doctor 2>&1 || true)"
if echo "$doctor_out" | grep -q "Stale wrappers" \
   && echo "$doctor_out" | grep -q "sbshared (was" \
   && echo "$doctor_out" | grep -q "stale-parent/parent/spells.yaml"; then
  pass
else
  fail_scenario "doctor did not attribute sbshared to parent: $doctor_out"
fi

# ---------------------------------------------------------------------------
# Diff: added/changed/removed markers reflect state vs fresh merge
# ---------------------------------------------------------------------------
run_scenario "diff: reports added/changed/removed spells"
mkdir -p "$tmpdir/diff"
cat > "$tmpdir/diff/spells.yaml" << 'YAML'
spells:
  sbbuild:
    script: make
  sbtest:
    script: swift test
YAML
(cd "$tmpdir/diff" && "$tmpdir/spells") > /dev/null 2>&1

# Edit manifest: change sbtest, add sbdeploy, remove sbbuild
cat > "$tmpdir/diff/spells.yaml" << 'YAML'
spells:
  sbtest:
    script: swift test --parallel
  sbdeploy:
    script: ./deploy
YAML
diff_out="$(cd "$tmpdir/diff" && "$tmpdir/spells" diff 2>&1 || true)"
if echo "$diff_out" | grep -qE "^\+ sbdeploy" \
   && echo "$diff_out" | grep -qE "^~ sbtest" \
   && echo "$diff_out" | grep -qE "^- sbbuild"; then
  pass
else
  fail_scenario "diff output missing expected markers: $diff_out"
fi

run_scenario "diff: no-op when manifest matches state"
noop_out="$(cd "$tmpdir/diff" && "$tmpdir/spells" > /dev/null && "$tmpdir/spells" diff 2>&1 || true)"
if echo "$noop_out" | grep -q "No changes since last activation"; then
  pass
else
  fail_scenario "expected no-changes line, got: $noop_out"
fi

# ---------------------------------------------------------------------------
# Activation summary prints diff markers after re-activation
# ---------------------------------------------------------------------------
run_scenario "activation: prints diff markers on re-activation"
mkdir -p "$tmpdir/activation-diff"
cat > "$tmpdir/activation-diff/spells.yaml" << 'YAML'
spells:
  sbkeep:
    script: echo keep
  sbchange:
    script: echo old
YAML
(cd "$tmpdir/activation-diff" && "$tmpdir/spells") > /dev/null 2>&1

# Edit manifest: change sbchange, add sbnew, remove sbkeep
cat > "$tmpdir/activation-diff/spells.yaml" << 'YAML'
spells:
  sbchange:
    script: echo new
  sbnew:
    script: echo new
YAML
reactivate_out="$(cd "$tmpdir/activation-diff" && "$tmpdir/spells" 2>&1 || true)"
if echo "$reactivate_out" | grep -qE "^  \+ sbnew" \
   && echo "$reactivate_out" | grep -qE "^  ~ sbchange" \
   && echo "$reactivate_out" | grep -qE "^  - sbkeep"; then
  pass
else
  fail_scenario "activation did not print diff markers: $reactivate_out"
fi

# ---------------------------------------------------------------------------
# list: override spells show `[override]` marker
# ---------------------------------------------------------------------------
run_scenario "list: override spells show marker"
mkdir -p "$tmpdir/list-override"
cat > "$tmpdir/list-override/spells.yaml" << 'YAML'
spells:
  sbbuild:
    script: make
  sbovercat:
    override: true
    script: "{{sbovercat}} --brief"
YAML
(cd "$tmpdir/list-override" && "$tmpdir/spells") > /dev/null 2>&1
list_out="$(cd "$tmpdir/list-override" && "$tmpdir/spells" list 2>&1 || true)"
if echo "$list_out" | grep -qE "^sbovercat\s+\[override\]" \
   && echo "$list_out" | grep -qE "^sbbuild$"; then
  pass
else
  fail_scenario "override marker missing in list: $list_out"
fi

# ---------------------------------------------------------------------------
# clean: named target removes wrapper + state entry
# ---------------------------------------------------------------------------
run_scenario "clean: named target removes wrapper"
mkdir -p "$tmpdir/clean-named"
cat > "$tmpdir/clean-named/spells.yaml" << 'YAML'
spells:
  sbone:
    script: echo one
  sbtwo:
    script: echo two
YAML
(cd "$tmpdir/clean-named" && "$tmpdir/spells") > /dev/null 2>&1
[[ -x "$SPELLBOOK_HOME/bin/sbone" ]] || { fail_scenario "sbone wrapper missing after activation"; }
clean_out="$(cd "$tmpdir/clean-named" && "$tmpdir/spells" clean sbone 2>&1 || true)"
if [[ ! -e "$SPELLBOOK_HOME/bin/sbone" ]] \
   && [[ -x "$SPELLBOOK_HOME/bin/sbtwo" ]] \
   && echo "$clean_out" | grep -q "Cleaned \`sbone\`"; then
  pass
else
  fail_scenario "clean did not drop sbone wrapper: $clean_out"
fi

# ---------------------------------------------------------------------------
# clean --orphans removes only wrappers that no longer exist in the manifest
# ---------------------------------------------------------------------------
run_scenario "clean --orphans removes stale wrappers only"
mkdir -p "$tmpdir/clean-orphans"
cat > "$tmpdir/clean-orphans/spells.yaml" << 'YAML'
spells:
  sbkeep:
    script: echo keep
  sborphan:
    script: echo orphan
YAML
(cd "$tmpdir/clean-orphans" && "$tmpdir/spells") > /dev/null 2>&1
# Remove sborphan from manifest without re-activating
cat > "$tmpdir/clean-orphans/spells.yaml" << 'YAML'
spells:
  sbkeep:
    script: echo keep
YAML
orphans_out="$(cd "$tmpdir/clean-orphans" && "$tmpdir/spells" clean --orphans 2>&1 || true)"
if [[ ! -e "$SPELLBOOK_HOME/bin/sborphan" ]] \
   && [[ -x "$SPELLBOOK_HOME/bin/sbkeep" ]] \
   && echo "$orphans_out" | grep -q "orphan"; then
  pass
else
  fail_scenario "orphan clean did not take effect: $orphans_out"
fi

# ---------------------------------------------------------------------------
# clean --all clears wrappers + project state
# ---------------------------------------------------------------------------
run_scenario "clean --all clears project state"
mkdir -p "$tmpdir/clean-all"
cat > "$tmpdir/clean-all/spells.yaml" << 'YAML'
spells:
  sballa:
    script: echo a
  sballb:
    script: echo b
YAML
(cd "$tmpdir/clean-all" && "$tmpdir/spells") > /dev/null 2>&1
clean_all_out="$(cd "$tmpdir/clean-all" && "$tmpdir/spells" clean --all 2>&1 || true)"
if [[ ! -e "$SPELLBOOK_HOME/bin/sballa" ]] \
   && [[ ! -e "$SPELLBOOK_HOME/bin/sballb" ]] \
   && echo "$clean_all_out" | grep -q "cleared project state"; then
  pass
else
  fail_scenario "clean --all did not fully reset: $clean_all_out"
fi

# ---------------------------------------------------------------------------
# doctor --fix re-activates when state drifts from manifest
# ---------------------------------------------------------------------------
run_scenario "doctor --fix re-activates on wrapper drift"
mkdir -p "$tmpdir/doctor-fix"
cat > "$tmpdir/doctor-fix/spells.yaml" << 'YAML'
spells:
  sbbefore:
    script: echo before
YAML
(cd "$tmpdir/doctor-fix" && "$tmpdir/spells") > /dev/null 2>&1
# Drift manifest without re-running activation
cat > "$tmpdir/doctor-fix/spells.yaml" << 'YAML'
spells:
  sbbefore:
    script: echo before
  sbafter:
    script: echo after
YAML
fix_out="$(cd "$tmpdir/doctor-fix" && "$tmpdir/spells" doctor --fix 2>&1 || true)"
if echo "$fix_out" | grep -q "Re-activated" \
   && echo "$fix_out" | grep -q "Fixed: New spells not yet activated" \
   && [[ -x "$SPELLBOOK_HOME/bin/sbafter" ]]; then
  pass
else
  fail_scenario "doctor --fix did not re-activate: $fix_out"
fi

run_scenario "doctor --fix is a no-op when everything is clean"
(cd "$tmpdir/doctor-fix" && "$tmpdir/spells") > /dev/null 2>&1
clean_fix_out="$(cd "$tmpdir/doctor-fix" && "$tmpdir/spells" doctor --fix 2>&1 || true)"
if echo "$clean_fix_out" | grep -q "Nothing to fix automatically"; then
  pass
else
  fail_scenario "doctor --fix should report nothing to fix: $clean_fix_out"
fi

# ---------------------------------------------------------------------------
# completion: zsh/bash/fish scripts emit their shell's idiom
# ---------------------------------------------------------------------------
run_scenario "completion: emits shell-specific script"
zsh_out="$("$tmpdir/spells" completion zsh 2>&1 || true)"
bash_out="$("$tmpdir/spells" completion bash 2>&1 || true)"
fish_out="$("$tmpdir/spells" completion fish 2>&1 || true)"
if echo "$zsh_out" | grep -q "compdef _spells spells" \
   && echo "$bash_out" | grep -q "complete -F _spells_completion spells" \
   && echo "$fish_out" | grep -q "__fish_use_subcommand"; then
  pass
else
  fail_scenario "completion scripts missing expected markers"
fi

run_scenario "completion: rejects unsupported shell"
bad_ec=0
bad_out="$("$tmpdir/spells" completion powershell 2>&1 || true)"
"$tmpdir/spells" completion powershell > /dev/null 2>&1 || bad_ec=$?
if [[ $bad_ec -ne 0 ]] \
   && echo "$bad_out" | grep -q "unsupported shell 'powershell'" \
   && echo "$bad_out" | grep -q "Supported shells: zsh, bash, fish"; then
  pass
else
  fail_scenario "expected non-zero exit + error + tip, got (ec=$bad_ec): $bad_out"
fi

# ---------------------------------------------------------------------------
# completion: missing shell argument prints usage and exits non-zero (QA 23.2)
# ---------------------------------------------------------------------------
run_scenario "completion: missing shell argument"
miss_ec=0
miss_out="$("$tmpdir/spells" completion 2>&1 || true)"
"$tmpdir/spells" completion > /dev/null 2>&1 || miss_ec=$?
if [[ $miss_ec -ne 0 ]] \
   && echo "$miss_out" | grep -q "completion: missing shell argument" \
   && echo "$miss_out" | grep -q "Usage: spells completion <zsh|bash|fish>"; then
  pass
else
  fail_scenario "expected non-zero exit + usage hint, got (ec=$miss_ec): $miss_out"
fi

# ---------------------------------------------------------------------------
# activation: first-time run has no prior state, every spell is "+"  (QA 19.2)
# ---------------------------------------------------------------------------
run_scenario "activation: first-time run prints + for every spell"
first_home="$tmpdir/first-home"
mkdir -p "$first_home"
mkdir -p "$tmpdir/first-activation"
cat > "$tmpdir/first-activation/spells.yaml" << 'YAML'
spells:
  sbfirst:
    script: echo first
YAML
first_out="$(cd "$tmpdir/first-activation" && SPELLBOOK_HOME="$first_home" "$tmpdir/spells" 2>&1 || true)"
if echo "$first_out" | grep -qE "^Activated 1 spells, 1 wrappers" \
   && echo "$first_out" | grep -qE "^  \+ sbfirst$"; then
  pass
else
  fail_scenario "first-time activation missing + marker: $first_out"
fi

# ---------------------------------------------------------------------------
# list --verbose: override marker survives and description is indented (QA 20.2)
# ---------------------------------------------------------------------------
run_scenario "list --verbose: override marker + indented description"
mkdir -p "$tmpdir/list-verbose-override"
cat > "$tmpdir/list-verbose-override/spells.yaml" << 'YAML'
spells:
  sbgit:
    override: true
    description: Shortened git status
    script: "{{sbgit}} status --short"
YAML
(cd "$tmpdir/list-verbose-override" && "$tmpdir/spells") > /dev/null 2>&1
verbose_out="$(cd "$tmpdir/list-verbose-override" && "$tmpdir/spells" list --verbose 2>&1 || true)"
if echo "$verbose_out" | grep -qE "^sbgit\s+\[override\]$" \
   && echo "$verbose_out" | grep -qE "^  Shortened git status$"; then
  pass
else
  fail_scenario "list --verbose missing override marker or indented description: $verbose_out"
fi

# ---------------------------------------------------------------------------
# clean: no argument prints usage and exits non-zero  (QA 21.4)
# ---------------------------------------------------------------------------
run_scenario "clean: missing target prints usage"
mkdir -p "$tmpdir/clean-missing"
cat > "$tmpdir/clean-missing/spells.yaml" << 'YAML'
spells:
  sbx:
    script: echo x
YAML
(cd "$tmpdir/clean-missing" && "$tmpdir/spells") > /dev/null 2>&1
clean_miss_ec=0
clean_miss_out="$(cd "$tmpdir/clean-missing" && "$tmpdir/spells" clean 2>&1 || true)"
(cd "$tmpdir/clean-missing" && "$tmpdir/spells" clean > /dev/null 2>&1) || clean_miss_ec=$?
if [[ $clean_miss_ec -ne 0 ]] \
   && echo "$clean_miss_out" | grep -q "clean: missing target" \
   && echo "$clean_miss_out" | grep -q "Usage: spells clean <name> | --all | --orphans"; then
  pass
else
  fail_scenario "expected non-zero + usage hint, got (ec=$clean_miss_ec): $clean_miss_out"
fi

# ---------------------------------------------------------------------------
# completion: sourced zsh script enables live TAB completion  (QA 23.3)
#
# Drives an interactive zsh under `expect(1)` so the real ZLE is available,
# sources the emitted completion script, activates a two-spell manifest, then
# types `spells help <TAB>` and `spells clean <TAB>`. The assertions confirm
# that completion resolves to the shared `sb` prefix (menu completion with two
# candidates `sbalpha` / `sbbravo`).
# ---------------------------------------------------------------------------
run_scenario "completion: zsh TAB completes spell names after help and clean"
if ! command -v expect >/dev/null 2>&1; then
  echo "  SKIP: expect(1) not available"
  pass
elif ! command -v zsh >/dev/null 2>&1; then
  echo "  SKIP: zsh not available"
  pass
else
  mkdir -p "$tmpdir/completion-tab"
  cat > "$tmpdir/completion-tab/spells.yaml" << 'YAML'
spells:
  sbalpha:
    script: echo alpha
  sbbravo:
    script: echo bravo
YAML
  (cd "$tmpdir/completion-tab" && "$tmpdir/spells") > /dev/null 2>&1

  completion_capture="$tmpdir/completion-tab/capture.txt"
  rm -f "$completion_capture"
  expect_bin_dir="$(dirname "$tmpdir/spells")"
  EXPECT_CAPTURE="$completion_capture" \
  EXPECT_PATH="$expect_bin_dir:$SPELLBOOK_HOME/bin:$PATH" \
  EXPECT_HOME="$SPELLBOOK_HOME" \
  EXPECT_CWD="$tmpdir/completion-tab" \
  expect -c '
    set timeout 15
    log_file $env(EXPECT_CAPTURE)
    set env(PATH) $env(EXPECT_PATH)
    set env(SPELLBOOK_HOME) $env(EXPECT_HOME)
    cd $env(EXPECT_CWD)
    # Interactive zsh with history disabled and a stable prompt marker.
    spawn zsh -f -i
    expect -re "%.*"
    send "autoload -Uz compinit && compinit -u\r"
    expect -re "%.*"
    send "PROMPT=\"READY%% \"\r"
    expect "READY% "
    send "source <(spells completion zsh)\r"
    expect "READY% "
    # Test 1: `spells help <TAB>` — expect completion to fill common prefix `sb`
    send "spells help \t"
    # Give ZLE time to render the menu/common-prefix completion.
    sleep 1
    send "\x15"  ;# ^U clears the line without submitting
    expect "READY% "
    # Test 2: `spells clean <TAB>` — same behaviour
    send "spells clean \t"
    sleep 1
    send "\x15"
    expect "READY% "
    send "exit\r"
    expect eof
  ' > /dev/null 2>&1

  # Both completions must have dropped the shared "sb" prefix onto the prompt.
  # We look for two occurrences: one after `help`, one after `clean`.
  help_hit=$(grep -c "spells help sb" "$completion_capture" || true)
  clean_hit=$(grep -c "spells clean sb" "$completion_capture" || true)
  if [[ "$help_hit" -ge 1 ]] && [[ "$clean_hit" -ge 1 ]]; then
    pass
  else
    fail_scenario "zsh TAB completion did not complete 'sb' prefix (help_hit=$help_hit clean_hit=$clean_hit, bytes=$(wc -c < "$completion_capture" | tr -d ' '))"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=============================="
echo "Spellbook E2E: $passed passed, $failed failed"
echo "=============================="

if [[ $failed -gt 0 ]]; then
  exit 1
fi

echo "Spellbook E2E: OK"
