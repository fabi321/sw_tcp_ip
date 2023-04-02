require('xorshift')

---@param tick number
---@param secret number
---@return number, number
function get_frequencies(tick, secret)
    xorshift:seed(tick ~ secret)
    xorshift:skip()
    local freq_1 = xorshift:next_int() & 0x7fffff
    xorshift:skip()
    local freq_2 = xorshift:next_int() & 0x7fffff
    return freq_1, freq_2
end
