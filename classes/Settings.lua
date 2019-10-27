---------------------------------------------------------------------------------------------------------
-- S E T T I N G S
---------------------------------------------------------------------------------------------------------
RF_AB.Settings.panel = nil
function RF_AB.Settings:CreateWindow()
    local LAM2 = LibAddonMenu2
    local saveData = RF_AB.savedVariables
    local panelData =
    {
        type = "panel",
        name = "red_Freak's Auto Buyer",
        displayName = "|ccc0000red_Freak|r's Auto Buyer",
        author = "@|ccc0000red_Freak|r",
        version = RF_AB.appVersion,
        registerForRefresh = true,
        registerForDefaults = true
    }

    LAM2:RegisterAddonPanel(RF_AB.addonName .. '_settings', panelData)

    local optionsData =
    {
        [1] = {
            type = "header",
            text = "red_Freak's AutoBuyer",
            width = "full"
        },
        [2] = {
            type = "description",
            text = 'red_Freak\'s AutoBuyer Settings:\r\n' ..
                    'Thanks to AwesomeGuildStore, PXVendorMagic, TamrielTradeCenter and FCOItemSaver for code inspiration.\r\n' ..
                    'Special thanks to wiki.esoui.com and https://en.uesp.net!\r\n' ..
                    '\r\n' ..
                    'The guild functionalllity highly uses AwesomeGuildStore functionality. Please donate to them. https://www.esoui.com/downloads/info695-AwesomeGuildStore.html#donate',
        },
        [3] = {
            type = "submenu",
            name = "general settings",
            controls = {
                {
                    type = "description",
                    text = "general addon settings",
                },
                {
                    type = "checkbox",
                    name = "enable at store",
                    tooltip = "Enable AutoBuyer for NPC stores.",
                    getFunc = function() return saveData.storeEnabled end,
                    setFunc = function(e) saveData.storeEnabled = e end,
                    default = RF_AB.defaults.storeEnabled,
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = "enable at guild kiosk",
                    tooltip = "Enable AutoBuyer for guild kiosks. (currently not implemented)",
                    getFunc = function() return saveData.guildEnabled end,
                    setFunc = function(value) saveData.guildEnabled = value end,
                    default = RF_AB.defaults.quildEnabled,
                    width = "half"
                },
                {
                    type = "dropdown",
                    name = "store buying strategy",
                    tooltip = "Defines the way purchases are made\r\n\r\n" ..
                            "|cCC0000just buy|r first seen item will be bought till stack is eached. Then second and so on.\r\n" ..
                            "|cCC0000equal buying|r the addOn checks if it's possible to buy all offered items till stack. If not, the" ..
                            "amount for all items will be adjusted.\r\n",
                    choices = { "just buy", "equal buying" },
                    getFunc = function() return RF_AB.savedVariables.buyingStrategyStore end,
                    setFunc = function(value) RF_AB.savedVariables.buyingStrategyStore = value end,
                    default = RF_AB.defaults.buyingStrategyStore,
                    disabled = function() return not (saveData.storeEnabled) end,
                    width = "half"
                },
                {
                    type = "dropdown",
                    name = "guil buying strategy",
                    tooltip = "Defines the way purchases are made\r\n\r\n" ..
                            "|cCC0000fill storage|r only buy until set storage is bought.\r\n" ..
                            "|cCC0000spend gold|r If the price is less buy more.\r\n" ..
                            "|cCC0000best deal|r like spend gold, but if the deal is great (50% of price) buy up to 10x storage",
                    choices = { "fill storage", "spend gold", "best deal" },
                    getFunc = function() return RF_AB.savedVariables.buyingStrategyGuild end,
                    setFunc = function(value) RF_AB.savedVariables.buyingStrategyGuild = value end,
                    default = RF_AB.defaults.buyingStrategyGuild,
                    disabled = function() return not (saveData.quildEnabled) end,
                    width = "half"
                },
                {
                    type = "slider",
                    name = "money to keep",
                    tooltip = "How much gold should be ignored.",
                    min = 0,
                    max = 1000000,
                    step = 1000,
                    getFunc = function() return RF_AB.savedVariables.keepMoney end,
                    setFunc = function(value) RF_AB.savedVariables.keepMoney = value end,
                    default = RF_AB.defaults.keepMoney,
                    disabled = function() return RF_AB.Settings:isDisabled() end
                },
            }
        }
    }
    optionsData = RF_AB.Settings:GetItemSettings(optionsData, 4)

    RF_AB.Settings.panel = LAM2:RegisterOptionControls(RF_AB.addonName .. '_settings', optionsData)
end

function RF_AB.Settings:isDisabled()
    return (not (RF_AB.savedVariables.storeEnabled or RF_AB.savedVariables.guildEnabled))
end

function RF_AB.Settings:isItemDisabled(name)
    return (not (RF_AB.savedVariables.items[name].buyStore or RF_AB.savedVariables.items[name].buyGuild))
end

function RF_AB.Settings:getItemDescription(item_name)
    return {
        type = "description",
        name_internal = "&{parent}_Description",
        text = RF_AB.savedVariables.items[item_name].itemLink,
        enableLinks = true,
        width = 'full'
    }
end

function RF_AB.Settings.getItemFieldByContext(context, item_name, field)
    return RF_AB.Settings['getItemFieldByContext_' .. field](context, item_name)
end

