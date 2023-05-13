require('util')
require('arp/router')
require('packeting')

---@type table<number, {retry_time: number, retry_count: number, packet: Packet, destination: number}>
packet_queue = {}
---@type table<string, {retry_time: number, retry_count: number}>
arp_lookup = {}
---@type number
newest_packet = 1
--- Sends all broadcast packets from direction 1 back to direction 1, too
---@type boolean
is_wifi = false
--- Largest interface id
---@type number
largest_interface_id = 4

---@param packet Packet
---@param direction number
function receive_packet(packet, direction)
    arp_receive_packet(packet, direction)
    ---@type number
    local stored = 0
    for _, p in pairs(packet_queue) do
        if packet.dest_addr == p.packet.dest_addr then
            stored = stored + 1
        end
    end
    if packet.proto == 1 and packet.src_port == 2 then
        for k, _ in pairs(arp_lookup) do
            if packet.src_addr == k then
                arp_lookup[k] = nil
                for _, p in pairs(packet_queue) do
                    if p.packet.dest_addr == packet.src_addr then
                        p.destination = direction
                    end
                end
            end
        end
    end
    if stored >= 10 then
        -- Drop the packet if the destination is congested
        return
    end
    if packet.dest_addr ~= broadcast_address then
        ---@type number
        local destination = get_direction_for_packet(packet)
        if destination < 0 then
            -- Try to look the address up
            if not arp_lookup[packet.dest_addr] then
                arp_lookup[packet.dest_addr] = {
                    retry_time = 0,
                    retry_count = 0
                }
            end
        end
        packet_queue[newest_packet] = --[[---@type {retry_time: number, retry_count: number, packet: Packet, destination: number}]] {
            retry_time = 0,
            retry_count = 0,
            packet = packet,
            destination = destination
        }
        newest_packet = newest_packet + 1
    else
        for i = 1, largest_interface_id do
            if i ~= direction or i == 1 and is_wifi then
                packet_queue[newest_packet] = {
                    retry_time = 0,
                    retry_count = 0,
                    packet = packet,
                    destination = i
                }
                newest_packet = newest_packet + 1
            end
        end
    end
    if packet.proto == 2 and packet.ack_nmb ~= 0 then
        for k, p in pairs(packet_queue) do
            if (
                    p.packet.dest_addr == packet.src_addr
                    and p.packet.src_addr == packet.dest_addr
                    and p.packet.seq_nmb == packet.ack_nmb
                    and p.packet.proto == 2
                ) then
                packet_queue[k] = nil
            end
        end
    end
end

function tick_packet_queue()
    for _, p in pairs(packet_queue) do
        p.retry_time = math.max(0, p.retry_time - 1)
    end
    for k, v in pairs(arp_lookup) do
        v.retry_time = math.max(0, v.retry_time - 1)
        if v.retry_time == 0 then
            send_own_packet(broadcast_address, 1, k, 1)
            v.retry_count = v.retry_count + 1
            v.retry_time = TIMEOUT
            if v.retry_count > 5 then
                arp_lookup[k] = nil
            end
        end
    end
end

---@param direction number
---@return Packet | nil
function send_packet(direction)
    for k, p in pairs(packet_queue) do
        if p.retry_time == 0 and direction == p.destination then
            if p.packet.proto == 2 then
                p.retry_time = 20
                p.retry_count = p.retry_count + 1
                if p.retry_count >= 5 then
                    packet_queue[k] = nil
                end
            else
                packet_queue[k] = nil
            end
            return p.packet
        end
    end
end
