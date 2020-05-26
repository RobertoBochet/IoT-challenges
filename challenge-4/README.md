# IoT - Challenge4

## Goal

Given a subset of the packages of the challenge 3 in the form of csv file, send the field `value` of some `MQTT` `publish` messages to a ThingSpeak channel, in according to following rules:

- topics `factory/department1/section1/plc` and `factory/department3/section3/plc` to `field1`
- topics `factory/department1/section1/hydraulic_valve` and `factory/department3/section3/hydraulic_valve` to `field2`
