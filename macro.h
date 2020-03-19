inline uint16_t timer_period()
{
    if(TOS_NODE_ID == 1) return 1000;
    if(TOS_NODE_ID == 2) return 333;
    if(TOS_NODE_ID == 3) return 200;
    return 1000;
}