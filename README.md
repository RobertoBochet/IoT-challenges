# IoT - Challenge1

## Goal

3 wireless motes connected among themselves

Each mote has a timer with its own frequency. At each timer trigger a message with a counter and own id is send.
When a message is come the counter is incremented and the LEDs status change according to following rules:

- message sent by mote 1 toggle led0
- message sent by mote 2 toggle led1
- message sent by mote 3 toggle led2
- message with `counter % 10 == 0` turn off all the LEDs