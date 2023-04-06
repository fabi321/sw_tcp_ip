require('util')
require('packet_queue')

---@type number
dhcp_state = 0
---@type string
dhcp_last_address = broadcast_address

---@param address_supplied boolean
function get_new_address(address_supplied)
    while address_cache[dhcp_last_address] or dhcp_last_address == broadcast_address do
        -- while random addresses for clients without a static address would be ideal, there is no reliable way to get
        -- synchronised seeds in Stormworks, so no random numbers
        local new_int_address = (tonumber(dhcp_last_address, 16) + 1) % 65535
        if not address_supplied then
            new_int_address = math.max(4096, new_int_address)
        end
        dhcp_last_address = ("%04x"):format(new_int_address)
    end
end

---@overload fun(packet: Packet)
---@param packet Packet
---@param address string | nil
function get_address(packet, address)
    if packet.ttl > 0 then
        arp_receive_packet(packet, 1)
    end
    if address and dhcp_last_address == broadcast_address then
        dhcp_last_address = address
    elseif dhcp_last_address == broadcast_address then
        get_new_address(false)
    end
    if dhcp_state == 0 then
        dhcp_state = 1
        receive_packet(--[[---@type Packet]] {
            src_addr = broadcast_address,
            dest_addr = broadcast_address,
            src_port = 1,
            dest_port = 0,
            seq_nmb = 0,
            ack_nmb = 0,
            proto = 1,
            ttl = 63,
            data = dhcp_last_address
        }, 0)
    elseif dhcp_state >= 1 and dhcp_state < TIMEOUT then
        if packet.ttl > 0 and packet.proto == 1 and packet.src_addr == dhcp_last_address and packet.src_port == 2 then
            get_new_address(address ~= nil)
            dhcp_state = 0
        else
            dhcp_state = dhcp_state + 1
        end
    elseif dhcp_state == TIMEOUT then
        dhcp_state = TIMEOUT + 1
        send_own_packet(broadcast_address, 1, dhcp_last_address, 2)
    end
end

---@overload fun(dest_addr: string, proto: number, data: string)
---@overload fun(dest_addr: string, proto: number, data: string, src_port: number)
---@overload fun(dest_addr: string, proto: number, data: string, src_port: number, dest_port: number, seq_nmb: number)
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
        }, 1)
end
