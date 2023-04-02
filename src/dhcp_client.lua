require('packet_queue')

---@type number
dhcp_state = 0
---@type string
dhcp_last_address = "0100"

---@param packet Packet
---@param address string | nil
function get_address(packet, address)
    if address and dhcp_last_address == "0100" then
        dhcp_last_address = address
    end
    if dhcp_state == 0 then
        dhcp_state = 1
        receive_packet({
            src_addr = "ffff",
            dest_addr = "ffff",
            src_port = 1,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 63,
            data = dhcp_last_address
        }, 0)
    elseif dhcp_state >= 1 and dhcp_state < 59 then
        if packet.proto == 1 and packet.src_addr == dhcp_last_address and packet.src_port == 2 then
            while address_cache[dhcp_last_address] do
                dhcp_last_address = ("%04x"):format((tonumber(dhcp_last_address, 16) + 1) % 65535)
            end
            dhcp_state = 0
        else
            dhcp_state = dhcp_state + 1
        end
    elseif dhcp_state == 59 then
        dhcp_state = 60
        receive_packet({
            src_addr = dhcp_last_address,
            dest_addr = "ffff",
            src_port = 2,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 63,
            data = dhcp_last_address
        }, 0)
    end
end
