require('util')

---@type number
icmp_client_state = 0
---@type number
icmp_client_wait_time = 0

---@param packet Packet
---@param destination_address string
---@return number | Packet | nil
function icmp_ping(packet, destination_address)
    if icmp_client_state == 0 then
        icmp_client_state = 1
        icmp_client_wait_time = 0
        return --[[---@type Packet]] {
            src_addr = "ffff",
            dest_addr = destination_address,
            src_port = 1,
            dest_port = 0,
            seq_nmb = 1,
            ack_nmb = 0,
            proto = 3,
            ttl = 255,
            data = "packet.data"
        }
    elseif icmp_client_state == 1 and icmp_client_wait_time < TIMEOUT then
        icmp_client_wait_time = icmp_client_wait_time + 1
        if packet.proto == 3 and packet.src_addr == destination_address and packet.src_port == 2 then
            icmp_client_state = 0
            return icmp_client_wait_time
        end
    else
        icmp_client_state = 0
        return -1
    end
end
