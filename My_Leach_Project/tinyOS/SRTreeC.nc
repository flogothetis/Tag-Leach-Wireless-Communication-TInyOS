#include "SimpleRoutingTree.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>



#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

module SRTreeC
{
	uses interface Boot;
	uses interface SplitControl as RadioControl;


	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;
	uses interface Packet as RoutingPacket;

	uses interface AMSend as NotifyAMSend;
	uses interface AMPacket as NotifyAMPacket;
	uses interface Packet as NotifyPacket;


	uses interface Leds;
	uses interface Timer<TMilli> as RoutingMsgTimer;
	uses interface Timer<TMilli> as Led0Timer;
	uses interface Timer<TMilli> as Led1Timer;
	uses interface Timer<TMilli> as Led2Timer;
	uses interface Timer<TMilli> as LostTaskTimer;
	uses interface Timer<TMilli> as HeadClusterTimer;
  uses interface Timer<TMilli> as SubHeadClusterTimer;
  uses interface Timer<TMilli> as ParentResetTimer;
	uses interface Receive as RoutingReceive;
	uses interface Receive as NotifyReceive;
	uses interface Receive as SerialReceive;

	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;

	uses interface PacketQueue as NotifySendQueue;
	uses interface PacketQueue as NotifyReceiveQueue;

