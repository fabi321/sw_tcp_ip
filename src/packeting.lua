gn = input.getNumber
sn = output.setNumber

---@class Packet
---@field src_addr string
---@field dest_addr string
---@field src_port number
---@field dest_port number
---@field seq_nmb number
---@field ack_nmb number
---@field proto number
---@field ttl number
---@field data string

---@param nmb number
---@param start number
---@param length number
---@return number
function byte_to_int(nmb, start, length)
    ---@type number, number
    local int, mask = ("I4"):unpack((("f"):pack(nmb))), 2 ^ (length * 8) - 1
    mask = mask << (start - 1) * 8
    return (int & mask) >> (start - 1) * 8
end

---@param nmb number
---@param length number
---@return string
function int_to_byte(nmb, length)
    return ("I%i"):format(length):pack(nmb)
end

---@param start_channel number
---@return Packet
function to_packet(start_channel)
    local data = ("fffff"):pack(
                gn(start_channel + 3),
                gn(start_channel + 4),
                gn(start_channel + 5),
                gn(start_channel + 6),
                gn(start_channel + 7))
    return --[[---@type Packet]] {
        src_addr = ("%04x"):format(byte_to_int(gn(start_channel), 1, 2)),
        dest_addr = ("%04x"):format(byte_to_int(gn(start_channel), 3, 2)),
        src_port = byte_to_int(gn(start_channel + 1), 1, 1),
        dest_port = byte_to_int(gn(start_channel + 1), 2, 1),
        seq_nmb = byte_to_int(gn(start_channel + 1), 3, 1),
        ack_nmb = byte_to_int(gn(start_channel + 1), 4, 1),
        proto = byte_to_int(gn(start_channel + 2), 1, 1),
        ttl = byte_to_int(gn(start_channel + 2), 2, 1) - 1,
        data = data:sub(1, byte_to_int(gn(start_channel + 2), 3, 1))
    }
end

---@param packet Packet
---@param start_channel number
function to_channels(packet, start_channel)
    local text = (
            int_to_byte(tonumber(packet.src_addr, 16), 2)
            .. int_to_byte(tonumber(packet.dest_addr, 16), 2)
            .. int_to_byte(packet.src_port, 1)
            .. int_to_byte(packet.dest_port, 1)
            .. int_to_byte(packet.seq_nmb, 1)
            .. int_to_byte(packet.ack_nmb, 1)
            .. int_to_byte(packet.proto, 1)
            .. int_to_byte(packet.ttl, 1)
            .. int_to_byte(#packet.data, 1)
            .. "\0"
            .. (packet.data .. "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"):sub(1, 20)
    )
    for i=0,7 do
        sn(start_channel + i, (("f"):unpack(text:sub(i * 4 + 1, i * 4 + 4))))
    end
end
