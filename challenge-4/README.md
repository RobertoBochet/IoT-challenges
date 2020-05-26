# IoT - Challenge4

## Goal

Given a subset of the packages of the challenge 3 in the form of csv file, send the field `value` of some `MQTT` `publish` messages to a ThingSpeak channel, in according to following rules:

- topics `factory/department1/section1/plc` and `factory/department3/section3/plc` to `field1`
- topics `factory/department1/section1/hydraulic_valve` and `factory/department3/section3/hydraulic_valve` to `field2`

## Code

### File parse

```regexp
^([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +(.+)$
```

With this regex is possible to split each column of the file's row.

### Filtering

With the filter blocks, we select only the rows that contains an `MQTT` `publish message`.

### Content parsing

```regexp
Publish Message (?:\(id=\d+\) )?\[([\w\d/]+)\]```
```

```regexp
 ((?:[a-z0-9]+,)*[a-z0-9]+)$
```

With these two regex we can divide header and content payload.

### Final conversions

 The rows can contain multiple publish messages, and for this reason these are split.
 
 The researched topics are filtered and merged.
 
 After the hex decoding and json parsing, the value is sent to the thingspeak channel exploiting MQTT.