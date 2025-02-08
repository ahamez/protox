# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- schema/0 to access the underlying definition of a message.

### Changed
- BREAKING CHANGE: Configuration of features to generate via the CLI mix task is done with the `--generate` argument.
- BREAKING CHANGE: encoding functions now return the size alongside iodata. Before that, one had to use :binary.list_to_bin/1 to flatten the iodata to then use byte_size, defeating the purpose of having an iodata.
- BREAKEING CHANGE: `Protox.decode!` and `Protox.decode`  no longer raise or return an error if a message with required fields don't have all said fields set. The rationale being that we should let the user decide if it's a problem or not.

### Removed
- Drop support for Elixir < 1.15.
- BREAKING CHANGE: Drop support of JSON encoding and decoding.
- BREAKING CHANGE: Remove :path option in favor of :paths.
- BREAKING CHANGE: Remove :keep_unknown_fields option.
  It added complexity to the generation logic while not providing any value as one can simply ignore those fields.
- BREAKING CHANGE: Remove generated `syntax/0` (functionality still available through schema/1).
- BREAKING CHANGE: Remove generated `file_options/0` (functionality still available through schema/1).
- BREAKING CHANGE: Remove generated `field_def/1` (functionality still available through schema/1).
- BREAKING CHANGE: Remove generated `defs/0` (functionality still available through schema/1).
- BREAKING CHANGE: Remove generated `required_fields/0` (functionality still available through schema/1).
- BREAKING CHANGE: Remove generated `encode/1` from strings for enums.
- BREAKING CHANGE: Remove `Protox.Encode.encode/1` and `Protox.Encode.encode!/1` (functionality is still available in generated modules and in `Protox`.).


## 1.7.8

### Fixed
- Fix warnings of unknown JSON modules when a JSON library is not installed


## 1.7.7

### Fixed
- Fix launch by removing :propcheck from extra applications


## 1.7.6

