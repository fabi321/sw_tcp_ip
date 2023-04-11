require('xorshift')

function onTick()
    if input.getNumber(1) ~= 0 then
        ---@type number
        rand_source = 0
        for i=1,3 do
            rand_source = rand_source ~ (input.getNumber(i)//2) << (i * 8)
        end
        xorshift:seed(rand_source)
        xorshift:skip()
        output.setNumber(1, xorshift:next_int() & 0x7fffff)
    end
end
