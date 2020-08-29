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

The motes' software was developed with `TinyOS`. Three type of firmware were been developed for the three types of node.

#### Custom message

The nodes communicate with a custom message, which is used both for data transmission and ACK. The message is composed as following:

- `msg_id`: An incremental number to identify the single connection (data from sensor and the relative ACK form NS share the same id). This parameter is used to delete the duplicate data received by NS and to identify to which packet corresponds the ACK.
- `msg_type`: Identify the type of message as defined in the `msg_type_t` type,
    - bit `0`: Indicates the type of packet (`0b0`: sensor data; `0b1`: ack)
    - bit `1`: Indicates if the packed was been relayed (`0b0`: not relayed; `0b1`: relayed).
- `sensor_id`: It is the ID of the source sensor of the data of the target sensor of the ACK.
- `data_type`: In according to `data_type_t` type specifies the type of the data.
- `data`: It is the value of the sensor(`8bit`).

#### Sensor node

When the sensor boots a random period (between 4s and 20s) is chosen as time interval between two data. It is also set the data type.

When the timer elapsed a new package is forged and the sequential counter of the packet is incremented. When the packet is sent a second timer is been started with a duration of one second. If this second timer elapsed the packet is consider as lost and the packet is resent. The timer for the resend action is canceled if the correct ACK arrived or if a new data have to be transmitted.

The node ignore all the packets which are not an `ack` or an `ack_relayed` and the ack with a `sensor_id` different from its own.

#### Gateway

When a packet `sensor_data` or `ack` arrived to a gateway this relays it, with the only changes of setting the `relayed` bit of the `msg_type` property in order to avoid loop issue; a gateway will not relays a packet which is already relayed.

#### Network server

The network server waiting for `sensor_data` packets (also for the relayed version), when one of them arrived a special message is sent through the serial. The message has the following structure `#{msg_id}:{sensor_id}:{data_type}:{data}#`. Then an ACK packet is populated with the same `msg_id` and `sensor_id` and it is sent.

### Node-red

`Node-RED` is connected to the network server with an serial connection. Through the serial connection both log and data messages are provided to `Node-RED` so the first operation consists to filter all the messages which have not the structure of the data message, this is done with a regex pattern `^#(\d+):(\d+):(\d+):(\d+)#$`.

It can be happened that a duplicate messages reach the network server as a result of a network error, so a block from `node-red-contrib-deduplicate` is used to remove the duplicated messages.

The messages are parsed with the same regex that was seen above.

The data values provided by the network are all unsigned int of 8bit, so it is applied a linear transformation to get the data values in the SI.

The useless data are removed from the messages and the payload becomes an array with the `data_type` element set to the data value.

Because of the rate limit of `15s` between two updates imposed of `ThingSpeak` all the messages received in a window of `20s` are merged and for the same data type an average is calculated.

To conclude the data_type are remapped to the relative `ThingSpeak` field, and sent though `MQTT` to `ThingSpeak` [channel](https://thingspeak.com/channels/1126451).

## Additional notes

### One-hope delivery

Also if in the proposed scenario is not required, without any modification of the code the direct communication between sensor and network server is possible.

### Gateway one-hope relay only

In order to extend the network structure it is useful notice that the gateways whit this implementation can handle only a relay of one hope (`S->G->N` is possible but not `S->G->G->N`) to implement this behavior should be introduced an loop avoidance algorithm.

### Several `buffer not empty` error

If it is simulated, this scenario will generated several errors of this type, in particular from the network server. This happened because the sensor nodes `2` and `4` has multiple path to reach the network server, so the same packet is delivered from both the gateways at the same time and because of the limited buffer of one packet of the network server only one ACK is sent with success.

To solve this issue would be sufficient to implement a transmission buffer in the network server with a circular buffer. The same approach that can be adopted with the gateway to improve the reliability of the network.

### Messages deduplication

The deduplication of the messages is handle from `Node-RED` for some reasons. The deduplication can be implemented directly in `TinyOS` mainly in two ways.

A simple way can be with an array with fixed dimension, that been grater than the motes' number, for each mote the last received `msg_id` is conserved in order to remove the future duplicate. This approach required to know the max number of motes at compile time inhibits a easy scale of the sensors number.

Another approach can be used a dynamical data structure, but in small devices can be introduced memory issues which must to be handled.

Any way both this method presenting a defect: If for any reason two packets from the same sensor arrived in a different order than that of sending the oldest one will be ignored by the network server.

With the use of the block on `Node-RED` (which is supposed running with many more available resources than which of the mote) also this behavior is handled.