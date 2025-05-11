require('wifi/frequency_core')

---@type number
tick = 0
---@type number
secret = -1

-- tumfl: preserve
function onTick()
    if input.getBool(10) then
        tick = input.getNumber(10) + 2
        secret = input.getNumber(11)
    end
    if secret ~= -1 then
        tick = tick + 1
        freq_2, freq_1 = get_frequencies(tick, secret)
        output.setNumber(20, freq_1)
        output.setNumber(21, freq_2)
    end
end
