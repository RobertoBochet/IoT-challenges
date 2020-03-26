# IoT - Challenge1

## Goal

3 wireless motes connected among themselves

Each mote has a timer with its own frequency. When the timer expires, a message with a counter and own id is send. 
When a message arrives the counter is incremented and the LEDs status change according to following rules:

- message sent by mote 1 toggle led0
- message sent by mote 2 toggle led1
- message sent by mote 3 toggle led2
- message with `counter % 10 == 0` turn off all the LEDs

## Code

### Message

The payload packet `custom_message_t` exchanged by motes is composed by the id of the sender and the counter of the sender.

### State of mote

Each mote has a buffer of one packet `packet` and a 16bit counter `counter`. The buffer has a state `is_buffer_empty`.

### Initialization

After the boot the mote initializes the AM controller, the mote tries to start AM control until it starts with success. Then, the timer is initialized and the mote begins its work.  
The timer period is got from `timer_period` inline function based on the `TOS_NODE_ID`.

### Timer expiration

When the timer expires the event `fired` will be occurred.  
The first check is on the buffer status, if it is not empty the event is skipped.  
The packet is populated and it tries to sent it. If the module accept to send the packet the buffer state is set to not empty.  
When the transmission is done the buffer state is set to empty.

### Message income

When a new message is come a check over its payload size is done.  
The counter is incremented, and the desiderated behaviour is implemented:  
If `counter % 10 == 0` all the LEDs are turned off, else the LEDs are toogled by the rules.

## Critical issues

### Limited buffer

```C
if(!is_buffer_empty) return;
```

If the timer is triggered before the previous packet is sent, the current packet is not sent.

#### Possible solution/workaround

You might enlarge the buffer size, or in a better way, with a RT kernel you could study the problem as a scheduling one.

### Indeterministic packet creation

```C
cm = (cus...e_t*) call Packet.getPayload(&packet, sizeof(cus...e_t));
if(cm == NULL) return;
```

The process to create a new packet could fail if the payload size is too big, in this case the current timer's trigger will be ignored.  
If there is no memory segmentation it is reasonable to expect this does not happen.

### Indeterministic sending packages

In the sending operation the controller might fail and the package is lost.

### Packet validation

```C
if (len == sizeof(custom_message_t))
```

The check of the size of the incoming packets payload is a trivial control, so it might be substituted by a more sophisticated one.

#### Possible solution/workaround

You could add a payload fingerprint to the message and do some checks on that.