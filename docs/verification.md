# Verification

Run `scripts/check.sh` for the required per-change checks, then use
`scripts/e2e.sh` for authorized release validation. Historical test counts and
latency measurements are not current verification evidence.

## Evidence to collect

- Record the tested commit, OS, architecture, Swift version and shell versions in
  the release task or release notes.
- Run the completion oracle against the public grammar, then exercise wrapper TAB
  completion in real zsh, bash and fish terminals. Unit tests do not establish
  interactive shell parity.
- Check activation, wrapper invocation, state-version refusal and concurrent
  activation through the compiled executable.
- Measure a 20-spell activation and a simple spell execution in release mode;
  compare with [the release budgets](quality-gates.md#release-time-performance-budgets).
- Confirm installation, checksum verification and shell integration against the
  exact release artifact when publication is authorized.

## Platform test runner

On Linux the test script builds the XCTest binary once and runs suites in separate
processes with a short timeout and one retry. This avoids an intermittent hang in
the combined XCTest run. macOS uses `swift test` directly. A retry is specific to
that runner failure mode and does not waive a failing test.

## Regression fixtures

The manifest-cache corrupt-tag test changes the trailing default-branch byte;
replacing every zero byte would corrupt unrelated payload fields. File-lock error
tests use a regular file where a parent directory is required, so failures must
propagate as a lock error. Diff output retains the manifest's origin path.

E2E fixtures cover sequence-form params, missing required enum values, alias-name
validation, relative inheritance cycles, external override lookup, PATH shadowing,
silent failure stderr/cursor restoration, picker cancellation, inherited origins,
orphan cleanup and live completion after `help` and `clean`. Keep assertions
against the real process: source comments are not evidence of these behaviors.
