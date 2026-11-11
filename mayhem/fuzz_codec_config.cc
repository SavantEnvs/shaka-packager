// Codec configuration records and audio descriptors as found in MP4 sample entries; the first byte
// picks the parser and the rest is its payload.
#include <cstddef>
#include <cstdint>
#include <vector>

#include <packager/media/codecs/aac_audio_specific_config.h>
#include <packager/media/codecs/ac4_parser.h>
#include <packager/media/codecs/av1_codec_configuration_record.h>
#include <packager/media/codecs/avc_decoder_configuration_record.h>
#include <packager/media/codecs/dovi_decoder_configuration_record.h>
#include <packager/media/codecs/dts_audio_specific_config.h>
#include <packager/media/codecs/ec3_audio_util.h>
#include <packager/media/codecs/es_descriptor.h>
#include <packager/media/codecs/hevc_decoder_configuration_record.h>
#include <packager/media/codecs/iamf_audio_util.h>
#include <packager/media/codecs/vp_codec_configuration_record.h>
#include <packager/media/base/fourccs.h>
#include <packager/media/base/stream_info.h>

using namespace shaka::media;

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  if (size < 2) return -1;
  const uint8_t which = data[0] % 12;
  const uint8_t* payload = data + 1;
  const size_t n = size - 1;
  const std::vector<uint8_t> vec(payload, payload + n);
  switch (which) {
    case 0: {
      AVCDecoderConfigurationRecord r;
      if (r.Parse(payload, n)) (void)r.GetCodecString(FOURCC_avc1);
      break;
    }
    case 1: {
      HEVCDecoderConfigurationRecord r;
      if (r.Parse(payload, n)) (void)r.GetCodecString(FOURCC_hvc1);
      break;
    }
    case 2: {
      AV1CodecConfigurationRecord r;
      if (r.Parse(payload, n)) (void)r.GetCodecString();
      break;
    }
    case 3: {
      VPCodecConfigurationRecord r;
      if (r.ParseMP4(vec)) (void)r.GetCodecString(kCodecVP9);
      break;
    }
    case 4: {
      VPCodecConfigurationRecord r;
      if (r.ParseWebM(vec)) (void)r.GetCodecString(kCodecVP9);
      break;
    }
    case 5: {
      DOVIDecoderConfigurationRecord r;
      if (r.Parse(vec)) (void)r.GetCodecString(FOURCC_dvh1);
      break;
    }
    case 6: {
      AACAudioSpecificConfig r;
      if (r.Parse(vec)) {
        (void)r.GetSamplesPerSecond();
        (void)r.GetNumChannels();
      }
      break;
    }
    case 7: {
      ESDescriptor r;
      (void)r.Parse(vec);
      break;
    }
    case 8: {
      uint32_t v;
      (void)CalculateEC3ChannelMap(vec, &v);
      (void)GetEc3NumChannels(vec);
      (void)CalculateEC3ChannelMPEGValue(vec, &v);
      (void)GetEc3JocComplexity(vec, &v);
      break;
    }
    case 9: {
      uint8_t info;
      (void)GetIamfCodecStringInfo(vec, info);
      uint32_t mask;
      (void)GetDTSXChannelMask(vec, mask);
      break;
    }
    case 10: {
      AC4Parser r;
      (void)r.Parse(payload, n);
      break;
    }
    default: {
      HEVCDecoderConfigurationRecord r;
      (void)r.ParseLHEVCConfig(vec);
      break;
    }
  }
  return 0;
}
