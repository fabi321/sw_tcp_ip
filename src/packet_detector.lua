require('util')
require('packeting')

-- tumfl: preserve
function onTick()
    packet = to_packet(1)
    output.setBool(1, packet.ttl > 0)
end