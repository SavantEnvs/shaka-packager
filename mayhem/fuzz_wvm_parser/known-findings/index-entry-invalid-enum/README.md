# WVM index entry stores an unchecked byte in an enum

`ParseIndexEntry` (`wvm_media_parser.cc:682`) does `tagtype = Tag(tag)` with a byte read from the stream, and the
following `switch (tagtype)` loads it (`:688`). A value that is not one of `Tag`'s enumerators is undefined behaviour,
and UBSan's enum check halts (`load of value 192, which is not a valid value for type 'Tag'`). It is the
"Misinterpretation of Input" defect in the run-1 list.

Reproduce: `/mayhem/fuzz_wvm_parser-standalone reproducer.bin`. Fix: keep the tag in an integer and compare against
the enumerators.
