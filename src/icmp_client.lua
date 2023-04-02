require('packet_queue')
require('dhcp_client')

---@type number
icmp_client_state = 0
---@type number
icmp_client_wait_time = 0

---@param packet Packet
---@param destination_address string
---@return number | nil
function icmp_ping(packet, destination_address)
    if icmp_client_state == 0 then
        icmp_client_state = 1
        icmp_client_wait_time = 0
        receive_packet({
            src_addr = dhcp_last_address,
            dest_addr = destination_address,
            src_port = 1,
            dest_port = 0,
            seq_nmb = 1,
            ack_nmb = 0,
            proto = 3,
            ttl = 63,
            data = "packet.data"
        }, 0)
    elseif icmp_client_state == 1 and icmp_client_wait_time < 60 then
        icmp_client_wait_time = icmp_client_wait_time + 1
        if packet.proto == 3 and packet.src_addr == destination_address and packet.dest_addr == dhcp_last_address and packet.seq_nmb == 1 then
            icmp_client_state = 0
            return icmp_client_wait_time
        end
    else
        icmp_client_state = 0
    end
end
