#include "mayhem/parser_harness.h"

#include <packager/media/formats/mp2t/mp2t_media_parser.h>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  return mayhem::RunParser<shaka::media::mp2t::Mp2tMediaParser>(data, size);
}
