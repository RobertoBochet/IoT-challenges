#include <stdio.h>
#include <stdint.h>
#include "custom_message.h"
#include "macro.h"

module CoreC @safe()
{
	uses
	{
		interface Boot;
		interface SplitControl as AMControl;

		interface Timer<TMilli> as MilliTimer;
		interface AMSend;
		interface Packet;
		interface Receive; 
	}
}

implementation {
	message_t packet;
	bool is_buffer_empty = TRUE;
  
	event void Boot.booted()
	{
		printf("Boot complete\n");

		printf("I am %d my period is %dms\n", TOS_NODE_ID, timer_period());

		// start the wireless interface
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t e)
	{
		// check if the wireless interface started succefully 
		if (e != SUCCESS) {
			printf("Fail to start AMControl\n");

			// retry to start wireless interface
			call AMControl.start();
			return;
		}

		printf("AM control is ready\n");

		// start timer
		call MilliTimer.startPeriodic(timer_period());
	}

	event void AMControl.stopDone(error_t e) {}

	event void MilliTimer.fired()
	{
		custom_message_t* cm;

		printf("Fire, try to send a new message\n");

		// checks if the buffer is not empty
		if(!is_buffer_empty) return;

		// creates the packet		
		cm = (custom_message_t*) call Packet.getPayload(&packet, sizeof(custom_message_t));

		// populates the packet
		cm->sender_id = TOS_NODE_ID;
		/* set stuff */


		// tries to send the packet
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(custom_message_t)) == SUCCESS)
			// sets the buffer state not empty
			is_buffer_empty = FALSE;
	}

	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		printf("Transmission complete\n");

		// sets the buffer state empty
		is_buffer_empty = TRUE;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		custom_message_t* cm;

		printf("Received a package\n");

		// checks if the payload is castable to custom message
		if (len == sizeof(custom_message_t)) {
			printf("The package seems valid\n");

			// cast payload to custom message
			cm = (custom_message_t*)payload;


			// do something
		}

		return msg; 
	}
}