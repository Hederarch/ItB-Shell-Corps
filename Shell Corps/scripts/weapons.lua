

local path = mod_loader.mods[modApi.currentMod].resourcePath
local codepath = mod_loader.mods[modApi.currentMod].scriptPath
local replaceRepair = require(codepath.."replaceRepair/replaceRepair")

modApi:appendAsset("img/weapons/core_out_repair_noarrows.png", path .."img/weapons/core_out_repair_noarrows.png")
modApi:appendAsset("img/weapons/passives/passive_core_eject.png", path .."img/weapons/passive_core_eject.png")
modApi:appendAsset("img/weapons/chembombard_icon.png", path .."img/weapons/chembombard_icon.png")
modApi:appendAsset("img/weapons/elytrajets_icon.png", path .."img/weapons/elytrajets_icon.png")
modApi:appendAsset("img/weapons/jaws_icon.png", path .."img/weapons/jaws_icon.png")
modApi:appendAsset("img/effects/shotup_core.png", path .."img/effects/shotup_core.png")

local function isRealMission(mission)
    local mission = mission or GetCurrentMission()

    return true
		and mission ~= nil
		and mission ~= Mission_Test
		and Board
		and Board:IsMissionBoard()
end

--==================================================================================================================================--

Weapon_Load_Up = Emitter:new{
	image = "combat/icons/icon_doubleshot_glow.png",
	x = -12,
	y = 5,
	max_alpha = 1.0,
	min_alpha = 1.0,
	angle = -90,
	rot_speed = 0,
	angle_variance = 0,
	random_rot = false,
	lifespan = 0.75,
	burst_count = 1,
	speed = 0.75,
	birth_rate = 0,
	gravity = false,
	layer = LAYER_FRONT
}
--==================================================================================================================================--
SC_Reactor = PassiveSkill:new {
	Name = "Re-Actors",
	Description = "Instead of repairing, eject a core and re-activate another Mech.",
	Passive = "SC_Reactivator",
	Icon = "weapons/passives/passive_core_eject.png",
	PowerCost = 0,
	Upgrades = 0,
	--UpgradeCost = {3},
	TipImage = {
		Unit = Point(2,1),
		Friendly = Point(2,3),
		Target = Point(2,3),
	}
}

function SC_Reactor:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local damage = SpaceDamage(p2,0)
	damage.iShield = self.Shield
	damage.sAnimation = "ExploRepulse3",
	ret:AddBounce(p1, 1)
	ret:AddArtillery(damage, "effects/shotup_core.png")
	ret:AddScript(string.format("local pawn = Board:GetPawn(Point(%d,%d)) pawn:SetActive(true) pawn:SetMovementSpent(false)", p2.x, p2.y))
	return ret
end

replaceRepair:addSkill{
		Name = "Power Down",
		Description = "Pass a power core to an ally, transfering attack opportunity and movement if not used. Cannot target allies who still have their action and movement unspent.",
		weapon = "SC_Ejector",
		Icon = "img/weapons/core_out_repair_noarrows.png",
		IsActive = function(pawn)
			if not GAME then return false end
			local mission = GAME.GetMission and GetCurrentMission()
			if not mission then return false end
				for i = 1,#replaceRepair.repairSkills do
					local rskill = replaceRepair.repairSkills[i].PilotSkill
					if rskill ~= nil then
						if pawn:IsAbility(rskill) then -- defer to pilot replacerepairs
							return false 
						end
					end
				end
			return IsPassiveSkill("SC_Reactivator")
		end
	}

SC_Ejector = Skill:new {
	Name = "Power Down",
	Description = "Pass a power core to an ally, transfering attack opportunity and movement if not used. Cannot target allies who still have their action and movement unspent.",
	Icon = "img/weapons/core_out_repair_noarrows.png",
	TipImage = {
		Unit = Point(2,1),
		Friendly = Point(2,3),
		Target = Point(2,3),
	}
}

