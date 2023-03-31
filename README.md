# Stormworks TCP/IP implementation

## Getting started

First of all, create a venv.

```shell
python3 -m virtualenv --creator venv .venv
. .venv/bin/activate
pip install -U -r requirements.txt
```

Compiling all the batches into a single file can be done by running

```shell
python compiler.py
```

This will result in a complete microcontroller in the file `train_controller.xml`

## Protocol

Each packet can use a total of 8 number channels.

 - Bytes 0 - 1: Source address
 - Bytes 2 - 3: Destination address
 - Byte 4: Source port
 - Byte 5: Destination port
 - Byte 6: Sequence number
 - Byte 7: Acknowledgement number
 - Byte 8: Protocol
 - Byte 9: TTL
 - Byte 10 - 11: Reserved for future use

Address `ffff` is reserved as broadcast


### ARP

Protocol id 1

 - Ignores ports, sequence and acknowledgement numbers
 - Used to prime all switches
 - Used as a crappy DHCP

### TCP

Protocol id 2

If TCP has broadcast as destination, there will be no sequence numbers and acknowledgement numbers

 - Works similar to real TCP
 - retransmits are handled on a hop-by-hop basis

### ICMP

Protocol id 3

 - source port used for type

| Id | Name         |
|----|--------------|
| 0  | Ping reply   |
| 1  | Ping request |

