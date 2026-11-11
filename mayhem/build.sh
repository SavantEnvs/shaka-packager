#!/usr/bin/env bash
#
# mayhem/build.sh: build the Shaka Packager fuzz harnesses and the test suite. Runs in /mayhem inside
# the commit image (mayhem/Dockerfile), offline, and is safe to re-run.
#
#   /mayhem/fuzz_<t>             libFuzzer harness (sanitized project + sanitized harness)
#   /mayhem/fuzz_<t>-standalone  the same harness behind $STANDALONE_FUZZ_MAIN (run-once reproducer)
#   /mayhem/build/tests/...      the unit-test executables and kat_probe, built with NORMAL flags
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SRC"

TARGETS="mp4_parser webm_parser mp2t_parser wvm_parser webvtt_parser codec_config"
# CMake targets whose closure holds every code path the harnesses call.
LIB_TARGETS="mp4 formats_webm mp2t wvm webvtt media_codecs"
TEST_TARGETS="mp4_unittest webm_unittest mp2t_unittest wvm_unittest webvtt_unittest media_codecs_unittest"

# 0) Upstream's third-party sources are git submodules; the Dockerfile pre-fetched them at the commits
#    the gitlinks name. Put them in place (re-runnable) and fail loudly if a pin has drifted.
for d in /opt/toolchains/deps/*/; do
  [ -f "$d/REV" ] || continue
  name="$(basename "$d")"; name="${name%-*}"
  dest="packager/third_party/$name/source"
  if want="$(git rev-parse "HEAD:$dest" 2>/dev/null)" && [ "$want" != "$(cat "$d/REV")" ]; then
    echo "build.sh: $name is pinned to $want upstream but the image has $(cat "$d/REV"); update mayhem/Dockerfile" >&2
    exit 1
  fi
  mkdir -p "$dest"
  cp -a "$d/src/." "$dest/"
done

# libs_of <build dir>: every static library CMake built, minus the test frameworks.
libs_of() {
  find "$1" -name '*.a' ! -name '*gtest*' ! -name '*gmock*' ! -name '*mock*' ! -name '*test_data*' | LC_ALL=C sort
}

INCLUDES="-I$SRC -I$SRC/include -I$SRC/build/fuzz \
 -I$SRC/packager/third_party/abseil-cpp/source \
 -I$SRC/packager/third_party/protobuf/source/src \
 -I$SRC/packager/third_party/libwebm/source \
 -I$SRC/packager/third_party/json/source/include \
 -I$SRC/packager/third_party/mbedtls/source/include"

# 1) Project with the fuzz flags. -fno-sanitize=shift-base: the H.26x bit reader and the TS PES parser
#    shift a negative int on every real stream (h26x_bit_reader.cc:76, ts_section_pes.cc:36), which
#    would halt every valid input; every other UBSan check stays on.
FUZZ_FLAGS="-O1 $SANITIZER_FLAGS -fno-sanitize=shift-base -fsanitize=fuzzer-no-link $DEBUG_FLAGS"
cmake -S . -B build/fuzz -G Ninja -DCMAKE_BUILD_TYPE=None \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$FUZZ_FLAGS" -DCMAKE_CXX_FLAGS="$FUZZ_FLAGS"
# shellcheck disable=SC2086
cmake --build build/fuzz -j"$MAYHEM_JOBS" --target $LIB_TARGETS

# 2) Harnesses, fuzzer + standalone.
mkdir -p build/h
$CXX $SANITIZER_FLAGS $DEBUG_FLAGS -c mayhem/lsan_off.cc -o build/h/lsan_off.o
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -x c -c "$STANDALONE_FUZZ_MAIN" -o build/h/standalone_main.o
mapfile -t FUZZ_LIBS < <(libs_of build/fuzz)
for t in $TARGETS; do
  # shellcheck disable=SC2086
  $CXX -std=gnu++17 -O1 $SANITIZER_FLAGS -fno-sanitize=shift-base -fsanitize=fuzzer-no-link $DEBUG_FLAGS \
    $INCLUDES -c "mayhem/fuzz_$t.cc" -o "build/h/fuzz_$t.o"
  $CXX $SANITIZER_FLAGS $DEBUG_FLAGS $LIB_FUZZING_ENGINE "build/h/fuzz_$t.o" build/h/lsan_off.o \
    -Wl,--start-group "${FUZZ_LIBS[@]}" -Wl,--end-group -o "/mayhem/fuzz_$t"
  $CXX $SANITIZER_FLAGS $DEBUG_FLAGS "build/h/fuzz_$t.o" build/h/lsan_off.o build/h/standalone_main.o \
    -Wl,--start-group "${FUZZ_LIBS[@]}" -Wl,--end-group -o "/mayhem/fuzz_$t-standalone"
done

# 3) Test suite with the project's normal flags, in its own tree (no sanitizers, no -gdwarf-3).
cmake -S . -B build/tests -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$COVERAGE_FLAGS" -DCMAKE_CXX_FLAGS="$COVERAGE_FLAGS"
# shellcheck disable=SC2086
cmake --build build/tests -j"$MAYHEM_JOBS" --target $TEST_TARGETS
mapfile -t TEST_LIBS < <(libs_of build/tests)
# shellcheck disable=SC2086
$CXX -std=gnu++17 -O1 $COVERAGE_FLAGS ${INCLUDES//build\/fuzz/build\/tests} mayhem/kat_probe.cc \
  -Wl,--start-group "${TEST_LIBS[@]}" -Wl,--end-group -o build/tests/kat_probe
