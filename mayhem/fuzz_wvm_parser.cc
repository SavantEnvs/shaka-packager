#include "mayhem/parser_harness.h"

#include <packager/media/formats/wvm/wvm_media_parser.h>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  return mayhem::RunParser<shaka::media::wvm::WvmMediaParser>(data, size);
}
