#ifndef DATA_MESSAGE_H
#define DATA_MESSAGE_H

typedef enum {
	sensor_data,
	gateway_relay
	ack
} msg_type_t;

typedef enum {
	temperature
} data_type_t;

typedef nx_struct {
	nx_uint8_t sensor_id;
	nx_uint8_t gateway_id;
	nx_uint8_t msg_id;
	nx_uint8_t msg_type;
	nx_uint8_t data_type;
	nx_uint8_t data;
} data_msg_t;

#endif