function RF_AB.Settings.getItemFieldByContext_Enable(context, item_name)
    return {
        type = "checkbox",
        name_internal = "${parent}_" .. context .. '_Enable',
        name = "enable at " .. context:lower(),
        tooltip = "enable at " .. context:lower(),
        getFunc = function() return RF_AB.savedVariables.items[item_name]['buy' .. context] end,
        setFunc = function(value) RF_AB.savedVariables.items[item_name]['buy' .. context] = value end,
        default = false,
        width = "half",
        disabled = function() return not (RF_AB.savedVariables[context:lower() .. 'Enabled'] and RF_AB.savedVariables.items[item_name]['isAvailable' .. context]) end
    }
end

function RF_AB.Settings.getItemFieldByContext_Price(context, item_name)
    return {
        type = "slider",
        name_internal = "${parent}_" .. context .. '_Price',
        name = "max price per unit (" .. context:lower() .. ")",
        min = 0,
        max = 10000,
        step = 0.01,
        decimals = 2,
        tooltip = "max price per unit (" .. context:lower() .. ")",
        getFunc = function() return RF_AB.savedVariables.items[item_name]['price' .. context] end,
        setFunc = function(value) RF_AB.savedVariables.items[item_name]['price' .. context] = value end,
        default = 0,
        width = "half",
        disabled = function() return not (RF_AB.savedVariables[context:lower() .. 'Enabled'] and RF_AB.savedVariables.items[item_name]['buy' .. context] and RF_AB.savedVariables.items[item_name]['isAvailable' .. context]) end
    }
end

function RF_AB.Settings.getItemFieldByContext_Amount(context, item_name)
    return {
        type = "slider",
        name_internal = "${parent}_" .. context .. '_Amount',
        name = "max stock (" .. context:lower() .. ")",
        min = 0,
        max = 10000,
        step = 1,
        tooltip = "amount to buy at " .. context:lower(),
        getFunc = function() return RF_AB.savedVariables.items[item_name]['toBuy' .. context] end,
        setFunc = function(value) RF_AB.savedVariables.items[item_name]['toBuy' .. context] = value end,
        default = 100,
        width = "half",
        disabled = function() return not (RF_AB.savedVariables[context:lower() .. 'Enabled'] and RF_AB.savedVariables.items[item_name]['buy' .. context] and RF_AB.savedVariables.items[item_name]['isAvailable' .. context]) end
    }
end

function RF_AB.Settings:getItemFieldsByContext(context, item_name)
    return {
        RF_AB.Settings.getItemFieldByContext(context, item_name, 'Enable'),
        RF_AB.Settings.getItemFieldByContext(context, item_name, 'Price'),
        RF_AB.Settings.getItemFieldByContext(context, item_name, 'Amount')
    }
end

function RF_AB.Settings:getItemFields(item_name)
    local itemFields = {
        RF_AB.Settings:getItemDescription(item_name)
    }

    local storeControls = RF_AB.Settings:getItemFieldsByContext('Store', item_name)
    local guildControls = RF_AB.Settings:getItemFieldsByContext('Guild', item_name)

    for i = 1, table.getn(storeControls) do
        table.insert(itemFields, storeControls[i])
        table.insert(itemFields, guildControls[i])
    end

    return itemFields
end

function RF_AB.Settings:GetItemSettings(optionsData, mainKey)
    local optionsDataSub = {
        [1] = {
            type = "description",
            text = "this tab will be filled by visting stores - after reloadUi",
        }
    }

    if RF_AB.savedVariables.items ~= nil then
        -- prepare categories
        optionsDataSub[2] = {
            type = "submenu",
            name = "other",
            controls = {},
        }
        for i = 1, CRAFTING_TYPE_MAX_VALUE, 1 do
            optionsDataSub[(i + 2)] = {
                type = "submenu",
                name = RF_AB.Utils.getCraftingSkillType(i),
                controls = {},
            }
        end

        -- sort the items by name
        local names = {}
        for name in pairs(RF_AB.savedVariables.items) do table.insert(names, name) end
        table.sort(names)

        -- iterate sortet
        local i = 0
        for _, name in ipairs(names) do
            local icon = ''
            if (RF_AB.savedVariables.items[name].icon ~= nil) then
                icon = RF_AB.savedVariables.items[name].icon
            end

            local optionsDataSubItem = RF_AB.Settings:getItemFields(name)

            -- add to category
            local skillType = GetItemLinkCraftingSkillType(RF_AB.savedVariables.items[name].itemLink)
            local function getContextString(item_name, context)
                if (RF_AB.savedVariables.items[item_name]['isAvailable' .. context] ~= nil) then
                    return ' [' .. context:lower() .. ']'
                else
                    return ''
                end
            end

            table.insert(optionsDataSub[2 + skillType].controls, {
                type = "submenu",
                name = RF_AB.savedVariables.items[name].itemLink .. getContextString(name, 'Store') .. getContextString(name, 'Guild'),
                controls = optionsDataSubItem
            })

            i = i + 1
        end
    end

    local entries = table.getn(optionsDataSub[2])
    for i = 1, CRAFTING_TYPE_MAX_VALUE + 1, 1 do
        local entries_category = #optionsDataSub[1 + i].controls
        optionsDataSub[1 + i].name = (optionsDataSub[1 + i].name .. '(' .. entries_category .. ' entries)')
        entries = entries + entries_category
    end

    optionsData[mainKey] = {
        type = "submenu",
        name = "item settings (" .. entries .. " entries)",
        controls = optionsDataSub,
    }

    return optionsData
end
