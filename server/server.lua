local QBCore = exports['qb-core']:GetCoreObject()

function GetPlayerIdentifierFromType(type, source)
	local identifiers = {}
	local identifierCount = GetNumPlayerIdentifiers(source)

	for a = 0, identifierCount do
		table.insert(identifiers, GetPlayerIdentifier(source, a))
	end

	for b = 1, #identifiers do
		if string.find(identifiers[b], type, 1) then
			return identifiers[b]
		end
	end
	return nil
end

RegisterNetEvent("purchaseWeapon")
AddEventHandler("purchaseWeapon", function(name, hash, price, ammo)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player then
        local account = Player.Functions.GetMoney('cash')

        if account >= price then
            local success = Player.Functions.RemoveMoney('cash', price, nil)
            
            if success then
                TriggerClientEvent("purchaseWeapon", source, name, hash, price, ammo)
                
                local citizenId = Player.PlayerData.citizenid
                local sqlCheckQuery = "SELECT * FROM player_weapons WHERE citizen_id = @citizenId LIMIT 1"
                local queryArgs = { ['@citizenId'] = citizenId }
                
                local result = MySQL.Sync.fetchAll(sqlCheckQuery, queryArgs)
                
                if result[1] ~= nil then
                    local weaponData = json.decode(result[1].weapons)
                    local found = false
                    
                    for _, weapon in ipairs(weaponData) do
                        if weapon.hash == hash then
                            weapon.ammo = tonumber(weapon.ammo) + tonumber(ammo)
                            found = true
                            break
                        end
                    end
                    
                    if not found then
                        table.insert(weaponData, { name = name, hash = hash, ammo = tonumber(ammo) })
                    end
                    
                    local sqlUpdateQuery = "UPDATE player_weapons SET weapons = @weapons WHERE citizen_id = @citizenId"
                    local updateArgs = {
                        ['@citizenId'] = citizenId,
                        ['@weapons'] = json.encode(weaponData)
                    }
                    MySQL.Sync.execute(sqlUpdateQuery, updateArgs)
                else
                    local newWeaponData = { { name = name, hash = hash, ammo = tonumber(ammo) } }
                    local sqlInsertQuery = "INSERT INTO player_weapons (citizen_id, weapons) VALUES (@citizenId, @weapons)"
                    local insertArgs = {
                        ['@citizenId'] = citizenId,
                        ['@weapons'] = json.encode(newWeaponData)
                    }
                    MySQL.Sync.execute(sqlInsertQuery, insertArgs)
                end
            else
                TriggerClientEvent("chat:addMessage", source, {
                    color = {255, 0, 0},
                    args = {"Error", "Failed to process payment. Please try again later."}
                })
            end
        else
            TriggerClientEvent("chat:addMessage", source, {
                color = {255, 0, 0},
                args = {"Error", "You don't have enough money."}
            })
        end
    else
        print("Player not found")
    end
end)

RegisterNetEvent("requestPlayerInventory")
AddEventHandler("requestPlayerInventory", function()
    local player = source
    if player then
        local inventoryData = LoadPlayerInventory(player)
        TriggerClientEvent("playerInventoryLoaded", player, inventoryData)
    end
end)

function LoadPlayerInventory(player)
    local playerData = QBCore.Functions.GetPlayer(player)
    local citizenId = playerData.PlayerData.citizenid
    
    local result = MySQL.Sync.fetchAll("SELECT weapons FROM player_weapons WHERE citizen_id = @citizenid", {
        ['@citizenid'] = citizenId
    })

    if result[1] then
        local weaponsData = json.decode(result[1].weapons)
        --print("Weapons data for player: " .. citizenId)
        --print(json.encode(weaponsData)) -- Print the weapons data for debugging
        
        local inventoryData = {}  -- Initialize the inventory data table

        for _, weapon in ipairs(weaponsData) do
            local weaponHash = weapon.hash
            local weaponName = weapon.name
            local ammoCount = weapon.ammo or 0

            local itemData = {}
            itemData.name = weaponName
            itemData.hash = weaponHash
            itemData.ammo = ammoCount

            table.insert(inventoryData, itemData)
        end

        return inventoryData
    else
        print("No weapons data found for player: " .. citizenId)
        return {}
    end
end
