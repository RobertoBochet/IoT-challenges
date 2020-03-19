configuration AppC
{}

implementation
{
	components MainC;
	components CoreC;
	components ActiveMessageC;
	components new AMSenderC(6);
	components new AMReceiverC(6);
	components new TimerMilliC();


	CoreC.Boot -> MainC.Boot;

	CoreC.AMControl -> ActiveMessageC;

	CoreC.MilliTimer -> TimerMilliC;

	CoreC.Receive -> AMReceiverC;
	CoreC.AMSend -> AMSenderC;
  	CoreC.Packet -> AMSenderC;
	
	components SerialPrintfC;
}