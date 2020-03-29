#include "sendAck.h"

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
}

implementation {

	uint8_t counter=0;
	message_t packet;

	void sendMessage(am_addr_t, uint8_t, uint16_t, uint16_t);

	//****************** Task send message *****************//
	void sendMessage(am_addr_t _dest, uint8_t _type, uint16_t _counter, uint16_t _data)
	{
		custom_msg_t* p;

		dbg("radio_send", "Try to send a new %s\n", _type == MSG_TYPE_REQ ? "request" : "response");

		// creates the packet		
		p = (custom_msg_t*) call Packet.getPayload(&packet, sizeof(custom_msg_t));

		// checks if the packet was created
		if(p == NULL) return;

		// populates the packet
		p->msg_type = _type;
		p->msg_counter = _counter;
		if(_type == MSG_TYPE_RESP) p->value = _data;

		dbg_clear("radio_send", "\tcounter:\t%d\n", _counter);
		if(_type == MSG_TYPE_RESP) dbg_clear("radio_send", "\tvalue:\t\t%d\n", _data);

		// set packet to request ACK
		call PacketAcknowledgements.requestAck(&packet);

		dbg_clear("radio_send", "\tset ACK bit\n");

		// tries to send the packet
		if (call AMSend.send(_dest, &packet, sizeof(custom_msg_t)) == SUCCESS)
			dbg_clear("radio_send", "\tscheduled message to send\n");

		else dbgerror("radio_send", "Send error!\n");
	}

	//***************** Boot interface ********************//
	event void Boot.booted() {
		dbg("boot","Application booted.\n");

		dbg_clear("boot", "\tI am %s\n", TOS_NODE_ID == MOTE_REQ ? "MOTE_REQ" : "MOTE_RESP");

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

		// start timer if this is the MOTE_REQ
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
		sendMessage(MOTE_RESP, MSG_TYPE_REQ, counter, 0);
	}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {
		// check if the packet was sent
		if (&packet == buf && err == SUCCESS) {

			dbg("radio_send", "Packet sent at time %s \n", sim_time_string());

			// check if there was an ACK as response
			if(call PacketAcknowledgements.wasAcked(buf)) {
				dbg_clear("radio_ack", "\tACK was received\n");

				// if this is the MOTE_REQ, stop the periodic request timer
				if(TOS_NODE_ID == MOTE_REQ) {
					dbg("timer", "Stop timer\n");

					call MilliTimer.stop();
				}
				
				// schedule the shutdown
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
			dbg_clear("radio_rec", "\tseems valid\n");
			
			// cast payload to custom message
			p = (custom_msg_t*)payload;

			// If the message is received by MOTE_REQ
			if(p->msg_type == MSG_TYPE_RESP && TOS_NODE_ID == MOTE_REQ) {
				dbg_clear("radio_rec", "\tcounter:\t%d\n", p->msg_counter);
				dbg_clear("radio_rec", "\tvalue:\t\t%d\n", p->value);

			// If the message is received by MOTE_RESP
			} else if(p->msg_type == MSG_TYPE_REQ && TOS_NODE_ID == MOTE_RESP) {
				dbg_clear("radio_rec", "\tcounter:\t%d\n", p->msg_counter);

				// save counter
				counter = p->msg_counter;

				// read sensor value
				call Read.read();
			}
		}

		return buf; 
	}

  //************************* Read interface **********************//
	event void Read.readDone(error_t result, uint16_t data) {
		sendMessage(MOTE_REQ, MSG_TYPE_RESP, counter, data);
	}

	//***************** PendingShutdownTimer interface ********************//
	event void PendingShutdownTimer.fired() {
		dbg("timer", "Shutdown timer fired\n");

		// stop the wireless interface
		call SplitControl.stop();

		dbg("boot", "Bye bye!\n");
	}
}