---@param packet Packet
---@param own_address string
---@return Packet | nil
function respond_to_arp(packet, own_address)
    if packet.src_port == 1 and packet.data == own_address then
        return {
            src_addr = own_address,
            dest_addr = packet.src_addr,
            src_port = 2,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 63,
            data = own_address
        }
    end
end