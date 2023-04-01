---@type number
icmp_client_state = 0
---@type number
icmp_client_wait_time = 0

---@param packet Packet
---@param own_address string
---@param destination_address string
---@return Packet | number | nil
function icmp_ping(packet, own_address, destination_address)
    if icmp_client_state == 0 then
        icmp_client_state = 1
        icmp_client_wait_time = 0
        return {
            src_addr = own_address,
            dest_addr = destination_address,
            src_port = 1,
            dest_port = 0,
            seq_nmb = 1,
            ack_nmb = 0,
            proto = 3,
            ttl = 63,
            data = "packet.data"
        }
    elseif icmp_client_state == 1 and icmp_client_wait_time < 60 then
        icmp_client_wait_time = icmp_client_wait_time + 1
        if packet.proto == 3 and packet.src_addr == destination_address and packet.dest_addr == own_address and packet.seq_nmb == 1 then
            icmp_client_state = 0
            return icmp_client_wait_time
        end
    else
        icmp_client_state = 0
    end
end
