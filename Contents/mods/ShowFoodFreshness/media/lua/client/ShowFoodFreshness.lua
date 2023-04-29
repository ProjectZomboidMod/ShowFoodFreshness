ModShowFoodFreshness = {}

local ISInventoryPane = ISInventoryPane
local Perks = Perks
local SandboxVars = SandboxVars
local getCore = getCore
local getSpecificPlayer = getSpecificPlayer
local getText = getText
local instanceof = instanceof
local isAltKeyDown = isAltKeyDown
local round = round

function ModShowFoodFreshness:init()
    self.SandboxVars = SandboxVars.ShowFoodFreshness or {}
    self.SandboxVars.CookingLevelToShowProgressBar = self.SandboxVars.CookingLevelToShowProgressBar or 0
    self.SandboxVars.CookingLevelToShowDays = self.SandboxVars.CookingLevelToShowDays or 0

    local core = getCore()
    self.FreshBarColor = self:colorInfoToRGBA(core:getGoodHighlitedColor(), 1)
    self.StaleBarColor = self:colorInfoToRGBA(core:getBadHighlitedColor(), 1)
    self.ConditionText = getText("IGUI_invpanel_Condition") .. ":"
    self.DefaultTextColor = self:textRGBA(0.6, 0.6, 0.8, 0.5)
    self.RedTextColor = self:textRGBA(0.7, 0.0, 0.0, 0.5)
    self.DayTextColor = self:textRGBA(0.6, 0.6, 0.8, 1)
    self.HourTextColor = self:textRGBA(0.7, 0.0, 0.0, 1)
    self.MaxOffAgeToRender = 50000

    -- data from zombie.inventory.types.Food.updateAge() v41.78.16
    self.FrozenMultiplier = 0.02
    self.FridgeFactorMultiplier = { 0.4, 0.3, 0.2, 0.1, 0.03 }
    self.FoodRotSpeedMultiplier = { 1.7, 1.4, 1.0, 0.7, 0.4 }
    self.FridgeTypeTable = {
        ["fridge"] = true,
        ["freezer"] = true,
    }

    return self
end

function ModShowFoodFreshness:colorInfoToRGBA(color, alpha)
    return {
        r = color:getR(),
        g = color:getG(),
        b = color:getB(),
        a = alpha or color:getA(),
    }
end

function ModShowFoodFreshness:textRGBA(r, g, b, a)
    -- order bugged in vanilla
    return {
        a = r,
        r = g,
        g = b,
        b = a or 1,
    }
end

function ModShowFoodFreshness:renderCheck(item)
    return isAltKeyDown() and item:getOffAge() <= self.MaxOffAgeToRender and not item:isRotten() and not item:isBurnt()
end

function ModShowFoodFreshness:isFridgeContainer(container)
    return container and self.FridgeTypeTable[container:getType()]
end

function ModShowFoodFreshness:getRotSpeed(item)
    local speed = 1
    if item:isFrozen() then
        speed = speed * (self.FrozenMultiplier or 1)
    elseif item:getHeat() < 1 and self:isFridgeContainer(item:getOutermostContainer()) then
        speed = speed * (self.FridgeFactorMultiplier[SandboxVars.FridgeFactor] or 1)
    end
    return speed * (self.FoodRotSpeedMultiplier[SandboxVars.FoodRotSpeed] or 1)
end

function ModShowFoodFreshness:getTimeTextAndColor(days)
    if days < 0 or days >= 999.5 then
        return nil, nil
    elseif days < 1 then
        return round(days * 24) .. "hr", self.HourTextColor
    else
        local idp = days < 9.95 and 1 or 0
        return round(days, idp) .. "d", self.DayTextColor
    end
end

local mod = ModShowFoodFreshness:init()

local ISInventoryPane_prerender = ISInventoryPane.prerender
function ISInventoryPane:prerender()
    local playerObj = getSpecificPlayer(self.player)
    self.playerCookingLevel = playerObj:getPerkLevel(Perks.Cooking)
    ISInventoryPane_prerender(self)
end

local ISInventoryPane_drawItemDetails = ISInventoryPane.drawItemDetails
function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)
    if instanceof(item, "Food") and mod:renderCheck(item) then
        local age = item:getAge()
        local offAge = item:getOffAge()
        local fgBar
        if (age > offAge) then
            age = age - offAge
            offAge = item:getOffAgeMax() - offAge
            fgBar = mod.StaleBarColor
        else
            fgBar = mod.FreshBarColor
        end
        local text, fgText
        if self.playerCookingLevel >= mod.SandboxVars.CookingLevelToShowDays then
            local days = (offAge - age) / mod:getRotSpeed(item)
            text, fgText = mod:getTimeTextAndColor(days)
        end
        if not text then text = mod.ConditionText end
        if not fgText then fgText = red and mod.RedTextColor or mod.DefaultTextColor end
        local progress = 1 - age / offAge
        local top = self.headerHgt + y * self.itemHgt + yoff
        if self.playerCookingLevel >= mod.SandboxVars.CookingLevelToShowProgressBar then
            self:drawTextAndProgressBar(text, progress, xoff, top, fgText, fgBar)
        else
            self:drawText(text, 40 + 30 + xoff, top + (self.itemHgt - self.fontHgt) / 2, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
        end
    else
        ISInventoryPane_drawItemDetails(self, item, y, xoff, yoff, red)
    end
end