function SC_Ejector:GetTargetArea(point)
	local ret = PointList()

	local board_size = Board:GetSize()
	local repaired_units = {}
	for i = 0, board_size.x - 1 do
		for j = 0, board_size.y - 1  do
			if Board:IsPawnTeam(Point(i,j),TEAM_PLAYER) then
				local pawn_id = Board:GetPawn(Point(i,j)):GetId()
				if not repaired_units[pawn_id] and Point(i,j) ~= point and (Board:GetPawn(Point(i,j)):IsMovementSpent() or not Board:GetPawn(Point(i,j)):IsActive())  then--prevents targeting the same unit twice if it's large, targeting allies who would waste it, or targeting yourself
					ret:push_back(Point(i,j))
					repaired_units[pawn_id] = true
				end
			end
		end
	end

	return ret
end

function SC_Ejector:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local damage = SpaceDamage(p2,0)
	damage.sImageMark = "combat/icons/icon_doubleshot_glow.png"
	damage.sAnimation = "ExploRepulse3",
	ret:AddBounce(p1, 1)
	ret:AddArtillery(damage, "effects/shotup_core.png")
	ret:AddScript(string.format("local target = Point(%d,%d) local pawn = Board:GetPawn(target) Board:Ping(target,GL_Color(75, 250, 75, 0.75)) pawn:SetActive(true) pawn:SetMovementSpent(%s)", p2.x, p2.y,tostring(Board:GetPawn(p1):IsMovementSpent())))
	ret:AddBurst(p2,"Weapon_Load_Up",DIR_NONE)
	
	-- achievement triggers
	if isRealMission() and GAME.squadTitles["TipTitle_"..GameData.ach_info.squad] == "Shell Corps" then 
		if not modApi.achievements:isComplete("hedera_shell_corps", "sc_ach5") then --Indecisive
			ret:AddScript("local mission = GetCurrentMission() if mission ~= nil then if mission.sc_cores_passed == nil then LOG(\"SHELL CORPS ACH5 HOOK FAILURE\") end mission.sc_cores_passed = mission.sc_cores_passed + 1 if mission.sc_cores_passed >= 6 then modApi.achievements:trigger(\"hedera_shell_corps\",\"sc_ach5\") end end")
		end
		if not modApi.achievements:isComplete("hedera_shell_corps", "sc_ach4") then -- Do It Yourselves
			if Board:GetPawn(p2):IsMech() == false then
				ret:AddScript("local mission = GetCurrentMission() if mission ~= nil then if mission.sc_cores_lazy == nil then  LOG(\"SHELL CORPS ACH4 HOOK FAILURE\") end mission.sc_cores_lazy = mission.sc_cores_lazy + 1 if mission.sc_cores_lazy >= 3 then modApi.achievements:trigger(\"hedera_shell_corps\",\"sc_ach4\") end end")
			end
		end
	end
	
	return ret
end
--==================================================================================================================================--
SC_AngleJump = Skill:new{
	Name = "Elytra Jets",
	Description = "Powerful thrusters for combat maneuvering. Jump diagonally, then charge forwards and punch.",
	TwoClick = true,
	Class = "Brute",
	Icon = "weapons/elytrajets_icon.png",
	LaunchSound = "/weapons/leap",
	ImpactSound = "/impact/generic/mech",
	Range = 2,
	BonusPush = false,
	Damage = 2,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeList = {"Turbulence","Gliding"},
	UpgradeCost = {1,2},
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(1,2),
		Target = Point(3,2),
		Second_Click = Point(1,2),
	}
}

