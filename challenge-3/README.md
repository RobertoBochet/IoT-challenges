# IoT - Challenge3

## Goal

Given a Wireshark session data `data.pcapng`, answer to some question concerning `CoAP` and `MQTT` protocols.

## Questions

### CoAP

#### 1) What’s the difference between the message with MID: 3978 and the one with MID: 22636?

**The package `3978` requires an ACK, the `22636` not.**

#### 2) Does the client receive the response of message No. 6949?

```
frame.number == 6949
```

With this we retrieve the message and get the request token `6f:b6:3c:18`.

```
coap.token == 6f:b6:3c:18
```

So we can find the response from the server. It is the message number `6953` and we can verify the success of the operation. The server responses with error `4.05 Method Not Allowed`.

**The client receive as response an error**

#### 3) How many replies of type `confirmable` and result code “Content” are received by the server “localhost”?

If the server receives a request for a data, but it is not ready or is required an ACK also from the client, then the server can response with an ACK, with code content `2.0.5`, and provides the content to the client in a confirmable packet. The token for all request's packets must have same `token`.

```
ip.dst == 127.0.0.1 && coap.code == 69 && coap.type == 0
```

Find the package to `127.0.0.1`, with code content `2.05` and of type `confirmable`.


**The answer is zero**

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

*n.b. some connections could be started from the same client*

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

*n.b. also if there were subscribers, set QoS to 2 doesn't guarantee that message is delivered to subscribers, but only to the broker*

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

The entire sniffing lasts `166s`.

```mqtt.msgtype == 1 && mqtt.kalive < 166```

With the filter and same manual filtering to remove packages where `frame.time + mqtt.kalive > 166` we find `28` new connections. These requires to contact the broker before the end of the sniffing to survive.

The mqtt protocol require that client must send to broker a `ping request` when it has passed the keep alive time by the last package exchanged with the broker. If it has passed 1.5 keep alive time, then the broker should disconnect the client.

**So, if those connections are closed before keep alive timer elapsed, or there is a exchange of message before client and broker no `ping request` is required.**