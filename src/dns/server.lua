require('dhcp_client')

---@type table<string, string>
dns_server_entries = {}

---@param packet Packet
function respond_to_dns(packet)
    if packet.src_port == 1 then
        send_own_packet(packet.src_addr, 4, dns_server_entries[packet.data], 1)
    elseif packet.src_port == 3 then
        dns_server_entries[packet.data] = packet.src_addr
    elseif packet.src_port == 4 then
        if packet.src_addr == dns_server_entries[packet.data] then
            dns_server_entries[packet.data] = nil
        end
    end
end
