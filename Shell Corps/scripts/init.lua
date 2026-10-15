
-- Squad Template by Hedera, built fron Lemonymous' Mech Template mod

local mod = {
	id = "hedera_shell_corps", --replace this, make it unique! it's only internal so it doesn't really matter.
	name = "Shell Corps", -- this name is what shows up in the mod list 
	version = "1.0.0", 
	requirements = {}, 
	modApiVersion = "2.3.0",
	icon = "img/mod_icon.png"
}

function mod:init() -- these are the files that the modloader will load
	local replaceRepair = require(self.scriptPath.."replaceRepair/replaceRepair")
	require(self.scriptPath .."achievements")
	require(self.scriptPath .."palettes")
	require(self.scriptPath .."pawns")
	require(self.scriptPath .."weapons")
	require(self.scriptPath .."hooks")
	
end
	-- this adds your weapons to the weapon deck so other squads can use them
    modApi:addWeaponDrop("SC_Jaws")
    modApi:addWeaponDrop("SC_AngleJump")
    modApi:addWeaponDrop("SC_KO_Combo")
	modApi:addWeaponDrop("SC_Reactor")

function mod:load(options, version)

	modApi:addSquad( 
		{
			id = mod.id,
			"Shell Corps",	--this name is what shows up in the hangar
			"SC_StagMech",			
			"SC_RoveMech",			
			"SC_JewelMech"			
		},
		"Shell Corps", -- this name is what shows up in the squad list
		"Sleek and modular mechs which can quickly transfer power cores to energize allies, but struggle with field repairs.", -- description when moused over
		self.resourcePath .."img/mod_icon.png"
	)
end

return mod
