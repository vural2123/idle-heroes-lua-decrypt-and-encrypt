--需要在main函数挂载

local NativeUpdateComponent = {}

NativeUpdateComponent.EVENT_RESTART = "DHCOM_EVENT_RESTART"
NativeUpdateComponent.EVENT_RESTART_CLEAN_UP = "DHCOM_EVENT_RESTART_CLEAN_UP"

function NativeUpdateComponent:init()
    local app = cc.Application:sharedApplication()
    local target = app:getTargetPlatform()
	if target == 2 then--mac
		self.modifyFlag = true

		-- local filepath = "../../../../../"
        local userdata = require("dhcomponents.data.userdata")
		local filepath = userdata.path
        cc.FileUtils:getInstance():removeAllPaths()
		cc.FileUtils:getInstance():addSearchPath(filepath.."scripts_raw/")
		cc.FileUtils:getInstance():addSearchPath(filepath.."res_raw/")
	end
end

function NativeUpdateComponent:isModify()
    return self.modifyFlag == true
end

function NativeUpdateComponent:restart(cleanup)
	if not self:isModify() then
		return
	end

    --清理资源
    if cleanup then
        local textureCache = CCTextureCache:sharedTextureCache()
        textureCache:removeAllTextures()

        CCNotificationCenter:sharedNotificationCenter():postNotification(NativeUpdateComponent.EVENT_RESTART_CLEAN_UP)
    end

    CCNotificationCenter:sharedNotificationCenter():postNotification(NativeUpdateComponent.EVENT_RESTART)

    --停掉所有全局定时器
    local schedulerUtil = require("dhcomponents.tools.SchedulerUtil")
    schedulerUtil:unscheduleAll()

    -- cc.Director:sharedDirector():getScheduler():unscheduleAll()

    --移除所有监听
    -- local eventDispatcher = cc.Director:getInstance():getEventDispatcher() 
    -- eventDispatcher:removeAllEventListeners()
    
    self:clearModules()

    cc.Director:sharedDirector():popToRootScene()

    -- require("main")

    --业务代码
    if netClient then
        netClient:close()
    end

    if cleanup then
        require("main")
    else
        replaceScene((require "ui.login.update").create(nil, nil))
    end
end

function NativeUpdateComponent:clearModules()
    local __g = _G
    setmetatable(__g, {})

    -- 白名单 main是无法重新加载的，也无法加载
    local whitelist = { 
        ["string"] = true, 
        ["io"] = true,
        ["pb"] = true,
        ["bit"] = true,
        ["os"] = true,
        ["debug"] = true,
        ["table"] = true,
        ["math"] = true,
        ["package"] = true,
        ["coroutine"] = true,
        ["pack"] = true,
        ["jit"] = true,
        ["jit.util"] = true,
        ["jit.opt"] = true,
        
        ["dhcomponents.NeverUpdateData"] = true,
    }

    for p, _ in pairs(package.loaded) do
        if not whitelist[p] then 
            package.loaded[p] = nil
        end
    end
end

NativeUpdateComponent:init()

return NativeUpdateComponent
