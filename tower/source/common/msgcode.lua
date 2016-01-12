
MSG = {}

MSG[99]  	= {proto = "tutorial.Person"}   	  	--系统消息
--对应的协议结构名
MSG[100] 	= {proto = "login.auth"} 		--登录验证
MSG[200]	= {proto = "login.auth_resp"}		--登录验证反馈

MSG[103]	= {proto = "sign.signin"}		--签到
MSG[203]	= {proto = "sign.signin_resp"}		

MSG[104]	= {proto = "mail.query"}		--邮件查询
MSG[204]	= {proto = "mail.query_resp"}

MSG[106]	= {proto = "mail.operator"}		--执行邮件
MSG[206]	= {proto = "mail.operator_resp"}

MSG[107]	= {proto = "friend.add"}		--添加好友
MSG[207]	= {proto = "friend.add_resp"}		--添加好友返回

MSG[108]	= {proto = "friend.del"}			--删除好友
MSG[208]	= {proto = "friend.del_resp"}

MSG[109]	= {proto = "friend.refresh"}		--刷新好友数据
MSG[209]	= {proto = "friend.refresh_resp"}

MSG[110] 	= {proto = "friend.recommend"}	--好友推荐
MSG[210] 	= {proto = "friend.recommend_resp"}	--好友推荐

MSG[111]	= {proto = "bag.query"}			--获取背包内容
MSG[211]	= {proto = "bag.query_resp"}		--获取背包内容

MSG[114]	= {proto = "friend.findplayer"}		--查找玩家
MSG[214]	= {proto = "friend.findplayer_resp"}		

MSG[115] 	= {proto = "syn.data"} 			--上传同步数据消息
MSG[116]	= {proto = "syn.record"}		--上传操作记录
MSG[215]	= {proto = "syn.resp"}			--操作返回

MSG[119] 	= {proto = "syn.query"} 		--同步玩家数据消息
MSG[219]	= {proto = "syn.query_resp"}		--返回玩家数据

MSG[128]	= {proto = "friend.energyget"}		--索要体力
MSG[228]	= {proto = "friend.energyget_resp"}		

MSG[129]	= {proto = "rank.query"}		--查询排行榜
MSG[229]	= {proto = "rank.query_resp"}

MSG[130]	= {proto = "friend.energygive"}		--赠送体力
MSG[230]	= {proto = "friend.energygive_resp"}	

MSG[231]	= {proto = "friend.change"}		--通知客户端好友改变

MSG[134]	= {proto = "item.update"}               --删除物品
MSG[234]	= {proto = "item.update_resp"}

MSG[135]	= {proto = "item.refresh"}              -- 刷新所有物品
MSG[235]	= {proto = "item.refresh_resp"}

MSG[136]	= {proto = "pass.update"}                 -- 过关
MSG[236]	= {proto = "pass.update_resp"}

MSG[137]	= {proto = "pass.refresh"}              -- 关卡所有信息
MSG[237]	= {proto = "pass.refresh_resp"}         -- 

MSG[138]	= {proto = "task.update"}              -- 接任务
MSG[238]	= {proto = "task.update_resp"}         -- 

MSG[139]	= {proto = "task.refresh"}              -- 完成任务
MSG[239]	= {proto = "task.refresh_resp"}         -- 

MSG[140]	= {proto = "tower.refresh"}              -- 爬塔
MSG[240]	= {proto = "tower.refresh_resp"}         -- 

MSG[141]	= {proto = "tower.update"}              -- 爬塔
MSG[241]	= {proto = "tower.update_resp"}         -- 

MSG[142]	= {proto = "role.refresh"}              -- 获取玩家数据
MSG[242]	= {proto = "role.refresh_resp"}         -- 

MSG[143]	= {proto = "role.update"}               -- 跟新玩家数据
MSG[243]	= {proto = "role.update_resp"}          -- 

MSG[144]	= {proto = "rank.query"}                -- 排行榜查询
MSG[244]	= {proto = "rank.query_resp"}           -- 

MSG[145]	= {proto = "friend.get_point"}          -- 好友这一关的分数
MSG[245]	= {proto = "friend.get_point_resp"}     -- 

MSG[146]	= {proto = "task.refresh_everyday"}          -- 每日任务
MSG[246]	= {proto = "task.refresh_everyday_resp"}     -- 

MSG[147]	= {proto = "friend.send_item"}          -- 送好友道具
MSG[247]	= {proto = "friend.send_item_resp"}     -- 

MSG[148]	= {proto = "friend.get_item"}          -- 获得好友赠送道具
MSG[248]	= {proto = "friend.get_item_resp"}     -- 

MSG[149]	= {proto = "rank.get_award"}          -- 获得好友赠送道具
MSG[249]	= {proto = "rank.get_award_resp"}     -- 

MSG[150]	= {proto = "rank.is_clear_point"}          -- 清空分数
MSG[250]	= {proto = "rank.is_clear_point_resp"}     --
 
MSG[151]	= {proto = "exchange.exchange"}          -- 兑换
MSG[251]	= {proto = "exchange.exchange_resp"}     -- 兑换返回

--第2种排行榜
MSG[152]	= {proto = "rank2.query"}                	-- 排行榜查询
MSG[252]	= {proto = "rank2.query_resp"}           	-- 

MSG[153]	= {proto = "rank2.get_award"}          	-- 获得好友赠送道具
MSG[253]	= {proto = "rank2.get_award_resp"}     	-- 

MSG[154]	= {proto = "rank2.is_clear_point"}          	-- 清空分数
MSG[254]	= {proto = "rank2.is_clear_point_resp"}   --

--第3种排行榜
MSG[155]	= {proto = "rank3.query"}                -- 排行榜查询
MSG[255]	= {proto = "rank3.query_resp"}           -- 

MSG[156]	= {proto = "rank3.get_award"}          -- 获得好友赠送道具
MSG[256]	= {proto = "rank3.get_award_resp"}     -- 

MSG[157]	= {proto = "rank3.is_clear_point"}          -- 清空分数
MSG[257]	= {proto = "rank3.is_clear_point_resp"}     --

MSG[158]	= {proto = "rank3.upload"}          -- 上传分数
MSG[258]	= {proto = "rank3.upload_resp"} 

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