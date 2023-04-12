getText = property.getText

---@type table<number>
blowfish_p = {}
---@type table<number, table<number, number>>
blowfish_s = {}
blowfish_p_text = getText("_blowfish_p")
blowfish_s_0_text = getText("_blowfish_s_0")
blowfish_s_1_text = getText("_blowfish_s_1")
blowfish_s_2_text = getText("_blowfish_s_2")
blowfish_s_3_text = getText("_blowfish_s_3")

--- Create an array based on a string of hexadecimal numbers. resulting array is zero based
---@param input string
---@return table<number, number>
function string_to_array(input)
    ---@type table<number, number>
    local result = {}
    ---@type number
    local idx = 0
    for match in input:gmatch("([0-9a-z]+)") do
        result[idx] = tonumber(match, 16)
        idx = idx + 1
    end
    return result
end

---@param x number
---@return number
function blowfish_f(x)
    local a, b, c, d = x >> 24 & 0xff, x >> 16 & 0xff, x >> 8 & 0xff, x & 0xff
    return ((blowfish_s[0][a] + (blowfish_s[1][b] & 0x1F) & 0xffffffff) ~ blowfish_s[2][c]) + (blowfish_s[3][d] & 0x1F) & 0xffffffff
end

---@param xl number
---@param xr number
---@return number, number
function blowfish_encrypt(xl, xr)
    for i=0, 15 do
        xl = xl ~ blowfish_p[i]
        xr = blowfish_f(xl) ~ xr
        xr, xl = xl, xr
    end
    xr, xl = xl, xr
    xr = xr ~ blowfish_p[16]
    xl = xl ~ blowfish_p[17]
    return xl, xr
end

---@param xl number
---@param xr number
function blowfish_decrypt(xl, xr)
    for i=17, 2, -1 do
        xl = xl ~ blowfish_p[i]
        xr = blowfish_f(xl) ~ xr
        xr, xl = xl, xr
    end
    xr, xl = xl, xr
    xr = xr ~ blowfish_p[1]
    xl = xl ~ blowfish_p[0]
    return xl, xr
end

--- Key index is 1 based, and only consists of 32bit integers
---@param key number[]
function blowfish_init(key)
    blowfish_p = string_to_array(blowfish_p_text)
    blowfish_s[0] = string_to_array(blowfish_s_0_text)
    blowfish_s[1] = string_to_array(blowfish_s_1_text)
    blowfish_s[2] = string_to_array(blowfish_s_2_text)
    blowfish_s[3] = string_to_array(blowfish_s_3_text)
    for i=0,16 do
        blowfish_p[i] = blowfish_p[i] ~ key[i % #key + 1]
    end
    local data_l, data_r = 0x0, 0x0
    for i=0, 17, 2 do
        data_l, data_r = blowfish_encrypt(data_l, data_r)
        blowfish_p[i] = data_l
        blowfish_p[i + 1] = data_r
    end
    for j=0, 3 do
        for i=0, 255, 2 do
            data_l, data_r = blowfish_encrypt(data_l, data_r)
            blowfish_s[j][i] = data_l
            blowfish_s[j][i + 1] = data_r
        end
    end
end
