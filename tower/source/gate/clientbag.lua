local skynet = require "skynet"

function cclient:initbag(data)
	self.backpack = data.backpack

	for _,item in ipairs(data.props) do
		self.props[item.id] = item
	end
end

function cclient:getcapacity()
	return self.backpack.basecapacity + self.backpack.extendedcapacity
end

function  cclient:addextendedcapacity(value)
	self.backpack.extendedcapacity = self.backpack.extendedcapacity + value
end

function  cclient:getcanopencapacity()
	return BACKPACK_MAX_CAPACITY - self.backpack.basecapacity - self.backpack.extendedcapacity
end
	
function  cclient:removeprop(prop)
	self.props[prop.id] = nil
end
	
function  cclient:addnewprop(prop)
	if not prop then
		return
	end

	self.props[prop.id] = prop
end

function cclient:getremaincapacity()
	local value = self.backpack.basecapacity + self.backpack.extendedcapacity - (#self.props)

	if value < 0 then
		value = 0
	end

	return value
end

function cclient:getthesameprop(dataid)
	for _,prop in pairs(self.props) do
		if prop.baseid == dataid then
			return prop
		end
	end
end
	
function  cclient:checkthesamepropcount(dataid)
	local totalcount = 0

	for _,prop in pairs(self.props) do
		if prop.baseid == dataid then
			totalcount = totalcount + 1
		end
	end

	return totalcount
end
