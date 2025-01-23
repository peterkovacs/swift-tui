#include <inttypes.h>
#include <stddef.h>
//#include <curses.h>
//#include <term.h>

/* All lengths are in bytes */
int codepoint_len(const uint32_t cp); /* len of associated utf-8 char */
int utf8_len(const uint8_t ch);          /* len of utf-8 encoded char */

uint32_t to_codepoint(const uint8_t chr[4]);

size_t write(int __fd, const void * __buf, size_t __nbyte);
