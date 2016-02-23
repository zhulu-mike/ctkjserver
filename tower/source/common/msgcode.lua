
MSG = {}

MSG[99]  	= {proto = "tutorial.Person"}   	  	--系统消息
--对应的协议结构名
MSG[100] 	= {proto = "login.auth"} 		--登录验证
MSG[200]	= {proto = "login.auth_resp"}		--登录验证反馈

MSG[103]	= {proto = "sync.res"}		--同步资源数据，即tbl_userdetail表
MSG[203]	= {proto = "sync.res_resp"}		

MSG[106]	= {proto = "sync.heros"}		--同步heros数据，即tbl_userheros表
MSG[206]	= {proto = "sync.heros_resp"}	

MSG[109]	= {proto = "sync.rounds"}		--同步rounds数据，即tbl_userrounds表
MSG[209]	= {proto = "sync.rounds_resp"}	

--资源数据同步
MSG[250]	= {proto = "sync.resupdate"}	
--英雄数据同步
MSG[251]	= {proto = "sync.herosupdate"}
--章节数据同步
MSG[252]	= {proto = "sync.chapterupdate"}

--启用消息
function enablemsg(id,enabled)
	local handler = MSG[id]

	if handler then
		if enabled then
			handler.on = handler.backon
		else
			handler.backon = handler.on
			handler.on = nil
		end
	end
end