# WVM index entry builds a `BitReader` over an empty descriptor and aborts

`ParseIndexEntry` hands a descriptor with no bytes to `BaseDescriptor::Parse`, whose `BitReader` constructor has
`CHECK(data_ != NULL && bytes_left_ > 0)` (`bit_reader.cc:21`), so an index entry whose descriptor is empty
aborts the process. Same class as the other assertion aborts (`../zero-size-sample-check/`): an internal invariant
reachable from the stream.

Reproduce: `/mayhem/fuzz_wvm_parser-standalone reproducer.bin`. Fix: skip an empty descriptor before parsing it.
