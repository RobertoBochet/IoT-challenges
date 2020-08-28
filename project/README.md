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
- `msg_type`: Identify the type of message as defined in the `msg_type_t` type.
- `sensor_id`: It is the ID of the source sensor of the data of the target sensor of the ACK.
- `gateway_id`: If the packet is relayed specified the id of the gateway which relays it.
- `data_type`: In according to `data_type_t` type specifies the type of the data.
- `data`: It is the value of the sensor(`8bit`).

#### Sensor node

When the sensor boots a random period (between 4s and 20s) is chosen as time interval between two data. It is also set the data type.

When the timer elapsed a new package is forged and the sequential counter of the packet is incremented. When the packet is sent a second timer is been started with a duration of one second. If this second timer elapsed the packet is consider as lost and the packet is resent. The timer for the resend action is canceled if the correct ACK arrived or if a new data have to be transmitted.

The node ignore all the packets which are not an `ack` or an `ack_relayed` and the ack with a `sensor_id` different from its own.

#### Gateway

The gateways when a packet `sensor_data` or `ack` is arrived they relay it with the only changes of setting the `gateway_id` parameter and changing the `msg_type` in corresponding relayed type in order to avoid loop issue; a gateway will not relays a packet which are already relayed.

#### Network server

### Node red
