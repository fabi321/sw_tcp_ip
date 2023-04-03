require('packeting')
require('packet_queue')
require('dhcp_client')
require('server')
require('icmp_server')
require('icmp_client')

function onTick()
    for i=1,8 do
        sn(i, 0)
    end
    local packet = to_packet(1)
    arp_receive_packet(packet, 1)
    if dhcp_state < 60 then
        if input.getBool(1) then
            get_address(packet)
        end
    else
        if packet.ttl > 0 then
            if packet.proto == 1 then
                respond_to_arp(packet)
            elseif packet.proto == 3 then
                respond_to_icmp(packet)
            end
        end
        if input.getBool(2) then
            local destination_address = ("%04x"):format(gn(10))
            local result = icmp_ping(packet, destination_address)
            if result then
                sn(11, result)
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
end
