require('packet_queue')
require('dhcp_client')

---@param packet Packet
function respond_to_arp(packet)
    if packet.src_port == 1 and packet.data == dhcp_last_address then
        receive_packet({
            src_addr = dhcp_last_address,
            dest_addr = packet.src_addr,
            src_port = 2,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 63,
            data = dhcp_last_address
        }, 0)
    end
end