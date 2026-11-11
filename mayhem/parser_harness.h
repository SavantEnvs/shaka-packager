// Shared driver for the MediaParser fuzz targets: feed the whole input in one Parse() call, then Flush().
#ifndef MAYHEM_PARSER_HARNESS_H_
#define MAYHEM_PARSER_HARNESS_H_

#include <cstddef>
#include <cstdint>
#include <limits>
#include <memory>
#include <vector>

#include <packager/media/base/media_parser.h>

namespace mayhem {

template <typename Parser>
int RunParser(const uint8_t* data, size_t size) {
  using shaka::media::MediaParser;
  if (size == 0 || size > static_cast<size_t>(std::numeric_limits<int>::max()))
    return -1;
  Parser parser;
  parser.Init(
      [](const std::vector<std::shared_ptr<shaka::media::StreamInfo>>&) {},
      [](uint32_t, std::shared_ptr<shaka::media::MediaSample>) { return true; },
      [](uint32_t, std::shared_ptr<shaka::media::TextSample>) { return true; },
      nullptr);
  if (!parser.Parse(data, static_cast<int>(size))) return 0;
  (void)parser.Flush();
  return 0;
}

}  // namespace mayhem

#endif  // MAYHEM_PARSER_HARNESS_H_
