require('packet_queue')
require('dhcp_client')

---@param packet Packet
function respond_to_icmp(packet)
    if packet.src_port == 1 and packet.dest_addr == dhcp_last_address then
        receive_packet({
            src_addr = dhcp_last_address,
            dest_addr = packet.src_addr,
            src_port = 2,
            dest_port = 0,
            seq_nmb = packet.seq_nmb,
            ack_nmb = 0,
            proto = 3,
            ttl = 63,
            data = packet.data
        }, 0)
    end
end
