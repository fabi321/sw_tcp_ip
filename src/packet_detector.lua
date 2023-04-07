require('util')
require('packeting')

function onTick()
    packet = to_packet(1)
    sb(1, packet.ttl > 0)
end