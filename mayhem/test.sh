#!/usr/bin/env bash
#
# mayhem/test.sh: RUN the parser unit tests and the known-answer probes that mayhem/build.sh built in
# build/tests (normal flags). Never compiles. exit 0 iff everything passed.
#   1. gtest suites for the MP4, WebM, MPEG-2 TS, WVM, WebVTT and codec parsers: each must print its
#      "[  PASSED  ] N tests." line with N equal to the number it ran, and no failures.
#   2. kat_probe demuxes real files from packager/media/test/data through the real parsers and its
#      output (codec strings, sizes, sample counts, byte totals) is compared with exact expected values.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
SRC="${SRC:-/mayhem}"
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

T=build/tests/packager/media
for exe in "$T/formats/mp4/mp4_unittest" "$T/formats/webm/webm_unittest" "$T/formats/mp2t/mp2t_unittest" \
           "$T/formats/wvm/wvm_unittest" "$T/formats/webvtt/webvtt_unittest" "$T/codecs/media_codecs_unittest" \
           build/tests/kat_probe; do
  [ -x "$exe" ] || { echo "missing $exe: mayhem/build.sh did not build it" >&2; exit 1; }
done

passed=0 failed=0

for exe in "$T/formats/mp4/mp4_unittest" "$T/formats/webm/webm_unittest" "$T/formats/mp2t/mp2t_unittest" \
           "$T/formats/wvm/wvm_unittest" "$T/formats/webvtt/webvtt_unittest" "$T/codecs/media_codecs_unittest"; do
  out="$("$exe" 2>&1)"; rc=$?
  ran="$(sed -n 's/^\[==========\] \([0-9]*\) tests\{0,1\} from .* ran\..*/\1/p' <<<"$out" | tail -1)"
  ok="$(sed -n 's/^\[  PASSED  \] \([0-9]*\) tests\{0,1\}\./\1/p' <<<"$out" | tail -1)"
  if [ "$rc" -eq 0 ] && [ -n "$ran" ] && [ "${ran:-0}" -gt 0 ] && [ "$ran" = "${ok:-x}" ] && ! grep -q '^\[  FAILED  \]' <<<"$out"; then
    echo "PASS $(basename "$exe"): $ok tests"
    passed=$(( passed + ok ))
  else
    echo "FAIL $(basename "$exe"): rc=$rc ran=${ran:-?} passed=${ok:-?}"
    grep -a '^\[  FAILED  \]' <<<"$out" | head -20
    failed=$(( failed + 1 ))
  fi
done

D=packager/media/test/data
probe() { # <name> <container> <file> <expected stdout, one line per \n>
  local got
  got="$(build/tests/kat_probe "$2" "$D/$3" 2>/dev/null | grep -E '^(stream|track|text)')"
  if [ "$got" = "$4" ]; then
    echo "PASS probe $1"; passed=$(( passed + 1 ))
  else
    echo "FAIL probe $1"; echo "--- expected"; echo "$4"; echo "--- got"; echo "$got"
    failed=$(( failed + 1 ))
  fi
}

probe mp4-avc-aac mp4 bear-640x360.mp4 'stream video codec=avc1.64001e 640x360 timescale=30000
stream audio codec=mp4a.40.2 rate=44100 channels=2 timescale=44100
track 1 samples=82 bytes=299498 keyframes=3 last_dts=79079
track 2 samples=119 bytes=42083 keyframes=119 last_dts=119808'

probe mp4-hevc-aac mp4 bear-640x360-hevc.mp4 'stream video codec=hev1.1.6.L63.90 640x360 timescale=30000
stream audio codec=mp4a.40.2 rate=44100 channels=2 timescale=44100
track 1 samples=84 bytes=87280 keyframes=3 last_dts=81081
track 2 samples=121 bytes=44953 keyframes=121 last_dts=122880'

probe mp4-av1 mp4 bear-av1.mp4 'stream video codec=av01.0.00M.08 320x240 timescale=30000
track 1 samples=82 bytes=23108 keyframes=1 last_dts=81081'

probe webm-vp8-vorbis webm bear-320x240.webm 'stream audio codec=vorbis rate=44100 channels=2 timescale=1000000
stream video codec=vp08.00.10.08.01.02.02.02.00 320x240 timescale=1000000
track 1 samples=82 bytes=194325 keyframes=7 last_dts=2703000
track 2 samples=166 bytes=18624 keyframes=166 last_dts=2744000'

probe ts-avc-aac ts bear-640x360.ts 'stream video codec=avc1.64001e 640x360 timescale=90000
stream audio codec=mp4a.40.2 rate=44100 channels=2 timescale=90000
track 256 samples=82 bytes=299498 keyframes=3 last_dts=243243
track 257 samples=119 bytes=42083 keyframes=119 last_dts=250512'

probe ts-avc-ac3 ts bear-640x360-ac3.ts 'stream video codec=avc1.64001e 640x360 timescale=90000
stream audio codec=ac-3 rate=44100 channels=2 timescale=90000
track 256 samples=82 bytes=299498 keyframes=3 last_dts=243243
track 257 samples=80 bytes=66872 keyframes=80 last_dts=251034'

probe wvm-avc-aac wvm bear-640x360.wvm 'stream video codec=avc1.64001e 640x360 timescale=90000
stream audio codec=mp4a.40.2 rate=44100 channels=2 timescale=90000
stream video codec=avc1.64001e 640x360 timescale=90000
stream audio codec=mp4a.40.2 rate=44100 channels=2 timescale=90000
track 0 samples=413 bytes=876502 keyframes=15 last_dts=1254000
track 1 samples=592 bytes=212443 keyframes=591 last_dts=1257000
track 2 samples=413 bytes=1387409 keyframes=15 last_dts=1254000
track 3 samples=592 bytes=212921 keyframes=591 last_dts=1257000'

probe webvtt vtt bear-english.vtt 'stream other codec=wvtt
text samples=2'

emit_ctrf "shaka-packager-parsers" "$passed" "$failed"
