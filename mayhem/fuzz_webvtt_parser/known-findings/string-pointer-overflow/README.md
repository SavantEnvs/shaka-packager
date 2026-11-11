# WebVTT region settings: ParsePercent indexes an empty string at size()-1

`ParsePercent` (`webvtt_parser.cc:94`), reached from `WebVttParser::ParseRegion`, tests `str[str.size() - 1]`. For a
region setting with an empty value (`width:` with nothing after the colon) that is index `-1` of an empty string
(UBSan pointer-overflow in `basic_string.h:1250`, "addition of unsigned offset ... overflowed").

Reproduce: `/mayhem/fuzz_webvtt_parser-standalone reproducer.bin`. Fix: return false when `str.empty()`.
