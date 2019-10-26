local function bestDealStrategyGetAmount(goldToSpend, pricePerUnit, stack, amountWanted, pendingOrder, itemConfig)
    -- test total price
    local priceStack = pricePerUnit * stack
    if (priceStack > goldToSpend) then
        RF_AB.Utils.error('Not buying ' .. stack .. 'x' .. itemConfig.itemLink .. '@' .. pricePerUnit .. 'g, no money left.')
        return 0
    end
    -- test factor
    local priceFaktor = pricePerUnit / itemConfig.priceGuild
    local inStock = RF_AB.Buyer.getItemStockByItemLink(itemConfig.itemLink)
    if (priceFaktor > 1) then
        RF_AB.Utils.hint('Not buying ' .. stack .. 'x' .. itemConfig.itemLink .. '@' .. pricePerUnit .. 'g, to expensive')
        return 0
    elseif (priceFaktor <= 0.333) then
        amountWanted = itemConfig.toBuyGuild * 10 - inStock - pendingOrder
    elseif (priceFaktor < 0.5) then
        amountWanted = itemConfig.toBuyGuild * 5 - inStock - pendingOrder
    else
        amountWanted = math.floor(itemConfig.toBuyGuild / priceFaktor) - inStock - pendingOrder
    end

    if (amountWanted >= stack) then return stack end

    RF_AB.Utils.hint('Not buying ' .. stack .. 'x' .. itemConfig.itemLink .. '@' .. pricePerUnit .. 'g, to much')
    return 0
end

function RF_AB.Buyer.Guild.registerEvents()
    EVENT_MANAGER:RegisterForEvent("AB_OpenGuildStore", EVENT_OPEN_TRADING_HOUSE, RF_AB.Buyer.Guild.StoreOpened)
    -- receive search results by AGS
    RF_AB.Buyer.Guild.AGS:RegisterCallback(RF_AB.Buyer.Guild.AGS.callback.SEARCH_RESULTS_RECEIVED, RF_AB.Buyer.Guild.buyItems)
    -- get the TradingHouseWrapper to directly "communicate" with AGS
    RF_AB.Buyer.Guild.AGS:RegisterCallback(RF_AB.Buyer.Guild.AGS.callback.AFTER_INITIAL_SETUP, RF_AB.Buyer.Guild.registerTradingHouseWrapper)

    EVENT_MANAGER:RegisterForEvent("AB_OpenGuildStore", EVENT_CLOSE_TRADING_HOUSE, RF_AB.Buyer.Guild.StoreClosed)
end

function RF_AB.Buyer.Guild.registerTradingHouseWrapper(Wrapper)
    RF_AB.debug('AGS after init callback')
    RF_AB.Buyer.Guild.TradingHouseWrapper = Wrapper
end

function RF_AB.Buyer.Guild.StoreOpened()
    -- get strategy
    if (RF_AB.savedVariables.buyingStrategyGuild == 'fill storage') then
        RF_AB.Utils.message('Fill Storage-Strategy.')
    elseif (RF_AB.savedVariables.buyingStrategyGuild == 'spend gold') then
        RF_AB.Utils.message('Spend Gold-Strategy.')
    elseif (RF_AB.savedVariables.buyingStrategyGuild == 'best deal') then
        RF_AB.Utils.message('Best Deal-Strategy.')
        RF_AB.Buyer.Guild.getAmountCallback = bestDealStrategyGetAmount
    else
        RF_AB.Utils.error('Choosen Strategy not supported.')
    end
end

function RF_AB.Buyer.Guild.StoreClosed()
    -- nil
end

