#include "utils.h"

void print_error(const char *format, ...) {
    va_list args;
    va_start(args, format);
    fprintf(stderr, "%s%s[ERROR] %s", bold_prefix, fg_red_196, reset);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
}

void print_debug(const char *format, ...) {
    va_list args;
    va_start(args, format);
    fprintf(stderr, "%s%s[DEBUG] %s", bold_prefix, fg_yellow_220, reset);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
}

void print_errno(const char *message) {
    if (errno) {
            fprintf(stderr, "%s%s%s%s %s%s->%s %s%s%s%s\n", bold_prefix, fg_red_196, message, reset, bold_prefix, fg_white, reset, bold_prefix, fg_red_160, strerror(errno), reset);
    }
}
