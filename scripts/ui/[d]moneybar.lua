-- 主UI
local bar = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local bag = require "data.bag"
local midasdata = require "data.midas"
local midas = require "ui.midas.main"
local gemshop = require "ui.shop.main"

function bar.create()
    local layer = CCLayer:create()

    -- container
    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(374, 40))
    container:setScale(view.minScale)
    container:setAnchorPoint(CCPoint(0.5, 1))
    container:setPosition(scalep(480, 568))

    layer:addChild(container)
    layer.container = container
    local container_w = container:getContentSize().width
    local container_h = container:getContentSize().height
    -- coin bg
    local coin_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    coin_bg:setPreferredSize(CCSizeMake(174, 40))
    coin_bg:setAnchorPoint(CCPoint(1, 0.5))
    coin_bg:setPosition(CCPoint(container_w/2-13, container_h/2))
    container:addChild(coin_bg)
    -- gem bg
    local gem_bg = img.createUI9Sprite(img.ui.main_coin_bg)
    gem_bg:setPreferredSize(CCSizeMake(174, 40))
    gem_bg:setAnchorPoint(CCPoint(0, 0.5))
    gem_bg:setPosition(CCPoint(container_w/2+13, container_h/2))
    container:addChild(gem_bg)
    -- coin icon
    local icon_coin = img.createItemIcon2(ITEM_ID_COIN)
    icon_coin:setPosition(CCPoint(5, coin_bg:getContentSize().height/2+2))
    coin_bg:addChild(icon_coin)
    -- gem icon
    local icon_gem = img.createItemIcon2(ITEM_ID_GEM)
    icon_gem:setPosition(CCPoint(5, gem_bg:getContentSize().height/2+2))
    gem_bg:addChild(icon_gem)
    -- coin btn
    local reddot_offset = 5
    local btn_coin0 = img.createUISprite(img.ui.main_icon_plus)
    addRedDot(btn_coin0, {
        px=btn_coin0:getContentSize().width-reddot_offset,
        py=btn_coin0:getContentSize().height-reddot_offset,
    })
    delRedDot(btn_coin0)
    local btn_coin = HHMenuItem:create(btn_coin0)
    btn_coin:setPosition(CCPoint(coin_bg:getContentSize().width-18, coin_bg:getContentSize().height/2+2))
    local btn_coin_menu = CCMenu:createWithItem(btn_coin)
    btn_coin_menu:setPosition(CCPoint(0, 0))
    coin_bg:addChild(btn_coin_menu)

    btn_coin:registerScriptTapHandler(function()
        audio.play(audio.midas)
        local midasdlg = midas.create()
        layer:getParent():addChild(midasdlg, 1001)
    end)

    -- gem btn
    local btn_gem0 = img.createUISprite(img.ui.main_icon_plus)
    local btn_gem = HHMenuItem:create(btn_gem0)
    btn_gem:setPosition(CCPoint(gem_bg:getContentSize().width-18, gem_bg:getContentSize().height/2+2))
    local btn_gem_menu = CCMenu:createWithItem(btn_gem)
    btn_gem_menu:setPosition(CCPoint(0, 0))
    gem_bg:addChild(btn_gem_menu)

    btn_gem:registerScriptTapHandler(function()
        audio.play(audio.button)
        local gemShop = gemshop.create()
        layer:getParent():addChild(gemShop, 1001)
    end)

    -- lbl coin
    local coin_num = bag.coin()
    local lbl_coin = lbl.createFont2(16, num2KM(coin_num), ccc3(255, 246, 223))
    lbl_coin:setPosition(CCPoint(coin_bg:getContentSize().width/2-10, coin_bg:getContentSize().height/2+3))
    coin_bg:addChild(lbl_coin)
    lbl_coin.num = coin_num
    -- lbl gem
    local gem_num = bag.gem()
    local lbl_gem = lbl.createFont2(16, gem_num, ccc3(255, 246, 223))
    lbl_gem:setPosition(CCPoint(gem_bg:getContentSize().width/2-10, gem_bg:getContentSize().height/2+3))
    gem_bg:addChild(lbl_gem)
    lbl_gem.num = gem_num

    local function updateLabels()
        local coinnum = bag.coin()
        if lbl_coin.num ~= coinnum then
            lbl_coin:setString(num2KM(coinnum))
            lbl_coin.num = coinnum
        end
        local gemnum = bag.gem()
        if lbl_gem.num ~= gemnum then
            lbl_gem:setString(gemnum)
            lbl_gem.num = gemnum
        end
    end
    
    local function onUpdate(ticks)
        updateLabels()
        if midasdata.showRedDot() then
            addRedDot(btn_coin0, {
                px=btn_coin0:getContentSize().width-reddot_offset,
                py=btn_coin0:getContentSize().height-reddot_offset,
            })
        else
            delRedDot(btn_coin0)
        end
    end

    layer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    autoLayoutShift(container)

    return layer
end

return bar
