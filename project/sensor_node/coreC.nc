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

		interface Timer<TMilli> as MilliTimer;

		interface Random;
		interface ParameterInit<uint16_t> as SeedInit;
	}
}

implementation {
	uint16_t period;
	uint8_t data_type;
	message_t packet;

	//***************** Boot interface ********************//
	event void Boot.booted() {
		printf("I am a sensor node with ID %d\n", TOS_NODE_ID);

		// set period and data type
		period = 500 * ((call Random.rand16()) / 2048) + 2000;
		data_type = temperature;

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

		// start timer with a random period
		printf("Start timer with a period of %d\n", period);
		call MilliTimer.startPeriodic(period);
	}

	event void SplitControl.stopDone(error_t err){}

	//***************** MilliTimer interface ********************//
	event void MilliTimer.fired() {
		data_msg_t* p;

		// creates the packet
		p = (data_msg_t*) call Packet.getPayload(&packet, sizeof(data_msg_t));

		// checks if the packet was created
		if(p == NULL) return;

		// populates the packet
		p->sender_id = TOS_NODE_ID;
		p->data_type = data_type;
		p->data = (call Random.rand16()) / 655;

		// tries to send the packet
		if (call AMSend.send(1, &packet, sizeof(data_msg_t)) == SUCCESS)
			dbg_clear("radio_send", "\tscheduled message to send\n");

		else dbgerror("radio_send", "Send error!\n");
	}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		data_msg_t* p;

		return buf;

		dbg("radio_rec", "Packet received at time %s \n", sim_time_string());

		// checks if the payload is castable to custom message
		if (len == sizeof(data_msg_t)) {
			dbg_clear("radio_rec", "\tseems valid\n");
			
			// cast payload to custom message
			p = (data_msg_t*)payload;

			dbg_clear("radio_rec", "\tcounter:\t%d\n", p->sender_id);
			dbg_clear("radio_rec", "\tvalue:\t\t%d\n", p->data);

			printf("%d:%d\n", p->sender_id, p->data);
		}

		return buf; 
	}
}