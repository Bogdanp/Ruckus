# Ruckus

Racket for iOS.

## Build

### Requirements

* [Racket 9.1 CS](https://racket-lang.org/)
* [Noise](https://github.com/Bogdanp/Noise)
* macOS Sequoia
* Xcode 26+

### First-time Setup

    $ raco pkg install --name ruckus-core/
    $ tuist install

### Building

    $ make
    $ tuist generate
    $ tuist xcodebuild build

## License

    Copyright 2026 CLEARTYPE SRL.  All rights reserved.