function RF_AB.Buyer.Guild.buyItems(pendingGuildName, numItems, page, hasMore, guildId)
    RF_AB.Utils.message('Processing ' .. numItems .. ' search results by ' .. pendingGuildName)
    if (not RF_AB.savedVariables.guildEnabled) then return end
    local preOrder = {} -- [name][uniqueId]
    -- collect item data
    for x = 1, numItems do
        local itemLink = GetTradingHouseSearchResultItemLink(x, LINK_STYLE_DEFAULT)
        if (GetItemLinkFilterTypeInfo(itemLink) == ITEMFILTERTYPE_CRAFTING) then
            local icon, name, quality, stack, seller, timeRemaining, price, currencyType, uniqueId, pricePerUnit = GetTradingHouseSearchResultItemInfo(x)
            if (currencyType == CURT_MONEY or currencyType == CURT_NONE) then
                local order_entry = RF_AB.Buyer.getOrderEnrtyGuild(name, pricePerUnit, itemLink, icon, x, stack)
                if (order_entry ~= nil) then
                    -- mixin some more infos
                    order_entry.seller = seller
                    order_entry.guildName = pendingGuildName
                    -- "sort" by item_name
                    if (preOrder[name] == nil) then preOrder[name] = {} end
                    preOrder[name][uniqueId] = order_entry
                end
            end
        end
    end

    local goldToSpend = RF_AB.Buyer.getGoldToSpend()
    local order = RF_AB.Buyer.Guild.getOrderByPreorder(preOrder, goldToSpend)

    RF_AB.Buyer.Guild.buy(order, goldToSpend, guildId)
end

function RF_AB.Buyer.Guild.buy(order, goldToSpend, guildId)
    for name, orderItem in pairs(order) do
        if (goldToSpend <= 0) then
            RF_AB.Utils.error('Not buying ' .. orderItem.itemLink .. ' no money left.')
        else
            if (goldToSpend >= orderItem.stack * orderItem.price) then
                RF_AB.Utils.success('Buying ' .. orderItem.stack .. 'x ' .. orderItem.itemLink .. ' @' .. RF_AB.Utils:MoneyString(orderItem.price))
                -- prepare data for AGS
                local itemData = RF_AB.Buyer.Guild.TradingHouseWrapper.itemDatabase:TryGetItemDataInCurrentGuildByUniqueId(orderItem.uniqueId)
                -- call AGS to handle purchase
                local purchaseActivity = RF_AB.Buyer.Guild.TradingHouseWrapper.activityManager:PurchaseItem(guildId, itemData)
                purchaseActivity.pendingPromise:Then(function()
                    -- set it bought
                    itemData.purchased = true
                    -- refresh search result
                    RF_AB.Buyer.Guild.TradingHouseWrapper.searchTab.searchResultList:RefreshVisible()
                end)
            else
                RF_AB.Utils.error('Not buying ' .. orderItem.itemLink .. ' no money left.')
            end

            goldToSpend = goldToSpend - (orderItem.stack * orderItem.price)
        end
    end
end

function RF_AB.Buyer.Guild.getOrderByPreorder(preOrder, goldToSpend)
    return RF_AB.Buyer.Guild.filterPreOrder(preOrder, goldToSpend, RF_AB.Buyer.Guild.getAmountCallback)
end

function RF_AB.Buyer.Guild.filterPreOrder(preOrder, goldToSpend, getAmountCallback)
    -- nested sorting function
    local function compareOrders(orderA, orderB)
        return orderA.price < orderA.price
    end

    local filteredOrder = {}
    for name, orders in pairs(preOrder) do
        local itemConfig = RF_AB:getItemConfig(name)
        local itemSum = 0
        local itemStock = 0

        table.sort(orders, compareOrders)
        for uniqueId, orderItem in pairs(orders) do
            if (goldToSpend - itemSum <= 0) then
                RF_AB.Utils.error('Not buying ' .. orderItem.itemLink .. ' no money left.')
            else
                local amountToBuy = getAmountCallback(goldToSpend, orderItem.price, orderItem.stack, orderItem.amount, itemStock, itemConfig)

                -- if the strategy decieded to buy then put in order
                if (amountToBuy > 0) then
                    orderItem.uniqueId = uniqueId
                    RF_AB.Utils.success('ordering ' .. amountToBuy .. 'x ' .. orderItem.itemLink)
                    table.insert(filteredOrder, orderItem)
                    itemSum = itemSum + (orderItem.price * orderItem.stack)
                    itemStock = itemStock + orderItem.stack
                end
            end
        end
    end

    return filteredOrder
end

function RF_AB.Buyer.Guild.fillStorageStrategy(preOrder, goldToSpend)
end

function RF_AB.Buyer.Guild.spendGoldStrategy(preOrder, goldToSpend)
end

function RF_AB.Buyer.Guild.bestDealStrategy(preOrder, goldToSpend)
end

RF_AB.Buyer.Guild.AGS = AwesomeGuildStore
RF_AB.Buyer.Guild.TradingHouseWrapper = nil
RF_AB.Buyer.Guild.registerEvents()
