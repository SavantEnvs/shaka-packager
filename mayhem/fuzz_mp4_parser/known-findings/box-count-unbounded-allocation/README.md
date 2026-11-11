# MP4 box counts size allocations without a bound (7 of the 9 run-1 defects, "Memory Allocation with Excessive Size Value")

Several box parsers read a 32-bit entry count from the box and `resize()` a vector to it before checking that the
box holds that many entries. A box of a few dozen bytes can ask for gigabytes. The first application frame in each
Mayhem defect is the `std::__new_allocator<T>::allocate` under the `resize`; the real site is one frame up. One root
cause, eight call sites (one reproducer each, named after the box):

| reproducer | site | vector |
|---|---|---|
| `stsc.bin` | `SampleToChunk::ReadWriteInternal`, `box_definitions.cc:801` | `chunk_info` (`ChunkInfo`) |
| `stsz.bin` | `SampleSize::ReadWriteInternal`, `box_definitions.cc:832` | `sizes` (`uint32_t`) |
| `stco.bin` | `ChunkOffset::ReadWriteInternal`, `box_definitions.cc:914` | `offsets` (`uint64_t`) |
| `dref.bin` | `DataReference::ReadWriteInternal`, `box_definitions.cc:2361` | `data_entry` (`DataEntryUrl`) |
| `trun.bin` | `TrackFragmentRun::ReadWriteInternal`, `box_definitions.cc:2776` | `sample_sizes` etc. |
| `trun-sample-info.bin` | `TrackRunIterator::Init`, `track_run_iterator.cc:445` | `tri.samples` (`SampleInfo`) |
| `senc.bin` | `SampleEncryption::ParseFromSampleEncryptionData`, `track_run_iterator.cc:374` | `SampleEncryptionEntry` |

The harness is not at fault: it feeds the whole input to `MP4MediaParser::Parse` once, like the packager does, and the
parser reaches these boxes through its own `BoxReader` child scan (`ParseMoof` for the `trun`/`senc` ones). The run kept going to the end (5,721 edges, ~9,000 execs/s over 300 s), so these inputs are a few of the
74 reported test cases, not a wall every input hits.

Reproduce: `ASAN_OPTIONS=max_allocation_size_mb=1024 /mayhem/fuzz_mp4_parser-standalone <file>.bin`. Without that
option the standalone binary tries the real multi-gigabyte allocation, which succeeds or is OOM-killed depending on
the host. Fix: `RCHECK(count <= reader->BytesLeft() / entry_size)` before each `resize`.
