#include "sendAck.h"

configuration sendAckAppC {}

implementation {
	/****** COMPONENTS *****/
	components MainC, sendAckC as App;
	components new TimerMilliC();
	components new TimerMilliC() as PendingShutdownTimer;
	components ActiveMessageC;
	components new AMSenderC(AM_PARAMETER);
	components new AMReceiverC(AM_PARAMETER);
	components new FakeSensorC();

	/****** INTERFACES *****/
	App.Boot -> MainC.Boot;

	// radio Control
	App.SplitControl -> ActiveMessageC;
	App.PacketAcknowledgements -> AMSenderC.Acks;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.Receive -> AMReceiverC;

	// timer interface
	App.MilliTimer -> TimerMilliC;
	App.PendingShutdownTimer -> PendingShutdownTimer;

	// sensor
	App.Read -> FakeSensorC;
}