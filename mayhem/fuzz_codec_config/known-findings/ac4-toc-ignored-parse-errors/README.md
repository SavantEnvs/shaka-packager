# `AC4Parser::ParseAc4Toc` ignores the result of its sub-parsers, then reads past the buffer (2 of the 15 run-1 defects)

`ParseAc4Toc` calls `ParseAc4PresentationV1Info` (`ac4_parser.cc:128`) and `ParseAc4SubstreamGroupInfo` (`:135`) and
discards their `bool` results, so after a failed `RCHECK` the parse carries on with half-filled structs.
These are real memory errors, confirmed by ASan, and the same cause gives the two shapes the run reported:

- `presentation-index-line-505.bin`: `GetPresentationIdx` returns an index with no matching presentation and
  `ac4_toc.presentation_v1_infos[pre_idx]` (`:505`) reads past the array (heap-buffer-overflow).
- `bit-reader-overread-heap.bin` / `bit-reader-overread-segv.bin`: `ReadAc4VariableBits` (`:52`) and
  `ParseBedDynObjAssignment` (`:732`) keep reading from an exhausted `BitReader`; `BitReader::UpdateCurrByte`
  (`bit_reader.cc:110`) then loads past the buffer.

Reproduce: `/mayhem/fuzz_codec_config-standalone <file>.bin`. Fix: `RCHECK` the sub-parser results and the
presentation index.
