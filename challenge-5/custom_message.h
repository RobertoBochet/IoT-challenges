#ifndef CUSTOM_MESSAGE_H
#define CUSTOM_MESSAGE_H

typedef nx_struct custom_msg {
	nx_uint8_t sender_id;
	nx_uint8_t value;
} custom_msg_t;

#endif