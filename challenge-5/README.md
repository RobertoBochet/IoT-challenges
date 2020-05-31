# IoT - Challenge5

## Goal

3 wireless motes connected among themselves

The motes 2 and 3, with a frequency of one message each 5 seconds, send a random value to mote 1.  
The mote 1 waits for a message, when one arrives it send this to **node red**, where a flow update with the value two different graph on **thingspeak**.