function SC_AngleJump:GetTargetArea(point)
	local ret = PointList()
	for i = DIR_START, DIR_END do
		for k = 1, self.Range do
			local curr = DIR_VECTORS[i]*k + DIR_VECTORS[(i + 1) % 4]*k + point
			if Board:IsValid(curr) and not Board:IsBlocked(curr, PATH_FLYER) then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function SC_AngleJump:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	if self.BonusPush then
		local takeoffx = SpaceDamage(p1,0)
		local takeoffy = SpaceDamage(p1,0)
		if p1.x > p2.x then
			takeoffx = SpaceDamage(p1 + DIR_VECTORS[DIR_RIGHT],0,DIR_RIGHT)
			takeoffx.sAnimation = "airpush_"..DIR_RIGHT
		else
			takeoffx = SpaceDamage(p1 + DIR_VECTORS[DIR_LEFT],0,DIR_LEFT)
			takeoffx.sAnimation = "airpush_"..DIR_LEFT
		end
		
		if p1.y > p2.y then
			takeoffy = SpaceDamage(p1 + DIR_VECTORS[DIR_DOWN],0,DIR_DOWN)
			takeoffy.sAnimation = "airpush_"..DIR_DOWN
		else
			takeoffy = SpaceDamage(p1 + DIR_VECTORS[DIR_UP],0,DIR_UP)
			takeoffy.sAnimation = "airpush_"..DIR_UP
		end
		
		ret:AddDamage(takeoffx)
		ret:AddDamage(takeoffy)
	else
		ret:AddDamage(SpaceDamage(p2, 0))
	end
	return ret
end

function SC_AngleJump:GetSecondTargetArea(p1,p2)
	local ret = PointList()
	local direction = GetDirection(p2 - p1)
	
	for i = DIR_START, DIR_END do
		for k = 1, self.Range do
			if Board:IsValid(DIR_VECTORS[i]*k + p2) then
				ret:push_back(DIR_VECTORS[i]*k + p2)
				if Board:IsBlocked(DIR_VECTORS[i]*k + p2, PATH_FLYER) then
					break
				end
			end
		end
	end
	return ret
end

function SC_AngleJump:GetFinalEffect(p1, p2, p3)
	local ret = SkillEffect()
	local dir = GetDirection(p3 - p2)
	
	local move = PointList()
	move:push_back(p1)
	move:push_back(p2)
	ret:AddBounce(p1,5)
	
	
	if self.BonusPush then
		local takeoffx = SpaceDamage(p1,0)
		local takeoffy = SpaceDamage(p1,0)
		if p1.x > p2.x then
			takeoffx = SpaceDamage(p1 + DIR_VECTORS[DIR_RIGHT],0,DIR_RIGHT)
			takeoffx.sAnimation = "airpush_"..DIR_RIGHT
		else
			takeoffx = SpaceDamage(p1 + DIR_VECTORS[DIR_LEFT],0,DIR_LEFT)
			takeoffx.sAnimation = "airpush_"..DIR_LEFT
		end
		
		if p1.y > p2.y then
			takeoffy = SpaceDamage(p1 + DIR_VECTORS[DIR_DOWN],0,DIR_DOWN)
			takeoffy.sAnimation = "airpush_"..DIR_DOWN
		else
			takeoffy = SpaceDamage(p1 + DIR_VECTORS[DIR_UP],0,DIR_UP)
			takeoffy.sAnimation = "airpush_"..DIR_UP
		end
		
		ret:AddDamage(takeoffx)
		ret:AddDamage(takeoffy)
	end
	ret:AddBurst(p1,"Emitter_Crack_Start2",DIR_NONE)
	ret:AddLeap(move, FULL_DELAY)
	
	if self.BonusPush then
	local backdir = GetDirection(p2 - p3)
		local pushfx = SpaceDamage(p2 + DIR_VECTORS[backdir],0,backdir)
		pushfx.sAnimation = "airpush_"..backdir
		ret:AddDamage(pushfx)
		ret:AddBounce(p2,3)
	else
		local pushfx = SpaceDamage(p2,0)
		pushfx.sAnimation = "airpush_"..GetDirection(p2 - p3)
		ret:AddDamage(pushfx)
		ret:AddBounce(p2,3)
	end
	if Board:IsBlocked(p3, PATH_FLYER) then
		ret:AddCharge(Board:GetSimplePath(p2, p3 - DIR_VECTORS[dir]), FULL_DELAY)
		local damage = SpaceDamage(p3, self.Damage, dir)
		damage.sAnimation = "explopunch1_"..dir
		ret:AddDamage(damage)	
	else
		ret:AddCharge(Board:GetSimplePath(p2, p3), FULL_DELAY)
		local brake = SpaceDamage(p3,0)
		brake.sAnimation = "airpush_"..dir
		ret:AddDamage(brake)
	end
	
	-- achievement triggers
	if isRealMission() and GAME.squadTitles["TipTitle_"..GameData.ach_info.squad] == "Shell Corps" then 
		if not modApi.achievements:isComplete("hedera_shell_corps", "sc_ach1") then --Hang Ten
			if (p1:Manhattan(p2)/2) + p2:Manhattan(p3) >= 10 then ret:AddScript("modApi.achievements:trigger(\"hedera_shell_corps\",\"sc_ach1\")") end
		end
	end
	
	return ret