	uses interface Timer<TMilli> as AggrTimer;
		uses interface Timer<TMilli> as FinalAggrTimer;
	uses interface Timer<TMilli> as valueTimer;




}
implementation
{
	uint16_t  roundCounter;
	uint16_t  product;
	uint16_t  sum;
	uint16_t  children ;
	message_t radioRoutingSendPkt;
	message_t radioNotifySendPkt;


	message_t serialPkt;
	//message_t serialRecPkt;

	bool RoutingSendBusy=FALSE;
	bool NotifySendBusy=FALSE;



	bool lostRoutingSendTask=FALSE;
	bool lostNotifySendTask=FALSE;
	bool lostRoutingRecTask=FALSE;
	bool lostNotifyRecTask=FALSE;

	uint8_t curdepth;
	uint16_t parentID;
	uint16_t parentID2;


	uint16_t value;
	uint16_t old_sum=-1;
	uint16_t old_product=-1;
	uint16_t old_children=-1;
	task void sendRoutingTask();
	task void sendNotifyTask();
	task void receiveRoutingTask();
	task void receiveNotifyTask();
	task void  AggrMessageBack();
		task void  FinalAggrMessageBack();
	task void HeadClusterFunction();
		task void SubHeadClusterFunction();
void setNotifySendBusy(bool state);
void setLostNotifyRecTask(bool state);
int HeadRound=0;
int SubHeadCounter= 0;
bool isHead =FALSE ;
bool wasHead=FALSE ;
bool afterRouting =FALSE ;
bool TalkToParent=FALSE ;
//_____________________Value Generator__________________________//

//Τhis generator produce a radom value to the Sensor

	event void valueTimer.fired(){

			value=rand()%21 + TOS_NODE_ID;
		//value=rand()%20;
		//if(TOS_NODE_ID !=0 )

		call valueTimer.startOneShot(NEW_VALUE_TIMER);

		return;

	}

//__________________ParentResetTimerC___________________________//

// At each 60.000 sec the sensor will hear new advertisment message for
// head-cluster sensors ,so the parentID2 of each sensor will be reseted.

	event void ParentResetTimer.fired()
	{
	parentID2=-1;
	call ParentResetTimer.startOneShot(EPOCH_DURATION);

	return;



	}






//____________________HeadClusterTimer____________________________//

event void HeadClusterTimer.fired(){
		post HeadClusterFunction();

}


//______________________________________________________________//
task void HeadClusterFunction()
{


// Head-Custer Election Phase


afterRouting =TRUE;
if(HeadRound==4)
{
	HeadRound=0;
	wasHead=FALSE;
	isHead=FALSE ;

}
if(isHead==TRUE) wasHead==TRUE ;


if( HeadRound>=0 && HeadRound <=3 && wasHead==FALSE)
{
	 if( rand()%2 <= (0.25 /(float)(1-0.25*(HeadRound%4))))
	 {
					isHead=TRUE;
					dbg("SRTreeC", "I am a Head Cluster");
					call SubHeadClusterTimer.startOneShot(PROCCESSING_TIME);

	 }

}

HeadRound=HeadRound+1;


call HeadClusterTimer.startOneShot(BIG_EPOCH);

return;

}







//___________________ SubHeadClusterTimer.fired()______________//
event void SubHeadClusterTimer.fired()

{
post SubHeadClusterFunction();

}


//________________________________________________________________//
task void SubHeadClusterFunction()
{

// Head-Clusters are going to broadcast an advertisment message
parentID2=-1;


 SubHeadCounter= SubHeadCounter+1;

 call RoutingMsgTimer.startOneShot(PROCCESSING_TIME + rand()%30);

if(SubHeadCounter<5)
call SubHeadClusterTimer.startOneShot(EPOCH_DURATION);

if(SubHeadCounter==5) SubHeadCounter=0;





return ;




}



//________________________AggrTimer.fired_________________________//
	event void AggrTimer.fired()
	{

		post AggrMessageBack();
	}

	event void FinalAggrTimer.fired()
	{

		post FinalAggrMessageBack();
	}


//______________________________FinalAggrMessageBack()_________________//
task void  FinalAggrMessageBack()
{

//From The Routing Tree to Node 0

message_t tmp;


double var1 ;
double average ;
dbg("SRTreeC", "\n\n\nMpika gia  Wake up  \n");

if ( TOS_NODE_ID==0)
{

dbg("SRTreeC", "\n\n\n Wake up  children %d\n\n\n\n",children);



average = (double)sum / (double)children ;
var1 =  (((double)product / (double)children ) - average*average);

dbg("SRTreeC", "Average of the Tree is  ----->> %f..........\n",average);
dbg("SRTreeC", "Variance of the Tree is  ----->>   %lf..........\n" ,var1);
dbg("SRTreeC", "Count of the Tree is  ----->> %d..........\n",children);
dbg("SRTreeC", "\n ##################################### \n");
dbg("SRTreeC", "#######   ROUND   %u    ############## \n", roundCounter);
dbg("SRTreeC", "#####################################\n");
roundCounter++;

	sum=0;
	product=0;
	children = 0;
	call FinalAggrTimer.startOneShot(EPOCH_DURATION);
}else{

AggrMessage* m;
dbg("SRTreeC", "\n\n\n Wake up  children %d\n\n\n\n",children);

m = (AggrMessage *) (call NotifyPacket.getPayload(&tmp, sizeof(AggrMessage)));
m->senderID=TOS_NODE_ID;
m->parentID = parentID;
if(!isHead && parentID2==-1)
{
m->sum = sum+value;
m->product =product+(value*value);
m->children = children+1;
}
else
{
m->sum = sum;
m->product =product;
m->children = children;
}
dbg("SRTreeC" , "\nEimai Head %d,Akousa Sum %d kai Children %d  \n", isHead,sum,children);

if( children!=0)
{

call NotifyAMPacket.setDestination(&tmp, parentID);
call NotifyPacket.setPayloadLength(&tmp,sizeof(AggrMessage));

if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
{
dbg("SRTreeC", "AggrMessage Succefull in SendingQueue\n");
post sendNotifyTask();
}
}



call FinalAggrTimer.startOneShot(EPOCH_DURATION);

}
}




//_____________________________AggrMessageBask_____________________________



task void  AggrMessageBack()
{


//From Nodes to Head-Clusters messages


message_t tmp;

if(TalkToParent)
{



AggrMessage* m;
dbg("SRTreeC", "\n\n\n Wake up  children %d\n\n\n\n",children);

m = (AggrMessage *) (call NotifyPacket.getPayload(&tmp, sizeof(AggrMessage)));
m->senderID=TOS_NODE_ID;
m->parentID = parentID2;

m->sum = value;
m->product =(value*value);
m->children = 1;

dbg("SRTreeC", "@\n I have sent value= %d\n",value);

call NotifyAMPacket.setDestination(&tmp, parentID2);
call NotifyPacket.setPayloadLength(&tmp,sizeof(AggrMessage));

if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
{
dbg("SRTreeC", "AggrMessage Succefull in SendingQueue\n");
post sendNotifyTask();
}
TalkToParent=FALSE ;

}






}

//______________SendNotifyTask ()_________________________________-
task void sendNotifyTask()
{
	uint8_t mlen;//, skip;
	error_t sendDone;
	uint16_t mdest;
	AggrMessage* mpayload;

	//message_t radioNotifySendPkt;


	if (call NotifySendQueue.empty())
	{
		dbg("SRTreeC","sendNotifyTask(): Q is empty!\n");

		return;
	}



	radioNotifySendPkt = call NotifySendQueue.dequeue();


	mlen=call NotifyPacket.payloadLength(&radioNotifySendPkt);

	mpayload= call NotifyPacket.getPayload(&radioNotifySendPkt,mlen);

	if(mlen!= sizeof(AggrMessage))
	{
		dbg("SRTreeC", "\t\t sendNotifyTask(): Unknown message!!\n");
		return;
	}

	dbg("SRTreeC" , " sendNotifyTask(): mlen = %u  senderID= %u \n",mlen,mpayload->senderID);

	mdest= call NotifyAMPacket.destination(&radioNotifySendPkt);


	sendDone=call NotifyAMSend.send(mdest,&radioNotifySendPkt, mlen);

	if ( sendDone== SUCCESS)
	{
		dbg("SRTreeC","sendNotifyTask(): Send returned success!!!\n");
		setNotifySendBusy(TRUE);
	}
	else
	{
		dbg("SRTreeC","send failed!!!\n");

		//setNotifySendBusy(FALSE);
	}
}
//___________________NotifyAMsend.sendDone__________________________
event void NotifyAMSend.sendDone(message_t *msg , error_t err)
{
	dbg("SRTreeC", "A Notify package sent... %s \n",(err==SUCCESS)?"True":"False");



	dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");

	setNotifySendBusy(FALSE);

	if(!(call NotifySendQueue.empty()))
	{
		post sendNotifyTask();
	}else{
		roundCounter+=1;
		children=0;
		sum=0;
		product=0;
	}
}
//________________________NotifyReceive______________________________


event message_t* NotifyReceive.receive( message_t* msg , void* payload , uint8_t len)
{
	error_t enqueueDone;
	message_t tmp;
	uint16_t msource;

	msource = call NotifyAMPacket.source(msg);

	dbg("SRTreeC", "### NotifyReceive.receive() start ##### \n");
	dbg("SRTreeC", "Something received!!!  from %u   %u \n",((AggrMessage*) payload)->senderID, msource);


	atomic{
	memcpy(&tmp,msg,sizeof(message_t));
	//tmp=*(message_t*)msg;
	}
	enqueueDone=call NotifyReceiveQueue.enqueue(tmp);

	if( enqueueDone== SUCCESS)
	{

		post receiveNotifyTask();
	}
	else
	{
		dbg("SRTreeC","NotifyMsg enqueue failed!!! \n");

	}
	dbg("SRTreeC", "### NotifyReceive.receive() end ##### \n");
	return msg;
}


//_____________________________ReceiveNotifyTask_______________________

task void receiveNotifyTask()
{
	message_t tmp;
	uint8_t len;
	message_t radioNotifyRecPkt;


	radioNotifyRecPkt= call NotifyReceiveQueue.dequeue();

	len= call NotifyPacket.payloadLength(&radioNotifyRecPkt);

	dbg("SRTreeC","ReceiveNotifyTask(): len=%u \n",len);

	if(len == sizeof(AggrMessage))
	{

		AggrMessage* mr = (AggrMessage*) (call NotifyPacket.getPayload(&radioNotifyRecPkt,len));

	//	dbg("SRTreeC" , "AggrMessage received from %d with product %d !!! \n", mr->senderID);
			if(mr->parentID == TOS_NODE_ID ){

			// Receive Messages from my Children
			children = children + mr->children;
			sum = sum + mr->sum;
			product= product +mr->product;


			}

	}
	else
	{
		dbg("SRTreeC","receiveNotifyTask():Empty message!!! \n");

		setLostNotifyRecTask(TRUE);
		return;
	}

}



//__________________________setLostRoutingSendTask_______________________

	void setLostRoutingSendTask(bool state)
	{
		atomic{
			lostRoutingSendTask=state;
		}
		if(state==TRUE)
		{
			//call Leds.led2On();
		}
		else
		{
			//call Leds.led2Off();
		}
	}





	//_________________________SetLostNotifySendTask___________________________


	void setLostNotifySendTask(bool state)
	{
		atomic{
		lostNotifySendTask=state;
		}

		if(state==TRUE)
		{
			//call Leds.led2On();
		}
		else
		{
			//call Leds.led2Off();
		}
	}





//_________________________SetLostNotifyRecTask___________________________

	void setLostNotifyRecTask(bool state)
	{
		atomic{
		lostNotifyRecTask=state;
		}
	}

	void setLostRoutingRecTask(bool state)
	{
		atomic{
		lostRoutingRecTask=state;
		}
	}
	void setRoutingSendBusy(bool state)
	{
		atomic{
		RoutingSendBusy=state;
		}
		if(state==TRUE)
		{
			call Leds.led0On();
			call Led0Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else
		{
			//call Leds.led0Off();
		}
	}





//__________________________________setNotifySendBusy____________________________

	void setNotifySendBusy(bool state)
	{
		atomic{
		NotifySendBusy=state;
		}
		dbg("SRTreeC","NotifySendBusy = %s\n", (state == TRUE)?"TRUE":"FALSE");
#ifdef PRINTFDBG_MODE
		printf("\t\t\t\t\t\tNotifySendBusy = %s\n", (state == TRUE)?"TRUE":"FALSE");
#endif

		if(state==TRUE)
		{
			call Leds.led1On();
			call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else
		{
			//call Leds.led1Off();
		}
	}





//____________________________________________Boot_____________________________________________//


	event void Boot.booted()
	{
//init Radio Control
		call RadioControl.start();
		parentID2=-1;
		setRoutingSendBusy(FALSE);
		setNotifySendBusy(FALSE);
//initialize some varibles of the mote
    	roundCounter =0;
	 		product=0;
		  sum=0;
			children=0 ;
			srand((unsigned) time(NULL));

//If I am the basic node
		if(TOS_NODE_ID==0)
		{

			curdepth=0;
			parentID=0;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

		}
//If i am a simple node
		else
		{
			curdepth=-1;
			parentID=-1;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

		}
	}

//Then -->  RadioControl.StartDone()






//______________________RadioControl.StartDone()___________________________________________________//

	event void RadioControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");
			//Timer to HeadCluster Decision

			call ParentResetTimer.startOneShot(ROUTING_TIME/2);

			if(TOS_NODE_ID!=0)
			call HeadClusterTimer.startOneShot(ROUTING_TIME);


			if (TOS_NODE_ID==0)
			{
				call RoutingMsgTimer.startOneShot(PROCCESSING_TIME);
			}
		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");

			call RadioControl.start();
		}
	}







	event void RadioControl.stopDone(error_t err)
	{
		dbg("Radio", "Radio stopped!\n");
#ifdef PRINTFDBG_MODE
		printf("Radio stopped!\n");
		printfflush();
#endif
	}





//______________________LostTaskTimer.fired_____________________________//

	event void LostTaskTimer.fired()
	{
		if (lostRoutingSendTask)
		{
			post sendRoutingTask();
			setLostRoutingSendTask(FALSE);
		}

		if( lostNotifySendTask)
		{
			post sendNotifyTask();
			setLostNotifySendTask(FALSE);
		}

		if (lostRoutingRecTask)
		{
			post receiveRoutingTask();
			setLostRoutingRecTask(FALSE);
		}

		if ( lostNotifyRecTask)
		{
			post receiveNotifyTask();
			setLostNotifyRecTask(FALSE);
		}
	}


//____________________RoutingMsgTimer.fired()_______________________




	event void RoutingMsgTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;

		RoutingMsg* mrpkt;
		dbg("SRTreeC", "RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");

		if (TOS_NODE_ID==0)
		{
			roundCounter+=1;

			dbg("SRTreeC", "\n ##################################### \n");
			dbg("SRTreeC", "#######   ROUND   %u    ############## \n", roundCounter);
			dbg("SRTreeC", "#####################################\n");

			call FinalAggrTimer.startOneShot(EPOCH_DURATION);
		}

		if(call RoutingSendQueue.full())
		{

			return;
		}


		mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));
		if(mrpkt==NULL)
		{
			dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");

			return;
		}
		atomic{
		mrpkt->senderID=TOS_NODE_ID;
		mrpkt->depth = curdepth;
		}
		dbg("SRTreeC" , "Sending RoutingMsg... \n");


		call RoutingAMPacket.setDestination(&tmp, AM_BROADCAST_ADDR);
		call RoutingPacket.setPayloadLength(&tmp, sizeof(RoutingMsg));

		enqueueDone=call RoutingSendQueue.enqueue(tmp);

		if( enqueueDone==SUCCESS)
		{
			if (call RoutingSendQueue.size()==1)
			{
				dbg("SRTreeC", "SendTask() posted!!\n");

				post sendRoutingTask();
			}

			dbg("SRTreeC","RoutingMsg enqueued successfully in SendingQueue!!!\n");

		}
		else
		{
			dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");

		}
	}

