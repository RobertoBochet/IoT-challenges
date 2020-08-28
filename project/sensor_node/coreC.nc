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

		interface Timer<TMilli> as DataTimer;
		interface Timer<TMilli> as RetransmissionTimer;

		interface Random;
		interface ParameterInit<uint16_t> as SeedInit;
	}
}

implementation {
	uint16_t period;
	uint8_t data_type;
	message_t packet;
	uint8_t last_msg_id;

	void setupSensor() {
		// set period
		period = 500 * ((call Random.rand16()) / 2048) + 4000;

		// set sensor type
		switch(TOS_NODE_ID) {
			case 2:
				data_type = voltage;
				break;
			case 3:
			case 4:
				data_type = humidity;
				break;
			default:
				data_type = temperature;
		}
	}

	uint8_t getData() {
		return (call Random.rand16()) / 256;
	}

	//***************** Boot interface ********************//
	event void Boot.booted() {
		printf("I am a sensor node with ID %d\n", TOS_NODE_ID);

		// init sequence message id
		last_msg_id = 0;

		setupSensor();

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
		call DataTimer.startPeriodic(period);
	}

	event void SplitControl.stopDone(error_t err){}
	

	bool preparePacket() {
		data_msg_t* p;

		// increments the message id sequence
		last_msg_id++;

		printf("Forging packet %d\n", last_msg_id);

		// creates the packet
		p = (data_msg_t*) call Packet.getPayload(&packet, sizeof(data_msg_t));

		// checks if the packet was created
		if(p == NULL) {
			printf("ERROR: Memory error");
			return FALSE;
		}

		// populates the packet
		p->msg_type = sensor_data;
		p->msg_id = last_msg_id;
		p->sensor_id = TOS_NODE_ID;
		p->data_type = data_type;
		p->data = getData();

		return TRUE;
	}

	void sendData() {
		// tries to send the packet
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(data_msg_t)) != SUCCESS) {
			printf("ERROR: Sending error, will retry soon...\n");

			// sets the timer for the retransmission
			call RetransmissionTimer.startOneShot(1000);

			return;
		}

		printf("Scheduled package %d to be sent\n", last_msg_id);
	}

	event void DataTimer.fired() { 
		// does not retransmit old data
		call RetransmissionTimer.stop();

		printf("Starting to send a new data\n");

		if (preparePacket() == FALSE) {
			printf("ERROR: Impossible sent data\n");
			return;
		}

		sendData();
	}

	event void RetransmissionTimer.fired() {
		printf("Retransmission timer elapsed without ACK for packet %d\n", last_msg_id);

		sendData();
	}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {
		printf("Package %d sent\n", last_msg_id);

		// sets the timer for the retransmission
		call RetransmissionTimer.startOneShot(1000);
	}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		data_msg_t* p;

		// checks if the payload is castable to custom message
		if (len != sizeof(data_msg_t)) {
			printf("ERROR: Invalid packet received\n");
			return buf;
		}
			
		// cast payload to custom message
		p = (data_msg_t*)payload;

		// if the packet is not an ACK ignore it
		if (!(p->msg_type & ack)) return buf;

		// if the ack is not intended to this sensor ignore it
		if (p->sensor_id != TOS_NODE_ID) return buf;

		printf("An ACK is came for the packet %d\n",p->msg_id);

		// if the last sended message id and received ACK id are equal stops the retransmission timer
		if (last_msg_id == p->msg_id) call RetransmissionTimer.stop();
		
		else printf("The ACK is old\n");

		return buf; 
	}
}