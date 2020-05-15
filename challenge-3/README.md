# IoT - Challenge3

## Goal

Given a Wireshark session data `data.pcapng`, answer to some question concerning `CoAP` and `MQTT` protocols.

## Questions

### CoAP

#### 1) What’s the difference between the message with MID: 3978 and the one with MID: 22636?

#### 2) Does the client receive the response of message No. 6949?

#### 3) How many replies of type confinable and result code “Content” are received by the server “localhost”?

### MQTT

#### 4) How many messages containing the topic “factory/department*/+” are published by a client with user name: “jane”?

Before to consider all the constraints we can try to find all mqtt packets matching `factory/department*/+` topic subscription. We can use the filter

```
mqtt.topic ~ "^factory\/department[0-9]+\/[^\/]+$"
```

`[^\/]+$` at the end guaranteed that the `+` mqtt one level operator is respected. 

We find out that there are not packet exchanged matching this pattern.

**The answer is zero**

#### 5) How many clients connected to the broker “hivemq” have specified a will message?

First we need the ip of server `broker.hivemq.com`, we can retrieve it exploit dns response

```
dns.a && dns.qry.name == "broker.hivemq.com"
```

We consider only ipv4 response and find two ip `18.185.199.22` and `3.120.68.56`.
Now, we can find the connections with `will flag` set that were sent to one of them ip.

```
(ip.dst == 18.185.199.22 || ip.dst == 3.120.68.56) && mqtt.conflag.willflag == 1 
```

So, we find 16 connections messages.

*NB. We can notice that some connections are probably started from the same client*

**The answer is 16**

#### 6) How many publishes with QoS 1 don’t receive the ACK?

In a publish message packets, the `DUP flag` is set only if the package is already sent and the current one is a resend attempt in consequence to not received `ACK`. 
So, we need to get only publish message with `QoS` equal to 1 and `DUP flag` set.

```
mqtt.msgtype == 3 && mqtt.qos == 1 && mqtt.dupflag == 1
```

**The answer is 2**

#### 7) How many last will messages with QoS set to 0 are actually delivered?

Since, QoS is equal 0 (at most once) is impossible to determinate if a message is delivered.

**The answer is that is unverifiable**

#### 8) Are all the messages with QoS > 0 published by the client “4m3DWYzWr40pce6OaBQAfk” correctly delivered to the subscribers?

```
mqtt.clientid == "4m3DWYzWr40pce6OaBQAfk"
```

We find the connection package, from it we can find out that the session is not persistent and retrieve the two end points, client `10.0.2.15:58313` and server `5.196.95.208:1883` which identify the TCP connection, Wireshark gives to this connection the stream index `67`.

```
tcp.stream == 67 && ip.src == 10.0.2.15 && mqtt.msgtype == 3 && mqtt.qos > 0
```

For this connection we find only one publish message with a QoS greater than 0 published by client. This message is published with retain unset and QoS of 2, we can also retrieve the message id `3`.

```
tcp.stream == 67 && mqtt.msgid == 3
```

The broker responded with a publish received, so we can be sure that it received the message.

```
mqtt.topic == "factory/department1/section1/deposit"
```

Set the ref time and masks we can easily find out that there are not subscribers to that topic at the moment when the client publish the message.

**There are not subscribers to whom delivery the messages**

#### 9) What is the average message length of a connect msg using mqttv5 protocol? Why messages have different size?

Message length in mqtt packet is expressed in the fixed header after the flags with a codification from 1 to 4 bytes, it indicates the remaining number of bytes of the packet (variable header plus payload).

The first bytes after the fixed header composing the variable header and for the mqttv5 connect message has a fixed length of 10 bytes.

The remaining bytes composing the **payload that has a variable length**. It must contain a variable length `client ID` and can contain some property (e.g. will parameters, authentication data).

```
mqtt.msgtype == 1  && mqtt.ver == 5
```

So we select only mqtt connect packages of version 5. With a fast calculation, we find the average message length.

**The answer is 30 bytes**

#### 10) Why there aren't any REQ/RESP pings in the `pcap`?