#include "custom_message.h"

#define AM_PARAMETER 6

configuration coreAppC {}

implementation {
	/****** COMPONENTS *****/
	components MainC, coreC as App;
	components new TimerMilliC();
	components ActiveMessageC;
	components new AMSenderC(AM_PARAMETER);
	components new AMReceiverC(AM_PARAMETER);
	components RandomMlcgC;

	/****** INTERFACES *****/
	App.Boot -> MainC.Boot;

	// radio Control
	App.SplitControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.Receive -> AMReceiverC;

	// timer interface
	App.MilliTimer -> TimerMilliC;

	// random interface
	App.Random -> RandomMlcgC;
	App.SeedInit -> RandomMlcgC;

	// print interface
	components SerialPrintfC;
}