//-> sendRoutingTask()


//________________________SendRoutingTask____________________________//


task void sendRoutingTask()
{
	//uint8_t skip;
	uint8_t mlen;
	uint16_t mdest;
	error_t sendDone;
//	message_t radioRoutingSendPkt;
//wake up value Generator

call valueTimer.startOneShot(PROCCESSING_TIME);

	if (call RoutingSendQueue.empty())
	{
		dbg("SRTreeC","sendRoutingTask(): Q is empty!\n");

		return;
	}


	if(RoutingSendBusy)
	{
		dbg("SRTreeC","sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");

		setLostRoutingSendTask(TRUE);
		return;
	}

	radioRoutingSendPkt = call RoutingSendQueue.dequeue();


	mlen= call RoutingPacket.payloadLength(&radioRoutingSendPkt);
	mdest=call RoutingAMPacket.destination(&radioRoutingSendPkt);
	if(mlen!=sizeof(RoutingMsg))
	{
		dbg("SRTreeC","\t\tsendRoutingTask(): Unknown message!!!\n");

		return;
	}
	sendDone=call RoutingAMSend.send(mdest,&radioRoutingSendPkt,mlen);

	if ( sendDone== SUCCESS)
	{
		dbg("SRTreeC","sendRoutingTask(): Send returned success!!!\n");

		setRoutingSendBusy(TRUE);
	}
	else
	{
		dbg("SRTreeC","send failed!!!\n");


	}
}


