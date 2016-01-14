
EXCUTE_SUCCESS = 0 --成功
CODE_SUCCESS = 1 --执行成功(默认)
CODE_FAILED = -100 --执行失败(默认)
	
AUTH_RESULT_ERROR_NONE = -1 --未进行认证
AUTH_RESULT_ERROR_DIRTY_NAME = -2 --名字存在禁用字
AUTH_RESULT_ERROR_NAME_TOO_LONG = -3--名字过长
AUTH_RESULT_ERROR_NAME_ALREADY_EXISTS = -4--昵称已存在
AUTH_RESULT_ERROR_NAME_EMPTY = -5--昵称为空
AUTH_RESULT_ERROR_SIGN = -6 	--校验码错误
AUTH_RESULT_ERROR_BUSY = -7 	--当前相同帐号正在登录中
AUTH_RESULT_VERSION = -8		--低于登录最低版本号
AUTH_RESULT_FORBIDDEN = -9	--帐号禁止登录
AUTH_RESULT_ALREADYLOGIN = -10 --帐号已经登录
AUTH_RESULT_SERVER_CLOSE = -11 --该服已经关闭，通常处于维护中
AUTH_RESULT_LOGIN_ING = -12 --账号正在登陆中

AUTH_RESULT_OK = 100 --认证通过

SYN_VERSIONERROR = -200	--同步版本错误，低于当前版本
SYN_DATAERROR = -201	--同步数据非法


	
GAME_CODE_ERROR_ROLE_ALREADY_EXISTS = -500--角色已存在
GAME_CODE_ERROR_ROLE_NOT_FIND = -501 --角色不存在
GAME_CODE_ERROR_SIGN_IN_REPEATE = -502 --今日已签到
GAME_CODE_ERROR_SIGN_IN_TODAY = -503 --今日未签到
GAME_CODE_ERROR_MAIL_NOT_FOUND = -504 --找不到该邮件
GAME_CODE_ERROR_MAIL_REPEATE_OPERATE = -505 --该邮件重复操作
GAME_CODE_ERROR_MAIL_IS_EXPIRE = -506 --邮件已过期
GAME_CODE_ERROR_FRIEND_NOT_FOUND = -507 --好友不存在
GAME_CODE_ERROR_HAS_FRIEND = -508 --好友已存在
GAME_CODE_ERROR_FRIEND_COUNT_OVERFLOW = -509--超出好友上限
GAME_CODE_ERROR_BACKPACK_REMAIN_CAPACITY_NOT_ENOUGH = -510 --背包剩余空间不足
GAME_CODE_ERROR_CAN_NOT_FIND_PROP = -511--找不到该物品
GAME_CODE_ERROR_FRIEND_TARGET_COUNT_OVERFLOW = -512 --对方好友超过上限
GAME_CODE_ERROR_FRIEND_TIMESERROR = -513 --重复申请

GAME_CODE_ERROR_ITEM_NOT_EXISTENT = -514 --道具不存在
	
GAME_CODE_ERROR_PARAM_WRONG= -999 --参数错误