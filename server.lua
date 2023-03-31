require('packeting')
require('packet_queue')
require('dhcp_client')
require('arp_server')

function onTick()
    for i=1,8 do
        sn(i, 0)
    end
    local packet = to_packet(1)
    if dhcp_state < 60 then
        if input.getBool(1) then
            local result = get_address(packet)
            if type(result) == 'table' then
                packet_queue[newest_packet] = {
                    retry_time = 0,
                    packet = result,
                    destination = 1,
                }
                newest_packet = newest_packet + 1
            end
        end
    else
        if packet.ttl > 0 then
            arp_receive_packet(packet, 1)
            if packet.proto == 1 then
                receive_packet(respond_to_arp(packet, dhcp_last_address), 1)
            end
        end
    end
    tick_packet_queue()
    packet = send_packet(1)
    if packet ~= nil then
        to_channels(packet, 1)
        sn(12, 1)
    end
    sn(10,tonumber(dhcp_last_address, 16))
    sn(11, dhcp_state)
end
