require('dhcp_client')

---@param packet Packet
function respond_to_icmp(packet)
    if packet.src_port == 1 and packet.dest_addr == dhcp_last_address then
        send_own_packet(packet.src_addr, 3, packet.data, 2, 0, packet.seq_nmb)
    end
end
