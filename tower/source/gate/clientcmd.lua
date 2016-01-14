local skynet = require "skynet"

--处理来自其它服务器的请求
function cclient:kick(id)
	self.kicked = true
	skynet.call(dog,"lua","close",self.fd)

	local dat = self:buildalldata()
	return 0,dat
end