end
	
SC_AngleJump_A = SC_AngleJump:new{
	UpgradeDescription = "Increases Damage but pushes more tiles when boosting.",
	BonusPush = true,
	Damage = 3,
	TipImage = {
		Unit = Point(2,3),
		Enemy1 = Point(1,2),
		Enemy2 = Point(1,3),
		Enemy3 = Point(2,4),
		Enemy4 = Point(4,2),
		Target = Point(3,2),
		Second_Click = Point(1,2),
	}
}
SC_AngleJump_B = SC_AngleJump:new{
	UpgradeDescription = "Removes range limits.",
	Range = 8,
	TipImage = {
		Unit = Point(1,5),
		Enemy = Point(1,1),
		Target = Point(5,1),
		Second_Click = Point(1,1),
	}
}
SC_AngleJump_AB = SC_AngleJump:new{
	Range = 8,
	Damage = 3,
	BonusPush = true,
	TipImage = {
		Unit = Point(2,3),
		Enemy1 = Point(1,2),
		Enemy2 = Point(1,3),
		Enemy3 = Point(2,4),
		Enemy4 = Point(4,2),
		Target = Point(3,2),
		Second_Click = Point(1,2),
	}
}
--==================================================================================================================================--

SC_KO_Combo = LineArtillery:new{ 
	Name = "Chem Bombarder",
	Description = "Fire an artillery that damages enemies and heals allies. Aim at self to repair.",
	Class = "Ranged",
	Icon = "weapons/chembombard_icon.png",
	Explosion = "",
	LaunchSound = "/weapons/acid_shot",
	ImpactSound = "/impact/generic/acid_canister",
	Combo = false,
	BuildingDmg = true,
	Upgrades = 2,
	UpgradeCost = {2,3},
	UpgradeList = { "Stable Compounds",  "Biofuel" },
	PowerCost = 0,
	Damage = 1,
	Healing = 1,
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1),
	},
}

function SC_KO_Combo:GetTargetArea(point)
	local ret = PointList()
	
	ret:push_back(point)
	
	for dir = DIR_START, DIR_END do
		for i = 2, self.ArtillerySize do
			local curr = Point(point + DIR_VECTORS[dir] * i)
			if not Board:IsValid(curr) then
				break
			end
			
			if not self.OnlyEmpty or not Board:IsBlocked(curr,PATH_GROUND) then
				ret:push_back(curr)
			end

		end
	end
	
	return ret
end

