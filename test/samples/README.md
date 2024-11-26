The files `proto2.proto`, `proto2_extension.proto` and `proto3.proto` are used
to generate `file_descriptor_set.bin`. This file is used by the Protox.Parse
test. The following command is used to generate this file:

```
protoc --include_imports -o ./file_descriptor_set.bin  ./proto2_extension.proto ./proto2.proto ./proto3.proto
```
