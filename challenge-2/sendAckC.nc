#include "sendAck.h"

#include "sendAck.h"
#include "Timer.h"

module sendAckC {
	uses {
		interface Boot;
		
		interface SplitControl;
		interface Packet;
		interface AMSend;
		interface Receive;
		interface PacketAcknowledgements;

		interface Timer<TMilli> as MilliTimer;
		interface Timer<TMilli> as PendingShutdownTimer;

		interface Read<uint16_t>;
	}

	} implementation {

	uint8_t counter=0;
	uint8_t rec_id;
	message_t packet;

	void sendReq();
	void sendResp();


	//***************** Send request function ********************//
	void sendReq() {
		custom_msg_t* p;

		dbg("radio_send", "Try to send a new request\n");

		// creates the packet		
		p = (custom_msg_t*) call Packet.getPayload(&packet, sizeof(custom_msg_t));

		// checks if the packet was created
		if(p == NULL) return;

		// populates the packet
		p->msg_type = MSG_TYPE_REQ;
		p->msg_counter = counter;

		// set packet to request ACK
		call PacketAcknowledgements.requestAck(&packet);

		// tries to send the packet
		if (call AMSend.send(MOTE_RESP, &packet, sizeof(custom_msg_t)) == SUCCESS)
			dbg("radio_send", "Request sent\n");

		else dbgerror("radio_send", "Send error!\n");
	}

	//****************** Task send response *****************//
	void sendResp() {
		/* This function is called when we receive the REQ message.
		* Nothing to do here.
		* `call Read.read()` reads from the fake sensor.
		* When the reading is done it raise the event read one.
		*/
		call Read.read();
	}

	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");

		dbg("boot", "I am %d\n", TOS_NODE_ID);

		// start the wireless interface
		call SplitControl.start();
	}

	//***************** SplitControl interface ********************//
	event void SplitControl.startDone(error_t err) {
		// check if the wireless interface started succefully 
		if (err != SUCCESS) {
			dbg("radio", "Fail to start AMControl\n");

			// retry to start wireless interface
			call SplitControl.start();
			return;
		}

		dbg("radio", "AM control is ready\n");

		// start timer if this is the mote #1
		if(TOS_NODE_ID == MOTE_REQ) {			
			dbg("timer", "Start timer\n");
			call MilliTimer.startPeriodic(1000);
		}
	}

	event void SplitControl.stopDone(error_t err){}

	//***************** MilliTimer interface ********************//
	event void MilliTimer.fired() {
		dbg("timer", "Timer fired\n");

		// increment counter
		counter++;

		// send request
		sendReq();
	}


	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {
		if (&packet == buf && err == SUCCESS) {

			dbg("radio_send", "Packet sent at time %s \n", sim_time_string());

			if(call PacketAcknowledgements.wasAcked(buf)) {
				dbg_clear("radio_ack", "\tACK was received\n");

				if(TOS_NODE_ID == MOTE_REQ) {
					dbg("timer", "Stop timer\n");

					call MilliTimer.stop();
				}
				
				call PendingShutdownTimer.startOneShot(1000);

			} else dbg_clear("radio_ack", "\tNo ACK received\n");

		} else dbgerror("radio_send", "Send done error!\n");
	}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		custom_msg_t* p;

		dbg("radio_rec", "Packet received at time %s \n", sim_time_string());

		// checks if the payload is castable to custom message
		if (len == sizeof(custom_msg_t)) {
			dbg_clear("radio_rec", "\tthis seems valid\n");
			
			// cast payload to custom message
			p = (custom_msg_t*)payload;

			if(p->msg_type == MSG_TYPE_RESP && TOS_NODE_ID == MOTE_REQ)
				dbg("radio_rec", "Sensor value received\n");

			else if(p->msg_type == MSG_TYPE_REQ && TOS_NODE_ID == MOTE_RESP) {
				dbg_clear("radio_rec", "\tcounter: %d\n", p->msg_counter);

				// save counter
				counter = p->msg_counter;

				// read sensor value
				sendResp();
			}
		}

		return buf; 
	}

  //************************* Read interface **********************//
	event void Read.readDone(error_t result, uint16_t data) {
		custom_msg_t* p;

		dbg("radio_send", "Try to send a respose\n");

		// creates the packet		
		p = (custom_msg_t*) call Packet.getPayload(&packet, sizeof(custom_msg_t));

		// checks if the packet was created
		if(p == NULL) return;

		// populates the packet
		p->msg_type = MSG_TYPE_RESP;
		p->msg_counter = counter;
		p->value = data;

		// set packet to request ACK
		call PacketAcknowledgements.requestAck(&packet);

		// tries to send the packet
		if (call AMSend.send(MOTE_REQ, &packet, sizeof(custom_msg_t)) == SUCCESS)
			dbg("radio_send", "Respose sent\n");

		else dbgerror("radio_send", "Send error!\n");
	}

	//***************** PendingShutdownTimer interface ********************//
	event void PendingShutdownTimer.fired() {
		dbg("timer", "Shutdown timer fired\n");

		// stop the wireless interface
		call SplitControl.stop();

		dbg("boot", "Bye bye!\n");
	}
}