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
		printf("I am a gateway with ID %d\n", TOS_NODE_ID);

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
		data_msg_t* p_in;
		data_msg_t* p_out;

		// checks if the payload is castable to custom message
		if (len != sizeof(data_msg_t)) {
			printf("ERROR: Invalid package received\n");
			return buf;
		}
			
		// cast payload to custom message
		p_in = (data_msg_t*)payload;

		// if the packet is already relayed ignore it
		if (p_in->msg_type & 0b10) return buf;

		if (p_in->msg_type == ack)
			printf("Received ack for packet %d to %d\n", p_in->msg_id, p_in->sensor_id);
		else
			printf("Received packet %d from %d\n", p_in->msg_id, p_in->sensor_id);

		// aborts the relayed process, if the buffer is not empty
		if (locked) {
			printf("ERROR: The buffer is not empty, the packet cannot be relayed");
			return buf;
		}

		locked = TRUE;

		// creates the packet
		p_out = (data_msg_t*) call Packet.getPayload(&packet, sizeof(data_msg_t));

		// checks if the packet was created
		if(p_out == NULL) {
			printf("ERROR: Memory error");
			locked = FALSE;
			return buf;
		}

		// populates the packet
		p_out->msg_type = p_in->msg_type | 0b10;
		p_out->msg_id = p_in->msg_id;
		p_out->sensor_id = p_in->sensor_id;
		p_out->gateway_id = TOS_NODE_ID;
		p_out->data_type = p_in->data_type;
		p_out->data = p_in->data;

		// tries to send the packet
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(data_msg_t)) != SUCCESS) {
			printf("ERROR: Sending error\n");

			locked = FALSE;

			return buf;
		}

		printf("Scheduled relayed packet %d with sensor %d to be sent\n", p_in->msg_id, p_in->sensor_id);
		
		return buf; 
	}
}