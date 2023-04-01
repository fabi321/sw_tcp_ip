---@param packet Packet
---@param own_address string
---@return Packet | nil
function respond_to_icmp(packet, own_address)
    if packet.src_port == 1 and packet.dest_addr == own_address then
        return {
            src_addr = own_address,
            dest_addr = packet.src_addr,
            src_port = 2,
            dest_port = 0,
            seq_nmb = packet.seq_nmb,
            ack_nmb = 0,
            proto = 3,
            ttl = 63,
            data = packet.data
        }
    end
end
