function RF_AB.Buyer.getOrderEnrtyStore(name, price, itemLink, icon, index, stack)
    return RF_AB.Buyer.getOrderEnrty('Store', name, price, itemLink, icon, index, stack)
end

function RF_AB.Buyer.getOrderEnrtyGuild(name, price, itemLink, icon, index, stack)
    return RF_AB.Buyer.getOrderEnrty('Guild', name, price, itemLink, icon, index, stack)
end

function RF_AB.Buyer.getOrderEnrty(context, name, price, itemLink, icon, index, stack)
    local prefix = ''
    if (context == 'Store') then
        prefix = 'ordering'
    elseif (context == 'Guild') then
        prefix = 'preordering'
    else
        RF_AB.Utils.error('Unknown context')
        return
    end
    local order_entry

    RF_AB:registerItem(name, price, itemLink, icon, context)
    local totalStackSize = RF_AB.Buyer.getItemStockByItemLink(itemLink)
    local itemConfig = RF_AB:getItemConfig(name)

    if (itemConfig ~= nil and itemConfig['buy' .. context]) then
        if (price <= itemConfig['price' .. context]) then
            local possibleBuyStack = itemConfig['toBuy' .. context]
            -- adjust amount if there is a possivle best deal
            if ((context == 'Guild' and RF_AB.savedVariables.buyingStrategyGuild == 'best deal' and totalStackSize <
                    itemConfig['toBuy' .. context] * 10)) then
                possibleBuyStack = itemConfig['toBuy' .. context] * 10
                RF_AB.Utils.hint('possible best deal: adjusting amount from ' .. itemConfig['toBuy' .. context] .. ' tot ' ..
                        possibleBuyStack .. ' for ' .. itemConfig.itemLink)
            end
            if (totalStackSize < possibleBuyStack) then
                local amountWantedOrig = (itemConfig['price' .. context] - totalStackSize)
                local amountWanted = (possibleBuyStack - totalStackSize)

                local amountString = amountWantedOrig
                if (amountWanted ~= amountWantedOrig) then amountString = amountString .. 'x / ' .. amountWanted end

                RF_AB.Utils.success(prefix .. ' ' .. amountString .. 'x ' .. itemConfig.itemLink)

                order_entry = {
                    amount = amountWanted,
                    price = price,
                    itemLink = itemConfig.itemLink,
                    index = index,
                    stack = stack
                }
            else
                RF_AB.Utils.hint('Not ' .. prefix .. ' ' .. itemConfig.itemLink .. ' enough in stock.')
            end
        elseif (not (context == 'Guild')) then
            RF_AB.Utils.warn('Not ' .. prefix .. ' ' .. itemConfig.itemLink .. '@' .. price .. ' to expensive.')
        end
    end

    return order_entry
end

function RF_AB.Buyer.getAmount(goldToSpend, price, amountWanted)
    local amountPayable = math.floor(goldToSpend / price)
    if (amountWanted <= amountPayable) then
        return amountWanted
    else
        return amountPayable
    end
end

function RF_AB.Buyer.getGoldToSpend(silent)
    local gold = GetCarriedCurrencyAmount(CURT_MONEY);
    local goldToSpend = gold - RF_AB.savedVariables.keepMoney
    if (goldToSpend < 0) then goldToSpend = 0 end

    if (silent ~= true) then RF_AB.Utils.message(RF_AB.Utils:MoneyString(gold) .. 'g in inventory, ' .. RF_AB.Utils:MoneyString(RF_AB.savedVariables.keepMoney) .. 'g to keep, ' .. RF_AB.Utils:MoneyString(goldToSpend) .. 'g to spend') end
    return goldToSpend
end

function RF_AB.Buyer.adjustOrderEqual(order, goldToSpend)
    -- get order total
    local orderTotal = 0
    for name, orderItem in pairs(order) do
        orderTotal = orderTotal + (orderItem.price * orderItem.amount)
    end
    if (orderTotal <= goldToSpend) then return order end
    -- adjust order
    local factor = goldToSpend / orderTotal
    for name, orderItem in pairs(order) do
        local amount_new = math.floor(order[name].amount * factor)
        RF_AB.Utils.warn('Adjusting order  ' .. orderItem.itemLink .. ' from ' .. orderItem.amount .. ' to ' ..
                amount_new .. ' not enough money')
        order[name].amount = amount_new
    end

    return order
end

function RF_AB.Buyer.getItemStockByItemLink(itemLink)
    local stackCountBackpack, stackCountBank, stackCountCraftBag = GetItemLinkStacks(itemLink)
    return stackCountBackpack + stackCountBank + stackCountCraftBag
end

RF_AB.Buyer.Store = {}
RF_AB.Buyer.Guild = {}


