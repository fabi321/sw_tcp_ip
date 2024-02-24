require('util')

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
---@param length number
---@return string
function int_to_byte(nmb, length)
    return ("I%i"):format(length):pack(nmb)
end

I4_FORMATTER = "I4"
F_FORMATTER = "f"

---@param start_channel number
---@param encrypted boolean
---@return number[]
function get_numbers(start_channel, encrypted)
    ---@type number[]
    local numbers = {}
    for i=1, 8 do
        numbers[i] = (I4_FORMATTER:unpack((F_FORMATTER:pack(gn(start_channel + i - 1)))))
    end
    if encrypted then
        for i=1, 8, 2 do
            numbers[i], numbers[i + 1] = blowfish_decrypt(numbers[i], numbers[i + 1])
        end
    end
    return numbers
end

---@param numbers number[]
---@param start_channel number
---@param encrypted boolean
function set_numbers(numbers, start_channel, encrypted)
    if encrypted then
        for i=1, 8, 2 do
            numbers[i], numbers[i + 1] = blowfish_encrypt(numbers[i], numbers[i + 1])
        end
    end
    for i=1,8 do
        sn(start_channel + i - 1, (F_FORMATTER:unpack((I4_FORMATTER:pack(numbers[i])))))
    end
end

---@overload fun(start_channel: number): Packet
---@param start_channel number
---@param encrypted boolean | nil
---@return Packet
function to_packet(start_channel, encrypted)
    local numbers = get_numbers(start_channel, encrypted or false)
    local data = ("I4I4I4I4I4"):pack(numbers[4], numbers[5], numbers[6], numbers[7], numbers[8])
    return --[[---@type Packet]] {
        src_addr = ADDRESS_FORMAT:format(numbers[1] & TWO_BYTE_MASK),
        dest_addr = ADDRESS_FORMAT:format(numbers[1] >> 16 & TWO_BYTE_MASK),
        src_port = numbers[2] & ONE_BYTE_MASK,
        dest_port = numbers[2] >> 8 & ONE_BYTE_MASK,
        seq_nmb = numbers[2] >> 16 & ONE_BYTE_MASK,
        ack_nmb = numbers[2] >> 24 & ONE_BYTE_MASK,
        proto = numbers[3] & ONE_BYTE_MASK,
        ttl = (numbers[3] >> 8 & ONE_BYTE_MASK) - 1,
        data = data:sub(1, numbers[3] >> 16 & ONE_BYTE_MASK)
    }
end

---@overload fun(packet: Packet, start_channel: number)
---@param packet Packet
---@param start_channel number
---@param encrypted boolean | nil
function to_channels(packet, start_channel, encrypted)
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
            .. (packet.data .. ("\0"):rep(20)):sub(1, 20)
    )
    ---@type number[]
    local numbers = {}
    for i=1,8 do
        numbers[i] = (I4_FORMATTER:unpack(text:sub(i * 4 - 3, i * 4)))
    end
    set_numbers(numbers, start_channel, encrypted or false)
end
