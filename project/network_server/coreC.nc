#include <stdio.h>
#include <stdint.h>
#include "data_message.h"


module coreC {
	uses {
		interface Boot;
		
		interface SplitControl;
		interface Packet;
		interface AMSend;
		interface Receive;
	}
}

implementation {
	message_t packet;
	bool locked = FALSE;

	//***************** Boot interface ********************//
	event void Boot.booted() {
		printf("I am the network server with ID %d\n", TOS_NODE_ID);

		// start the wireless interface
		call SplitControl.start();
	}

	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err) {
		// check if the wireless interface started successfully 
		if (err != SUCCESS) {
			printf("Fail to start AMControl\n");

			// retry to start wireless interface
			call SplitControl.start();
			return;
		}

		printf("AM control is ready\n");
	}

	event void SplitControl.stopDone(error_t err){}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) { locked = FALSE; }

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		data_msg_t* p_in, * p_out;

		// checks if the payload is castable to custom message
		if (len != sizeof(data_msg_t)) {
			printf("Invalid package received\n");
			return buf;
		}
			
		// cast payload to custom message
		p_in = (data_msg_t*)payload;

		// if the package is not a gateway relay ignore it
		if (p_in->msg_type != sensor_data_relayed) return buf;

		printf("A relayed message is came\n");
		printf("From sensor with ID %d through gateway with ID %d\n", p_in->sensor_id, p_in->gateway_id);
		printf("With a value of `%d`\n", p_in->data);

		// sends data to node red
		printf("#%d:%d:%d:%d#\n", p_in->msg_id, p_in->sensor_id, p_in->data_type, p_in->data);

		// sends the ACK

		// aborts the sending process of ACK if the buffer is not empty
		if (locked) {
			printf("ERROR: The buffer is not empty, the ACK cannot be sent\n");
			return buf;
		}

		// locks sending buffer
		locked = TRUE;

		// creates the packet
		p_out = (data_msg_t*) call Packet.getPayload(&packet, sizeof(data_msg_t));

		// checks if the packet was created
		if(p_out == NULL) {
			printf("ERROR: Memory error\n");
			locked = FALSE;
			return buf;
		}

		// populates the packet
		p_out->msg_type = ack;
		p_out->msg_id = p_in->msg_id;
		p_out->sensor_id = p_in->sensor_id;
		p_out->gateway_id = 0;
		p_out->data_type = 0;
		p_out->data = 0;

		// tries to send the packet
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(data_msg_t)) != SUCCESS) {
			// unlock the buffer
			locked = FALSE;

			printf("ERROR: ACK not be sent\n");

			return buf;
		}

		printf("Scheduled ACK to be sent\n");

		return buf; 
	}
}