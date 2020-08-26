# IoT - Project

## Goal

Implement and showcase a network architecture similar to LoraWAN in TinyOS (or Contiki). The requirements of this project are:

1. Create a topology with 5 sensor nodes, 2 gateway nodes and one network server node.

1. Each sensor node periodically transmits (random) data (also random), which is received by one or more gateways. Gateways just forward the received data to the network server.

1. Network server keeps track of the data received by gateways, taking care of removing duplicates. An ACK message is sent back to the forwarding gateway, which in turn transmits it to the nodes. If a node does not receive an ACK within a 1 second window, the message is re-transmitted.

1. The network server node should be connected to Node-RED, and periodically transmit data from sensor nodes to Thingspeak (or another service of your choice) through MQTT.

1. Thingspeak (or the cloud service you use) must show at least two charts and one gauge.
