# IoT - Challenge3

## Goal

Given a Wireshark session data `data.pcapng`, answer to some question concerning `CoAP` and `MQTT` protocols.

## Questions

### CoAP

### 1) What’s the difference between the message with MID: 3978 and the one with MID: 22636?

### 2) Does the client receive the response of message No. 6949?

### 3) How many replies of type confinable and result code “Content” are received by the server “localhost”?

### MQTT

#### 4) How many messages containing the topic “factory/department*/+” are published by a client with user name: “jane”?

Before to consider all the constraints we can try to find all mqtt packets matching `factory/department*/+` topic subscription. We can use the filter

```
mqtt.topic ~ "^factory\/department[0-9]+\/[^\/]+$"
```

`[^\/]+$` at the end guaranteed that the `+` mqtt one level operator is respected. 

We find out that there are not packet exchanged matching this pattern.

**The answer is zero**

### 5) How many clients connected to the broker “hivemq” have specified a will message?

### 6) How many publishes with QoS 1 don’t receive the ACK?

### 7) How many last will messages with QoS set to 0 are actually delivered?

### 8) Are all the messages with QoS > 0 published by the client “4m3DWYzWr40pce6OaBQAfk” correctly delivered to the subscribers?

### 9) What is the average message length of a connect msg using mqttv5 protocol? Why messages have different size?

### 10) Why there aren’t any REQ/RESP pings in the pcap?