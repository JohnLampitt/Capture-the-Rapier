bloodParticle = "particles/units/heroes/hero_huskar/huskar_lifebreak_bloodyend.vpcf"
goreParticle = "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture_nuke.vpcf"

function DropRandomItem( data ) 
	--print('Drop random item called')
	local hero = data.caster

	local itemsCount = hero:GetNumItemsInInventory()

	if itemsCount == 0 then
		--print('No items in inventory, take health instead')
		HurtHeroPercentage(hero, data.no_item_health_loss, data.ability)
		return
	end

	local selectedItem = RandomInt(1, itemsCount)
	local itemsSeen = 0

	for i=0, 5 do
		local item = hero:GetItemInSlot(i)
		if item ~= nil then
			itemsSeen = itemsSeen + 1
			if itemsSeen == selectedItem then
				--Drop selected item
				local copiedItem = CreateItem( item:GetName(), nil, nil )
				--Should probably do charges
				local spawnPoint = hero:GetAbsOrigin()
				local physicalObject = CreateItemOnPositionSync( spawnPoint, copiedItem )
				copiedItem:LaunchLoot( false, RandomFloat(100,500) , RandomFloat(0.5, 1.5), spawnPoint + RandomVector( 600 ))
				hero:RemoveItem(item)
				return
			end
		end
	end
end

function HurtHeroPercentage( hero, percentage, ability )
	local hurtDamage = hero:GetMaxHealth() * percentage / 100
	local currentHealth = hero:GetHealth()
	hero:ModifyHealth( currentHealth - hurtDamage, ability, true, 0)
	if currentHealth - hurtDamage > 0 then
		ParticleManager:CreateParticle(bloodParticle, 7, hero)
	else
		ParticleManager:CreateParticle(goreParticle, 7, hero)
	end
end


function HitByProjectile( data ) 
	local target = data.target
	local casterPos = data.caster:GetAbsOrigin()
	local caster = data.caster
	local knockbackTarget = target

	if target:HasModifier( knockbackInvulModifier ) then
		--Create a illusion
		illusion = CreateIllusion( data.target, 10, 100, 100)

		--Apply invis to hero
		target:AddNewModifier(target, data.ability, "modifier_invisible", {duration = 3}) 


		--Deal with fake flags
		if target:HasModifier( radiantFlagModifier ) then
			--Give the illusion a fake radiant flag
			local radiantFakeFlag = EntIndexToHScript( radiantFakeFlagIndex )
			radiantFakeFlag:GetContainedItem():ApplyDataDrivenModifier( illusion, illusion, radiantFakeFlagModifier, {})
		end

		if target:HasModifier( direFlagModifier ) then
			--Give the illusion a fake dire flag
			local direFakeFlag = EntIndexToHScript( direFakeFlagIndex )
			direFakeFlag:GetContainedItem():ApplyDataDrivenModifier( illusion, illusion, direFakeFlagModifier, {})
		end

		--Set new knockback target
		knockbackTarget = illusion
	else
		if target:HasModifier( radiantFlagModifier ) then
			target:RemoveModifierByName( radiantFlagModifier )
			EntIndexToHScript( radiantFlagIndex ):SetOrigin( target:GetOrigin() )
		end

		if target:HasModifier( direFlagModifier ) then
			target:RemoveModifierByName( direFlagModifier )
			EntIndexToHScript( direFlagIndex ):SetOrigin( target:GetOrigin() )
		end
	end

	--Create knocback effect
	knockbackTarget:AddNewModifier(knockbackTarget, nil, "modifier_knockback",
	                {
	                        duration = 1,
	                        should_stun = 1,
	                        knockback_distance = 200,
	                        knockback_height = 100,
	                        knockback_duration = 1,
	                        center_x = casterPos.x,
	                        center_y = casterPos.y,
	                        center_z = casterPos.z,
	                })

	--Remove invul from target
	target:RemoveModifierByName( knockbackInvulModifier )
end

function CreateIllusion( hero, duration, incomingDamage, outgoingDamage )
	local unit = hero:GetUnitName()
	local position = hero:GetAbsOrigin()

	--Create illusion
	local illusion = CreateUnitByName( unit, position, false, hero, nil, hero:GetTeamNumber() )
	local angles = hero:GetAngles()
	illusion:SetAngles( angles.x, angles.y, angles.z )


	--Allow controlable
	illusion:SetPlayerID( hero:GetPlayerID() )
	illusion:SetControllableByPlayer( hero:GetPlayerID(), true )


	--Level up correctly
	while illusion:GetLevel() ~= hero:GetLevel() do
		illusion:HeroLevelUp( false )
	end
	illusion:SetAbilityPoints( 0 )

	--Skill correctly
	for abilityNumber = 0, 5 do
		local ability = hero:GetAbilityByIndex( abilityNumber )
		if ability ~= nil then
			local illusionAbility = illusion:FindAbilityByName( ability:GetAbilityName() )
			illusionAbility:SetLevel( ability:GetLevel() )
		end
	end

	--Copy across items
	for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot( itemSlot )
		if item ~= nil then
			local illusionItem = CreateItem( item:GetName() , illusion, illusion)
			illusion:AddItem( illusionItem )
		end
	end

	--Copy across cosmetics
	local cosmetic = hero:FirstMoveChild()
	local illusionCosmetic = illusion:FirstMoveChild()
	local cosmeticContainer = {}
	local illusionCosmeticContainer = {}
	while cosmetic ~= nil or illusionCosmetic ~= nil do
		--if cosmetic:GetClassname() ~= "" and cosmetic:GetClassname() == "dota_item_wearable" then
		if cosmetic:GetClassname() == "dota_item_wearable" and cosmetic:GetModelName()~= "" then
			local modelName = cosmetic:GetModelName()
			--local oldModelName = illusionCosmetic:GetModelName()
			--illusionCosmetic:SetModel(modelName)
			--print( 'Illusion prev:' .. oldModelName .. ' now set to:' .. modelName )
			table.insert(cosmeticContainer, modelName)
			table.insert(illusionCosmeticContainer, illusionCosmetic)
		end
		cosmetic = cosmetic:NextMovePeer()
		illusionCosmetic = illusionCosmetic:NextMovePeer()
	end
	for i, v in ipairs(cosmeticContainer) do
		illusionCosmeticContainer[i]:SetModel(v)
	end

	--Match health
	illusion:ModifyHealth( hero:GetHealth(), nil, true, 0)

	--Turn unit into illusion
	illusion:MakeIllusion()
	illusion:AddNewModifier(hero, nil, "modifier_illusion", {duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage})


	return illusion
end		

function TestCall( data )
	print( 'TestCalled' )
end
