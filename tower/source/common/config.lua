 
--是否开启调试模式
DEBUG = true
--打印日志等级，0表示不打印日志，其他等级，自己控制，值越大，打印的日志应该越多
LOG_LEVEL = 2

--客户端进入的最小版本号
MIN_VERSION = 1
CUR_VERSION = 1

--玩家数据保存间隔(S)
PLAYER_SAVE_INTERVAL = 600

--最大包裹容量
BACKPACK_MAX_CAPACITY = 100

--最大好友数
MAX_FRIEND_COUNT = 30

--1天体力领取的最大次数
MAX_ENERGYGET_BYDAY = 10

--1天体力赠送的最大次数
MAX_ENERGYGIVE_BYDAY = 30

--排行榜榜单人数
MAX_RANK_COUNT =  50

--排行榜奖励最低分数
RANK_BASE_SCORE = 30000

--排名最低分数
RANK_SCORE = 100000

--玩家信息删除时间
REDIS_PLAYER_TTL = ONE_WEEK

--邮件最长保留时间
REDIS_MAIL_TTL = 2 * ONE_WEEK

--在线账户剔除时间
ONLINE_USER_KICKTIME = 300

--礼物最大收取
MAX_GIFT_COUNT = 100

--邮件类型
MAIL_TYPE_COMMON  		 = 1	--普通邮件
MAIL_TYPE_FRIEND_ADD 	 = 2	--好友添加邮件
MAIL_TYPE_FRIEND_DEL	 = 3	--好友删除
MAIL_TYPE_FRIEND_ACCEPT	 = 4	--对方接受好友请求
MAIL_TYPE_ENERGY_GIVE 	 = 5	--体力赠送邮件
MAIL_TYPE_ENERGY_REQUEST = 6	--体力请求邮件
MAIL_TYPE_RANK_REWARD    = 7	--排行榜奖励邮件
MAIL_TYPE_ADDITEM		 = 9	--道具发放

--邮件操作
MAIL_OP_ACCEPT = 1		--同意操作
MAIL_OP_IGNORE = 2		--忽略操作

--邮件状态
MAIL_STATUS_UNREAD = 1	--未读邮件
MAIL_STATUS_ACCEPT  = 2	--同意或读取邮件
MAIL_STATUS_IGNORE  = 3	--忽略邮件

--签到操作
SIGN_QUERY		= 1	--查询签到信息
SIGN_GET		= 2	--签到并领取奖励

--排行榜
RANK_ENDLESS = 1

