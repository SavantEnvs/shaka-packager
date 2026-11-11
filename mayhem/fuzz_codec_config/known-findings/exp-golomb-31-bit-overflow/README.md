# `H26xBitReader::ReadUE` overflows `int` for a 31-bit Exp-Golomb code (6 of the 15 run-1 defects)

`ReadUE` (`h26x_bit_reader.cc:133`) accepts `num_bits == 31` leading zeros and computes `(1 << 31) - 1`, which is
`INT_MIN - 1`: signed overflow, halted by UBSan. Every `ue(v)` / `se(v)` field in an H.264 SPS or scaling list and
an H.265 VPS goes through it, so one root cause fans out into six Mayhem defects with different callers:

- `avc-sps.bin`: `H264Parser::ParseSps` (selector 0, `AVCDecoderConfigurationRecord`).
- `avc-scaling-list.bin`: `ParseScalingList` -> `ReadSE`.
- `hevc-vps.bin`: `H265Parser::ParseVps` (selector 1).

Reproduce: `/mayhem/fuzz_codec_config-standalone <file>.bin`. Fix: bound `num_bits` at 30, or compute in `uint32_t`.
