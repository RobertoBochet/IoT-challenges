# IoT - Challenge3

## Goal

Given a Wireshark session data `data.pcapng`, answer to some question concerning `CoAP` and `MQTT` protocols.

## CoAP

- What’s the difference between the message with MID: 3978 and the one with MID: 22636?

- Does the client receive the response of message No. 6949?

- How many replies of type confinable and result code “Content” are received by the server “localhost”?

## MQTT

- How many messages containing the topic “factory/department*/+” are published by a client with user name: “jane”?

- How many clients connected to the broker “hivemq” have specified a will message?

- How many publishes with QoS 1 don’t receive the ACK?

- How many last will messages with QoS set to 0 are actually delivered?

- Are all the messages with QoS > 0 published by the client “4m3DWYzWr40pce6OaBQAfk” correctly delivered to the subscribers?

- What is the average message length of a connect msg using mqttv5 protocol? Why messages have different size?

- Why there aren’t any REQ/RESP pings in the pcap?