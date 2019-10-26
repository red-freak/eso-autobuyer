-- hook for all but store context
local function show(inventorySlot, slotAction)
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local icon, name, stack, pricePerUnit, itemLink, context = RF_AB.Utils.getItemInfo(bagId, slotIndex, inventorySlot)

    if (not (itemLink)) then return end
    if not (GetItemLinkFilterTypeInfo(itemLink) == ITEMFILTERTYPE_CRAFTING and not (IsItemLinkBound(itemLink))) then
        return
    end

    -- if it's in inventory and not bound than it must be tradeable by guild
    RF_AB:registerItem(name, pricePerUnit, itemLink, icon, 'Guild')
    -- register menu
    AddCustomMenuItem('Auto Buyer settings', function() RF_AB.ContextMenu:Callback(name) end)
end

function RF_AB.ContextMenu:Register()
    local LCM = LibCustomMenu
    LCM:RegisterContextMenu(show, LCM.CATEGORY_PRIMARY)
end

local function RF_AB_SettingDialog_CloseButton_OnClicked()
    -- todo: save data
    ZO_PopupTooltip_Hide()
    RF_AB_SettingsDialog:SetHidden(true)
end

local RF_AB_SettingDialog_Fields = {}

local function RF_AB_SettingDialog_itemField_OnValueChanged(self, value, reason)
    d(value)
    local field_name_price = self:GetName():gsub('_Enable', '_Price')
    LibAddonMenu2.util.RequestRefreshIfNeeded(RF_AB_SettingDialog_Fields[field_name_price])
    local field_name_amount = self:GetName():gsub('_Enable', '_Amount')
    LibAddonMenu2.util.RequestRefreshIfNeeded(RF_AB_SettingDialog_Fields[field_name_amount])
end

function RF_AB.ContextMenu.GetDescriptionText(itemConfig)
    return itemConfig.itemLink
end

function RF_AB.ContextMenu.GetSalesTrackerText(itemConfig)
    -- todo: add TTC, MM and ATT support
    return ''
end

local function injectDataToLAMField(control, controlData)
    if (controlData.type == 'checkbox') then
        -- inject our self for OnMouseUp - currently only Enabled is checkbox
        local origHandler = control:GetHandler('OnMouseUp')
        control:SetHandler('OnMouseUp', function(self, value, eventReason)
            origHandler(self)
            RF_AB_SettingDialog_itemField_OnValueChanged(self, value, eventReason)
        end)
    elseif (controlData.type == 'slider') then
        -- nil
    end
    -- common data
    control.label:SetText(controlData.name)
    control.data.tooltipText = controlData.tooltip
    control.data.setFunc = controlData.setFunc
    control.data.getFunc = controlData.getFunc
    control.data.disabled = controlData.disabled
    LibAddonMenu2.util.RequestRefreshIfNeeded(control)
end

