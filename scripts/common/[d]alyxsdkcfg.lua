local cfg = {}
cfg.upName = "alyx"
cfg.support_takingdata = true

local cjson = json

require "common.func"
require "common.const"
local netClient = require "net.netClient"
local i18n = require "res.i18n"
local player = require "data.player"
local userdata = require "data.userdata"

local director = CCDirector:sharedDirector()

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
    cfg.logout()
    SDKHelper:getInstance():login("", function(xdata)
        --tablePrint(__xdata)
        print("sdklogin：", xdata)
        local __data = jsonDecode(xdata)
        if __data and __data.errcode and __data.errcode ~= 0 then
            delWaitNet()
            showToast(__data.desc or "登录失败")
            schedule(director:getRunningScene(), 1, function()
                replaceScene(require("ui.login.home").create())
            end)
        else
            local jparams = {
                mem_id = __data.mem_id,
                token = __data.token,
            }
            local jsonstr = jsonEncode(jparams)
            local nparams = {
                sid = 0,
            }
            nparams["jsonStr"] = jsonstr
            nparams["platform"] = "aile"
            netClient:thirdlogin(nparams, function(nData)
                tablePrint(nData)
                delWaitNet()
                if callback then
                    callback(nData)
                end
            end)
        end
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
        type = 20,
    }
    addWaitNet()
    getOrder(oparams, function(__data)
        tablePrint(__data)
        local netOrder = jsonDecode(__data.order_info)
        local ucParams = {
            cp_order_id = netOrder.cp_order_id,
            product_price = netOrder.product_price,
            product_id = netOrder.productId .. "",
            product_name = netOrder.product_name,
            product_desc = netOrder.product_desc,
            ext = netOrder.ext or "",
            role_type = "5",
            ctime = "0",
            mtime = "0",
            party_name = player.gname or "NO_PARTY",
            role_id = (player.uid or "") .. "",
            role_levle = player.lv() .. "",
            role_name = player.name or "",
            role_vip = player.vipLv() .. "",
            server_id = player.sid .. "",
            server_name = "S" .. player.sid,
        }
        require("data.takingdata").onChargeReq(ucParams.cp_order_id, netOrder.productId, netOrder.product_price, "CNY", 0, "third")
        local paramStr = jsonEncode(ucParams)
        SDKHelper:getInstance():pay(paramStr, function(pdata)
            --tablePrint(pdata)
            local tdata = jsonDecode(pdata)
            if not tdata or not tdata.errcode or tdata.errcode ~= 0 then
                --showToast("支付界面被关闭")
                if callback then
                    callback()
                end
                return
            end
            require("data.takingdata").onChargeSuc(netOrder.cp_order_id)
            --showToast("支付成功.")
            local gParams = {
                sid = player.sid,
                orderid = netOrder.cp_order_id or "",
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
    -- pay
    -- verify
end

cfg.submitRoleData = function(params, callback)
    local sparams = {
        role_type = "5",
        ctime = "0",
        mtime = "0",
        party_name = player.gname or "",
        role_id = (player.uid or "") .. "",
        role_levle = player.lv() .. "",
        role_name = player.name or "",
        role_vip = player.vipLv() .. "",
        server_id = player.sid .. "",
        server_name = "S" .. player.sid,
    }
    local paramStr = jsonEncode(sparams)
    SDKHelper:getInstance():submitRoleData(paramStr, function(xdata)
    end)
end


return cfg
