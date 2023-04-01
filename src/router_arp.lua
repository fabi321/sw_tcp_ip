---@type table<string, number>
address_cache = {}

---@param packet Packet
---@param direction number
function arp_receive_packet(packet, direction)
    if not packet.src_addr ~= "ffff" then
        address_cache[packet.src_addr] = direction
    end
end

---@param packet Packet
---@return number
function get_direction_for_packet(packet)
    return address_cache[packet.dest_addr] or -1
end

