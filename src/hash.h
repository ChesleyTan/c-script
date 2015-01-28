#pragma once
#include <stdlib.h>
#include <string.h>

/* Credits to http://www.sparknotes.com/cs/searching/hashtables/section3.rhtml
 * for tutorial on implementing a hash table in C */
typedef enum {
    STRING_VALUE,
    INTEGER_VALUE
} varType;
typedef struct _linked_list {
    varType type;
    char *varName;
    char *s;
    int i;
    struct _linked_list *next;
} linked_list;

typedef struct _hash_table {
    int size;       /* the size of the table */
    linked_list **table; /* the table elements */
} hash_table;

hash_table * create_hash_table(int size);
linked_list *lookup(hash_table *hashtable, char *str);
unsigned int hash(hash_table *hashtable, char *str);
int add(hash_table *hashtable, char *str);
void free_table(hash_table *hashtable);
