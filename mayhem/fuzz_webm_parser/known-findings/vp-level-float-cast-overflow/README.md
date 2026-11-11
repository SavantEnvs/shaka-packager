# WebM VP9 level computation converts an out-of-range double to uint64_t

`WebMTracksParser::OnListEnd` (`webm_tracks_parser.cc:246`) calls `VPCodecConfigurationRecord::SetVP9Level`, which
does `luma_sample_rate = luma_picture_size / sample_duration_seconds` into a `uint64_t`
(`vp_codec_configuration_record.cc:251`). A negative or tiny default-duration from the track entry makes the quotient
unrepresentable (UBSan: `-7.68e+13 is outside the range of representable values of type 'unsigned long'`).

Reproduce: `/mayhem/fuzz_webm_parser-standalone reproducer.bin`. Fix: treat a non-positive duration as
`kUnknownSampleDuration`, and clamp the quotient, before the conversion.