function SC_KO_Combo:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2-p1)

	if p2 == p1 then
		local self = SpaceDamage(p1,-self.Healing,dir)
		self.sAnimation = "ExploFirefly2"
		ret:AddDamage(self)
		return ret
	end

	local arc = SpaceDamage(p2,0)
	arc.sAnimation = "ExploFirefly2"
	ret:AddArtillery(arc, "effects/shotup_ant2.png")  


	if Board:GetPawnTeam(p2) == TEAM_PLAYER or (Board:IsBuilding(p2) and not self.BuildingDmg) then
		local heal = SpaceDamage(p2,-self.Healing,dir)
		heal.iFire = EFFECT_REMOVE
		heal.iAcid = EFFECT_REMOVE
		ret:AddDamage(heal)
		local damagepush = SpaceDamage(p2 + DIR_VECTORS[(dir+1)%4], 0, (dir+1)%4)
		damagepush.sAnimation = "airpush_"..((dir+1)%4)
		ret:AddDamage(damagepush) 
		damagepush = SpaceDamage(p2 + DIR_VECTORS[(dir-1)%4], 0, (dir-1)%4)
		damagepush.sAnimation = "airpush_"..((dir-1)%4)
		ret:AddDamage(damagepush)
	else
		local hurt = SpaceDamage(p2,self.Damage,dir) -- more than 1 damage is OP as fuck with _B up
		local do_kill_fx = false
		if self.Combo and Board:IsDeadly(hurt,Pawn) then
			hurt.bKO_Effect = true
			do_kill_fx = true
		end -- order issues, oh well.
		
		hurt.sAnimation = "ExploFirefly2"
		ret:AddDamage(hurt)
		local damagepush = SpaceDamage(p2 + DIR_VECTORS[(dir+1)%4], 0, (dir+1)%4)
		damagepush.sAnimation = "airpush_"..((dir+1)%4)
		ret:AddDamage(damagepush) 
		damagepush = SpaceDamage(p2 + DIR_VECTORS[(dir-1)%4], 0, (dir-1)%4)
		damagepush.sAnimation = "airpush_"..((dir-1)%4)
		ret:AddDamage(damagepush)
		
		if do_kill_fx then
			local rearc = SpaceDamage(p1,0)
			rearc.sAnimation = "ExploFirefly2"
			rearc.sImageMark = "combat/icons/icon_doubleshot_glow.png"
			rearc.sSound = "/impact/generic/grid_charge"
			rearc.bHidePath = true
			ret:AddArtillery(p2,rearc, "effects/shotup_core.png",FULL_DELAY)  
			ret:AddScript(string.format("local target = Point(%d,%d) local pawn = Board:GetPawn(target) Board:Ping(target,GL_Color(75, 250, 75, 0.75)) pawn:SetActive(true) pawn:SetMovementSpent(false)", p1.x, p1.y))
			ret:AddBurst(p1,"Weapon_Load_Up",DIR_NONE)
			
			-- achievement triggers
			if not modApi.achievements:isComplete("hedera_shell_corps", "sc_ach2") then --Green Energy
				ret:AddScript("local mission = GetCurrentMission() if mission ~= nil then if mission.sc_killcombo == nil then LOG(\"SHELL CORPS ACH2 HOOK FAILURE\") end mission.sc_killcombo = mission.sc_killcombo + 1 if mission.sc_killcombo >= 3 then modApi.achievements:trigger(\"hedera_shell_corps\",\"sc_ach2\") end end")
			end
			
			
		end
	end

	return ret
end

SC_KO_Combo_A = SC_KO_Combo:new{
	UpgradeDescription = "Increase healing by 2 and no longer damage Buildings",
	Healing = 3,
	BuildingDmg = false,
	TipImage = {
		Unit = Point(2,4),
		Building = Point(2,1),
		Enemy = Point(1,1),
		Enemy2 = Point(3,1),
		Target = Point(2,1),
	},
}
SC_KO_Combo_B = SC_KO_Combo:new{
	UpgradeDescription = "Creates makeshift cores from killed enemies, restoring attacks and movement.",
	Combo = true,
	OnKill = "Move & Attack Again",
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1),
		CustomEnemy = "Leaper1",
	},
}
SC_KO_Combo_AB = SC_KO_Combo:new{
	Combo = true,
	OnKill = "Move & Attack Again",
	Healing = 3,
	BuildingDmg = false,
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1),
		CustomEnemy = "Leaper1",
	},
}

--==================================================================================================================================--

SC_Jaws = {
	Name = "Power Jaws",
	Description = "Dash to a target and throw it. Longer dashes let you throw further.",
	Class = "Prime",
	Rarity = 1,
	Icon = "weapons/jaws_icon.png",	
	Explosion = "",
	TwoClick = true,
	Damage = 1,
	Diagonal = false,
	PushDamage = 0,
	Range = RANGE_PROJECTILE,--TOOLTIP info
	Cost = "low",
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {1,2},
	UpgradeList = { "Precise Throw",  "+1 Damage" },
	LaunchSound = "/weapons/grapple",
	ImpactSound = "/impact/generic/grapple",
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1),
		Second_Click = Point(2,3),
	}
}
			
