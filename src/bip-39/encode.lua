require('bip-39/wordlist')

---@param number_to_encode number
---@return string[]
function bip_39_encode(number_to_encode)
    -- ensure that the number is of the integer subtype
    number_to_encode = number_to_encode // 1
    local parity = number_to_encode % 3 + 1
    print(parity)
    ---@type string[]
    local words = {}
    for i=0,5 do
        local current_number = number_to_encode >> i * 11 & 0x7ff
        if i == 5 then
            current_number = current_number << 2 | parity
        end
        words[i + 1] = number_to_word[current_number]
    end
    return words
end
