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
 - Byte 10: Length (in bytes)
 - Byte 11: Reserved for future use

Address `ffff` is reserved as broadcast.
Address `0000` is preferably used for the DNS server, but not technically restricted to it.
DHCP will only assign addresses between (including) `1000` and `fffe`.


### ARP

Protocol id 1

 - source port used for type
 - Used to prime all switches
 - Used as a crappy DHCP

| Id | Name                |
|----|---------------------|
| 1  | Who has \<Address\> |
| 2  | I have \<Address\>  |

### TCP

Protocol id 2

If TCP has broadcast as destination, there will be no sequence numbers and acknowledgement numbers

 - Works similar to real TCP
 - retransmits are handled on a hop-by-hop basis

### ICMP

Protocol id 3

 - source port used for type
 - for ping: sequence number is returned as is

| Id | Name         |
|----|--------------|
| 0  | Ping reply   |
| 1  | Ping request |

### DNS

Protocol id 4
 - source port used for type/request/response
 - Names are limited to 20 characters. There are no domains available

| Id | Name                             | Notes                                                               |
|----|----------------------------------|---------------------------------------------------------------------|
| 0  | what is the address for {name}   |                                                                     |
| 1  | the address for ... is {address} | Name is not referred again. need to remember the sequence id        |
| 2  | I want to register {name}        | The address that name is to be registered to is the {src_addr}      |
| 3  | I want to unregister {name}      | The address that was assigned with {name} has to be the own address |
