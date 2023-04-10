require('bip-39/wordlist')

---@param words_to_decode string[]
---@return number | nil
function bip_39_decode(words_to_decode)
    ---@type number
    local decoded_number = 0
    ---@type number
    local parity = 0
    for i=5,0,-1 do
        local current_number = word_to_number[words_to_decode[i + 1]]
        if current_number == nil then
            return nil
        end
        if i == 5 then
            decoded_number = current_number >> 2
            parity = current_number & 3
        else
            decoded_number = decoded_number << 11 | current_number
        end
    end
    if parity ~= decoded_number % 3 + 1 then
        return nil
    end
    return decoded_number
end
