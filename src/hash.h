#pragma once
#include <stdlib.h>
#include <string.h>

/* Credits to http://www.sparknotes.com/cs/searching/hashtables/section3.rhtml
 * for tutorial on implementing a hash table in C */
typedef struct _list_t {
    char * str;
    int i;
    struct _list_t *next;
} list_t;

typedef struct _hash_table_t {
    int size;       /* the size of the table */
    list_t **table; /* the table elements */
} hash_table_t;

hash_table_t * create_hash_table(int size);
list_t *lookup(hash_table_t *hashtable, char *str);
unsigned int hash(hash_table_t *hashtable, char *str);
int add(hash_table_t *hashtable, char *str);
void free_table(hash_table_t *hashtable);
