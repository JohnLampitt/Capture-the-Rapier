--Constants
home = "HOME"
away = "AWAY"

radiantFlagItem = "item_radiant_flag"
radiantFlagModifier = "modifier_radiant_flag"
direFlagItem = "item_dire_flag"
direFlagModifier = "modifier_dire_flag"

radiantFakeFlagItem = "item_radiant_fake_flag"
radiantFakeFlagModifier = "modifier_radiant_fake_flag"
direFakeFlagItem = "item_dire_fake_flag"
direFakeFlagModifier = "modifier_dire_fake_flag"

knockbackInvulModifier = "knockback_invulnerable"

flagPickupRange = 200

expPerSecond = 10

respawnTime = 10

if CTFGameMode == nil then
	print ( '[CTFGameMode] creating CTFGameMode class' )
	CTFGameMode = class({})
	CTFGameMode.__index = CTFGameMode
end

require('flag_functions')
require('ctf_abilities')

function CTFGameMode:InitGameMode() 
	--Get handle to game mode
	GameMode = GameRules:GetGameModeEntity()  

	--Start filtering orders
	GameMode:SetExecuteOrderFilter( Dynamic_Wrap( CTFGameMode, "FilterExecuteOrder" ), self ) 

	--Find flag spawn points
	radiantFlagSpawn = Entities:FindByName(nil, "radiant_flag_spawn"):GetOrigin()
	direFlagSpawn = Entities:FindByName(nil, "dire_flag_spawn"):GetOrigin()

	--Spawn in flag items
	local flagItem = CreateItem(direFlagItem, nil, nil)
	direFlagIndex = CreateItemOnPositionSync(direFlagSpawn, flagItem):GetEntityIndex()
	flagItem = CreateItem(radiantFlagItem, nil, nil)
	radiantFlagIndex = CreateItemOnPositionSync(radiantFlagSpawn, flagItem):GetEntityIndex()

	--Set score
	direScore = 0
	radiantScore = 0

	--Location to port flags to when not needed
	flagStorage = Vector(-10, -10, -10)

	--Spawn fake flags
	flagItem = CreateItem(radiantFakeFlagItem, nil, nil)
	radiantFakeFlagIndex = CreateItemOnPositionSync(flagStorage, flagItem):GetEntityIndex()
	flagItem = CreateItem(direFakeFlagItem, nil, nil)
	direFakeFlagIndex = CreateItemOnPositionSync(flagStorage, flagItem):GetEntityIndex()

	--Listen for deaths
	ListenToGameEvent( "entity_killed" , Dynamic_Wrap( CTFGameMode, "PlayerDeath" ), self )

	--Listen for spawns
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CTFGameMode, "PlayerSpawned" ), self)

	--We dont want a long pregame
	GameRules:SetPreGameTime( 2 )

	--UI update thinker
	GameRules:GetGameModeEntity():SetThink(  "UpdateScoreboard" , self, "ScoreboardThink", 2 )

	--Game status watcher
	GameRules:GetGameModeEntity():SetThink( "GameModeWatch", self, "MasterThink", 2 )

	print( '[CTFGameMode] adddon initiated' )
end

function CTFGameMode:FilterExecuteOrder( filterTable )
    --[[
    print("-----------------------------------------")
    for k, v in pairs( filterTable ) do
        print("Order: " .. k .. " " .. tostring(v) )
    end
    ]]
    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]
    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]

    --Pickup item order
    if order_type == 14 then
    	if targetIndex == direFlagIndex then
    		print( '[CTFGameMode] dire flag pickup requested' )
    		self:DireFlagPickup( issuer )
    		return false
    	end
    	if targetIndex == radiantFlagIndex then
    		print( '[CTFGameMode] radiant flag pickup requested' )
    		self:RadiantFlagPickup( issuer )
    		return false
    	end
    end

    return true
end

function CTFGameMode:DireScore()
	print('[CTFGameMode] Dire Score!')
	direScore = direScore + 1
end

function CTFGameMode:RadiantScore()
	print('[CTFGameMode] Radiant Score!')
	radiantScore = radiantScore + 1
end

function CTFGameMode:UpdateScoreboard()
	data = {}

	--Score data
	data.direScore = direScore
	data.radiantScore = radiantScore

	local direFlag = EntIndexToHScript( direFlagIndex )
	local direDistance = direFlag:GetOrigin():__sub( direFlagSpawn ):Length()

	local radiantFlag = EntIndexToHScript( radiantFlagIndex )
	local radiantDistance = radiantFlag:GetOrigin():__sub( radiantFlagSpawn ):Length()
	
	if direDistance > flagPickupRange then
		data.direLocation = "away"
	else
		data.direLocation = "home"
	end

	if radiantDistance > flagPickupRange then 
		data.radiantLocation = "away"
	else
		data.radiantLocation = "home"
	end

	CustomGameEventManager:Send_ServerToAllClients("flag_score_update", data)

	return 1
end

function CTFGameMode:GameModeWatch() 
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
		--PREGAME
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--GAME IN PROGRESS
		self:GiveAllHerosExp( expPerSecond )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		--POSTGAME KILL
		return nil
	end
	return 1
end

function CTFGameMode:PlayerSpawned( data )
	local entityIndex = data.entindex
	local entity = EntIndexToHScript( entityIndex )
end

function CTFGameMode:PlayerDeath( data )
	local entityIndex = data.entindex_killed
	local entity = EntIndexToHScript( entityIndex )

	--Check if had flag modifier
	if entity:HasModifier( radiantFlagModifier ) then
		--move radiant flag to death position
		local flag = EntIndexToHScript( radiantFlagIndex )
		flag:SetOrigin( entity:GetOrigin() )
	end

	--Check if had flag modifier
	if entity:HasModifier( direFlagModifier ) then
		--move radiant flag to death position
		local flag = EntIndexToHScript( direFlagIndex )
		flag:SetOrigin( entity:GetOrigin() )
	end

	--Check if had fake flag modifier
	if entity:HasModifier( radiantFakeFlagModifier ) then
		--move radiant flag to death position
		local flag = EntIndexToHScript( radiantFakeFlagIndex )
		flag:SetOrigin( entity:GetOrigin() )
	end

	--Check if had fake flag modifier
	if entity:HasModifier( direFakeFlagModifier ) then
		--move radiant flag to death position
		local flag = EntIndexToHScript( direFakeFlagIndex )
		flag:SetOrigin( entity:GetOrigin() )
	end


	--Set custom respawn time
	entity:SetTimeUntilRespawn( respawnTime )

end

function CTFGameMode:GiveAllHerosExp( exp )
	for i = 0, 10 do
		if PlayerResource:IsValidPlayerID( i ) then
			local hero = PlayerResource:GetSelectedHeroEntity( i )
			if hero ~= nil then
				hero:AddExperience( exp, 0, false, true)
			end
		end
	end
end


