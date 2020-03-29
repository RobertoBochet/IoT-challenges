# IoT - Challenge2

## Goal

2 wireless motes connected among themselves

The mote 1 sends a periodic request (**REQ**) to mote 2 every **1s**. When mote 1 receives an **ACK** it stops to send **REQ**.  
The mote 2 is waiting for **REQ**, when that arrives, it responses with an **ACK**, then it sends sensor's value within response message (**RESP**). The simulation ends when the **ACK** signal is received by the mote 2.

**REQ** contains message type (REQ) and an incremental counter.  
**RESP** contains message type (RESP), the counter received from mote 1 and the value of the sensor.

## Code

Mote #1, which sends request will be called `MOTE_REQ` and mote #2, which responds with the sensor value will be called `MOTE_RESP`.

### Initialization

After the boot the mote initializes the AM controller, the mote tries to start AM control until it starts with success. Then, the mote begins its work.

The mote `MOTE_REQ` starts the periodic timer with a period of `1s`.
When the timer elapsed `MOTE_REQ` increments the counter and sends a request to the mote `MOTE_RESP` using `sendMessage` function.

### Request sent

When the request message is sent, the `MOTE_REQ` checks if the `MOTE_RESP` responded to the request with an ACK signal.  
If an ACK was arrived, the `MOTE_REQ` stops its periodic timer.

### Response

When a request arrives to `MOTE_RESP` the counter is stored and a reading of sensor value is started.  
When the reading is ready a new response message is sent with the function `sendMessage` to the `MOTE_REQ`. If the ACK signal return to `MOTE_RESP`, the mote schedules itself shutdown within `1s` with `PendingShutdownTimer`.

### ACK on response message

The `MOTE_REQ` waiting for the response from `MOTE_RESP`, when it arrives the mote schedules itself shutdown within `1s` with `PendingShutdownTimer`.

### `PendingShutdownTimer` elapsed

When the timer elapsed the `shutdown` function is called.  
The delayed shutdown is required to guaranteed that ACK signals are sent before shutdown.

### Functions

#### `sendMessage`

```C
void sendMessage(am_addr_t _dest, uint8_t _type, uint16_t _counter, uint16_t _data)
```

The function takes in, the target of the message (`_dest`), the type of the message between `MSG_TYPE_REQ` or `MSG_TYPE_RESP` (`_type`), the current counter (`_counter`) and the sensor's value if `_type==MSG_TYPE_RESP` (`_data`).  
The function forges the message packet in according to the input; set the packet to request an ACK response (with `PacketAcknowledgements` interface) and schedules the sent of the message.

#### `shutdown`

```C
void shutdown()
```

It stops the `SplitControl` interface. 