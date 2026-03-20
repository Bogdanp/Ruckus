# Ruckus

[![CI](https://github.com/Bogdanp/Ruckus/actions/workflows/ci.yml/badge.svg)](https://github.com/Bogdanp/Ruckus/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Bogdanp/Ruckus/graph/badge.svg?token=LSSCXQP4O9)](https://codecov.io/gh/Bogdanp/Ruckus)

Racket for iOS. The frontend is mostly vibe coded.

## Build

### Requirements

* [Racket 9.1 CS](https://racket-lang.org/)
* [Noise](https://github.com/Bogdanp/Noise)
* macOS Sequoia
* Xcode 26+

### First-time Setup

    $ cp xcconfigs/Local.xcconfig.example xcconfigs/Local.xcconfig
    # Edit xcconfigs/Local.xcconfig with your Apple Development Team ID
    $ ./bin/pbraco pkg install --name ruckus-core/
    $ ./bin/pbraco pkg install --copy ruckus-openssl/
    $ tuist install
    $ ./bin/prepare-distribution

### Building

    $ make
    $ tuist generate
    $ tuist xcodebuild build

## License

Licensed under the 3-Clause BSD License. See [LICENSE](LICENSE) for details.
