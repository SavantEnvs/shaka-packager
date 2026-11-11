# MP4 inputs that trip internal `CHECK`/`DCHECK` assertions

Three more aborts from run 1, all through Abseil's `FailWithoutStackTrace` (Mayhem folds them into one defect, the
"Improper Input Validation" one). Each is a library invariant that malformed input can violate; none is in the
harness.

- `track-run-sample-count.bin`: `DCHECK_EQ(num_samples, decoding_time.NumSamples())`, `track_run_iterator.cc:209`;
  `stsz` and `stts` disagree on the sample count.
- `byte-queue-pop.bin`: `CHECK(count <= used_)`, `byte_queue.cc:74`; the parser pops more bytes than it queued.
- `media-sample-null-data.bin`: `CHECK(data)`, `media_sample.cc:54`; a sample is built from a null pointer.

The zero-size sample abort is in `../zero-size-sample-check/`. Reproduce:
`/mayhem/fuzz_mp4_parser-standalone <file>.bin`.