SC_Jaws = Skill:new(SC_Jaws)

function SC_Jaws:GetTargetArea(p1)

	if not self.Phase then
		return Board:GetSimpleReachable(p1, self.PathSize, self.CornersAllowed)
	else
		local ret = PointList()
	
		for dir = DIR_START, DIR_END do
			for i = 1, 8 do
				local curr = Point(p1 + DIR_VECTORS[dir] * i)
				if not Board:IsValid(curr) then
					break
				end
				
				ret:push_back(curr)
				
				if Board:IsBlocked(curr,PATH_PHASING) then
					break
				end
			end
		end
	
	return ret
	
	end
end

function SC_Jaws:GetTargetArea(p1)

	if not self.Phase then
		return Board:GetSimpleReachable(p1, self.PathSize, self.CornersAllowed)
	else
		local ret = PointList()
	
		for dir = DIR_START, DIR_END do
			for i = 1, 8 do
				local curr = Point(p1 + DIR_VECTORS[dir] * i)
				if not Board:IsValid(curr) then
					break
				end
				
				ret:push_back(curr)
				
				if Board:IsBlocked(curr,PATH_PROJECTILE) then
					break
				end
			end
		end
	
	return ret
	
	end
end

function SC_Jaws:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)

	local pushloc = p2
	
	if Board:IsPawnSpace(p2) and not Board:GetPawn(p2):IsGuarding() then
		local target_id = Board:GetPawn(p2):GetId()
		local owner_id = Board:GetPawn(p1):GetId()
		ret:AddCharge(Board:GetSimplePath(p1, p2), FULL_DELAY)	
		local hit = SpaceDamage(p2, self.Damage)
		hit.sSound = "/impact/generic/mech"
		hit.sAnimation = "Swipe2Claw1"
		local nothrow = Board:IsDeadly(hit, Pawn) or Board:GetPawn(p2):IsGuarding()
		if Board:IsDeadly(hit, Pawn) then hit.bKO_Effect = true end
		ret:AddScript(string.format("Board:GetPawn(%d):SetSpace(Point(-1,-1))",owner_id)) --dodge the damage
		ret:AddDamage(hit)
		ret:AddScript(string.format("Board:GetPawn(%d):SetSpace(Point(%d,%d))",owner_id,p2.x,p2.y)) -- come back we miss you
		
		pushloc = p2
		if not nothrow then
			ret:AddScript(string.format("Board:GetPawn(%d):MoveToBottom()",target_id))
			local move = PointList()
			move:push_back(p2)
			move:push_back(p2 - DIR_VECTORS[direction])
			ret:AddBurst(p2,"Emitter_Crack_Start2",DIR_NONE)
			ret:AddLeap(move, FULL_DELAY)
		end
		
	elseif Board:IsBlocked(p2, PATH_PROJECTILE) then
		ret:AddCharge(Board:GetSimplePath(p1, p2 - DIR_VECTORS[direction]), FULL_DELAY)	
		pushloc = p2 - DIR_VECTORS[direction]
	else
		ret:AddCharge(Board:GetSimplePath(p1, p2), FULL_DELAY)	
		pushloc = p2
	end

	return ret
end

function SC_Jaws:IsTwoClickException(p1,p2)
	local hit = SpaceDamage(p2, self.Damage)
	return (Board:IsDeadly(hit, Pawn) or not Board:IsPawnSpace(p2))
end

