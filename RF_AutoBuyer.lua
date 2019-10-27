local version = '0.2.17 beta'
local addonName = "red_Freak's AutoBuyer"

-- First, we create a namespace for our addon by declaring a top-level table that will hold everything else.
RF_AB = {
    Utils = {},
    Buyer = {},
    Settings = {},
    ContextMenu = {}
}

-- This isn't strictly necessary, but we'll use this string later when registering events.
-- Better to define it in a single place rather than retyping the same string.
RF_AB.addonName = addonName
RF_AB.loaded = false

RF_AB.defaults = {
    storeEnabled = true,
    quildEnabled = false,
    verbose = true,
    keepMoney = 10000,
    buyingStrategyStore = "equal buying",
    buyingStrategyGuild = "best deal"
}

-- Next we create a function that will initialize our addon
function RF_AB:Initialize()
    RF_AB.appVersion = version
    RF_AB.addonName = addonName
    RF_AB.savedVariables = ZO_SavedVars:New('RF_AB_SavedVars', 1.0, nil, self.defaults)

    -- register addon settings depends on LibAddonMenu2
    RF_AB.Settings:CreateWindow()
    -- register contect menu depends on LibCustomMenu
    RF_AB.ContextMenu:Register()

    RF_AB.loaded = true
end

function RF_AB:registerItem(name, price, itemLink, icon, context)
    if (RF_AB.savedVariables.items == nil) then RF_AB.savedVariables.items = {} end
    if (RF_AB.savedVariables.items[name] == nil) then
        RF_AB.savedVariables.items[name] = {
            buyStore = false,
            buyGuild = false,
            name = name,
            price = price,
            toBuy = 100,
            itemLink = itemLink,
            icon = icon
        }
    end
    if (RF_AB.savedVariables.items[name]['isAvailable' .. context] == nil) then
        RF_AB.savedVariables.items[name]['isAvailable' .. context] = true
    end
end

function RF_AB:getItemConfig(name)
    return RF_AB.savedVariables.items[name]
end

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function RF_AB:OnAddOnLoaded(event, addonName)
    -- name seems to be nil every time so we help us self
    if (not (RF_AB.loaded)) then
        RF_AB:Initialize()
        --  RF_AB.Handler.handleOnAddOnLoad(event, addonName)
        EVENT_MANAGER:UnregisterForEvent(RF_AB.addonName, EVENT_ADD_ON_LOADED)
    end
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(RF_AB.addonName, EVENT_ADD_ON_LOADED, RF_AB.OnAddOnLoaded)
