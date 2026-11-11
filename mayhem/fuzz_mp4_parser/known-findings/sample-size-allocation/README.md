# MP4 sample size of 2^31 or more becomes a negative `int`, passes the buffer check and sizes a huge `new[]`

`TrackRunIterator::sample_size()` returns the `stsz`/`trun` size as an `int`. In `MP4MediaParser::EnqueueSample` a
size of 2^31 or more is negative, so the "do we have the bytes yet" test `buf_size < runs_->sample_size()`
(`mp4_media_parser.cc:1012`) is false, and `const size_t media_data_size = runs_->sample_size()` (`:1022`) then
sign-extends it to about 2^64 (ASan reports a request of `0xffffffff89000011`). `MediaSample::SetData`
(`media_sample.cc:118`) does `new uint8_t[data_size]` with it. Distinct from the box-count findings: the cause is
the signed type of a payload length, not an entry count.

Reproduce: `ASAN_OPTIONS=max_allocation_size_mb=1024 /mayhem/fuzz_mp4_parser-standalone reproducer.bin`.
Fix: keep the sample size unsigned, or reject a negative size before the buffer test.
