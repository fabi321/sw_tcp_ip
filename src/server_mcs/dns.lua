require('util')
require('packeting')
require('dns/server')

function onTick()
    for i=1,8 do
        sn(i, 0)
    end
    sb(1, true)
    -- DNS server preferably uses address 0
    sn(17, 0)
    local packet = to_packet(1)
    if packet.ttl > 0 then
        if packet.proto == 4 then
            local response = respond_to_dns(packet)
            if response ~= nil then
                to_channels(response, 1)
            end
        end
    end
end
