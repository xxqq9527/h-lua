--- 组装物品的描述
---@private
slkHelper.itemDesc = function(v)
    local d = {}
    if (v.ACTIVE ~= nil) then
        table.insert(d, "主动：" .. v.ACTIVE)
    end
    if (v.PASSIVE ~= nil) then
        table.insert(d, "被动：" .. v.PASSIVE)
    end
    if (v.ATTR ~= nil) then
        table.sort(v.ATTR)
        table.insert(d, slkHelper.attrDesc(v.ATTR, ";"))
    end
    -- 仅文本无效果，适用于例如技能书这类的物品
    if (v.ATTR_TXT ~= nil) then
        table.sort(v.ATTR_TXT)
        table.insert(d, slkHelper.attrDesc(v.ATTR_TXT, ";"))
    end
    local overlie = v.OVERLIE or 1
    local weight = v.WEIGHT or 0
    weight = tostring(math.round(weight))
    table.insert(d, "叠加：" .. overlie .. ";重量：" .. weight .. "Kg")
    if (v.Desc ~= nil and v.Desc ~= "") then
        table.insert(d, v.Desc)
    end
    return string.implode("|n", d)
end

--- 组装物品的说明
---@private
slkHelper.itemUbertip = function(v)
    local d = {}
    if (v.ACTIVE ~= nil) then
        table.insert(d, hColor[slkHelper.conf.color.itemActive]("主动：" .. v.ACTIVE))
        if (v.cooldown ~= nil and v.cooldown > 0) then
            table.insert(d, hColor[slkHelper.conf.color.itemCoolDown]("冷却：" .. v.cooldown .. "秒"))
        end
    end
    if (v.PASSIVE ~= nil) then
        table.insert(d, hColor[slkHelper.conf.color.itemPassive]("被动：" .. v.PASSIVE))
    end
    if (v.RING ~= nil) then
        if (v.RING.radius ~= nil or (type(v.RING.target) == 'table' and #v.RING.target > 0)) then
            local txt = "光环目标："
            if (v.RING.radius ~= nil) then
                txt = txt .. v.RING.radius .. '范围内'
            end
            if (type(v.RING.target) == 'table' and #v.RING.target > 0) then
                local labels = {}
                for _, t in ipairs(v.RING.target) do
                    table.insert(labels, CONST_TARGET_LABEL[t])
                end
                txt = txt .. string.implode(',', labels)
            end
            table.insert(d, hColor[slkHelper.conf.color.ringArea](txt))
        end
        if (v.RING.attr ~= nil) then
            table.insert(d, hColor[slkHelper.conf.color.ringTarget]("光环效果：|n" .. slkHelper.attrDesc(v.RING.attr, "|n", ' - ')))
        end
        table.sort(v.RING.attr)
    end
    if (v.ATTR ~= nil) then
        table.sort(v.ATTR)
        table.insert(d, hColor[slkHelper.conf.color.itemAttr](slkHelper.attrDesc(v.ATTR, "|n")))
    end
    -- 仅文本无效果，适用于例如技能书这类的物品
    if (v.ATTR_TXT ~= nil) then
        table.sort(v.ATTR_TXT)
        table.insert(d, hColor[slkHelper.conf.color.itemAttr](slkHelper.attrDesc(v.ATTR_TXT, "|n")))
    end
    -- 作为零件
    if (slkHelper.item.synthesisMapping.fragment[v.Name] ~= nil
        and #slkHelper.item.synthesisMapping.fragment[v.Name] > 0) then
        table.insert(d, hColor[slkHelper.conf.color.itemFragment]("可以合成：" .. string.implode(
            '、',
            slkHelper.item.synthesisMapping.fragment[v.Name]))
        )
    end
    -- 合成公式
    if (slkHelper.item.synthesisMapping.profit[v.Name] ~= nil) then
        table.insert(d, hColor[slkHelper.conf.color.itemProfit]("需要零件：" .. slkHelper.item.synthesisMapping.profit[v.Name]))
    end
    local overlie = v.OVERLIE or 1
    table.insert(d, hColor[slkHelper.conf.color.itemOverlie]("叠加：" .. overlie))
    local weight = v.WEIGHT or 0
    weight = tostring(math.round(weight))
    table.insert(d, hColor[slkHelper.conf.color.itemWeight]("重量：" .. weight .. "Kg"))
    if (v.Desc ~= nil and v.Desc ~= "") then
        table.insert(d, hColor[slkHelper.conf.color.itemDesc](v.Desc))
    end
    return string.implode("|n", d)
end

--- 创建一件物品的冷却技能
---@private
slkHelper.itemCooldown0ID = nil
slkHelper.itemCooldownID0 = function()
    if (slkHelper.itemCooldown0ID == nil) then
        local oobTips = "ITEMS_DEFCD_ID_#0"
        local oob = slk.ability.AIgo:new("items_default_cooldown_#0")
        oob.Effectsound = ""
        oob.Name = oobTips
        oob.Tip = oobTips
        oob.Ubertip = oobTips
        oob.Art = ""
        oob.TargetArt = ""
        oob.Targetattach = ""
        oob.DataA1 = 0
        oob.Art = ""
        oob.CasterArt = ""
        oob.Cool = 0
        slkHelper.itemCooldown0ID = oob:get_id()
    end
    return slkHelper.itemCooldown0ID
end

--- 创建一件物品的冷却技能
--- 使用的模版仅仅是模版，并不会有默认的特效和效果
---@private
slkHelper.itemCooldownID = function(v)
    if (v.cooldown == nil) then
        return "AIat"
    end
    if (v.cooldown < 0) then
        v.cooldown = 0
    end
    if (v.cooldown == 0) then
        return slkHelper.itemCooldownID0()
    end
    local oobTips = "ITEMS_DEFCD_ID_" .. v.Name
    local oob
    if (v.cooldownTarget == 'location') then
        -- 对点（模版：照明弹）
        oob = slk.ability.Afla:new("items_default_cooldown_" .. v.Name)
        oob.DataA1 = 0
        oob.EfctID1 = ""
        oob.Dur1 = 0.01
        oob.HeroDur1 = 0.01
        oob.Rng1 = v.range
        oob.Area1 = 0
        oob.DataA1 = 0
        oob.DataB1 = 0
    elseif (v.cooldownTarget == 'unit') then
        -- 对点范围（模版：暴风雪）
        oob = slk.ability.ACbz:new("items_default_cooldown_" .. v.Name)
    elseif (v.cooldownTarget == 'unit') then
        -- 对单位（模版：霹雳闪电）
        oob = slk.ability.ACfb:new("items_default_cooldown_" .. v.Name)
    else
        -- 立刻（模版：金箱子）
        oob = slk.ability.AIgo:new("items_default_cooldown_" .. v.Name)
        oob.DataA1 = 0
    end
    oob.Effectsound = ""
    oob.Name = oobTips
    oob.Tip = oobTips
    oob.Ubertip = oobTips
    oob.TargetArt = v.TargetArt or ""
    oob.Targetattach = v.Targetattach or ""
    oob.CasterArt = v.CasterArt or ""
    oob.Art = ""
    oob.item = 1
    oob.Cast1 = v.cast or 0
    oob.Cost1 = v.cost or 0
    oob.Cool1 = v.cooldown
    oob.Requires = ""
    oob.Hotkey = ""
    oob.Buttonpos1 = "0"
    oob.Buttonpos2 = "0"
    oob.race = "other"
    return oob:get_id()
end

slkHelper.item = {}

---@private
slkHelper.item.synthesisMapping = {
    profit = {},
    fragment = {},
}

--- 物品合成公式数组，只支持slkHelper创建的注册物品
---例子1 "小刀割大树=小刀+大树" 2个不一样的合1个
---例子2 "三头地狱犬的神识=地狱狗头x3" 3个一样的合1个
---例子3 "精灵神水x2=精灵的眼泪x50" 50个一样的合一种,但得到2个
---例子4 {{"小刀割大树",1},{"小刀",1},{"大树",1}} 对象型配置，第一项为结果物品(适合物品名称包含特殊字符的物品，如+/=影响公式的符号)
slkHelper.item.synthesis = function(formula)
    for _, v in ipairs(formula) do
        local profit = ''
        local fragment = {}
        if (type(v) == 'string') then
            local f1 = string.explode('=', v)
            if (string.strpos(f1[1], 'x') == false) then
                profit = { f1[1], 1 }
            else
                local temp = string.explode('x', f1[1])
                temp[2] = math.floor(temp[2])
                profit = temp
            end
            local f2 = string.explode('+', f1[2])
            for _, vv in ipairs(f2) do
                if (string.strpos(vv, 'x') == false) then
                    table.insert(fragment, { vv, 1 })
                else
                    local temp = string.explode('x', vv)
                    temp[2] = math.floor(temp[2])
                    table.insert(fragment, temp)
                end
            end
        elseif (type(v) == 'table') then
            profit = v[1]
            fragment = table.remove(v, 1)
        end
        --
        local fmStr = {}
        for _, fm in ipairs(fragment) do
            if (fm[2] <= 1) then
                table.insert(fmStr, fm[1])
            else
                table.insert(fmStr, fm[1] .. 'x' .. fm[2])
            end
            if (slkHelper.item.synthesisMapping.fragment[fm[1]] == nil) then
                slkHelper.item.synthesisMapping.fragment[fm[1]] = {}
            end
            if (table.includes(profit[1], slkHelper.item.synthesisMapping.fragment[fm[1]]) == false) then
                table.insert(slkHelper.item.synthesisMapping.fragment[fm[1]], profit[1])
            end
        end
        slkHelper.item.synthesisMapping.profit[profit[1]] = string.implode('+', fmStr)
        --
        slkHelper.save({
            class = "synthesis",
            profit = profit,
            fragment = fragment,
        })
    end
end

--- 创建一件影子物品
--- 不主动使用，由normal设置{useShadow = true}自动调用
--- 设置的CUSTOM_DATA数据会自动传到数据中
---@private
---@param v table
slkHelper.item.shadow = function(v)
    slkHelper.count = slkHelper.count + 1
    local Name = "# " .. v.Name
    local obj = slk.item.rat9:new("itemShadows_" .. v.Name)
    obj.Name = Name
    obj.Description = slkHelper.itemDesc(v)
    obj.Ubertip = slkHelper.itemUbertip(v)
    obj.goldcost = v.goldcost
    obj.lumbercost = v.lumbercost
    obj.class = "Charged"
    obj.Level = v.lv
    obj.oldLevel = v.lv
    obj.Art = v.Art
    obj.file = v.file
    obj.prio = v.prio or 0
    obj.abilList = ""
    obj.ignoreCD = 1
    obj.drop = v.drop or 0
    obj.perishable = 1
    obj.usable = 1
    obj.powerup = 1
    obj.sellable = v.sellable or 1
    obj.pawnable = v.pawnable or 1
    obj.droppable = v.droppable or 1
    obj.pickRandom = v.pickRandom or 1
    obj.stockStart = v.stockStart or 0
    obj.stockRegen = v.stockRegen or 0
    obj.stockMax = v.stockMax or 1
    obj.uses = v.uses
    if (v.Hotkey ~= nil) then
        obj.Hotkey = v.Hotkey
        v.Buttonpos1 = CONST_HOTKEY_FULL_KV[v.Hotkey].Buttonpos1 or 0
        v.Buttonpos2 = CONST_HOTKEY_FULL_KV[v.Hotkey].Buttonpos2 or 0
        obj.Tip = "获得" .. v.Name .. "(" .. hColor[slkHelper.conf.color.hotKey](v.Hotkey) .. ")"
    else
        obj.Buttonpos1 = v.Buttonpos1 or 0
        obj.Buttonpos2 = v.Buttonpos2 or 0
        obj.Tip = "获得" .. v.Name
    end
    local id = obj:get_id()
    return {
        SHADOW = true,
        CUSTOM_DATA = v.CUSTOM_DATA or {},
        CLASS_GROUP = v.CLASS_GROUP or nil,
        ITEM_ID = id,
        Name = Name,
        class = v.class,
        Art = v.Art,
        file = v.file,
        goldcost = v.goldcost,
        lumbercost = v.lumbercost,
        usable = 1,
        powerup = 1,
        perishable = 1,
        sellable = v.sellable,
        OVERLIE = 1,
        WEIGHT = v.WEIGHT,
        ATTR = v.ATTR,
        RING = v.RING,
    }
end

--- 创建一件实体物品
--- 设置的CUSTOM_DATA数据会自动传到数据中
--- 默认不会自动协助开启shadow模式（满格拾取/合成）可以设置slkHelper的conf来配置
---@public
---@param v table
slkHelper.item.normal = function(v)
    slkHelper.count = slkHelper.count + 1
    local cd = slkHelper.itemCooldownID(v)
    local abilList = ""
    local usable = 0
    local OVERLIE = v.OVERLIE or 1
    local ignoreCD = 0
    if (cd ~= "AIat") then
        abilList = cd
        usable = 1
        if (v.perishable == nil) then
            v.perishable = 1
        end
        v.class = "Charged"
        if (cd == slkHelper.itemCooldown0ID) then
            ignoreCD = 1
        end
    else
        if (v.perishable == nil) then
            v.perishable = 0
        end
        v.class = "Permanent"
    end
    local lv = 1
    v.goldcost = v.goldcost or 0
    v.lumbercost = v.lumbercost or 0
    v.uses = v.uses or 1
    lv = math.floor((v.goldcost + v.lumbercost) / 500)
    if (lv < 1) then
        lv = 1
    end
    v.Name = v.Name or "未命名" .. slkHelper.count
    v.Art = v.Art or "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
    v.file = v.file or "Objects\\InventoryItems\\TreasureChest\\treasurechest.mdl"
    v.powerup = v.powerup or 0
    v.sellable = v.sellable or 1
    v.pawnable = v.pawnable or 1
    v.dropable = v.dropable or 1
    v.WEIGHT = v.WEIGHT or 0
    -- 处理useShadow
    local useShadow = (slkHelper.conf.itemAutoShadow == true and v.powerup == 0)
    if (type(v.useShadow) == 'boolean') then
        useShadow = v.useShadow
    end
    local shadowData = {}
    if (useShadow == true) then
        shadowData = slkHelper.item.shadow(v)
    end
    if (v.RING ~= nil) then
        v.RING.effectTarget = v.RING.effectTarget or "Abilities\\Spells\\Other\\GeneralAuraTarget\\GeneralAuraTarget.mdl"
        v.RING.attach = v.RING.attach or "origin"
        v.RING.attachTarget = v.RING.attachTarget or "origin"
        v.RING.radius = v.RING.radius or 600
        -- target请参考物编的目标允许
        local target
        if (type(v.RING.target) == 'table' and #v.RING.target > 0) then
            target = v.RING.target
        elseif (type(v.RING.target) == 'string' and string.len(v.RING.target) > 0) then
            target = string.explode(',', v.RING.target)
        else
            target = { 'air', 'ground', 'friend', 'self', 'vuln', 'invu' }
        end
        v.RING.target = target
    end
    local obj = slk.item.rat9:new("items_" .. v.Name)
    obj.Name = v.Name
    obj.Description = slkHelper.itemDesc(v)
    obj.Ubertip = slkHelper.itemUbertip(v)
    obj.goldcost = v.goldcost or 1000000
    obj.lumbercost = v.lumbercost or 1000000
    obj.class = v.class
    obj.Level = lv
    obj.oldLevel = lv
    obj.Art = v.Art
    obj.file = v.file
    obj.prio = v.prio or 0
    obj.cooldownID = cd
    obj.abilList = abilList
    obj.ignoreCD = ignoreCD
    obj.drop = v.drop or 0
    obj.perishable = v.perishable
    obj.usable = usable
    obj.powerup = v.powerup
    obj.sellable = v.sellable
    obj.pawnable = v.pawnable
    obj.droppable = v.droppable or 1
    obj.pickRandom = v.pickRandom or 1
    obj.stockStart = v.stockStart or 0 -- 库存开始
    obj.stockRegen = v.stockRegen or 0 -- 进货周期
    obj.stockMax = v.stockMax or 1 -- 最大库存
    obj.uses = v.uses --使用次数
    if (v.Hotkey ~= nil) then
        obj.Hotkey = v.Hotkey
        v.Buttonpos1 = CONST_HOTKEY_FULL_KV[v.Hotkey].Buttonpos1 or 0
        v.Buttonpos2 = CONST_HOTKEY_FULL_KV[v.Hotkey].Buttonpos2 or 0
        obj.Tip = "获得" .. v.Name .. "(" .. hColor[slkHelper.conf.color.hotKey](v.Hotkey) .. ")"
    else
        obj.Buttonpos1 = v.Buttonpos1 or 0
        obj.Buttonpos2 = v.Buttonpos2 or 0
        obj.Tip = "获得" .. v.Name
    end
    local id = obj:get_id()
    if (shadowData.ITEM_ID ~= nil) then
        shadowData.SHADOW_ID = id
        table.insert(slkHelperHashData, { type = "item", data = shadowData })
    end
    table.insert(slkHelperHashData, {
        type = "item",
        data = {
            CUSTOM_DATA = v.CUSTOM_DATA or {},
            CLASS_GROUP = v.CLASS_GROUP or nil,
            ITEM_ID = id,
            Name = v.Name,
            class = v.class,
            Art = v.Art,
            file = v.file,
            goldcost = v.goldcost,
            lumbercost = v.lumbercost,
            usable = usable,
            powerup = v.powerup,
            perishable = v.perishable,
            sellable = v.sellable,
            OVERLIE = OVERLIE,
            WEIGHT = v.WEIGHT,
            ATTR = v.ATTR,
            RING = v.RING,
            SHADOW_ID = shadowData.ITEM_ID or nil,
            cooldownID = cd
        }
    })
    return shadowData.ITEM_ID or id
end