//___________________________Routing.SendDone()_____________________________
event void RoutingAMSend.sendDone(message_t * msg , error_t err)
{
	dbg("SRTreeC", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");


	dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");

	setRoutingSendBusy(FALSE);

	if(!(call RoutingSendQueue.empty()))
	{
		post sendRoutingTask();
	}
	//call Leds.led0Off();


}




//____________________________RoutingReceive_______________________________

	event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource =call RoutingAMPacket.source(msg);

		dbg("SRTreeC", "### RoutingReceive.receive() start ##### \n");
		dbg("SRTreeC", "Something received!!!  from %u  %u \n",((RoutingMsg*) payload)->senderID ,  msource);



		atomic{
		memcpy(&tmp,msg,sizeof(message_t));

		}
		enqueueDone=call RoutingReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
			post receiveRoutingTask();
		}
		else
		{
			dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");

		}



		dbg("SRTreeC", "### RoutingReceive.receive() end ##### \n");
		return msg;
	}


	//_________________________ReceiveRoutingTask________________________
	task void receiveRoutingTask()
	{

		message_t tmp;
		uint8_t len;
		message_t radioRoutingRecPkt;



		radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();

		len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);


		if(len == sizeof(RoutingMsg))
		{

			RoutingMsg * mpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));



			//dbg("SRTreeC" , "receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);


			if (isHead==FALSE && afterRouting==TRUE )
			{


							if ( (parentID2<0)||(parentID2>=65535))
							{

									parentID2= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID
									TalkToParent=TRUE;
									dbg("SRTreeC" , "\n\n\n I am : %d , my SECOND father= %d " , TOS_NODE_ID,parentID2);

									call AggrTimer.startOneShot(PROCCESSING_TIME+ rand()%100+rand()%100);
							}


			}
			if ( (parentID<0)||(parentID>=65535) && afterRouting==FALSE)
			{
				// tote den exei akoma patera
				parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;q
				curdepth= mpkt->depth + 1;

					dbg("SRTreeC" , "\n\n\nI am : %d , my father= %d  my depth = %d \n", TOS_NODE_ID,parentID,curdepth);

					call RoutingMsgTimer.startOneShot(PROCCESSING_TIME);
					call FinalAggrTimer.startOneShot( (ROUTING_TIME - (PROCCESSING_TIME*(curdepth+1))) + (MAXIMUM_SENSORS - curdepth)*PROCCESSING_TIME  + rand()%80 + OTHER_PROCESSES);

					//Wake up each node


	}

}
}


//____________________________Some Leds______________________________________


	event void Led0Timer.fired()
	{
		call Leds.led0Off();
	}
	event void Led1Timer.fired()
	{
		call Leds.led1Off();
	}
	event void Led2Timer.fired()
	{
		call Leds.led2Off();
	}


//_________________________________SerialReceive_____________________
	event message_t* SerialReceive.receive(message_t* msg , void* payload , uint8_t len)
	{
		// when receiving from serial port
		dbg("Serial","Received msg from serial port \n");

		return msg;
	}
}
