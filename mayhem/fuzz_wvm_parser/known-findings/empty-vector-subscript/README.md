# WVM `EsPayload` takes `&sample_data_[size - 0]` of an empty vector

`Parse` (`wvm_media_parser.cc:461`) resizes `sample_data_` by `num_bytes` and then does
`memcpy(&sample_data_[sample_data_.size() - num_bytes], ...)`. With `num_bytes == 0` on an empty vector that
subscript binds a reference to a null pointer, which UBSan reports (`reference binding to null pointer`). Harmless
in practice (a zero-length `memcpy`), but it is a defect UBSan halts on; it is the `std::vector::operator[]` defect
in the run-1 list.

Reproduce: `/mayhem/fuzz_wvm_parser-standalone reproducer.bin`. Fix: skip the copy when `num_bytes == 0`.
