-- Variables
local QBCore = exports['qb-core']:GetCoreObject()
local lastAd, ads = 0, {}

-- Functions
local function createJailStory(name, time)
    exports.oxmysql:execute(
        'INSERT INTO newspaper (story_type, jailed_player, jailed_time, date) VALUES (?, ?, ?, CURRENT_TIMESTAMP)',
        { 'jail', name, time })
end
exports('CreateJailStory', createJailStory)

-- Commands
QBCore.Commands.Add('ad', 'Post an advertisement', { 'ad' }, true, function(source, _, rawCommand)
    local QPlayer = QBCore.Functions.GetPlayer(source)
    local message = rawCommand:sub(3)
    local time = os.date(Config.DateFormat)
    local playerName = ("%s %s"):format(QPlayer.PlayerData.charinfo.firstname, QPlayer.PlayerData.charinfo.lastname)
    local bankMoney = QPlayer.PlayerData.money.bank

    if os.time() - lastAd >= Config.AdvertisementCooldown then
        if bankMoney >= Config.AdvertisementPrice then
            lastAd = os.time()
            QPlayer.Functions.RemoveMoney('bank', Config.AdvertisementPrice)
            TriggerClientEvent('chat:addMessage', -1, {
                template =
                '<div class="chat-message advertisement"><i class="fas fa-ad"></i> <b><span style="color: #81db44">{0}</span>&nbsp;<span style="font-size: 14px; color: #e1e1e1;">{2}</span></b><div style="margin-top: 5px; font-weight: 300;">{1}</div></div>',
                args = { playerName, message, time }
            })
            ads[#ads + 1] = {
                date = time,
                name = playerName,
                message = message,
            }
        else
            TriggerClientEvent('QBCore:Notify', source, "You don't have enough money in the bank.", 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "Ads are on cooldown. Please try again later.", 'error')
    end
end)

-- Callbacks
QBCore.Functions.CreateCallback('newspaper:server:getStories', function(source, cb)
    local src = source
    local QPlayer = QBCore.Functions.GetPlayer(src)
    local isReporter = false
    local reporterLevel = nil
    local amountOfNews = Config.AmountOfNews or 10
    local amountOfSentences = Config.AmountOfSentences or 10
    local playerName = ("%s %s"):format(QPlayer.PlayerData.charinfo.firstname, QPlayer.PlayerData.charinfo.lastname)

    local reporterOnDuty = QPlayer.PlayerData.job['onduty']

    if QPlayer.PlayerData.job['name'] == 'reporter' then
        isReporter = true
        reporterLevel = QPlayer.PlayerData.job.grade['level']
    end

    local news = exports.oxmysql:executeSync("SELECT * FROM newspaper WHERE story_type = ? ORDER BY id DESC LIMIT " ..
        amountOfNews .. "", { 'news' })

    local sentences = exports.oxmysql:executeSync(
        "SELECT * FROM newspaper WHERE story_type = ? ORDER BY id DESC LIMIT " .. amountOfSentences .. "", { 'jail' })

    cb(news, sentences, ads, isReporter, reporterLevel, reporterOnDuty, playerName)

    reporterLevel = nil
end)

-- Events
RegisterNetEvent('newspaper:buy', function(type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cash = Player.PlayerData.money['cash']

    if type then
        if cash >= Config.Price then
            Player.Functions.RemoveMoney("cash", Config.Price)
            TriggerClientEvent('inventory:client:ItemBox', src, Config.NewspaperItem, "add")
            Player.Functions.AddItem(type, 1)
        else
            TriggerClientEvent('QBCore:Notify', src, '$' .. Config.Price .. ' required for buying a newspaper',
                'error')
        end
    end
end)

RegisterNetEvent('newspaper:server:updateStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            knownPlayers[source] = nil;
            DropPlayer(src, "Exploid detected") -- Update this to ban if you feel like it

            return
        else
            exports.oxmysql:insert('UPDATE newspaper SET title = ?, body = ?, image = ? WHERE id = ?',
                { data.title, data.body, data.image, data.id })

            TriggerClientEvent('QBCore:Notify', src, 'Story has been updated!', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need to be a reporter to update a story', 'success')
    end

    knownPlayers[source] = nil;
end)

RegisterNetEvent('newspaper:server:publishStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            knownPlayers[source] = nil;
            DropPlayer(src, "Exploid detected") -- Update this to ban if you feel like it

            return
        else
            exports.oxmysql:insert(
                'INSERT INTO newspaper (story_type, title, body, date, image, publisher) VALUES (?, ?, ?, ?, ?, ?)',
                { 'news', data.title, data.body, data.date, data.image, playerName })

            TriggerClientEvent('QBCore:Notify', src, 'Story has been published!', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need to be a reporter to publish a story', 'success')
    end

    knownPlayers[source] = nil;
end)

RegisterNetEvent('newspaper:server:deleteStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            -- Player not supposed to have access to this. Ban the player.

            knownPlayers[source] = nil;

            return
        else
            exports.oxmysql:execute('DELETE FROM newspaper WHERE id = ?', { data.id })

            TriggerClientEvent('QBCore:Notify', src, 'Story have been deleted', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Not possible to delete story', 'success')
    end

    knownPlayers[source] = nil;
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(QPlayer)
    local newspapers = exports['qb-inventory']:GetItemsByName(QPlayer.PlayerData.source, 'newspaper')

    for i = 1, #newspapers do
        exports['qb-inventory']:RemoveItem(QPlayer.PlayerData.source, 'newspaper', newspapers[i].amount, newspapers[i].slot)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `newspaper` (
            `id` INT(10) NOT NULL AUTO_INCREMENT,
            `story_type` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8_general_ci',
            `title` VARCHAR(5000) NOT NULL DEFAULT '' COLLATE 'utf8_general_ci',
            `body` VARCHAR(5000) NOT NULL DEFAULT '' COLLATE 'utf8_general_ci',
            `date` VARCHAR(50) NULL DEFAULT '' COLLATE 'utf8_general_ci',
            `jailed_player` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8_general_ci',
            `jailed_time` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8_general_ci',
            `image` VARCHAR(250) NULL DEFAULT NULL COLLATE 'utf8_general_ci',
            `publisher` VARCHAR(250) NOT NULL DEFAULT 'Los Santos Newspaper' COLLATE 'utf8_general_ci',
            PRIMARY KEY (`id`) USING BTREE
        )
    ]])

    QBCore.Functions.AddItem('newspaper', Config.NewspaperItem)
    QBCore.Functions.CreateUseableItem("newspaper", function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)

        if Player.Functions.GetItemByName(item.name) ~= nil then
            TriggerClientEvent('newspaper:client:openNewspaper', src)
        end
    end)
end)
