require('packeting')
require('packet_queue')

function onTick()
    for i=1,32 do
        sn(i, 0)
    end
    for i=1,4 do
        local packet = to_packet(i * 8 - 7)
        if packet.ttl > 0 then
            receive_packet(packet, i)
        end
    end
    tick_packet_queue()
    for i=1,4 do
        local packet = send_packet(i)
        if packet ~= nil then
            to_channels(packet, i * 8 - 7)
        end
    end
end