### Fixed
- Fix typespecs for JSON decoding (thanks to https://github.com/squirmy)


## 1.7.5

### Changed
- Use origin repository for propchek rather than a fork


## 1.7.4

### Fixed
- Fix handling of enum in snake case


## 1.7.3

### Added
- Raise DecodingError and EncodingError for invalid strings (thanks to https://github.com/g-andrade)


## 1.7.2

### Fixed
- Fix typespec of enum encode function (thanks to https://github.com/wingyplus)


## 1.7.1

### Fixed
- Fix decoding and encoding of proto3 optional fields

## 1.7.0

### Added
- Support FileOptions (which can be access with `Msg.file_options/0`)


## 1.6.10

### Changed
- Format of generated files


## 1.6.9

### Fixed
- Fix deprecation warnings in Elixir >= 1.14 about Bitwise (thanks to https://github.com/moogle19)


## 1.6.8

### Added
- Raise clearer error message if protoc is missing (thanks to https://github.com/josevalim)


## 1.6.7

### Changed
- New release to publish docs using the improved ex_doc 0.27


## 1.6.6

### Fixed
- Fix JSON conformance tests related to fractional part in Timestamp

### Added
- Option to not generate deprecated functions `defs/0` and `defs_by_name/0`

## 1.6.5

### Changed
- Elixir 1.9 is now the minimal supported version
- Relax constraint on Decimal version (thanks to https://github.com/ananthakumaran)


## 1.6.4

### Changed
- Renamed module Protox.Message into Protox.MergeMessage to reflect its real role

### Fixed
- Fix inconsistent behavior when encoding to JSON an enum with an unknown atom field (WARNING: Requires to regenerate code from .proto definitions)


## 1.6.3

### Fixed
- Fix typespec of message's json_decode! function


## 1.6.2

### Fixed
- Fix possible double compilation of Empty well-known type
- Fix dependency on protoc for generated code


## 1.6.1

### Fixed
- Fix compilation when protoc does not include well-known types


## 1.6.0

### Added
- Add support of JSON protobuf encoding and decoding (https://developers.google.com/protocol-buffers/docs/proto3##json), with support of well-known types (except for Any)

### Changed
- More accurate error reporting
- Internal refactoring to hopefully make things more explicit (based on a work initiated by https://github.com/sneako)

### Fixed
- Fix decoding of fixed32 and fixed64 values (detected using JSON conformance tests)

### Deprecated
- `Protox.Encode.encode/1` and `Protox.Encode.encode!/1`; use `Protox.encode/1` and `Protox.encode!/1` instead
-  Generated functions`defs/0` and `defs_by_name/0`


## 1.5.1

### Fixed
 Fix handling of multiple import paths (thanks to https://github.com/zolakeith)


## 1.5.0

### Added
- Allow multiple import paths (thanks to https://github.com/cheng81)


## 1.4.0

### Added
- Add support of proto3 optional fields (thanks to https://github.com/sneako)


## 1.3.2

### Changed
- Bump version to build doc using ex_doc 0.24


## 1.3.1

### Fixed
- Fix table of types mapping in documentation


## 1.3.0

### Added
- Allow namespaces through protox.generate (thanks to https://github.com/sdrew)

### Changed
- Expand output path when generating files
- More thorough testing of code generation


## 1.2.4

### Changed
- Format generated code

### Fixed
- Fix warning when compiling generated code (thanks to https://github.com/xinz)
- Fix warning about unused variable in generated code when encoding an empty protobuf message


## 1.2.3

### Changed
- Update documentation to better explain the package directive usage


## 1.2.2

### Added
- Enable listing of task protox.generate via mix help.


## 1.2.1

### Added
- `--keep-unknown-fields` option to configure support of unknown fields when generating files


## 1.2.0

### Added
- Add `:keep_unknown_fields` option to configure support of unknown fields


## 1.1.1

### Fixed
- Fix documentation links


## 1.1.0

### Added
- It's now possible to generate one file per protobuf message to speed up compilation (thanks to https://github.com/qgau)


## 1.0.0

### Changed
- Use Protox exceptions as errors codes


## 0.25.0

### Added
- Add mix task to generate files

### Changed
- Bump to Elixir 1.7 as minimal supported version


## 0.24.0

### Changed
- Usage of `@external_resource` is no longer necessary

## 0.23.1

### Fixed
- Fix parse of `[packed=false]` option (the serialization was correct, but not in compliance with Protobuf conformance checker recommandations)


## 0.23.0

### Changed
- BREAKING CHANGE: `encode/1` returns a tuple, use `encode!/1` to get the old behavior of `encode/1`
- +40% speedup & -30% memory consumption when decoding thanks to macros
- Raise RequiredFieldsError when encoding or decoding a Protobuf 2 message with unset required fields (that is, that have the value `nil`)
- Raise IllegalTagError when decoding a message with a tag set to `0`

### Fixed
- Fix missing encoding of unknown fields when a message hadn't any field


## 0.22.0

### Changed
- Constant time encoding of oneof fields


## 0.21.0

### Changed
- Move back to ahamez/protox
- Bump to Elixir 1.6 as minimal supported version

### Added
- Add benchmarks
- Add conformance tests to CI
- Add dialyzer to CI


## 0.20.0

### Fixed
- Pass all tests of protobuf 3.12 conformance suite tests
- Always serialize required fields (proto2)

### Added
- `defs_by_name/0` in generated modules for messages
- `syntax/0` in generated modules for messages
- `Protox.MergeMessage.merge/2` to merge two messages of the same type

### Changed
- BREAKING CHANGE: (proto2) use nil for unset fields
- BREAKING CHANGE: rename generated `get_required_fields/0` into `required_fields/0`
- BREAKING CHANGE: rename generated `get_unknown_fields/0` into `unknown_fields/0`
- BREAKING CHANGE: rename generated `get_unknown_fields_name/0` into `unknown_fields_name/0`


## 0.19.1

### Fixed
- Fix warning about duplicate keys (thanks to https://github.com/ananthakumaran)


## 0.19.0

### Changed
- CamelCase for all generated modules (fixes https://github.com/ahamez/protox/issues/3)


## 0.18.0

### Added
- Allow ability to construct file names at compile time (thanks to https://github.com/ananthakumaran)


## 0.17.0

### Added
- `:path` option to specify import path (thanks to https://github.com/mathsaey)


## 0.16.2

### Fixed
- Fix generation of typespecs for when there are more than one required field


## 0.16.1

### Changed
- Change base name for unknown fields from `__unknown_fields__` to `__uf__`

## 0.16.0

### Fixed
- Fix handling of +/-infinity and NaN when encoding/decoding floats

#### Changed
- Move `RandomInit` to tests


## 0.15.2

### Fixed
- Fix typespecs for enum constants accessors


## 0.15.1

### Fixed
- Fix typespecs for unknown and required fields accessors


## 0.15.0

#### Changed
- Use `0.0` as default value for floats and doubles

## 0.14.0

### Changed
- Development now takes place at https://github.com/EasyMile/protox
- Move conformance test escript to https://github.com/EasyMile/protox-conformance

### Removed
- Benchmarks escripts


## 0.13.0

### Added
- Typespecs for generated encoder
- Bring `varint` library into `protox`

### Fixed
- Fix decoding of booleans encoded with a varint which is not `0` or `1`


## 0.12.1

### Fixed
- Fix handling of unset members in map entries


## 0.12.0

#### Changed
- ~2x speed improvement when encoding


## 0.11.1

### Added
- It's now possible to clear unknown fields


## 0.11.0

### Added
- Encode unknown fields


## 0.10.0

### Changed
- Update deps (dialyxir, excoveralls, hackney)


## 0.9.0

### Added
- Keep unknown fields when decoding

## 0.8.0

### Changed
- Raise an error when decoding and when required fields are missing


## 0.7.1

### Fixed
- Fix encoding of varint to match C++ version
- Fix encoding of enums to match C++ version


## 0.7.0

### Added
- Read definitions from files or binaries
- Parse definitions with protoc
- Generate Elixir structs from parsed definition
- Can prepend namespaces
- Encode/decode protobuf messages
