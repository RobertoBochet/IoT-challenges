# IoT - Challenge2

## Goal

2 wireless motes connected among themselves

The mote 1 sends a periodic request (**REQ**) to mote 2 every **1s**. When mote 1 receives an **ACK** it stops to send **REQ**.  
The mote 2 is waiting for **REQ**, when that arrives, it responses with an **ACK**, then it sends sensor's value within response message (**RESP**). The simulation ends when the **ACK** signal is received by the mote 2.

**REQ** contains message type (REQ) and an incremental counter.  
**RESP** contains message type (RESP), the counter received from mote 1 and the value of the sensor.