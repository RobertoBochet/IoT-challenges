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
	event void AMSend.sendDone(message_t* buf,error_t err) {}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		data_msg_t* p;

		return buf;

		dbg("radio_rec", "Packet received at time %s \n", sim_time_string());

		// checks if the payload is castable to custom message
		if (len != sizeof(data_msg_t)) {
			printf("Invalid package received\n");
			return buf;
		}
			
		// cast payload to custom message
		p = (data_msg_t*)payload;

		// if the package is not a gateway relay ignore it
		if (p->msg_type != gateway_relay) return buf;

		printf("A relayed message is came");
		printf("From sensor with ID %d through gateway with ID %d", p->sensor_id, p->gateway_id);
		printf("With a value of `%d`", p->data);

		return buf; 
	}
}