# AAC `AudioSpecificConfig` keeps an out-of-range value in an enum

The escape path of the object-type field stores `static_cast<AudioObjectType>(32 + audioObjectTypeExt)`
(`aac_audio_specific_config.cc:220`) with an extension read from the stream, so `audio_object_type_` can hold a
value that is not an enumerator. The next load of it (`:82`, `audio_object_type_ == AOT_SBR`) is undefined
behaviour and UBSan's enum check halts: `load of value 88, which is not a valid value for type 'AudioObjectType'`.
It is the "Misinterpretation of Input" defect in the run-1 list.

Reproduce: `/mayhem/fuzz_codec_config-standalone reproducer.bin` (selector byte 6). Fix: keep the object type in an
integer, or validate the extension before the cast.
