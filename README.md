# Protox

[![Build Status](https://travis-ci.org/ahamez/protox.svg?branch=master)](https://travis-ci.org/ahamez/protox) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master) [![Deps Status](https://beta.hexfaktor.org/badge/prod/github/ahamez/protox.svg)](https://beta.hexfaktor.org/github/ahamez/protox)


**TODO: Add description**


# Prerequisites

Protox uses Google's `protoc` to pase `.proto` files. It must be available in `$PATH`.
You can get it [here](https://github.com/google/protobuf).


# Unsupported features

* groups
* protobuf 3 JSON mapping
* rpc

Furthermore, all options other than `packed` and `default` are ignored.


# Implementation choices

* When decoding enum aliases, the last encountered constant will be used.
  For instance, in the following example, `:BAR` will always be used if the value `1` is read
  on the wire.
  ```
  enum E {
    option allow_alias = true;
    FOO = 0;
    BAZ = 1;
    BAR = 1;
  }
  ```

* When decoding, fields for which tags are unknown are discarded.

# Conformance

This library has been tested using the conformance checker provided by Google.
Note that only the protobuf part is tested: as protox doesn't support JSON
output, the corresponding tests are skipped.


## How to launch the conformance test

### Get conformance-test-runner

Follow the instructions here: https://github.com/google/protobuf/tree/master/conformance.


### Launch test

* `mix protox.conformance --runner=/path/to/conformance-test-runner`

A report will be generated in a file named `conformance_report.txt`.

If everything's fine, something like the following should be displayed:

```
CONFORMANCE TEST BEGIN ====================================

CONFORMANCE SUITE PASSED: 149 successes, 384 skipped, 0 expected failures, 0 unexpected failures.
```



# Credits

[gpb](https://github.com/tomas-abrahamsson/gpb)

[exprotobuf](https://github.com/bitwalker/exprotobuf)
