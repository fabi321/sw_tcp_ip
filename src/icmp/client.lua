require('util')
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
        send_own_packet(destination_address, 3, "packet.data", 1, 0, 1)
    elseif icmp_client_state == 1 and icmp_client_wait_time < TIMEOUT then
        icmp_client_wait_time = icmp_client_wait_time + 1
        if packet.proto == 3 and packet.src_addr == destination_address and packet.dest_addr == dhcp_last_address and packet.seq_nmb == 1 then
            icmp_client_state = 0
            return icmp_client_wait_time
        end
    else
        icmp_client_state = 0
    end
end
