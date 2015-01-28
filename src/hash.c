#include "hash.h"
#include <stdio.h>

/* Credits to http://www.sparknotes.com/cs/searching/hashtables/section3.rhtml
 * for tutorial on implementing a hash table in C */
hash_table * create_hash_table(int size) {
    hash_table *new_table;

    /* Check for invalid size */
    if (size<1)
        return NULL;

    /* Allocate memory for the table structure */
    if ((new_table = malloc(sizeof(hash_table))) == NULL) {
        return NULL;
    }

    /* Attempt to allocate memory for the table itself */
    if ((new_table->table = malloc(sizeof(linked_list) * size)) == NULL) {
        return NULL;
    }

    /* Initialize the elements of the table */
    int i;
    for(i=0; i<size; i++) new_table->table[i] = NULL;

    /* Set the table's size */
    new_table->size = size;

    return new_table;
}

unsigned int hash(hash_table *hashtable, char *varName) {
    unsigned int hashval = 0;

    for (;*varName != '\0';++varName) {
        hashval = *varName + (hashval << 5) - hashval;
    }

    /* % with table size to prevent out of bounds */
    return hashval % hashtable->size;
}

linked_list *lookup(hash_table *hashtable, char *varName) {
    linked_list *list;
    unsigned int hashval = hash(hashtable, varName);

    for(list = hashtable->table[hashval]; list != NULL; list = list->next) {
        if (strcmp(varName, list->varName) == 0) {
            return list;
        }
    }
    return NULL;
}


int add(hash_table *hashtable, char *varName) {
    linked_list *new_list;
    linked_list *current_list;

    current_list = lookup(hashtable, varName);

    /* Return 2 to signify that the item already exists */
    if (current_list != NULL) return 2;

    /* Allocate memory for a new linked list */
    new_list = malloc(sizeof(linked_list));
    if (new_list == NULL) {
        return 1;
    }

    /* Insert into list */
    unsigned int hashval = hash(hashtable, varName);
    new_list->varName = strdup(varName);
    new_list->next = hashtable->table[hashval];
    hashtable->table[hashval] = new_list;

    return 0;
}

void free_table(hash_table *hashtable) {

    if (hashtable == NULL) {
        return;
    }

    int i;
    linked_list *list, *temp;

    /*
     * Free each item in the table
     */
    for(i=0; i<hashtable->size; i++) {
        list = hashtable->table[i];
        while (list != NULL) {
            temp = list;
            list = list->next;
            free(temp->varName);
            free(temp->s);
            free(temp);
        }
    }

    /* Free the table itself */
    free(hashtable->table);
    free(hashtable);
}
