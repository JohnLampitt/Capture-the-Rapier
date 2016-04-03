	--[[
		Globals
			radiantHomePos
			direHomePos
			radiantFlag
			direFlag
	]]

function CTFGameMode:DireFlagPickup( playerId )
	--Get the position of the dire flag
	local flagPosition = EntIndexToHScript( direFlagIndex ):GetOrigin()

	--Get hero for player
	local hero = PlayerResource:GetSelectedHeroEntity( playerId )

	--Check hero is capable of picking up flag
	if hero:IsStunned() or hero:IsNightmared() or hero:IsHexed() then
		return 
	end

	--Find distance between the dire flag and the hero
	local inRange = hero:IsPositionInRange( flagPosition, flagPickupRange )

	if inRange then
		print( '[FlagFunctions] dire flag in pickup range' )
		--Check player is on radiant team
		if PlayerResource:GetTeam( playerId ) == 2 then
			--Apply modifier
			print('[FlagFunctions] Applying flag modifier')
			local flag = EntIndexToHScript( direFlagIndex )
			flag:GetContainedItem():ApplyDataDrivenModifier( hero, hero, direFlagModifier, {})
			--Move flag off screen
			flag:SetOrigin( flagStorage )
		else 
			--Check if flag is at spawn already
			local flag = EntIndexToHScript( direFlagIndex )
			local distance = flag:GetOrigin():__sub( direFlagSpawn ):Length()
			if distance < flagPickupRange then
				--Check if this is a scoring flag touch
				if hero:HasModifier( radiantFlagModifier ) then
					--dire score
					self:DireScore()
					--reset radiant flag
					EntIndexToHScript( radiantFlagIndex ):SetOrigin( radiantFlagSpawn )
					--remove flag modifier from hero
					hero:RemoveModifierByName( radiantFlagModifier )
				end
			else
				--Return flag to base
				flag:SetOrigin( direFlagSpawn )
			end
		end
	else
		hero:MoveToPosition( flagPosition )
		print( '[FlagFunctions] dire flag not in pickup range' )
	end
end

function CTFGameMode:RadiantFlagPickup( playerId )
	--Get the position of the dire flag
	local flagPosition = EntIndexToHScript( radiantFlagIndex ):GetOrigin()

	--Get hero for player
	local hero = PlayerResource:GetSelectedHeroEntity( playerId )

	--Check hero is capable of picking up flag
	if hero:IsStunned() or hero:IsNightmared() or hero:IsHexed() then
		return 
	end

	--Find distance between the dire flag and the hero
	local inRange = hero:IsPositionInRange( flagPosition, flagPickupRange )

	if inRange then
		print( '[FlagFunctions] radiant flag in pickup range' )
		--Check player is on dire team
		if PlayerResource:GetTeam( playerId ) == 3 then
			--Apply modifier
			print('[FlagFunctions] Applying flag modifier')
			local flag = EntIndexToHScript( radiantFlagIndex )
			flag:GetContainedItem():ApplyDataDrivenModifier( hero, hero, radiantFlagModifier, {})
			--Move flag off screen
			flag:SetOrigin( flagStorage )
		else 
			--Check if flag is at spawn already
			local flag = EntIndexToHScript( radiantFlagIndex )
			local distance = flag:GetOrigin():__sub( radiantFlagSpawn ):Length()
			if distance < flagPickupRange then
				--Check if this is a scoring flag touch
				if hero:HasModifier( direFlagModifier ) then
					--radiant score
					self:RadiantScore()
					--reset dire flag
					EntIndexToHScript( direFlagIndex ):SetOrigin( direFlagSpawn )
					--remove flag modifier from hero
					hero:RemoveModifierByName( direFlagModifier )
				end
			else
				--Return flag to base
				flag:SetOrigin( radiantFlagSpawn )
			end
		end
	else
		hero:MoveToPosition( flagPosition )
		print( '[FlagFunctions] radiant flag not in pickup range' )
	end
end
