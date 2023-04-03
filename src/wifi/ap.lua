i=input;o=output
gn=i.getNumber;gb=i.getBool;sn=o.setNumber;sb=o.setBool

require('wifi/frequency_core')

---@param f number
---@returns number
function f_to_i(f)
    return ("I4"):unpack((("f"):pack(f)))
end

---@param i number
---@returns number
function i_to_f(i)
    return ("f"):unpack((("I4"):pack(i)))
end

---@type number
tick = 0
---@type number
secret = -1

function onTick()
    rand_source = gn(10)
    if secret == -1 then
        if rand_source ~= 0 then
            xorshift:seed(f_to_i(rand_source))
            xorshift:skip()
            secret = xorshift:next_int()  & 0x7fffff
        end
    else
        tick = tick + 1
        sn(10, tick)
        sn(11, secret)
        freq_1, freq_2 = get_frequencies(tick, secret)
        sn(20, freq_1)
        sn(21, freq_2)
    end
end
