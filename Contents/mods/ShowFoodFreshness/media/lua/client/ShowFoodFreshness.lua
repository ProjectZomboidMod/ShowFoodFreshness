ModShowFoodFreshness = {}

local ISInventoryPane = ISInventoryPane
local getCore = getCore
local getText = getText
local instanceof = instanceof
local isAltKeyDown = isAltKeyDown

local function colorInfoToRGBA(color, alpha)
    return {
        r = color:getR(),
        g = color:getG(),
        b = color:getB(),
        a = alpha or color:getA(),
    }
end

function ModShowFoodFreshness:init()
    local core = getCore()
    self.freshColor = colorInfoToRGBA(core:getGoodHighlitedColor(), 1)
    self.staleColor = colorInfoToRGBA(core:getBadHighlitedColor(), 1)
    self.conditiontext = getText("IGUI_invpanel_Condition") .. ":"
    return self
end

function ModShowFoodFreshness:canDrawItemDetails(item)
    return isAltKeyDown() and instanceof(item, "Food")
end

local mod = ModShowFoodFreshness:init()

local ISInventoryPane_drawItemDetails = ISInventoryPane.drawItemDetails
function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)
    if mod.canDrawItemDetails(item) then
        local age = item:getAge()
        local offAge = item:getOffAge()
        local fgBar
        if (age > offAge) then
            age = age - offAge
            offAge = item:getOffAgeMax() - offAge
            fgBar = mod.staleColor
        else
            fgBar = mod.freshColor
        end
        local progress = 1 - age / offAge
        local top = self.headerHgt + y * self.itemHgt + yoff
        local fgText = {r=0.6, g=0.8, b=0.5, a=0.6}
        if red then fgText = {r=0.0, g=0.0, b=0.5, a=0.7} end
        self:drawTextAndProgressBar(mod.conditiontext, progress, xoff, top, fgText, fgBar)
    else
        ISInventoryPane_drawItemDetails(self, item, y, xoff, yoff, red)
    end
end
