require('util')

---@type table<string, number>
address_cache = {}

---@param packet Packet
---@param direction number
function arp_receive_packet(packet, direction)
    if packet.src_addr ~= broadcast_address then
        address_cache[packet.src_addr] = direction
    elseif packet.proto == 1 and packet.src_port == 1 and address_cache[packet.data] == nil then
        address_cache[packet.data] = -TIMEOUT
    end
end

function tick_arp_cache()
    for k, v in pairs(address_cache) do
        if v < 0 then
            v = v + 1
            if v == 0 then
                address_cache[k] = nil
            end
        end
    end
end

---@param packet Packet
---@return number
function get_direction_for_packet(packet)
    return address_cache[packet.dest_addr] or -1
end

