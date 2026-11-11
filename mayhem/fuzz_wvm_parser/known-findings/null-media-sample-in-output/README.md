# WVM `Output()` dereferences `media_sample_` before any PES with a timestamp created it (5 of the 8 run-1 defects)

`media_sample_` starts as `NULL` (`wvm_media_parser.cc:120`) and is only created by `StartMediaSampleDemux`
(`:820`), which runs when a PES with a PTS (or the program end) is seen. `EsPayload` appends bytes to
`sample_data_` whatever came before, so a stream whose first payload arrives without such a PES makes
`DemuxNextPes` (`:807`) call `Output` with data queued and no sample: `media_sample_->SetData` (`:830`, `:841`) or
`media_sample_->data_size()` (`:979`) is a member call on null. The same cause, three lines, reached from `Parse`
(`:392`, `:479`):

- `output-830.bin`: encrypted-sample branch.
- `output-841.bin`: video (H.264 byte-stream) branch.
- `output-979.bin`: a non-video, non-encrypted sample, which skips `SetData` and reaches the `DCHECK_GT`.

UBSan reports `member call on null pointer of type 'MediaSample'`; without UBSan it is a plain null dereference.
The frames are library code reached through the normal `Parse` entry point.

Reproduce: `/mayhem/fuzz_wvm_parser-standalone <file>.bin`. Fix: return false from `Output` (or skip it) while
`media_sample_` is null.
