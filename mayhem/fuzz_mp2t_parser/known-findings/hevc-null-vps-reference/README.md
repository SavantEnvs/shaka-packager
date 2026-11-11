# HEVC slice parsing binds a reference to a null VPS

`hevc-multi-slice.ts` is upstream's own test stream (`packager/media/test/data/hevc-multi-slice.ts`). It carries no VPS
the slice parser can find, so `H265Parser::ParseSliceHeader` (`h265_parser.cc:440`) evaluates `*vps` on a null
pointer to pass `const H265Vps&` to `GetNumPicTotalCurr`. UBSan: `reference binding to null pointer of type
'const H265Vps'`, so the harness aborts on a valid file.

It is kept out of `testsuite/` for that reason. Reproduce: `/mayhem/fuzz_mp2t_parser-standalone hevc-multi-slice.ts`.
Fix: look the VPS up once and return an error (or skip the VPS-dependent part) when it is null.
