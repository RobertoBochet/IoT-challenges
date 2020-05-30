#include <stdio.h>
#include <stdint.h>
#include "custom_message.h"


module coreC {
	uses {
		interface Boot;
		
		interface SplitControl;
		interface Packet;
		interface AMSend;
		interface Receive;

		interface Timer<TMilli> as MilliTimer;
	}
}

implementation {
	message_t packet;

	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");

		dbg_clear("boot", "\tI am %s\n", TOS_NODE_ID == 1 ? "the sink" : "an emitter");

		// start the wireless interface
		call SplitControl.start();
	}

	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err) {
		// check if the wireless interface started successfully 
		if (err != SUCCESS) {
			dbg("radio", "Fail to start AMControl\n");

			// retry to start wireless interface
			call SplitControl.start();
			return;
		}

		dbg("radio", "AM control is ready\n");

		// start timer if this is not the sink
		if(TOS_NODE_ID != 1) {
			dbg("timer", "Start timer\n");
			call MilliTimer.startPeriodic(5000);
		}
	}

	event void SplitControl.stopDone(error_t err){}

	//***************** MilliTimer interface ********************//
	event void MilliTimer.fired() {
		custom_msg_t* p;

		dbg("timer", "Timer fired\n");

		// creates the packet
		p = (custom_msg_t*) call Packet.getPayload(&packet, sizeof(custom_msg_t));

		// checks if the packet was created
		if(p == NULL) return;

		// populates the packet
		p->sender_id = TOS_NODE_ID;
		p->value = 75;

		// tries to send the packet
		if (call AMSend.send(1, &packet, sizeof(custom_msg_t)) == SUCCESS)
			dbg_clear("radio_send", "\tscheduled message to send\n");

		else dbgerror("radio_send", "Send error!\n");
	}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		custom_msg_t* p;

		// only mote one should receive messages
		if(TOS_NODE_ID != 1)
			return;

		dbg("radio_rec", "Packet received at time %s \n", sim_time_string());

		// checks if the payload is castable to custom message
		if (len == sizeof(custom_msg_t)) {
			dbg_clear("radio_rec", "\tseems valid\n");
			
			// cast payload to custom message
			p = (custom_msg_t*)payload;

			dbg_clear("radio_rec", "\tcounter:\t%d\n", p->sender_id);
			dbg_clear("radio_rec", "\tvalue:\t\t%d\n", p->value);

			printf("%d:%d\n", p->sender_id, p->value);
		}

		return buf; 
	}
}