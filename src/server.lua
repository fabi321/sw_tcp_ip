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
            if result then
                receive_packet(result, 0)
            end
        end
    else
        if packet.ttl > 0 then
            arp_receive_packet(packet, 1)
            if packet.proto == 1 then
                local response = respond_to_arp(packet, dhcp_last_address)
                if response then
                    receive_packet(response, 0)
                end
            end
        end
    end
    tick_packet_queue()
    packet = send_packet(1)
    if packet ~= nil then
        to_channels(packet, 1)
    end
    for i=2,4 do
        send_packet(i)
    end
    sn(10, tonumber(dhcp_last_address, 16))
    sn(11, dhcp_state)
end
