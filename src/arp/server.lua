require('dhcp_client')

---@param packet Packet
function respond_to_arp(packet)
    if packet.src_port == 1 and packet.data == dhcp_last_address then
        send_own_packet(packet.src_addr, 1, dhcp_last_address, 2)
    end
end