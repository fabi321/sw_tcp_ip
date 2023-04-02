require('util')
require('router_arp')
require('packeting')

---@type table<number, {retry_time: number, retry_count: number, packet: Packet, destination: number}
packet_queue = {}
---@type number
newest_packet = 1

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
    if stored >= 10 then
        -- Drop the packet if the destination is congested
        return
    end
    if packet.dest_addr ~= broadcast_address then
        ---@type number
        local destination = get_direction_for_packet(packet)
        if destination == -1 then
            -- Drop the packet if the destination couldn't be found in arp
            return
        end
        packet_queue[newest_packet] = --[[---@type {retry_time: number, retry_count: number, packet: Packet, destination: number}]] {
            retry_time = 0,
            retry_count = 0,
            packet = packet,
            destination = destination
        }
        newest_packet = newest_packet + 1
    else
        for i=1,4 do
            if i ~= direction then
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
