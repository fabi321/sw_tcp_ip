require('bip-39/wordlist')
require('bip-39/draw_word')
require('bip-39/decode')
require('ui/basic')

---@type string
bip_39_current_word = ""
---@type string[]
bip_39_previous_words = {}
---@type boolean
bip_39_last_press = false
bip_39_keyboard_layout = {
    "qwertyuiop",
    "asdfghjkl ",
    "zxcvbnm<"
}
---@type string[]
bip_39_candidate_words = {}
---@type table<string, boolean>
bip_39_valid_characters = {}
---@type boolean
bio_39_is_valid = false

---@param current_word string
---@return string[], table<string, boolean>
function get_candidate_words(current_word)
    ---@type string[], table<string, boolean>
    local candidate_words, valid_characters = {}, {}
    for _, word in pairs(number_to_word) do
        if word:sub(1, #current_word) == current_word then
            candidate_words[#candidate_words + 1] = word
            if word ~= current_word then
                valid_characters[word:sub(#current_word + 1, #current_word + 1)] = true
            else
                valid_characters[" "] = true
            end
        end
    end
    return candidate_words, valid_characters
end

---@param pressX number
---@param pressY number
---@return nil | number
function bip_39_keyboard_on_tick(pressX, pressY)
    local current_press = pressX ~= 0 or pressY ~= 0
    local relevant_press = current_press and not bip_39_last_press
    bip_39_last_press = current_press
    bip_39_candidate_words = {}
    bip_39_valid_characters = {}
    if bip_39_current_word ~= "" then
        bip_39_candidate_words, bip_39_valid_characters = get_candidate_words(bip_39_current_word)
    elseif #bip_39_previous_words < 6 then
        for _, row in ipairs(bip_39_keyboard_layout) do
            for i = 1, #row do
                bip_39_valid_characters[row:sub(i, i)] = true
            end
            bip_39_valid_characters[" "] = false
        end
    end
    if #bip_39_candidate_words == 1 then
        bip_39_previous_words[#bip_39_previous_words + 1] = bip_39_candidate_words[1]
        bip_39_current_word = ""
    end
    if relevant_press and is_in_rect(pressX, pressY, 64, 42, 23, 5) then
        bip_39_current_word = bip_39_current_word:sub(1, -2)
        if #bip_39_current_word == 0 and #bip_39_previous_words > 0 then
            bip_39_current_word = bip_39_previous_words[#bip_39_previous_words]
            bip_39_previous_words[#bip_39_previous_words] = nil
            ---@type string[]
            local candidate_words, _ = get_candidate_words(bip_39_current_word)
            while #candidate_words <= 1 do
                bip_39_current_word = bip_39_current_word:sub(1, -2)
                candidate_words, _ = get_candidate_words(bip_39_current_word)
            end
        end
    end
    if #bip_39_previous_words == 6 then
        local result = bip_39_decode(bip_39_previous_words)
        bio_39_is_valid = result ~= nil
        return result
    end
    if not relevant_press then
        return nil
    end
    if #bip_39_candidate_words > 5 or #bip_39_candidate_words == 0 then
        for i, row in ipairs(bip_39_keyboard_layout) do
            for j = 1, #row do
                ---@type number, number, string
                local posX, posY, key = j * 8, i * 6 + 24, row:sub(j, j)
                if key ~= "<" then
                    if is_in_rect(pressX, pressY, posX, posY, 7, 5) then
                        if bip_39_valid_characters[key] then
                            if key ~= " " then
                                bip_39_current_word = bip_39_current_word .. key
                            else
                                for _, word in pairs(bip_39_candidate_words) do
                                    if word == bip_39_current_word then
                                        bip_39_previous_words[#bip_39_previous_words + 1] = bip_39_current_word
                                        bip_39_current_word = ""
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        for i, word in ipairs(bip_39_candidate_words) do
            if is_in_rect(pressX, pressY, (i + 9) % 2 * 48, (i + 9) // 2 * 6, 48, 5) then
                bip_39_previous_words[#bip_39_previous_words + 1] = word
                bip_39_current_word = ""
            end
        end
    end
    return nil
end

---@param title string
function bip_39_keyboard_on_draw(title)
    setColor(0, 0, 0)
    screen.drawClear()
    setColor(100, 100, 100)
    screen.drawTextBox(0, 0, 96, 6, title, 0, 0)
    for i, word in ipairs(bip_39_previous_words) do
        bip_39_draw_word(i + 1, word)
    end
    bip_39_draw_word(#bip_39_previous_words + 2, bip_39_current_word)
    screen.drawRectF(0, 25, 96, 3)
    if #bip_39_previous_words == 6 then
        setColor(100, 100, 100)
        screen.drawTextBox(0, 30, 96, 18, bio_39_is_valid and "valid entry" or "invalid entry", 0, 0)
    elseif #bip_39_candidate_words <= 5 and #bip_39_candidate_words > 0 then
        for i, word in ipairs(bip_39_candidate_words) do
            bip_39_draw_word(i + 9, word)
        end
    else
        for i, row in ipairs(bip_39_keyboard_layout) do
            for j = 1, #row do
                ---@type number, number, string
                local posX, posY, key = j * 8, i * 6 + 24, row:sub(j, j)
                if key ~= "<" then
                    if bip_39_valid_characters[key] then
                        setColor(10, 10, 10)
                        screen.drawRectF(posX, posY, 7, 5)
                        setColor(100, 100, 100)
                    else
                        setColor(10, 10, 10)
                    end
                    screen.drawTextBox(posX, posY, 7, 5, key, 0)
                end
            end
        end
    end
    setColor(10, 10, 10)
    screen.drawRectF(64, 42, 23, 5)
    setColor(100, 100, 100)
    screen.drawTextBox(64, 42, 23, 5, "<-", 0)
end
