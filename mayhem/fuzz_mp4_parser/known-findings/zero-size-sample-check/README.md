# MP4 sample of size 0 aborts in `MediaSample::set_duration`

`MP4MediaParser::EnqueueSample` (`mp4_media_parser.cc:1062`) calls `set_duration()` on a sample built from a
zero-length `stsz`/`trun` entry. A zero-size `MediaSample` is the end-of-stream marker, so
`CHECK(!end_of_stream())` (`media_sample.h:108`) fails and the process aborts on attacker-controlled input.

Reproduce: `/mayhem/fuzz_mp4_parser-standalone reproducer.bin`. Fix: reject a zero sample size (return false)
before calling `set_duration`.
