
function queue()
	return {
		first=-1,
		last=0,
		pushleft=function (self, value)
			local first = self.first - 1
			self.first = first
			self[first] = value
		end,
		pushright=function (self, value)
			local last = self.last + 1
			self.last = last
			self[last] = value
		end,
		popleft=function (self)
			local first = self.first
			if first > self.last then return nil end
			local value = self[first]
			self[first] = nil
			self.first = first + 1
			return value
		end
	}
end
