#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	AM_SUMMSG=12,
	NEW_VALUE_TIMER=6000,
	EPOCH_DURATION=10000,
	ROUTING_TIME=5000,
	PROCCESSING_TIME=100,
	TIMER_LEDS_MILLI=1000,
	MAXIMUM_SENSORS=50,
	MAXIMUM_CHILDREN =10,
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/
typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;
} RoutingMsg;

typedef nx_struct AggrMessage
{
	nx_uint16_t senderID;
	nx_uint16_t parentID;
	nx_uint16_t product;
	nx_uint16_t sum;
	nx_uint16_t children ;
}  AggrMessage ;
typedef nx_struct Cache
{
	nx_uint16_t senderID;
	nx_uint16_t old_product;
	nx_uint16_t product;
	nx_uint16_t old_sum;
	nx_uint16_t sum;
	nx_uint8_t success;
	nx_uint16_t old_children ;
	nx_uint16_t children ;
}  Cache ;

#endif
