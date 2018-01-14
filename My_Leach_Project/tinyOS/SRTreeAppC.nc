#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif
	components MainC, LedsC, ActiveMessageC ;
		components new TimerMilliC() as RoutingMsgTimerC;
	components new TimerMilliC() as Led0TimerC;
	components new TimerMilliC() as Led1TimerC;
	components new TimerMilliC() as Led2TimerC;
	components new TimerMilliC() as LostTaskTimerC;
	components new TimerMilliC() as AggrTimerC;
	components new TimerMilliC() as FinalAggrTimerC;

	components new TimerMilliC() as valueTimerC;
	components new TimerMilliC() as HeadClusterTimerC;
	components new TimerMilliC() as SubHeadClusterTimerC;
components new TimerMilliC() as ParentResetTimerC;
	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	components new AMSenderC(AM_SUMMSG) as NotifySenderC;
	components new AMReceiverC(AM_SUMMSG) as NotifyReceiverC;


	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as NotifySendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as NotifyReceiveQueueC;

	SRTreeC.Boot->MainC.Boot;

	SRTreeC.RadioControl -> ActiveMessageC;
	SRTreeC.Leds-> LedsC;

	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
	SRTreeC.Led0Timer-> Led0TimerC;
	SRTreeC.Led1Timer-> Led1TimerC;
	SRTreeC.Led2Timer-> Led2TimerC;
	SRTreeC.LostTaskTimer->LostTaskTimerC;
	SRTreeC.AggrTimer->AggrTimerC;
	SRTreeC.FinalAggrTimer->FinalAggrTimerC;

SRTreeC.valueTimer->valueTimerC;
SRTreeC.HeadClusterTimer ->HeadClusterTimerC;
SRTreeC.SubHeadClusterTimer ->SubHeadClusterTimerC;
SRTreeC.ParentResetTimer->ParentResetTimerC;
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;

	SRTreeC.NotifyPacket->NotifySenderC.Packet;
	SRTreeC.NotifyAMPacket->NotifySenderC.AMPacket;
	SRTreeC.NotifyAMSend->NotifySenderC.AMSend;
	SRTreeC.NotifyReceive->NotifyReceiverC.Receive;


	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
	SRTreeC.NotifySendQueue->NotifySendQueueC;
	SRTreeC.NotifyReceiveQueue->NotifyReceiveQueueC;

}
