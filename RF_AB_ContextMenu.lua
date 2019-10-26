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

local function RF_AB_SettingDialog_CloseButton_OnClicked(self)
    -- todo: save data
    ZO_PopupTooltip_Hide()
    RF_AB_SettingsDialog:SetHidden(true)
end

local function RF_AB_SettingDialog_itemField_OnValueChanged(field, self, value, reason)
    d(field)
end

local function showSettingsDialog(itemConfig)
    local wm = WINDOW_MANAGER

    -- main window
    local dialog = CreateTopLevelWindow("RF_AB_SettingsDialog")
    dialog:SetHidden(false)
    dialog:SetAnchor(TOPLEFT, nil, TOPLEFT, 100, 150)
    dialog:SetDimensions(600, 400)
    dialog:SetMovable(false)

    -- small close button
    local closeButton = CreateControlFromVirtual("$(parent)_CloseButton", dialog, "ZO_CloseButton")
    closeButton:SetAnchor(TOPRIGHT, dialog, TOPRIGHT, -10, 10)
    -- closeButton:SetHandler("OnMouseEnter", ZO_Options_OnMouseEnter)
    -- closeButton:SetHandler("OnMouseExit", ZO_Options_OnMouseExit)
    closeButton:SetHandler("OnMouseEnter", function() ZO_Options_OnMouseEnter(closeButton) end)
    closeButton:SetHandler("OnMouseExit", function() ZO_Options_OnMouseExit(closeButton) end)
    closeButton:SetHandler("OnClicked", function(...) RF_AB_SettingDialog_CloseButton_OnClicked(closeButton) end)

    -- background
    local bg = dialog:CreateControl("$(parent)_Background", CT_TEXTURE)
    bg:SetTexture("EsoUI/Art/Miscellaneous/centerscreen_left.dds")
    bg:SetDimensions(680, 520)
    bg:SetAnchor(TOPLEFT, nil, TOPLEFT, -40, -40)
    bg:SetDrawLayer(DL_BACKGROUND)
    bg:SetExcludeFromResizeToFitExtents(true)

    -- title
    local title = dialog:CreateControl("$(parent)_Title", CT_LABEL)
    title:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 10)
    title:SetFont("ZoFontWinH1")
    title:SetText("|ccc0000red_Freak|r's Auto Buyer - " .. itemConfig.itemLink .. " settings")

    -- hr
    local divider = wm:CreateControlFromVirtual("$(parent)_Divider", dialog, "ZO_Options_Divider")
    divider:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 55)

    -- item desciption
    local itemDescription = LAMCreateControl.description(dialog,
        RF_AB.Settings:getItemDescription(itemConfig.name))
    itemDescription:SetDimensions(580, 20)
    itemDescription:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, 80)

    -- collect data for item fields
    local itemControlData = {
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Enable'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Enable'),
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Price'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Price'),
        RF_AB.Settings.getItemFieldByContext('Store', itemConfig.name, 'Amount'),
        RF_AB.Settings.getItemFieldByContext('Guild', itemConfig.name, 'Amount')
    }
    -- mock some values to let us handel by LAM
    dialog.data = { registerForDefaults = true, registerForRefresh = true }
    -- display fields by LAM
    for i, controlData in pairs(itemControlData) do
        local control = LAMCreateControl[controlData.type](dialog, controlData, "$(parent)_Element" .. i)
        control:SetDimensions(280, 40)
        local row = math.floor(i / 2)
        local even = (i % 2 == 0)
        if (not (even)) then
            control:SetAnchor(TOPLEFT, dialog, TOPLEFT, 10, (row - 1) * 60 + 100)
        else
            control:SetAnchor(TOPLEFT, dialog, TOPLEFT, 310, (row - 1) * 60 + 100)
        end
        control:SetHandler('OnValueChanged', function(self, value, eventReason)
            RF_AB_SettingDialog_itemField_OnValueChanged(control:GetName, self, value, eventReason)
        end)

        control:SetHidden(false)
    end


    --SetHandler
    --    <Button name="$(parent)_OkButton" clickSound="Click" mouseOverBlendMode="ADD" inherits="ZO_DefaultButton" text="Save">
    --        <Anchor point="TOPLEFT" relativeTo="$(parent)" relativePoint="TOPLEFT" offsetX="5"
    --    offsetY="50"/>
    --            <Dimensions x="80" y="40"/>
    --
    --        <OnClicked>
    --        RF_AB_SingleSettingDialog_CloseButton_OnClicked(self)
    --        </OnClicked>
    --        </Button>
    --        <Button name="$(parent)_CancelButton" clickSound="Click" mouseOverBlendMode="ADD"
    --    inherits="ZO_DefaultButton" text="Cancel">
    --        <Anchor point="TOPLEFT" relativeTo="$(parent)" relativePoint="TOPLEFT" offsetX="90" offsetY="5"/>
    --        <Dimensions x="80" y="40"/>
    --        <OnClicked>
    --        RF_AB_SingleSettingDialog_CloseButton_OnClicked(self)
    --        </OnClicked>
    --        </Button>
end

function RF_AB.ContextMenu:Callback(name)
    local itemConfig = RF_AB:getItemConfig(name)
    if (itemConfig == nil) then return end

    -- show tooltip
    RF_AB.ContextMenu.ToolTipHandler = ZO_PopupTooltip_SetLink(itemConfig.itemLink)
    showSettingsDialog(itemConfig)
end

RF_AB.ContextMenu.ToolTipHandler = nil
