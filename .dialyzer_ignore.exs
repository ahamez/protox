# TestAllRequiredTypesProto2 (test/support/messages.ex) contains recursively
# required fields, so its encoding provably never returns; dialyzer rejects
# the generated specs of such degenerate messages now that the encoding path
# is rescue-free enough for it to prove non-termination. The warnings don't
# carry the module name, hence the file-plus-warning-type granularity.
[
  {"test/support/messages.ex", :invalid_contract},
  {"test/support/messages.ex", :no_return},
  {"test/support/messages.ex", :unused_fun}
]
