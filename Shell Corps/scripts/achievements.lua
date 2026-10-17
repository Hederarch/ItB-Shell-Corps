--stolen from Mass Destruction by Alcom Isst. Thanks Alcom!

--Libraries
local mod = modApi:getCurrentMod()
local modApiExt = modapiext

--Constants
local squad_id = "hedera_shell_corps"

--Save data
local function achievementData()

	local game = GAME or {}	-- GAME may not be initialized in the hangar menu. Use a dummy

	--Establish achievement data
	if game.hedera_sc_ach == nil then
		game.hedera_sc_ach = {}
	end

	if game.hedera_sc_ach.achievementData == nil then
		game.hedera_sc_ach.achievementData = {}
	end

	--Establish achievement data values
	local gameData = game.hedera_sc_ach.achievementData

	return gameData
end


local function check_mastery_status()
	if modApi.achievements:isComplete(squad_id,"sc_ach1") and modApi.achievements:isComplete(squad_id,"sc_ach2") and modApi.achievements:isComplete(squad_id,"sc_ach3") and modApi.achievements:isComplete(squad_id,"sc_ach4") and modApi.achievements:isComplete(squad_id,"sc_ach5") then
		modApi.achievements:trigger(squad_id,"sc_final")
	end
end



--Achievement 1
local sc_ach1 = modApi.achievements:add{
	--Required
	id = "sc_ach1",
	name = "Hang Ten",
	image = mod.resourcePath.."img/achievements/shellcorps_chievo1.png",

	--Optional
	tooltip = "Travel 10 spaces in one use of the Elytra Jets.",
	squad = squad_id,
	addReward = check_mastery_status,
	remReward = check_mastery_status,
}

--Achievement 2
local sc_ach2 = modApi.achievements:add{
	--Required
	id = "sc_ach2",
	name = "Green Energy",
	image = mod.resourcePath.."img/achievements/shellcorps_chievo2.png",

	--Optional
	tooltip = "Trigger Chem Bombarder's on-kill bonus 3 times in one turn.",
	squad = squad_id,
	addReward = check_mastery_status,
	remReward = check_mastery_status,
}

--Achievement 3
local sc_ach3 = modApi.achievements:add{
	--Required
	id = "sc_ach3",
	name = "Unstoppable Force",
	image = mod.resourcePath.."img/achievements/shellcorps_chievo3.png",

	--Optional
	tooltip = "Travel 6 spaces in one use of the Power Jaws, then throw an enemy.",
	squad = squad_id,
	addReward = check_mastery_status,
	remReward = check_mastery_status,
}

--Achievement 4
local sc_ach4 = modApi.achievements:add{
	--Required
	id = "sc_ach4",
	name = "Do It Yourselves",
	image = mod.resourcePath.."img/achievements/shellcorps_chievo4.png",

	--Optional
	tooltip = "Pass all 3 cores to a non-Mech ally in one turn.",
	squad = squad_id,
	addReward = check_mastery_status,
	remReward = check_mastery_status,
}


--Achievement 5
local sc_ach5 = modApi.achievements:add{
	--Required
	id = "sc_ach5",
	name = "Indecisive",
	image = mod.resourcePath.."img/achievements/shellcorps_chievo5.png",

	--Optional
	tooltip = "Pass cores 6 times in one turn.",
	squad = squad_id,
	addReward = check_mastery_status,
	remReward = check_mastery_status,
}

--Achievement Final
local sc_final = modApi.achievements:add{
	--Required
	id = "sc_final",
	name = "Shell Corps Mastery",
	image = mod.resourcePath.."img/achievements/shellcorps_mastery.png",

	--Optional
	tooltip = "Unlock all Shell Corps achievements.",
	squad = squad_id,
}

local function CleanMissionVariables(mission)
	mission.sc_cores_passed = 0
	mission.sc_cores_lazy = 0
	mission.sc_killcombo = 0
end


local function EVENT_onModsLoaded()
	modApi:addNextTurnHook(CleanMissionVariables)
end

modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)
