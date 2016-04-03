-- Generated from template
require("ctf")

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	--Precache flags
	PrecacheItemByNameSync(direFlagItem, context)
	PrecacheItemByNameSync(radiantFlagItem, context)
	PrecacheResource( "particle" , bloodParticle, context)
	PrecacheResource( "particle" , goreParticle, context)
	
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CTFGameMode()
	GameRules.AddonTemplate:InitGameMode()
	--GameRules.AddonTemplate:SetUp()
end