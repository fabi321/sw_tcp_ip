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

### About the way that the protocols are butchered

Most of the documentation is to be read as a diff opposed to what the standards usually are.

Addresses are a mixture of MAC- and IP-Addresses. There are no statically assigned addresses, but there is no routing.
They are assigned using DHCP, but it is closer to the IPv6 autoconfiguration than to DHCP, in that there is no server.
Clients are identifying as broadcast during the initialisation. ARP is not used to get IP to MAC address mappings, but
rather used to discover what addresses are in use.

While I do call the central connection points `router`, this is mostly done to not confuse the average user as much.
Since there is no routing taking place, `switch` would be a more appropriate name for them.
They have no own address, and all they are doing is effectively having an arp cache, that they use to identify, where
to send packets to.

### [ARP](https://en.wikipedia.org/wiki/Address_Resolution_Protocol)

Protocol id 1

 - source port used for type
 - Used to prime all switches
 - Used as a crappy DHCP
 - For DHCP: Cache all requests with id 1, as they might be ongoing DHCP connection attempts

| Id | Name                                       |
|----|--------------------------------------------|
| 1  | Who has {address}                          |
| 2  | I have {address}                           |

### [TCP](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)

Protocol id 2

If TCP has broadcast as destination, there will be no sequence numbers and acknowledgement numbers

 - Works similar to real TCP
 - retransmits are handled on a hop-by-hop basis

### [ICMP](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol)

Protocol id 3

 - source port used for type
 - for ping: sequence number is returned as is

| Id | Name         |
|----|--------------|
| 0  | Ping reply   |
| 1  | Ping request |

### [DNS](https://en.wikipedia.org/wiki/Domain_Name_System)

Protocol id 4
 - source port used for type/request/response
 - Names are limited to 20 characters. There are no domains available

| Id | Name                             | Notes                                                               |
|----|----------------------------------|---------------------------------------------------------------------|
| 0  | what is the address for {name}   |                                                                     |
| 1  | the address for ... is {address} | Name is not referred again. need to remember the sequence id        |
| 2  | I want to register {name}        | The address that name is to be registered to is the {src_addr}      |
| 3  | I want to unregister {name}      | The address that was assigned with {name} has to be the own address |
