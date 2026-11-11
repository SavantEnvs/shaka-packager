# `ExtractResolutionFromSps` multiplies unvalidated SPS fields in `int` (2 of the 15 run-1 defects)

`h264_parser.cc:73` (`crop_y = crop_unit_y * (crop_top + crop_bottom)`) and `:79` (`pic_width_in_mbs * 16`) multiply values
read with `ue(v)` and never range-checked, so a crafted SPS overflows `int`.
The cause is the same for both: the SPS parser accepts any `ue(v)` for the picture size and crop offsets.

- `height-line-73.bin`: `4 * 754453074` (crop height).
- `width-line-79.bin`: `595640336 * 16`.

Reproduce: `/mayhem/fuzz_codec_config-standalone <file>.bin`. Fix: validate the SPS fields against the level limits in
`ParseSps`, or widen the arithmetic to 64 bits.
