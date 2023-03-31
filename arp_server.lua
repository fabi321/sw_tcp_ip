---@param packet Packet
---@param own_address string
---@return Packet
function respond_to_arp(packet, own_address)
    return {
        src_addr = own_address,
        dest_addr = packet.src_addr,
        src_port = 0,
        dest_port = 0,
        seq_nmb = 0,
        ack_nmb = 0,
        proto = 1,
        ttl = 255,
        data = packet.data
    }
end