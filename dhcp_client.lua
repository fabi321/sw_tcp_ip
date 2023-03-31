---@type number
dhcp_state = 0
---@type string
dhcp_last_address = "0000"

---@param packet Packet
---@param address string | nil
---@return string | Packet | nil
function get_address(packet, address)
    address = address or dhcp_last_address
    if dhcp_state == 0 then
        if dhcp_last_address == address then
            address = ("%x"):format(tonumber(address, 16) + 1)
        end
        dhcp_last_address = address
        dhcp_state = 1
        return {
            src_addr = "ffff",
            dest_addr = address,
            src_port = 0,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 255
        }
    elseif dhcp_state >= 1 and dhcp_state < 60 then
        if packet.proto == 1 and packet.dest_addr == "ffff" and packet.src_addr == address then
            dhcp_state = 0
        else
            dhcp_state = dhcp_state + 1
        end
    else
        return dhcp_last_address
    end
end
