# Fix CI coverage step — tests never run due to SwiftLint build phase failure

## Summary

The "Coverage summary" CI step fails because the `.xcresult` bundle has no
coverage data. The underlying cause is that **tests never execute** — the
SwiftLint build phase script fails during `xcodebuild test` because SwiftLint
is not installed in the `build-test` job, and `xcpretty` masks the nonzero exit
code so CI proceeds to the coverage step.

From the CI logs:

```
Testing failed:
  Command PhaseScriptExecution failed with a nonzero exit code
  Testing cancelled because the build failed.

** TEST FAILED **

The following build commands failed:
  PhaseScriptExecution SwiftLint …/Script-9377716972C7F4195B8915DD.sh
    (in target 'Ruckus' from project 'Ruckus')
```

## Affected Code

### `Project.swift:71-77`

The Ruckus target includes a SwiftLint pre-build script:

```swift
scripts: [
  .pre(
    script: "swiftlint lint --quiet",
    name: "SwiftLint",
    basedOnDependencyAnalysis: false
  )
],
```

### `.github/workflows/ci.yml:198-229`

The `build-test` job installs Tuist but not SwiftLint. The `lint` job installs
SwiftLint separately, but that doesn't help `build-test`:

```yaml
- name: Install Tuist
  run: brew install tuist
```

Additionally, the test step pipes through `xcpretty`, which swallows the
nonzero exit code from `xcodebuild`:

```yaml
- name: Test
  run: |
    xcodebuild test ... | xcpretty
```

## Impact

Tests never execute in CI. Coverage is never collected. The `| xcpretty` pipe
masks both failures, making it look like only the coverage step is broken.

## Suggested Fix

Two things need to be fixed:

**1. Install SwiftLint in `build-test`** (or make the script non-fatal):

```yaml
- name: Install SwiftLint
  run: brew install swiftlint
```

Alternatively, make the build phase script tolerate a missing `swiftlint` since
linting already runs in its own CI job:

```swift
.pre(
  script: "which swiftlint && swiftlint lint --quiet || true",
  name: "SwiftLint",
  basedOnDependencyAnalysis: false
)
```

**2. Fix xcpretty masking failures** by using `set -o pipefail`:

```yaml
- name: Test
  run: |
    set -o pipefail
    xcodebuild test -workspace Ruckus.xcworkspace -scheme Ruckus \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
      -resultBundlePath TestResults.xcresult | xcpretty
```

The `pipefail` fix is critical — without it, any xcodebuild failure (not just
SwiftLint) will be silently ignored.
