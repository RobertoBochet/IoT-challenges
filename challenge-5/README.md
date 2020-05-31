# IoT - Challenge5

## Goal

3 wireless motes connected among themselves

The motes 2 and 3, with a frequency of one message each 5 seconds, send a random value to mote 1.  
The mote 1 waits for a message, when one arrives it send this to **Node RED**, where a flow update with the value two different graph on **thingspeak**, filtered out the values bigger than `70`.

## Implementation

### TinyOS

Each time that **mote 1** receives a message, it prints a new string with the following format.

```
{sender_id}:{value}\n
```

### Node RED

The messages are received with a TCP connection to **Cooja**.

As first thing, the message is parsed with the regex `^([0-9]+):([0-9]{1,3})$` to extract the *mote_id* and the *value*.

All the values bigger than `70` are filtered out. Then, the *mote_id* is associated to a **thingspeak** field.

To prevent the saturation of **thingspeak** available broadband (**thingspeak** accept at most one message every `15s`) a rate limiter is introduced.
The chosen policy is to send a message each `20s` including only the last value received for field.

Finally the mqtt package is created and sent to **thingspeak** mqtt broker.