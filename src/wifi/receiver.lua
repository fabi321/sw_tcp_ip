i=input;o=output
gn=i.getNumber;gb=i.getBool;sn=o.setNumber;sb=o.setBool

require('wifi/frequency_core')

---@type number
tick = 0
---@type number
secret = -1

function onTick()
    if gb(10) then
        tick = gn(10) + 2
        secret = gn(11)
    end
    if secret ~= -1 then
        tick = tick + 1
        freq_2, freq_1 = get_frequencies(tick, secret)
        sn(20, freq_1)
        sn(21, freq_2)
    end
end
