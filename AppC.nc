#define AM_PARAMETER 6

configuration AppC
{}

implementation
{
	components MainC;
	components CoreC;
	components ActiveMessageC;
	components new AMSenderC(AM_PARAMETER);
	components new AMReceiverC(AM_PARAMETER);
	components new TimerMilliC();
	components LedsC;


	CoreC.Boot -> MainC.Boot;

	CoreC.MilliTimer -> TimerMilliC;

	CoreC.AMControl -> ActiveMessageC;

	CoreC.Receive -> AMReceiverC;
	CoreC.AMSend -> AMSenderC;
  	CoreC.Packet -> AMSenderC;

	CoreC.Leds -> LedsC;
	
	// for debug
	components SerialPrintfC;
}