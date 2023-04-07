---@type table<string, string>
dns_server_entries = {}

---@param packet Packet
---@return Packet | nil
function respond_to_dns(packet)
    if packet.src_port == 1 then
        return --[[---@type Packet]] {
            src_addr = "ffff",
            dest_addr = packet.src_addr,
            src_port = 1,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 4,
            ttl = 255,
            data = dns_server_entries[packet.data]
        }
    elseif packet.src_port == 3 then
        dns_server_entries[packet.data] = packet.src_addr
    elseif packet.src_port == 4 then
        if packet.src_addr == dns_server_entries[packet.data] then
            dns_server_entries[packet.data] = nil
        end
    end
end
