raw_words = property.getText("_wordlist1") .. property.getText("_wordlist2") .. property.getText("_wordlist3") .. property.getText("_wordlist4")

---@type table<string, number>
word_to_number = {}
--- Do NOT use ipairs, as the first word has index 0
---@type table<number, string>
number_to_word = {}

---@type number
local index = 0
for word in raw_words:gmatch("([^,]+)") do
    number_to_word[index] = word
    word_to_number[word] = index
    index = index + 1
end
