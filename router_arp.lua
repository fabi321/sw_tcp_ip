---@type table<string, boolean>
ignored_addresses = {["ffff"] = true, ["fffe"] = true, ["0000"] = true}

---@type table<string, number>
address_cache = {}

---@param packet Packet
---@param direction number
function arp_receive_packet(packet, direction)
    if not ignored_addresses[packet.src_addr] then
        address_cache[packet.src_addr] = direction
    end
end

---@param packet Packet
---@return number
function get_direction_for_packet(packet)
    return address_cache[packet.dest_addr] or -1
end

