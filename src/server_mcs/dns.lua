require('packeting')
require('dns/server')

function onTick()
    for i=1,8 do
        sn(i, 0)
    end
    output.setBool(1, true)
    -- DNS server preferably uses address 0
    sn(17, 0)
    local packet = to_packet(1)
    if packet.ttl > 0 then
        if packet.proto == 4 then
            respond_to_dns(packet)
        end
    end
end
