# MP4 child box header read runs past the end of the buffer

`BoxReader::ScanChildren` (`box_reader.cc:84`) builds a child `BoxReader` over `&data()[pos()]` and `ReadHeader`
(`box_reader.cc:125`) reads its first 32-bit size with `BufferReader::ReadNBytes` (`buffer_reader.cc:109`).
ASan reports a heap-buffer-overflow (and a SEGV for other inputs) there, so the window handed to the child
extends past the bytes the parent owns.

Reproduce: `/mayhem/fuzz_mp4_parser-standalone reproducer.bin`. Not analysed further than the frames above.
