-- 主UI
local ui = {}

local cjson = json

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local player = require "data.player"
local bag = require "data.bag"

local function getOrder(params, callback)
    params.sid = player.sid
    params.storeid = params.productId
    params.device_info = HHUtils:getAdvertisingId() or ""
    params.body = "游戏礼包"
    params.subject = "游戏礼包"
    local net = require "net.netClient"
    net:gorder(params, function(__data)
        tbl2string(__data)
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

local function payWx(params, callback)
    local orderInfo = cjson.encode(params)
    DHPayment:getInstance():payWx(orderInfo, callback)
end

local function payAli(params, callback)
    local orderInfo = params.paystr
    DHPayment:getInstance():payAli(orderInfo, callback)
end

function ui.create(uiParams)
    local productId = uiParams.productId
    local callback = uiParams.callback
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    -- board
    local board= img.createUI9Sprite(img.ui.dialog_1)
    board:setPreferredSize(CCSizeMake(562, 384))
    board:setScale(view.minScale)
    board:setPosition(view.midX-5*view.minScale, view.midY)
    layer:addChild(board)
    layer.board = board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    -- anim
    if _anim then
        board:setScale(0.5*view.minScale)
        board:runAction(CCScaleTo:create(0.15, 1*view.minScale, 1*view.minScale))
    end

    -- title
    local lbl_title = lbl.createFont1(24, i18n.global.setting_board_title.string, ccc3(0xe6, 0xd0, 0xae))
    lbl_title:setPosition(CCPoint(board_w/2, board_h-29))
    board:addChild(lbl_title, 2)
    local lbl_title_shadowD = lbl.createFont1(24, i18n.global.setting_board_title.string, ccc3(0x59, 0x30, 0x1b))
    lbl_title_shadowD:setPosition(CCPoint(board_w/2, board_h-31))
    board:addChild(lbl_title_shadowD)

    function layer.setTitle(_str)
        lbl_title:setString(_str)
        lbl_title_shadowD:setString(_str)
    end

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- btn_close
    local btn_close0 = img.createUISprite(img.ui.close)
    local btn_close = SpineMenuItem:create(json.ui.button, btn_close0)
    btn_close:setPosition(CCPoint(board_w-25, board_h-28))
    local btn_close_menu = CCMenu:createWithItem(btn_close)
    btn_close_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_close_menu, 100)
    layer.btn_close = btn_close
    btn_close:registerScriptTapHandler(function()
        backEvent()
    end)

    -- inner_board
    local inner_board = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    inner_board:setPreferredSize(CCSizeMake(510, 288))
    inner_board:setAnchorPoint(CCPoint(0.5, 0))
    inner_board:setPosition(CCPoint(board_w/2, 35))
    board:addChild(inner_board)
    layer.inner_board = inner_board
    local inner_board_w = inner_board:getContentSize().width
    local inner_board_h = inner_board:getContentSize().height

    local btn_wx0 = img.createUISprite(img.ui.pay_wx)
    local btn_wx = SpineMenuItem:create(json.ui.button, btn_wx0)
    btn_wx:setPosition(CCPoint(145, inner_board_h/2))
    local btn_wx_menu = CCMenu:createWithItem(btn_wx)
    btn_wx_menu:setPosition(CCPoint(0, 0))
    inner_board:addChild(btn_wx_menu)

    local btn_ali0 = img.createUISprite(img.ui.pay_ali)
    local btn_ali = SpineMenuItem:create(json.ui.button, btn_ali0)
    btn_ali:setPosition(CCPoint(366, inner_board_h/2))
    local btn_ali_menu = CCMenu:createWithItem(btn_ali)
    btn_ali_menu:setPosition(CCPoint(0, 0))
    inner_board:addChild(btn_ali_menu)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    btn_wx:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            productId = productId,
            type = PAY_METHOD.WX,
        }
        addWaitNet(function()
            delWaitNet()
            showToast("支付超时")
        end, 90)
        getOrder(params, function(__data)
            tbl2string(__data)
            local netOrder = cjson.decode(__data.order_info)
            local wxParams = {
                appid = "wxfd23210e2c64a0f3",
                partnerid = "1441277802",
                prepayid = netOrder.prepayid,
                package = "Sign=WXPay",
                noncestr = netOrder.noncestr,
                timestamp = netOrder.timestamp,
                sign = netOrder.sign,
            }
            payWx(wxParams, function(status)
                if status ~= "ok" then
                    schedule(layer, 0.8, function()
                        showToast("支付被取消或失败.")
                    end)
                    delWaitNet()
                    return
                end
                schedule(layer, 0.8, function()
                    showToast("支付成功.")
                end)
                local gParams = {
                    sid = player.sid,
                    orderid = netOrder.orderid or "",
                    appsflyer = HHUtils:getAppsFlyerId(),
                    advertising = HHUtils:getAdvertisingId(),
                }
                local net = require "net.netClient"
                net:gpay(gParams, function(gdata)
                    tbl2string(gdata)
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
                    layer:removeFromParentAndCleanup(true)
                    if callback then
                        callback(gdata.reward)
                    end
                end)
            end)
        end)
    end)

    btn_ali:registerScriptTapHandler(function()
        audio.play(audio.button)
        local params = {
            productId = productId,
            type = PAY_METHOD.ALI,
        }
        addWaitNet(function()
            delWaitNet()
            showToast("支付超时")
        end, 90)
        getOrder(params, function(__data)
            tbl2string(__data)
            local netOrder = cjson.decode(__data.order_info)
            local aliParams = {
                paystr = netOrder.paystr,
            }
            payAli(aliParams, function(status)
                if status ~= "ok" then
                    showToast("支付被取消或失败.")
                    delWaitNet()
                    return
                end
                showToast("支付成功.")
                local gParams = {
                    sid = player.sid,
                    orderid = netOrder.orderid or "",
                    appsflyer = HHUtils:getAppsFlyerId(),
                    advertising = HHUtils:getAdvertisingId(),
                }
                local net = require "net.netClient"
                net:gpay(gParams, function(gdata)
                    tbl2string(gdata)
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
                    layer:removeFromParentAndCleanup(true)
                    if callback then
                        callback(gdata.reward)
                    end
                end)
            end)
        end)
    end)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
    end
    local function onExit()
        layer.notifyParentUnlock()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer
end

return ui
