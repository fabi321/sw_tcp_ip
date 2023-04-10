---@param position number
---@param word string
function bip_39_draw_word(position, word)
    screen.drawText(position % 2 * 48, position // 2 * 6, word)
end
