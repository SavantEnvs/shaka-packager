# `AC4Parser::ParseAc4Toc` allocates arrays of a bitstream-chosen length (3 of the 15 run-1 defects)

`ac4_parser.cc:126` does `new Ac4PresentationV1Info[ac4_toc.n_presentations]` and `:133`
`new Ac4SubstreamGroupInfo[total_n_substream_groups]`, both counts read from the bitstream with no bound
(`total_n_substream_groups` comes from `max_group_index`, which the presentation parser also reads from the
stream). These are real unbounded allocations, not leak noise: the request is gigabytes of `new[]` for a payload of a few
dozen bytes, and ASan reports `allocation-size-too-big`, not a leak.

- `presentations-line-126.bin`, `substream-groups-line-133.bin`.

Reproduce: `ASAN_OPTIONS=max_allocation_size_mb=1024 /mayhem/fuzz_codec_config-standalone <file>.bin` (selector
byte 10 routes to `AC4Parser::Parse`). Fix: cap both counts at the ranges the AC-4 spec allows.
