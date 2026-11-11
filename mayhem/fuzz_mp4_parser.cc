#include "mayhem/parser_harness.h"

#include <packager/media/formats/mp4/mp4_media_parser.h>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  return mayhem::RunParser<shaka::media::mp4::MP4MediaParser>(data, size);
}
