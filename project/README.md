# IoT - Project

## Goal

Implement and showcase a network architecture similar to `LoraWAN` in `TinyOS` (or `Contiki`). The requirements of this project are:

1. Create a topology with 5 sensor nodes, 2 gateway nodes and one network server node.

1. Each sensor node periodically transmits (random) data (also random), which is received by one or more gateways. Gateways just forward the received data to the network server.

1. Network server keeps track of the data received by gateways, taking care of removing duplicates. An ACK message is sent back to the forwarding gateway, which in turn transmits it to the nodes. If a node does not receive an ACK within a 1 second window, the message is re-transmitted.

1. The network server node should be connected to `Node-RED`, and periodically transmit data from sensor nodes to `Thingspeak` (or another service of your choice) through `MQTT`.

1. `Thingspeak` (or the cloud service you use) must show at least two charts and one gauge.

## Implementation

### Network

The motes' software was developed with `TinyOS`. Three types of firmware have been developed for the three types of node.

#### Custom message

The nodes communicate with a custom message, which is used both for data transmission and ACK. The message is composed as following:

- `msg_id`: An incremental number to identify the single connection (data from sensor and the relative ACK from NS share the same id). This parameter is used to delete the duplicate data received by NS and to identify which packet corresponds to the ACK.
- `msg_type`: Identifies the type of message as defined in the `msg_type_t` type,
    - bit `0`: Indicates the packet type (`0b0`: sensor data; `0b1`: ack)
    - bit `1`: Indicates if the packet has been relayed (`0b0`: not relayed; `0b1`: relayed).
- `sensor_id`: It is the ID of the source sensor of the data of the target sensor of the ACK.
- `data_type`: In according to `data_type_t` type specifies the type of the data.
- `data`: It is the value of the sensor(`8bit`).

#### Sensor node

When the sensor boots a random period (between `4s` and `20s`) is chosen as time interval between two data. The data type is also set.

When the timer elapses a new package is forged and the packets' sequential counter is incremented. When the packet is sent a second timer starts with a duration of one second. If this second timer elapses the packet is considered lost and it is resent. The timer for the resend action is canceled if the correct ACK arrives or if new data have to be transmitted.

The node ignores all the packets which are neither an `ack` nor an `ack_relayed` and the ack with a `sensor_id` different from its own.

#### Gateway

When a packet `sensor_data` or `ack` arrives to a gateway this relays it, with the only change of setting of the packet's `relayed` bit, in order to avoid loop issues; a gateway will not relay a packet which has already been relayed.

#### Network server

The network server waits for `sensor_data` packets (also for the relayed version), when one of them arrives a special message is sent through the serial. The message has the following structure `#{msg_id}:{sensor_id}:{data_type}:{data}#`. Then an ACK packet is populated with the same `msg_id` and `sensor_id` and it is sent.

### Node-red

`Node-RED` is connected to the network server with a serial connection. Through the serial connection both log and data messages are provided to `Node-RED` so the first operation consists in filtering out all the messages which do not have the structure of the data message. This is done with a regex pattern `^#(\d+):(\d+):(\d+):(\d+)#$`.

It can happen that a duplicate message reaches the network server as a result of a network error, so a block from `node-red-contrib-deduplicate` is used to remove the duplicated messages.

The messages are parsed with the same regex that was seen above.

The data values provided by the network are all unsigned integer of `8bit`, so a linear transformation is applied to get the data values in the SI.

The useless data are removed from the messages and the payload becomes an array with the `data_type` element set to the data value.

Because of the rate limit of `15s` between two updates imposed by `ThingSpeak`, all the messages received within a timeframe of `20s` are merged and an average is calculated for the same type of data.

To conclude the `data_type` are remapped to the relative `ThingSpeak` field and sent through `MQTT` to the `ThingSpeak` [channel](https://thingspeak.com/channels/1126451).

## Additional notes

### One-hope delivery

Even if it is not required in the proposed scenario, the direct communication between the sensors and the network server is possible without any source code modification.

### Gateway one-hope relay only

In order to extend the network structure, it is useful to notice that the gateways with this implementation can handle only a one-hope relay (`S->G->N` is possible but not `S->G->G->N`). To implement this behavior a loop avoidance algorithm should be introduced.

### Several `buffer not empty` error

If it is simulated, this scenario will generate several errors of this type, particularly from the network server. This happens because the sensor nodes `2` and `4` have multiple paths to reach the network server, so the same packet is delivered from both gateways at the same time then due to the limited buffer of one packet of the network server only one ACK is sent with success.

To solve this issue, it would be sufficient to implement a transmission buffer in the network server with a circular buffer. The same approach can be adopted with the gateways to improve the reliability of the network.

### Limit of one sensor data

As implementation choice in the case a node has new data ready but it has not already received the ACK related to the previous packet, it will discard the old data and when the resend timer elapses it will not retry to send it. This behavior implies a possibility loss of data.

To reduce the possibility of data loss, a transmission buffer can be implemented: however one needs to consider implementing a behavior to avoid the buffer saturation with the possible consequence of new-data loss.

### Messages deduplication

The deduplication of the messages is handled by `Node-RED` for several reasons. The deduplication can be implemented directly in `TinyOS` mainly in two ways.

A simple way can be with a fixed dimension array, whose size must be greater than the motes' number. For each mote the last received `msg_id` is conserved in order to remove the future duplicates. This approach requires the knowledge of the maximum number of motes at compile time, with the side effect of inhibiting an easy scale of the network dimension.

Another approach can be to use a dynamical data structure, but in small devices this can introduce memory issues which must be handled.

However, both these methods present a defect: If for any reason two packets from the same sensor arrive in a different order than that of sending the oldest one will be ignored by the network server.

With the use of the block on `Node-RED` (which is supposed to be running with many more available resources than those of a mote) also this behavior is handled.

### Header compression

In order to reduce the overhead of the transmitted packets the header can be compressed giving less than a word(`8bit`) for a single property. The current dimension of the custom message is `40bit`, which can be reduced by merging some properties by the use of bitmap. `msg_type` and `data_type` require only `2bit` each, so they can be merged in the same word with `4bit` of padding and the new message size  will become `32bit`. Moreover the `msg_id` can be reduced by taking into account the time window of the deduplication block and the maximum frequency of the sensor. If the dimension of the network is known a priori the `sensor_id` size can also be reduced.

In our scenario a possible choice for the packet size could be `6bit` for `msg_id`, `6bit` for `sensor_id`, `2bit` for `msg_type`, `2bit` for `data_type` and `8bit` for `data`, with a packet of `24bit`.