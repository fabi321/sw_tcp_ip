require('packeting')

function onTick()
    packet = to_packet(1)
    output.setBool(1, packet.ttl > 0)
end