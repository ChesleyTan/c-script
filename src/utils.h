#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <string.h>

// ANSI Escape codes
static const char *reset = "\e[0m";
static const char *bold_prefix = "\e[1;";
static const char *dim_prefix = "\e[2;";
static const char *underline_prefix = "\e[4;";
static const char *fg_red_160 = "38;5;160m";
static const char *fg_red_196 = "38;5;196m";
static const char *fg_yellow_220 = "38;5;220m";
static const char *fg_green_34 = "38;5;34m";
static const char *fg_green_118 = "38;5;118m";
static const char *fg_blue_24 = "38;5;24m";
static const char *fg_blue_39 = "38;5;39m";
static const char *fg_white = "38;5;15m";

void print_error(const char *format, ...);
void print_debug(const char *format, ...);
void print_errno(const char *message);
int * intdup(const int *src, size_t len);
char ** str_arrdup(char **src, size_t len);
int str_arrlen(char **arr);
