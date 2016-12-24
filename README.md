# Protox

[![Build Status](https://travis-ci.org/ahamez/protox.svg?branch=master)](https://travis-ci.org/ahamez/protox) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master)


**TODO: Add description**

# Implementation choices

* When decoding enum aliases, the last encountered constant will be used.
  For instance, in the following example, will always be used.
  ```
  enum EnumAllowingAlias {
    option allow_alias = true;
    FOO = 0;
    BAZ = 1;
    BAR = 1;
  }
  ```


# Conformance

This library has been tested using the conformance checker provided by Google. More details
at https://github.com/ahamez/protox_conformance.


# Credits

https://github.com/tomas-abrahamsson/gpb

https://github.com/bitwalker/exprotobuf
