#ifndef MYLIST_H
#define MYLIST_H

#include <syslog.h>

#define log_err(fmt,arg...)    syslog(LOG_ERR, fmt, ##arg)
#define log_notice(fmt,arg...) syslog(LOG_NOTICE, fmt, ##arg)

typedef struct list_head {
	struct list_head *next, *prev;
	void *data;
} list_head_t;

static __inline struct list_head * list_head_creat(void)
{
	struct list_head *index = NULL;

	index = (struct list_head *)malloc(sizeof(struct list_head));
	if (NULL == index)	{
		log_err("Err: list_head_creat -- malloc fail\n");
	}

	return index;
}

static __inline void list_head_init(struct list_head *head)
{
	head->prev = head;
	head->next = head;
	head->data = NULL;
}

/*
 * Insert a new entry between two known consecutive entries.
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static __inline void list_add2(struct list_head *newone,
			      struct list_head *prev,
			      struct list_head *next)
{
	next->prev = newone;
	newone->next = next;
	newone->prev = prev;
	prev->next = newone;
}

static __inline void list_add(struct list_head *newone,
			      struct list_head *head)
{
	list_add2(newone, head, head->next);
}

/**
 * list_add_tail - add a new entry
 * @new: new entry to be added
 * @head: list head to add it before
 *
 * Insert a new entry before the specified head.
 * This is useful for implementing queues.
 */
static __inline void list_add_tail(struct list_head *newone, struct list_head *head)
{
	list_add2(newone, head->prev, head);
}

/*
 * Delete a list entry by making the prev/next entries
 * point to each other.
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static __inline void list_del2(struct list_head * prev, struct list_head * next)
{
	next->prev = prev;
	prev->next = next;
}

/**
 * list_del - deletes entry from list.
 * @entry: the element to delete from the list.
 * Note: list_empty() on entry does not return true after this, the entry is
 * in an undefined state.
 */
static __inline void list_del(struct list_head *entry)
{
	list_del2(entry->prev, entry->next);
	entry->next = NULL;
	entry->prev = NULL;
}


/**
 * list_replace - replace old entry by new one
 * @old : the element to be replaced
 * @new : the new element to insert
 *
 * If @old was empty, it will be overwritten.
 */
static __inline void list_replace(struct list_head *old,
				struct list_head *newone)
{
	newone->next = old->next;
	newone->next->prev = newone;
	newone->prev = old->prev;
	newone->prev->next = newone;
	old->next = NULL;
	old->prev = NULL;
}

/**
 * list_is_last - tests whether @list is the last entry in list @head
 * @list: the entry to test
 * @head: the head of the list
 */
static __inline int list_is_last(const struct list_head *index,
				const struct list_head *head)
{
	return index->next == head;
}

static __inline int list_is_head(const struct list_head *index,
				const struct list_head *head)
{
	return index == head;
}

/**
 * list_empty - tests whether a list is empty
 * @head: the list to test.
 */
static __inline int list_empty(const struct list_head *head)
{
	return head->next == head;
}


static __inline int get_list_number(const struct list_head *head)
{
    int cnt = 0;
    list_head_t *index = NULL;
    
    if (list_is_empty(head)) {
        return 0;
    }

    for (index=head; !list_is_last(index, head); index=index->next) {
        cnt ++;
    }
    return cnt;
}

static __inline list_head_t *get_list_item(int index_num, const struct list_head *head)
{
    list_head_t *index = NULL;
    int i = 0;
    
    if (list_is_empty(head)) {
        return NULL;
    }

    if ((index_num < 1) || (index_num > get_list_number(head))) {
        return NULL;
    }

    index = head->next;
    for (i=1; i<index_num; i++) {
        index = index->next;
    }

    return index;
}

#endif
