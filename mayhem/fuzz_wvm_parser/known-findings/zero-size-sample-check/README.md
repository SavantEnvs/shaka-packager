# WVM output of an empty sample aborts in `MediaSample::data_size`

`WvmMediaParser::Output` (`wvm_media_parser.cc:979`) calls `data_size()` on a sample whose data is empty, which is
the end-of-stream marker, so `CHECK(!end_of_stream())` (`media_sample.h:127`) fails and the process aborts.

Reproduce: `/mayhem/fuzz_wvm_parser-standalone reproducer.bin`. Fix: skip an empty PES payload before touching
the sample.
