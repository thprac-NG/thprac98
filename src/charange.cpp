#include "src/charange.hpp"

const char_chunk_mask_t char_chunk_mask;

const char_chunk_t char_chunks[THPRAC_CHAR_CHUNKS_SIZE] = {
#include "charange.inc"
};