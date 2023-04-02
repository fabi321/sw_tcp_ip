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
        receive_packet(--[[---@type Packet]] {
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
        send_own_packet("ffff", 1, dhcp_last_address, 2)
    end
end

---@param dest_addr string
---@param proto number
---@param data string
---@param src_port number | nil
---@param dest_port number | nil
---@param seq_nmb number | nil
---@param ack_nmb number | nil
function send_own_packet(dest_addr, proto, data, src_port, dest_port, seq_nmb, ack_nmb)
    receive_packet(--[[---@type Packet]] {
            src_addr = dhcp_last_address,
            dest_addr = dest_addr,
            src_port = src_port or 0,
            dest_port = dest_port or 0,
            seq_nmb = seq_nmb or 0,
            ack_nmb = ack_nmb or 0,
            proto = proto,
            ttl = 63,
            data = data
        }, 0)
end
