#ifndef SENDACK_H
#define SENDACK_H

#define AM_PARAMETER 6

// type of the msg
enum {
	MSG_TYPE_REQ, MSG_TYPE_RESP
};

// payload of the msg
typedef nx_struct {
	nx_uint8_t msg_type;
	nx_uint16_t msg_counter;
	nx_uint16_t value;
} custom_msg_t;

// motes id
enum {
	MOTE_REQ = 1, MOTE_RESP = 2
}; 

#endif
