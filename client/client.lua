if config.customMenuEnabled then
    local RuntimeTXD = CreateRuntimeTxd('Custom_Menu_Head')
    local Object = CreateDui(config.menuImage, 512, 128)
    _G.Object = Object
    local TextureThing = GetDuiHandle(Object)
    local Texture = CreateRuntimeTextureFromDuiHandle(RuntimeTXD, 'Custom_Menu_Head', TextureThing)
    menuImage = "Custom_Menu_Head"
else
    menuImage = "shopui_title_sm_hangar"
end

-- Alert on top left of screen
function alert(msg)
    SetTextComponentFormat("STRING")
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Check if player is in a gun store
function InGunStore()
	local playerCoords = GetEntityCoords(PlayerPedId(), 0)
	local GunStore = GetCoordsAndRotationOfClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.5, 1093460780, 0)

	if GunStore == 1 then
		return true
    elseif _menuPool:IsAnyMenuOpen() and GunStore ~= 1 then
        _menuPool:CloseAllMenus()
    end
end

RegisterNetEvent("purchaseWeapon")
AddEventHandler("purchaseWeapon", function(name, hash, price, ammo)
    if ammo == "none" then
        giveWeapon(name, hash, price)
    else
        giveAmmo(name, ammo, price, hash)
    end
end)

function giveWeapon(name, hash, price)
    GiveWeaponToPed(PlayerPedId(), GetHashKey(hash), 30, false, false)
    print("PlayerPedId:", PlayerPedId())
    SetNotificationTextEntry("STRING")
    AddTextComponentString("You've purchased a " .. "~b~" .. name .. "~w~ for ~g~$" .. price .. ".")
    DrawNotification(true, true)
end

function giveAmmo(name, amount, price, ammoType)
    AddAmmoToPedByType(PlayerPedId(), ammoType, amount)
    print("PlayerPedId:", PlayerPedId())
    SetNotificationTextEntry("STRING")
    AddTextComponentString("You've purchased ~b~" .. amount .. " ~s~rounds of ~b~" .. name .. "~w~ for ~g~$" .. price .. ".")
    DrawNotification(true, true)
end

for _, blipPos in ipairs(config.blips) do
    local blip = AddBlipForCoord(blipPos.x, blipPos.y, blipPos.z)
    SetBlipSprite(blip, 110)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Gun Store")
    EndTextCommandSetBlipName(blip)
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(1000)
    TriggerServerEvent("requestPlayerInventory")
end)

RegisterNetEvent("playerInventoryLoaded")
AddEventHandler("playerInventoryLoaded", function(inventoryData)
    print("Inventory data received from server:")
    for _, itemData in ipairs(inventoryData) do
        local itemHash = itemData.hash
        local itemName = itemData.name

        if itemHash:find("weapon_") then
            local ammoCount = itemData.ammo or 0
            GiveWeaponToPed(PlayerPedId(), GetHashKey(itemHash), ammoCount, false, false)
            --print("PlayerPedId:", PlayerPedId())
            --print("Weapon found:", itemName, "(Hash:", itemHash, ")")
        elseif itemHash:find("AMMO_") then
            local weaponHash = itemData.hash
            local ammoCount = itemData.ammo
            local ammoType = GetHashKey(weaponHash)
            AddAmmoToPedByType(PlayerPedId(), ammoType, ammoCount)
            --print("PlayerPedId:", PlayerPedId())
            --print("Ammo found:", itemName, "(Hash:", ammoType, ") - Ammo count:", ammoCount)
        end
    end
end)
