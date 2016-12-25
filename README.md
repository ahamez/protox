# Protox

[![Build Status](https://travis-ci.org/ahamez/protox.svg?branch=master)](https://travis-ci.org/ahamez/protox) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master)


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


# Conformance

This library has been tested using the conformance checker provided by Google. More details
at [protox_conformance](https://github.com/ahamez/protox_conformance).


# Credits

[gpb](https://github.com/tomas-abrahamsson/gpb)

[exprotobuf](https://github.com/bitwalker/exprotobuf)
