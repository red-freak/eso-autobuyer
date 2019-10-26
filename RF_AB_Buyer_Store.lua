local GetStoreItemLink = GetStoreItemLink

function RF_AB.Buyer.Store.buyItems()
    -- store context
    if (not RF_AB.savedVariables.storeEnabled) then return end

    local storeItems = GetNumStoreItems()
    local goldToSpend = RF_AB.Buyer.getGoldToSpend()

    if (RF_AB.savedVariables.buyingStrategyStore == 'just buy') then
        RF_AB.Utils.message('Just Buy-Strategy.')
        RF_AB.Buyer.Store.justBuyStrategy(storeItems, goldToSpend)
    elseif (RF_AB.savedVariables.buyingStrategyStore == 'equal buying') then
        RF_AB.Utils.message('Eual Buying-Strategy.')
        RF_AB.Buyer.Store.equalBuyingStrategy(storeItems, goldToSpend)
    else
        RF_AB.Utils.error('Choosen Strategy not supported.')
    end
end

function RF_AB.Buyer.Store.buy(order, goldToSpend)
    for name, orderItem in pairs(order) do
        if (goldToSpend <= 0) then
            RF_AB.Utils.error('Not buying ' .. orderItem.itemLink .. ' no money left.')
        else
            local amountToBuy = RF_AB.Buyer.getAmount(goldToSpend, orderItem.price, orderItem.amount)
            if (amountToBuy == orderItem.amount) then
                RF_AB.Utils.success('Buying ' .. amountToBuy .. 'x ' .. orderItem.itemLink)
            else
                RF_AB.Utils.warn('Buying ' .. amountToBuy .. 'x ' .. orderItem.itemLink ..
                        ', ' .. orderItem.amount .. ' wanted. not enough money')
            end
            BuyStoreItem(orderItem.index, amountToBuy)
            goldToSpend = goldToSpend - (amountToBuy * orderItem.price)
        end
    end
end

function RF_AB.Buyer.Store.justBuyStrategy(storeItems, goldToSpend)
    local order = RF_AB.Buyer.Store.getOrder(storeItems)
    RF_AB.Buyer.Store.buy(order, goldToSpend)
end

function RF_AB.Buyer.Store.equalBuyingStrategy(storeItems, goldToSpend)
    local order = RF_AB.Buyer.Store.getOrder(storeItems)
    order = RF_AB.Buyer.adjustOrderEqual(order, goldToSpend)
    RF_AB.Buyer.Store.buy(order, goldToSpend)
end



function RF_AB.Buyer.Store.getOrder(storeItems)
    local order = {}

    for x = 1, storeItems do
        if (GetStoreEntryTypeInfo(x) == ITEMFILTERTYPE_CRAFTING) then
            local icon, name, stack, price, sellPrice, meetsRequirementsToBuy, meetsRequirementsToUse, quality, questNameColor, currencyType1, currencyQuantity1, currencyType2, currencyQuantity2, storeEntryType = GetStoreEntryInfo(x)
            if (currencyType1 == CURT_MONEY or currencyType1 == CURT_NONE) then
                local itemLink = GetStoreItemLink(x, LINK_STYLE_DEFAULT)
                local order_entry = RF_AB.Buyer.getOrderEnrtyStore(name, price, itemLink, icon, x)
                if (order_entry ~= nil) then order[name] = order_entry end
            end
        end
    end

    return order
end

EVENT_MANAGER:RegisterForEvent("AB_OpenStore", EVENT_OPEN_STORE, RF_AB.Buyer.Store.buyItems)

