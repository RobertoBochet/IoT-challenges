#ifndef CUSTOM_MESSAGE_H
#define CUSTOM_MESSAGE_H

typedef nx_struct custom_message {
	nx_uint16_t sender_id;
	nx_uint16_t counter;
} custom_message_t;

#endif