local function showSettingsDialog(itemConfig)
    local wm = WINDOW_MANAGER
    local tmp
    -- main window
    local dialog = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog"] or CreateTopLevelWindow("RF_AB_SettingsDialog")
    RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog"] = dialog
    dialog:SetHidden(false)
    dialog:SetAnchor(TOPLEFT, nil, TOPLEFT, 100, 150)
    dialog:SetDimensions(600, 400)
    dialog:SetMovable(false)
    -- mock some values to be able to be handeled by LAM
    dialog.data = { registerForDefaults = true, registerForRefresh = true }

    -- small close button
    local closeButton = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_CloseButton"] or CreateControlFromVirtual("$(parent)_CloseButton",
        dialog, "ZO_CloseButton")
    RF_AB_SettingDialog_Fields[closeButton:GetName()] = closeButton
    closeButton:SetAnchor(TOPRIGHT, dialog, TOPRIGHT, 0, 0)
    closeButton:SetHandler("OnClicked", function(...) RF_AB_SettingDialog_CloseButton_OnClicked(dialog) end)

    -- background
    local bg = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Background"] or dialog:CreateControl("$(parent)_Background", CT_TEXTURE)
    RF_AB_SettingDialog_Fields[bg:GetName()] = bg
    bg:SetTexture("EsoUI/Art/Miscellaneous/centerscreen_left.dds")
    bg:SetDimensions(680, 520)
    bg:SetAnchor(TOPLEFT, nil, TOPLEFT, -40, -40)
    bg:SetDrawLayer(DL_BACKGROUND)
    bg:SetExcludeFromResizeToFitExtents(true)

    -- title
    local title = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Title"] or dialog:CreateControl("$(parent)_Title", CT_LABEL)
    RF_AB_SettingDialog_Fields[title:GetName()] = title
    title:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 10)
    title:SetFont("ZoFontWinH1")
    title:SetText("|ccc0000red_Freak|r's Auto Buyer - " .. itemConfig.itemLink .. " settings")

    -- hr
    local divider = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Divider"] or wm:CreateControlFromVirtual("$(parent)_Divider", dialog,
        "ZO_Options_Divider")
    RF_AB_SettingDialog_Fields[divider:GetName()] = divider
    divider:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 55)

    -- item description
    local itemDescription = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Description"] or dialog:CreateControl("$(parent)_Description",
        CT_LABEL)
    RF_AB_SettingDialog_Fields[itemDescription:GetName()] = itemDescription
    itemDescription:SetDimensions(580, 20)
    tmp = RF_AB.ContextMenu.GetDescriptionText(itemConfig)
    itemDescription:SetText(tmp)
    itemDescription:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 70)
    -- item description sales tracker
    local itemDescriptionSalesTracker = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Description_Sales_Tracker"] or
            dialog:CreateControl("$(parent)_Description_Sales_Tracker", CT_LABEL)
    RF_AB_SettingDialog_Fields[itemDescriptionSalesTracker:GetName()] = itemDescriptionSalesTracker
    itemDescriptionSalesTracker:SetDimensions(580, 20)
    tmp = RF_AB.ContextMenu.GetSalesTrackerText(itemConfig)
    itemDescriptionSalesTracker:SetText(tmp)
    itemDescriptionSalesTracker:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 90)
    -- item description hint
    local itemDescriptionHint = RF_AB_SettingDialog_Fields["RF_AB_SettingsDialog_Description_Hint"] or
            dialog:CreateControl("$(parent)_Description_Hint", CT_LABEL)
    RF_AB_SettingDialog_Fields[itemDescriptionHint:GetName()] = itemDescriptionHint
    itemDescriptionHint:SetDimensions(580, 20)
    itemDescriptionHint:SetText('|cCC0000Values are changed directly, no save, no cancel.|r')
    itemDescriptionHint:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 110)

    -- collect data for item fields
    local itemControlData = {
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Enable'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Enable'),
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Price'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Price'),
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Amount'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Amount')
    }
    -- display fields by LAM
    for i, controlData in pairs(itemControlData) do
        local name_internal = controlData.name_internal:gsub('${parent}', 'RF_AB_SettingsDialog')
        local control = RF_AB_SettingDialog_Fields[name_internal] or LAMCreateControl[controlData.type](dialog, controlData, name_internal)
        RF_AB_SettingDialog_Fields[control:GetName()] = control

        injectDataToLAMField(control, controlData)

        -- some markup
        control:SetDimensions(280, 40)
        local row = math.floor(i / 2)
        local even = (i % 2 == 0)
        if (not (even)) then
            control:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, (row - 1) * 60 + 130)
        else
            control:SetAnchor(TOPLEFT, dialog, TOPLEFT, 310, (row - 1) * 60 + 130)
        end
        control:SetHidden(false)
    end
end

function RF_AB.ContextMenu:Callback(name)
    local itemConfig = RF_AB:getItemConfig(name)
    if (itemConfig == nil) then return end

    -- show tooltip
    RF_AB.ContextMenu.ToolTipHandler = ZO_PopupTooltip_SetLink(itemConfig.itemLink)
    showSettingsDialog(itemConfig)
end


RF_AB.ContextMenu.ToolTipHandler = nil
