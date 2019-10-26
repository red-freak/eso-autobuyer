function RF_AB.Utils.log(message, level)
    if (level == nil) then level = 'log' end
    local colors = {
        white = 'FFFFFF',
        success = '00CC00',
        log = 'FFFF00',
        message = 'FFFF00',
        debug = 'CCCCCC',
        hint = 'CCCC00',
        warning = 'CC6600',
        error = 'CC0000'
    }

    if (not (RF_AB.savedVariables.verbose) and (level ~= 'success' and level ~= 'error' and level ~= 'message')) then
        return
    end


    local color = colors['log']
    if (colors[level] ~= nil) then color = colors[level] end

    CHAT_SYSTEM:AddMessage('|cCCCCCCAutoBuyer:|r |c' .. color .. message .. '|r')
end

function RF_AB.Utils.debug(message)
    RF_AB.Utils.log(message, 'debug')
end

function RF_AB.debug(message)
    RF_AB.Utils.debug(message)
end

function RF_AB.Utils.message(message)
    RF_AB.Utils.log(message, 'message')
end

function RF_AB.Utils.hint(message)
    RF_AB.Utils.log(message, 'hint')
end

function RF_AB.Utils.warn(message)
    RF_AB.Utils.log(message, 'warning')
end

function RF_AB.Utils.error(message)
    RF_AB.Utils.log(message, 'error')
end

function RF_AB.Utils.success(message)
    RF_AB.Utils.log(message, 'success')
end

function RF_AB.Utils:MoneyString(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    -- ZO_Currency_FormatPlatform(CURT_MONEY, entry.purchasePrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
    return formatted
end

function RF_AB.Utils.getCraftingSkillType(id)
    if (id > CRAFTING_TYPE_MAX_VALUE) then id = 0 end

    local typeToHumanReadable = {}
    typeToHumanReadable[CRAFTING_TYPE_ALCHEMY] = 'Alchemy'
    typeToHumanReadable[CRAFTING_TYPE_BLACKSMITHING] = 'Blacksmithing'
    typeToHumanReadable[CRAFTING_TYPE_CLOTHIER] = 'Clothier'
    typeToHumanReadable[CRAFTING_TYPE_ENCHANTING] = 'Enchanting'
    typeToHumanReadable[CRAFTING_TYPE_INVALID] = 'Invalid'
    typeToHumanReadable[CRAFTING_TYPE_JEWELRYCRAFTING] = 'Jewelery'
    typeToHumanReadable[CRAFTING_TYPE_PROVISIONING] = 'Provisioning'
    typeToHumanReadable[CRAFTING_TYPE_WOODWORKING] = 'Woodworking'

    return typeToHumanReadable[id]
end

-- returns icon, name, stack, pricePerUnit, itemLink
function RF_AB.Utils.getItemInfo(bagId, slotIndex)
    local icon, name, stack, pricePerUnit, itemLink, context
    if (bagId == nil and slotIndex ~= nil) then
        icon, name, _, stack, _, _, _, _, _, pricePerUnit = GetTradingHouseSearchResultItemInfo(slotIndex)
        itemLink = GetTradingHouseSearchResultItemLink(slotIndex, LINK_STYLE_DEFAULT)
        context = 'Guild'
    elseif (bagId ~= nil and slotIndex ~= nil) then
        -- we are in an inventory, see https://wiki.esoui.com/Globals#Bag
        icon, stack, pricePerUnit, _, _, _, _, _ = GetItemInfo(bagId, slotIndex)
        itemLink = GetItemLink(bagId, slotIndex)
        name = GetItemLinkName(itemLink)
        context = 'Bag'
    else -- if (bagId == nil and slotIndex == nil) then
        RF_AB.debug('currently store context menu support is not available')
        context = 'Store'
    end

    return icon, name, stack, pricePerUnit, itemLink
end
