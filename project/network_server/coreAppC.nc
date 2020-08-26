#include "data_message.h"

#define AM_PARAMETER 6

configuration coreAppC {}

implementation {
	/****** COMPONENTS *****/
	components MainC, coreC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_PARAMETER);
	components new AMReceiverC(AM_PARAMETER);

	/****** INTERFACES *****/
	App.Boot -> MainC.Boot;

	// radio Control
	App.SplitControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.Receive -> AMReceiverC;

	// print interface
	components SerialPrintfC;
}