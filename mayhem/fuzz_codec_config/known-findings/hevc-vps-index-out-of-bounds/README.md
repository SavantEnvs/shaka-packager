# HEVC VPS multiview extension indexes arrays with unchecked bitstream values

Selector byte 1 sends the payload to `HEVCDecoderConfigurationRecord::Parse`, whose `ParseInternal` calls
`H265Parser::ParseVps` (`h265_parser.cc:1062`). The VPS multiview-extension code does
`vps->layer_id_in_vps[layer_id_in_nuh[i]] = i` with a `layer_id_in_nuh` value read from the bitstream and never
range-checked against the 64-entry array (UBSan: `index -1094795586 out of bounds for type 'int[64]'`); an
out-of-bounds write follows for a large positive value.

Reproduce: `/mayhem/fuzz_codec_config-standalone reproducer.bin`. Fix: reject `layer_id_in_nuh[i]` outside
`[0, 63]` with `kInvalidStream`.
