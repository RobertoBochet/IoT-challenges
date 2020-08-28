#ifndef DATA_MESSAGE_H
#define DATA_MESSAGE_H

typedef enum {
	sensor_data = 0b00,
	ack = 0b01,
	sensor_data_relayed = 0b10,
	ack_relayed = 0b11
} msg_type_t;

typedef enum {
	temperature = 0,
	voltage = 1,
	humidity = 2
} data_type_t;

typedef nx_struct {
	nx_uint8_t msg_id;
	nx_uint8_t msg_type;
	nx_uint8_t sensor_id;
	nx_uint8_t gateway_id;
	nx_uint8_t data_type;
	nx_uint8_t data;
} data_msg_t;

#endif