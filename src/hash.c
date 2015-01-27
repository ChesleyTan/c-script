#include "hash.h"
#include <stdio.h>

/* Credits to http://www.sparknotes.com/cs/searching/hashtables/section3.rhtml
 * for tutorial on implementing a hash table in C */
hash_table_t * create_hash_table(int size) {
    hash_table_t *new_table;

    /* Check for invalid size */
    if (size<1)
        return NULL;

    /* Allocate memory for the table structure */
    if ((new_table = malloc(sizeof(hash_table_t))) == NULL) {
        return NULL;
    }

    /* Attempt to allocate memory for the table itself */
    if ((new_table->table = malloc(sizeof(list_t) * size)) == NULL) {
        return NULL;
    }

    /* Initialize the elements of the table */
    int i;
    for(i=0; i<size; i++) new_table->table[i] = NULL;

    /* Set the table's size */
    new_table->size = size;

    return new_table;
}

unsigned int hash(hash_table_t *hashtable, char *str) {
    unsigned int hashval = 0;

    for (;*str != '\0';++str) {
        hashval = *str + (hashval << 5) - hashval;
    }

    /* % with table size to prevent out of bounds */
    return hashval % hashtable->size;
}

list_t *lookup(hash_table_t *hashtable, char *str) {
    list_t *list;
    unsigned int hashval = hash(hashtable, str);

    for(list = hashtable->table[hashval]; list != NULL; list = list->next) {
        if (strcmp(str, list->str) == 0) {
            return list;
        }
    }
    return NULL;
}


int add(hash_table_t *hashtable, char *str) {
    list_t *new_list;
    list_t *current_list;
    unsigned int hashval = hash(hashtable, str);

    /* Allocate memory for a new linked list */
    new_list = malloc(sizeof(list_t));
    if (new_list == NULL) {
        return 1;
    }

    current_list = lookup(hashtable, str);
    
    /* Return 2 to signify that the item already exists */
    if (current_list != NULL) return 2;

    /* Insert into list */
    new_list->str = strdup(str);
    new_list->next = hashtable->table[hashval];
    hashtable->table[hashval] = new_list;

    return 0;
}

void free_table(hash_table_t *hashtable) {

    if (hashtable == NULL) {
        return;
    }

    int i;
    list_t *list, *temp;

    /* 
     * Free each item in the table
     */
    for(i=0; i<hashtable->size; i++) {
        list = hashtable->table[i];
        while (list != NULL) {
            temp = list;
            list = list->next;
            free(temp->str);
            free(temp);
        }
    }

    /* Free the table itself */
    free(hashtable->table);
    free(hashtable);
}
