ESX = nil

cachedData = {
	["motels"] = {},
	["storages"] = {},
	["insideMotel"] = false
}

Citizen.CreateThread(function()
	while not ESX do
		--Fetching esx library, due to new to esx using this.

		TriggerEvent("esx:getSharedObject", function(library) 
			ESX = library 
		end)

		Citizen.Wait(25)
	end

	if ESX.IsPlayerLoaded() then
		Init()
	end

	AddTextEntry("Instructions", Config.HelpTextMessage)
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerData)
	ESX.PlayerData = playerData

	Init()
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(newJob)
	ESX.PlayerData["job"] = newJob
end)

RegisterNetEvent("motel:eventHandler")
AddEventHandler("motel:eventHandler", function(response, eventData)
	if response == "update_motels" then
		cachedData["motels"] = eventData
	elseif response == "update_storages" then
		cachedData["storages"][eventData["storageId"]] = eventData["newTable"]

		if ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "main_storage_menu_" .. eventData["storageId"]) then
			local openedMenu = ESX.UI.Menu.GetOpened("default", GetCurrentResourceName(), "main_storage_menu_" .. eventData["storageId"])

			if openedMenu then
				openedMenu.close()

				OpenStorage(eventData["storageId"])
			end
		end
	elseif response == "invite_player" then
		if eventData["player"]["source"] == GetPlayerServerId(PlayerId()) then
			Citizen.CreateThread(function()
				local startedInvite = GetGameTimer()

				cachedData["invited"] = true

				while GetGameTimer() - startedInvite < 7500 do
					Citizen.Wait(0)

					ESX.ShowHelpNotification("Te invitó : " .. eventData["motel"]["room"] .. ", Músculo ~INPUT_DETONATE~ para entrar")

					if IsControlJustPressed(0, 47) then
						EnterMotel(eventData["motel"])

						break
					end
				end

				cachedData["invited"] = false
			end)
		end
	elseif response == "knock_motel" then
		local currentInstance = DecorGetInt(PlayerPedId(), "currentInstance")

		if currentInstance and currentInstance == eventData["uniqueId"] then
			ESX.ShowNotification("Alguien llamó a tu puerta.")
		end
	else
		-- print("Wrong event handler.")
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(50)

	cachedData["lastCheck"] = GetGameTimer() - 4750

	local pinkCageBlip = AddBlipForCoord(Config.LandLord["position"])

	SetBlipSprite(pinkCageBlip, 475)
	SetBlipScale(pinkCageBlip, 0.5)
	SetBlipColour(pinkCageBlip, 25)
	SetBlipAsShortRange(pinkCageBlip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Pink Cage Motel")
	EndTextCommandSetBlipName(pinkCageBlip)

	while true do
		local sleepThread = 500

		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)

		local yourMotel = GetPlayerMotel()

		for motelRoom, motelPos in ipairs(Config.MotelsEntrances) do
			local dstCheck = GetDistanceBetweenCoords(pedCoords, motelPos, true)
			local dstRange = yourMotel and (yourMotel["room"] == motelRoom and 35.0 or 3.0) or 3.0

			if dstCheck <= dstRange then
				sleepThread = 5

				if dstCheck <= 0.9 then
					local displayText = yourMotel and (yourMotel["room"] == motelRoom and "Músculo ~r~[E]~s~ Entrar" or "") or ""; displayText = displayText .. " ~r~[H]~s~ Menu"

					if not cachedData["invited"] then
						--DrawScriptText(motelPos - vector3(0.0, 0.0, 0.20), displayText)
						coordenadas = vector3(motelPos.x,motelPos.y,motelPos.z+0.9)
						ESX.ShowFloatingHelpNotification(displayText, coordenadas)

					end

					if IsControlJustPressed(0, 38) then
						if yourMotel then
							if yourMotel["room"] == motelRoom then
								EnterMotel(yourMotel)
							end
						end
					elseif IsControlJustPressed(0, 74) then
						OpenMotelRoomMenu(motelRoom)
					end
				end
			end
		end

		local dstCheck = GetDistanceBetweenCoords(pedCoords, Config.LandLord["position"], true)

		if dstCheck <= 3.0 then
			sleepThread = 5

			if dstCheck <= 0.9 then
				local displayText = 'Pulsa el músculo ~r~[E]~s~ para hablar con el dueno del ~y~hotel~s~'
				
				if not cachedData["purchasing"] then
					local coordenadas =  vector3(Config.LandLord["position"].x,Config.LandLord["position"].y,Config.LandLord["position"].z+0.8)
					ESX.ShowFloatingHelpNotification(displayText, coordenadas)
				end

				if IsControlJustPressed(0, 38) then
					OpenLandLord()
				end
			end
		end
		Citizen.Wait(sleepThread)
	end
end)