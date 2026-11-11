// Known-answer probe for mayhem/test.sh: demuxes one file with the real parsers and prints what they
// extracted (streams, sample counts, byte totals), so test.sh can compare against exact values.
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iterator>
#include <map>
#include <memory>
#include <vector>

#include <packager/media/base/audio_stream_info.h>
#include <packager/media/base/media_sample.h>
#include <packager/media/base/media_parser.h>
#include <packager/media/base/stream_info.h>
#include <packager/media/base/text_sample.h>
#include <packager/media/base/video_stream_info.h>
#include <packager/media/formats/mp2t/mp2t_media_parser.h>
#include <packager/media/formats/mp4/mp4_media_parser.h>
#include <packager/media/formats/webm/webm_media_parser.h>
#include <packager/media/formats/webvtt/webvtt_parser.h>
#include <packager/media/formats/wvm/wvm_media_parser.h>

using namespace shaka::media;

struct Totals {
  uint64_t samples = 0, bytes = 0, keys = 0;
  int64_t last_dts = 0;
};

static int Run(MediaParser& parser, const std::vector<uint8_t>& data) {
  std::map<uint32_t, Totals> totals;
  uint64_t text = 0;
  parser.Init(
      [](const std::vector<std::shared_ptr<StreamInfo>>& streams) {
        for (const auto& s : streams) {
          if (s->stream_type() == kStreamVideo) {
            const auto* v = static_cast<const VideoStreamInfo*>(s.get());
            printf("stream video codec=%s %ux%u timescale=%u\n",
                   s->codec_string().c_str(), v->width(), v->height(),
                   s->time_scale());
          } else if (s->stream_type() == kStreamAudio) {
            const auto* a = static_cast<const AudioStreamInfo*>(s.get());
            printf("stream audio codec=%s rate=%u channels=%u timescale=%u\n",
                   s->codec_string().c_str(), a->sampling_frequency(),
                   a->num_channels(), s->time_scale());
          } else {
            printf("stream other codec=%s\n", s->codec_string().c_str());
          }
        }
      },
      [&](uint32_t id, std::shared_ptr<MediaSample> s) {
        Totals& t = totals[id];
        t.samples++;
        t.bytes += s->data_size();
        t.keys += s->is_key_frame();
        t.last_dts = s->dts();
        return true;
      },
      [&](uint32_t, std::shared_ptr<TextSample>) {
        text++;
        return true;
      },
      nullptr);
  if (!parser.Parse(data.data(), static_cast<int>(data.size()))) {
    printf("parse failed\n");
    return 1;
  }
  if (!parser.Flush()) {
    printf("flush failed\n");
    return 1;
  }
  for (const auto& [id, t] : totals)
    printf("track %u samples=%llu bytes=%llu keyframes=%llu last_dts=%lld\n", id,
           (unsigned long long)t.samples, (unsigned long long)t.bytes,
           (unsigned long long)t.keys, (long long)t.last_dts);
  if (text) printf("text samples=%llu\n", (unsigned long long)text);
  return 0;
}

int main(int argc, char** argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: kat_probe mp4|webm|ts|wvm|vtt FILE\n");
    return 2;
  }
  std::ifstream in(argv[2], std::ios::binary);
  std::vector<uint8_t> data((std::istreambuf_iterator<char>(in)),
                            std::istreambuf_iterator<char>());
  if (data.empty()) return 2;
  if (!strcmp(argv[1], "mp4")) {
    mp4::MP4MediaParser p;
    return Run(p, data);
  } else if (!strcmp(argv[1], "webm")) {
    WebMMediaParser p;
    return Run(p, data);
  } else if (!strcmp(argv[1], "ts")) {
    mp2t::Mp2tMediaParser p;
    return Run(p, data);
  } else if (!strcmp(argv[1], "wvm")) {
    wvm::WvmMediaParser p;
    return Run(p, data);
  } else if (!strcmp(argv[1], "vtt")) {
    WebVttParser p;
    return Run(p, data);
  }
  return 2;
}
