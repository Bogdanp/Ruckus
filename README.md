# Ruckus

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
    $ raco pkg install --name ruckus-core/
    $ tuist install
    $ ./bin/prepare-distribution

### Building

    $ make
    $ tuist generate
    $ tuist xcodebuild build

## License

Licensed under the 3-Clause BSD License. See [LICENSE](LICENSE) for details.
