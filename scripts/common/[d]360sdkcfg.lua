local cfg = {}
cfg.upName = "360"
cfg.support_takingdata = true

local director = CCDirector:sharedDirector()
local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

local bcfg = require "common.basesdkcfg"

local function getOrder(params, callback)
    params.sid = player.sid
    params.storeid = params.productId
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.body = params.body or "游戏礼包"
    params.subject = "游戏礼包"
    netClient:gorder(params, function(__data)
        tablePrint(__data)
        if __data.status ~= 0 then
            delWaitNet()
            showToast(i18n.global.error_server_status_wrong.string .. tostring(__data.status))
            return
        end
        if callback then
            callback(__data)
        end
    end)
end

local jsonEncode = bcfg.jsonEncode
local jsonDecode = bcfg.jsonDecode


cfg.init = nil

cfg.login = function(params, callback)
    addWaitNet()
    local txparams = {
        which = "360",
    }
    local txparamsstr = jsonEncode(txparams)
    print("360进入login前的最后一步")
    cfg.logout()
    SDKHelper:getInstance():login(txparamsstr, function(xdata)
        --解析数据
        local __data = jsonDecode(xdata)
        tablePrint(__data)
        if __data and __data.errcode and __data.errcode ~= 0 then
            showToast("登陆失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
            return
        end
    
        local jparams = {
            access_token = __data.accessToken,
        }
        print("360获得accessToken = "..__data.accessToken)
        local jsonstr = jsonEncode(jparams)
        local nparams = {
            sid = 0,
            jsonStr = jsonstr,
            platform = "360"
        }

        print("网络请求发起 = "..jsonstr)
        netClient:thirdlogin(nparams, function(nData)
            print("网络收到回信")
            --tablePrint(nData)
            cfg.need_submit = true
            delWaitNet()
            if callback then
                callback(nData)
            end
        end)
    end)
end

cfg.logout = function(params, callback)
    SDKHelper:getInstance():logout("", function(xdata)
        schedule(director:getRunningScene(), function()
            replaceScene(require("ui.login.home").create())
        end)
    end)
end

cfg.exit = nil

cfg.pay = function(params, callback)
    -- get order
    local oparams = {
        productId = params.productId,
        type = 12,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local txParams = {
            cpOrderId = netOrder.cpOrderId,
            notifyUrl = netOrder.notifyUrl,
            price = netOrder.price .. "",
            productName = netOrder.productName,
            productDes = netOrder.productDes,
            userName = netOrder.name,
            qhid = netOrder.qhid,
            productId = netOrder.productId .. "",
            notifyUrl = netOrder.notifyUrl,
            appName = "放置奇兵",
            nick = player.name,
            serverId = player.sid .. "",
            serverName = "S" .. player.sid,
            exchangeRate = "10",
            coinName = "钻石",
            roleId = player.uid .. "",
            roleLv = player.lv() .. "",
            roleVipLv = player.vipLv() .. "",
            roleBalance = require("data.bag").gem() .. "",
            gname = player.gname or "no party",
        }
        require("data.takingdata").onChargeReq(txParams.cpOrderId, netOrder.productId, netOrder.price/100, "CNY", 0, "third")
        local paramStr = jsonEncode(txParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                delWaitNet()
                showToast("支付失败:" .. tdata.desc)
                if callback then
                    callback()
                end
                return
            end
            showToast("支付成功.")
            require("data.takingdata").onChargeSuc(netOrder.cpOrderId)
            local gParams = {
                sid = player.sid,
                orderid = netOrder.cpOrderId or "",
                appsflyer = HHUtils:getAppsFlyerId(),
                advertising = HHUtils:getAdvertisingId(),
            }
             -- 延迟0.5s 等待后端支付通知到达
            schedule(director:getRunningScene(), 0.5, function()
                netClient:gpay(gParams, function(gdata)
                    tablePrint(gdata)
                    delWaitNet()
                    if gdata.status ~= 0 then
                        showToast(i18n.global.error_server_status_wrong.string .. tostring(gdata.status))
                        return
                    end
                    if gdata.reward and ((gdata.reward.equips and #gdata.reward.equips > 0) 
                        or (gdata.reward.items and #gdata.reward.items > 0)) then
                        -- 首充礼包状态
                        require("data.activity").pay()
                    end
                    if callback then
                        callback(gdata.reward)
                    end
                end)
            end)
        end)
    end)
end

cfg.submitRoleData = function(params, callback)
    local sparams = {
        stype = params.stype or "enterServer",
        roleid = params.roleId .. "",
        rolename = params.roleName .. "",
        rolelevel = params.roleLevel .. "",
        vip = player.vipLv() .. "",
        balanceid = ITEM_ID_GEM,
        balancename = "钻石",
        balancenum = require("data.bag").gem(),
        partyid = player.gid or "0",
        partyname = player.gname or "无",
        zoneid = params.zoneId .. "",
        zonename = params.zoneName .. "",
    }
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end

return cfg
