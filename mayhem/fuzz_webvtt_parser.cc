#include "mayhem/parser_harness.h"

#include <packager/media/formats/webvtt/webvtt_parser.h>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  return mayhem::RunParser<shaka::media::WebVttParser>(data, size);
}
