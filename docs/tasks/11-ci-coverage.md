# Set Up and Run Code Coverage in CI

## Summary

The CI workflow runs tests but does not collect or report code coverage.
Adding coverage reporting would provide visibility into how well the test
suite exercises the codebase and help catch regressions in test quality.

## Affected Code

### `.github/workflows/ci.yml:218-226`

```yaml
    - name: Test
      run: |
        xcodebuild test -workspace Ruckus.xcworkspace -scheme Ruckus \
          -destination 'platform=iOS Simulator,name=iPhone 17 Pro' | xcpretty
```

The test step pipes through `xcpretty` and does not enable coverage
collection or produce any coverage artifacts.

## Impact

Without coverage data there is no way to track whether new code is tested
or whether test coverage is trending down over time.

## Suggested Fix

1. **Enable coverage in the xcodebuild invocation.** Add
   `-enableCodeCoverage YES` to the test command and capture the result
   bundle:

   ```yaml
   - name: Test
     run: |
       xcodebuild test -workspace Ruckus.xcworkspace -scheme Ruckus \
         -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
         -enableCodeCoverage YES \
         -resultBundlePath TestResults.xcresult | xcpretty
   ```

2. **Extract an lcov report.** Use `xcrun xcresulttool` or `xcrun
   llvm-cov` to convert the `.xcresult` bundle into an lcov file that
   standard tools can consume:

   ```yaml
   - name: Generate coverage report
     run: |
       xcrun xcresulttool export \
         --path TestResults.xcresult \
         --type cobertura \
         --output-path coverage.xml
   ```

   Alternatively, use a community action like
   `nicklockwood/xcode-build-tools` or `maxep/spm-lcov-action` to
   simplify the conversion.

3. **Upload the coverage artifact.** At minimum, upload the report as a
   build artifact so it can be inspected:

   ```yaml
   - uses: actions/upload-artifact@v7
     with:
       name: coverage
       path: coverage.xml
   ```

   Optionally, integrate with a coverage service (Codecov, Coveralls,
   etc.) for trend tracking and PR annotations.

## Related

- None.
