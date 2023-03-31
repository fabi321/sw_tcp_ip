---@class Xorshift
---@field magic number
---@field state number
---@field seed function(num: number)
---@field next_int function(): number
---@field skip function()
xorshift = {
    magic = 0x2545F4914F6CDD1D,
    state = 0,
    seed = function(self, num)
        self.state = num
    end,
    next_int = function(self)
        local x = self.state
        x = x ~ (x >> 12)
        x = x ~ (x << 25)
        x = x ~ (x >> 27)
        self.state = x
        local answer = (x * self.magic) >> 32
        return answer
    end,
    skip = function(self)
        for i=1,10 do
            self:next_int()
        end
    end
}