function SC_Jaws:GetSecondTargetArea(p1,p2)
	local ret = PointList()
	local direction = GetDirection(p2 - p1)
	
	if not Board:IsPawnSpace(p2) or Board:GetPawn(p2):IsGuarding() then
		return ret
	end
	
	for i = DIR_START, DIR_END do
		for j = 1, p1:Manhattan(p2) do
			local curr = p2 + DIR_VECTORS[i]*j
			if (Board:IsValid(curr) and not Board:IsBlocked(curr, PATH_FLYER)) or curr == p1 then --allow for swaps
				ret:push_back(curr)
			end
			if self.Diagonal then
				local curr = p2 + DIR_VECTORS[i]*j + DIR_VECTORS[(i+1)%4]*j
				if Board:IsValid(curr) and not Board:IsBlocked(curr, PATH_FLYER) then
					ret:push_back(curr)
				end
			end
		end
	end
	
	return ret
end

function SC_Jaws:GetFinalEffect(p1, p2, p3)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)

	local pushloc = p2
	
	if Board:IsPawnSpace(p2) and not Board:GetPawn(p2):IsGuarding() then
		
		local target_id = Board:GetPawn(p2):GetId()
		local owner_id = Board:GetPawn(p1):GetId()

		
		
		local hit = SpaceDamage(p2, self.Damage)
		hit.sSound = "/impact/generic/mech"
		hit.sAnimation = "explosword_"..direction
		local nothrow = Board:IsDeadly(hit, Pawn) or Board:GetPawn(p2):IsGuarding()
		if not nothrow then 
			hit.sImageMark = "advanced/combat/throw_"..GetDirection(p2-p1)..".png" 
			hit.sAnimation = "explosword_"..direction
		end
		if Board:IsDeadly(hit, Pawn) then hit.bKO_Effect = true end
		ret:AddCharge(Board:GetSimplePath(p1, p2), FULL_DELAY)
		ret:AddScript(string.format("Board:GetPawn(%d):SetSpace(Point(-1,-1))",owner_id)) --dodge the damage
		ret:AddDamage(hit)
		ret:AddScript(string.format("Board:GetPawn(%d):SetSpace(Point(%d,%d))",owner_id,p2.x,p2.y)) -- come back we miss you
		pushloc = p2
		if not nothrow then
			ret:AddScript(string.format("Board:GetPawn(%d):MoveToBottom()",target_id))
			local move = PointList()
			move:push_back(p2)
			move:push_back(p3)
			ret:AddBurst(p2,"Emitter_Crack_Start2",DIR_NONE)
			local icon = SpaceDamage(p2,0)
			icon.sImageMark = "advanced/combat/throw_"..GetDirection(p2-p1)..".png"
			ret:AddDamage(icon)
			ret:AddLeap(move, NO_DELAY)
		end
		
		ret:AddDelay(1) --should cover leap time
	elseif Board:IsBlocked(p2, PATH_PROJECTILE) then
		ret:AddCharge(Board:GetSimplePath(p1, p2 - DIR_VECTORS[direction]), FULL_DELAY)	
		pushloc = p2 - DIR_VECTORS[direction]
		local hit = SpaceDamage(p2, self.Damage)
		hit.sSound = "/impact/generic/mech"
		hit.sAnimation = "Swipe2Claw1"
		ret:AddDamage(hit)
	else
		ret:AddCharge(Board:GetSimplePath(p1, p2), FULL_DELAY)	
		pushloc = p2
	end
	
	-- achievement triggers
	if isRealMission() and GAME.squadTitles["TipTitle_"..GameData.ach_info.squad] == "Shell Corps" then 
		if not modApi.achievements:isComplete("hedera_shell_corps", "sc_ach3") then --Unstoppable Force
			if p1:Manhattan(p2) >= 6 and not nothrow then ret:AddScript("modApi.achievements:trigger(\"hedera_shell_corps\",\"sc_ach3\")") end
		end
	end
	
	return ret
end

SC_Jaws_A = SC_Jaws:new{
	UpgradeDescription = "Can now throw targets diagonally as well.",
	Diagonal = true,
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1),
		Second_Click = Point(4,3),
	}
}

SC_Jaws_B = SC_Jaws:new{
	UpgradeDescription = "Increases Damage by 1.",
	Damage = 2,
}

SC_Jaws_AB = SC_Jaws:new{
	Damage = 2,
	Diagonal = true,
}