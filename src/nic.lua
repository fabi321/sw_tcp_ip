require('util')
require('packeting')
require('packet_queue')
require('dhcp_client')
require('icmp/server')
require('arp/server')

largest_interface_id = 2

-- tumfl: preserve
function onTick()
    for i=1,16 do
        output.setNumber(i, 0)
    end
    local packet = to_packet(9)
    if dhcp_state < TIMEOUT + 1 then
        if input.getBool(1) then
            ---@type string | nil
            local preferred_address = nil
            if input.getNumber(17) ~= 65535 then
                preferred_address = ADDRESS_FORMAT:format(input.getNumber(17))
            end
            get_address(packet, preferred_address)
        end
    else
        if packet.ttl > 0 then
            receive_packet(packet, 2)
        end
        packet = to_packet(1)
        if packet.ttl > 0 then
            packet.src_addr = dhcp_last_address
            packet.ttl = 63 -- Traceroute is basically useless anyways, as ttl reducing intermediates don't have addresses
            receive_packet(packet, 1)
        end
    end
    tick_arp_cache()
    tick_packet_queue()
    packet = send_packet(1)
    if packet ~= nil then
        if packet.proto == 1 then
            respond_to_arp(packet)
        elseif packet.proto == 3 and packet.src_port == 1 then
            respond_to_icmp(packet)
        else
            to_channels(packet, 1)
        end
    end
    packet = send_packet(2)
    if packet ~= nil then
        to_channels(packet, 9)
    end
    output.setNumber(17, tonumber(dhcp_last_address, 16))
    output.setBool(1, dhcp_state == TIMEOUT + 1)
end
