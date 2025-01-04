#ifndef __test_sfx_INCLUDE__
#define __test_sfx_INCLUDE__

#include <gbdk/platform.h>
#include <stdint.h>

#define MUTE_MASK_test_sfx 0b00000001

BANKREF_EXTERN(test_sfx)
extern const uint8_t test_sfx[];
extern void __mute_mask_test_sfx;

#endif
