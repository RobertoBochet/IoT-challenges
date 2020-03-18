#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct {
  nx_uint16_t sender_id;
  nx_uint16_t counter;
} message_t;

#endif