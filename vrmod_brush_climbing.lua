if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("vrmod_brush_climb_launch")
	util.AddNetworkString("vrmod_brush_climb_sync")
	util.AddNetworkString("vrmod_wallrun_sync")
	util.AddNetworkString("vrmod_slide_sync")

	local svLedgeNormalMin   = CreateConVar("sv_vrmod_brushclimb_ledge_normal_min",  "0.55", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum surface normal Z to classify as a ledge (below this = wall)", 0, 1)
	local svFloorNormalMin   = CreateConVar("sv_vrmod_brushclimb_floor_normal_min",  "0.85", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum surface normal Z to classify as a floor (above = floor, below = ledge)", 0, 1)
	local svCeilNormalMax    = CreateConVar("sv_vrmod_brushclimb_ceil_normal_max",   "-0.55",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum surface normal Z to classify as a ceiling", -1, 0)
	local svReduceCollider   = CreateConVar("sv_vrmod_brushclimb_reduce_collider",   "1",    {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Force duck hull while climbing and after release until ground touch", 0, 1)
	-- Surface type permissions (admin sets the ceiling; clients can only further restrict)
	local svAllowWalls       = CreateConVar("sv_vrmod_brushclimb_allow_walls",       "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing wall surfaces", 0, 1)
	local svAllowCeilings    = CreateConVar("sv_vrmod_brushclimb_allow_ceilings",    "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing ceiling surfaces", 0, 1)
	local svAllowLedges      = CreateConVar("sv_vrmod_brushclimb_allow_ledges",      "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing ledge surfaces", 0, 1)
	local svAllowFloors      = CreateConVar("sv_vrmod_brushclimb_allow_floors",      "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing floor surfaces", 0, 1)
	-- Entity type permissions
	local svAllowDoors       = CreateConVar("sv_vrmod_brushclimb_allow_doors",       "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing door entities", 0, 1)
	local svAllowPushable    = CreateConVar("sv_vrmod_brushclimb_allow_pushable",    "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing func_pushable entities", 0, 1)
	local svAllowToggleable  = CreateConVar("sv_vrmod_brushclimb_allow_toggleable",  "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing toggleable brush entities (func_button, etc.)", 0, 1)
	local svWallrunJumpForce = CreateConVar("sv_vrmod_wallrun_jump_force", "350", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Wall jump launch force", 50, 800)
	local svWallrunWallForce = CreateConVar("sv_vrmod_wallrun_wall_force", "120", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Force pushing player into wall while running", 10, 400)
	local svWallrunFreeTime = CreateConVar("sv_vrmod_wallrun_free_time", "0.6", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds of free running before gravity builds", 0, 10)
	local svWallrunFallRate = CreateConVar("sv_vrmod_wallrun_fall_rate", "90", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Downward acceleration after free time", 0, 600)
	local svWallrunMaxFall = CreateConVar("sv_vrmod_wallrun_max_fall_speed", "260", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max downward speed while wall running", 0, 1000)
	local svWallrunSpeedGrace = CreateConVar("sv_vrmod_wallrun_speed_grace", "0.15", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to blend direction when attaching to wall at speed", 0, 1)
	local svWallrunMinJumpTime = CreateConVar("sv_vrmod_wallrun_min_jump_time", "0.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Min seconds on wall before wallrun jump fires (prevents sprint-jump hijack)", 0, 1)

	local svSlideEnable      = CreateConVar("sv_vrmod_slide_enable",       "1",   {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Enable VRMod sliding", 0, 1)
	local svSlideMinSpeed    = CreateConVar("sv_vrmod_slide_min_speed",    "150", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum horizontal speed to enter a slide", 0, 800)
	local svSlideFriction    = CreateConVar("sv_vrmod_slide_friction",     "40",  {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Horizontal deceleration while sliding (units/s^2)", 0, 600)
	local svSlideAirBoost    = CreateConVar("sv_vrmod_slide_air_boost",    "80",  {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed boost added when landing into a slide from the air", 0, 600)
	local svSlideStopSpeed   = CreateConVar("sv_vrmod_slide_stop_speed",   "60",  {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed below which a slide automatically ends", 0, 400)
	local svSlideEntryBoost  = CreateConVar("sv_vrmod_slide_entry_boost",  "60",  {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Flat speed bonus added the moment a slide begins", 0, 600)

	local editableServerCvars = {
		sv_vrmod_brushclimb_ledge_normal_min = svLedgeNormalMin,
		sv_vrmod_brushclimb_floor_normal_min = svFloorNormalMin,
		sv_vrmod_brushclimb_ceil_normal_max  = svCeilNormalMax,
		sv_vrmod_brushclimb_reduce_collider  = svReduceCollider,
		sv_vrmod_brushclimb_allow_walls      = svAllowWalls,
		sv_vrmod_brushclimb_allow_ceilings   = svAllowCeilings,
		sv_vrmod_brushclimb_allow_ledges     = svAllowLedges,
		sv_vrmod_brushclimb_allow_floors     = svAllowFloors,
		sv_vrmod_brushclimb_allow_doors      = svAllowDoors,
		sv_vrmod_brushclimb_allow_pushable   = svAllowPushable,
		sv_vrmod_brushclimb_allow_toggleable = svAllowToggleable,
		sv_vrmod_wallrun_jump_force = svWallrunJumpForce,
		sv_vrmod_wallrun_wall_force = svWallrunWallForce,
		sv_vrmod_wallrun_free_time = svWallrunFreeTime,
		sv_vrmod_wallrun_fall_rate = svWallrunFallRate,
		sv_vrmod_wallrun_max_fall_speed = svWallrunMaxFall,
		sv_vrmod_wallrun_speed_grace    = svWallrunSpeedGrace,
		sv_vrmod_wallrun_min_jump_time  = svWallrunMinJumpTime,
		sv_vrmod_slide_enable      = svSlideEnable,
		sv_vrmod_slide_min_speed   = svSlideMinSpeed,
		sv_vrmod_slide_friction    = svSlideFriction,
		sv_vrmod_slide_air_boost   = svSlideAirBoost,
		sv_vrmod_slide_stop_speed  = svSlideStopSpeed,
		sv_vrmod_slide_entry_boost = svSlideEntryBoost,
	}

	concommand.Add("vrmod_brushclimb_admin_set", function(ply, _, args)
		if IsValid(ply) and not ply:IsAdmin() then return end
		local cvarName = args[1]
		local rawValue = args[2]
		local cv = cvarName and editableServerCvars[cvarName] or nil
		if not cv or rawValue == nil then return end
		cv:SetString(tostring(rawValue))
	end)

	local fallProtectUntil = {}
	local nextLaunchTime = {}
	local isBrushHolding = {}
	local holdExpireAt = {}
	local duckHoldUntil = {}
	local duckUntilGround = {}
	local zeroVel = Vector(0, 0, 0)

	-- Slide state
	local isSliding         = {}
	local slideDir          = {}
	local slideSpeed        = {}
	local wantsSlide        = {}
	local slideDirWanted    = {}
	local wasAirLow         = {}
	local slideJumpMomentum = {}  -- {dir, speed, storedAt}

	-- Wall run entry state
	local wallRunEntrySpeed = {}  -- horizontal speed captured at first wall contact
	local holdSyncGrace = 0.25
	local duckGrace = 0.35
	local maxSyncDistSqr = 300 * 300
	local nudgeDirs = {
		Vector(0, 0, 1), Vector(0, 0, -1),
		Vector(1, 0, 0), Vector(-1, 0, 0),
		Vector(0, 1, 0), Vector(0, -1, 0),
		Vector(1, 1, 0):GetNormalized(), Vector(1, -1, 0):GetNormalized(),
		Vector(-1, 1, 0):GetNormalized(), Vector(-1, -1, 0):GetNormalized(),
	}

	local function CanFitAt(ply, pos, mins, maxs)
		local tr = util.TraceHull({
			start = pos,
			endpos = pos,
			mins = mins,
			maxs = maxs,
			mask = MASK_PLAYERSOLID,
			filter = ply,
		})
		return not (tr.StartSolid or tr.AllSolid)
	end

	local function CanFitAnyHull(ply, pos)
		local minsStand, maxsStand = ply:GetHull()
		local minsDuck, maxsDuck = ply:GetHullDuck()
		return CanFitAt(ply, pos, minsStand, maxsStand) or CanFitAt(ply, pos, minsDuck, maxsDuck)
	end

	local function ResolveToNearbyFit(ply, desiredPos, fallbackPos, maxRadius, stepSize)
		if CanFitAnyHull(ply, desiredPos) then
			return desiredPos
		end

		maxRadius = maxRadius or 18
		stepSize = stepSize or 3
		for radius = stepSize, maxRadius, stepSize do
			for i = 1, #nudgeDirs do
				local testPos = desiredPos + nudgeDirs[i] * radius
				if CanFitAnyHull(ply, testPos) then
					return testPos
				end
			end
			local upTest = desiredPos + Vector(0, 0, radius * 0.8)
			if CanFitAnyHull(ply, upTest) then
				return upTest
			end
		end

		if fallbackPos and CanFitAnyHull(ply, fallbackPos) then
			return fallbackPos
		end
		return nil
	end

	local function applyLaunch(_, ply)
		if not IsValid(ply) then return end
		local now = CurTime()
		if (nextLaunchTime[ply] or 0) > now then return end
		nextLaunchTime[ply] = now + 0.08

		local launch = net.ReadVector()
		local maxSpeed = 900
		if launch:LengthSqr() > maxSpeed * maxSpeed then
			launch = launch:GetNormalized() * maxSpeed
		end

		local currentVel = ply:GetVelocity()
		local desiredVel = currentVel + launch
		local maxResultSpeed = 950
		if desiredVel:LengthSqr() > maxResultSpeed * maxResultSpeed then
			desiredVel = desiredVel:GetNormalized() * maxResultSpeed
		end
		ply:SetVelocity(desiredVel - currentVel)
	end

	if vrmod and vrmod.NetReceiveLimited then
		vrmod.NetReceiveLimited("vrmod_brush_climb_launch", 24, 96, applyLaunch)
	else
		net.Receive("vrmod_brush_climb_launch", applyLaunch)
	end

	local function applySync(_, ply)
		if not IsValid(ply) then return end
		local pos = net.ReadVector()
		local holding = net.ReadBool()
		if not pos then return end

		local currentPos = ply:GetPos()
		local now = CurTime()
		if currentPos:DistToSqr(pos) > maxSyncDistSqr then
			if not holding then
				isBrushHolding[ply] = false
				holdExpireAt[ply] = nil
			end
			return
		end

		if holding then
			local resolved = ResolveToNearbyFit(ply, pos, currentPos, 20, 4)
			if resolved then
				ply:SetPos(resolved)
				isBrushHolding[ply] = true
				holdExpireAt[ply] = now + holdSyncGrace
				duckHoldUntil[ply] = now + duckGrace
				fallProtectUntil[ply] = now + 0.35
			else
				isBrushHolding[ply] = false
				holdExpireAt[ply] = nil
				fallProtectUntil[ply] = now + 0.45
			end
			return
		end

		isBrushHolding[ply] = false
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = now + 0.2
		duckUntilGround[ply] = svReduceCollider:GetBool()

		local resolved = ResolveToNearbyFit(ply, pos, currentPos, 14, 2)
		if resolved then
			ply:SetPos(resolved)
		end
		fallProtectUntil[ply] = now + 0.9
	end

	if vrmod and vrmod.NetReceiveLimited then
		vrmod.NetReceiveLimited("vrmod_brush_climb_sync", 60, 128, applySync)
	else
		net.Receive("vrmod_brush_climb_sync", applySync)
	end

	-- Wall run server state
	local vrWallRunWants = {}
	local wallRunStartTime = {}

	net.Receive("vrmod_wallrun_sync", function(_, ply)
		if not IsValid(ply) then return end
		local active = net.ReadBool()
		local normal = net.ReadVector()
		if active then
			vrWallRunWants[ply] = normal
		else
			vrWallRunWants[ply] = nil
		end
	end)

	net.Receive("vrmod_slide_sync", function(_, ply)
		if not IsValid(ply) then return end
		local active = net.ReadBool()
		local dir    = net.ReadVector()
		wantsSlide[ply]     = active
		slideDirWanted[ply] = dir
	end)

	hook.Add("GetFallDamage", "vrmod_brush_climb_nofall", function(ply)
		if fallProtectUntil[ply] and fallProtectUntil[ply] > CurTime() then return 0 end
		if vrWallRunWants[ply] or wallRunStartTime[ply] then return 0 end
		if isSliding[ply] or slideJumpMomentum[ply] or wasAirLow[ply] or wantsSlide[ply] then return 0 end
	end)

	hook.Add("SetupMove", "vrmod_brush_climb_hold_velocity_lock", function(ply, mv)
		local now = CurTime()
		local holding = isBrushHolding[ply] and (holdExpireAt[ply] or 0) > now
		if holding then
			mv:SetVelocity(zeroVel)
			mv:SetForwardSpeed(0)
			mv:SetSideSpeed(0)
			mv:SetUpSpeed(0)
		elseif isBrushHolding[ply] then
			isBrushHolding[ply] = false
		end

		-- Wall run physics
		local wallNormal = vrWallRunWants[ply]
		if wallNormal and not holding and not ply:IsOnGround() then
			local currentVel = mv:GetVelocity()
			local currentHorizSpeed = Vector(currentVel.x, currentVel.y, 0):Length()

			if not wallRunStartTime[ply] then
				wallRunStartTime[ply] = now
				wallRunEntrySpeed[ply] = currentHorizSpeed
				fallProtectUntil[ply] = now + 10
			end

			local elapsed = now - wallRunStartTime[ply]

			-- FIX: only fire wallrun jump if the player has actually been on the wall
			-- long enough. This prevents a sprint-jump grazing the wall for one tick
			-- from hijacking the jump direction.
			if ply:KeyPressed(IN_JUMP) then
				if elapsed >= svWallrunMinJumpTime:GetFloat() then
					-- True wallrun jump
					local eyeFwd = ply:EyeAngles():Forward()
					local flatFwd = Vector(eyeFwd.x, eyeFwd.y, 0)
					if flatFwd:LengthSqr() > 0.001 then flatFwd:Normalize() end
					local jumpDir = (flatFwd + wallNormal * 0.5 + Vector(0, 0, 0.7)):GetNormalized()
					local jumpVel = jumpDir * svWallrunJumpForce:GetFloat()
					local resultVel = currentVel + jumpVel
					local maxSpeed = 950
					if resultVel:LengthSqr() > maxSpeed * maxSpeed then
						resultVel = resultVel:GetNormalized() * maxSpeed
					end
					mv:SetVelocity(resultVel)
					fallProtectUntil[ply] = now + 1.0
				end
				-- Either way, exit wallrun on jump press
				vrWallRunWants[ply] = nil
				wallRunEntrySpeed[ply] = nil
			else
				-- Wall-run movement direction
				local viewDir = ply:EyeAngles():Forward()
				local moveDir = viewDir - wallNormal * viewDir:Dot(wallNormal)
				moveDir.z = 0
				if moveDir:LengthSqr() < 0.001 then
					moveDir = wallNormal:Cross(Vector(0, 0, 1))
				end
				moveDir:Normalize()

				local freeTime    = svWallrunFreeTime:GetFloat()
				local entrySpeed  = wallRunEntrySpeed[ply] or 0

				-- FIX: never reduce horizontal speed. Always carry at least entrySpeed
				-- (or whatever is faster right now). The drop phase only adds downward
				-- velocity — it does not touch horizontal.
				local targetHorizSpeed = math.max(entrySpeed, currentHorizSpeed, ply:GetMaxSpeed())

				-- FIX: gravity adds to current Z instead of replacing it.
				-- During free time: hold Z near zero (counteract gravity).
				-- After free time: accumulate downward acceleration on top of currentVel.z.
				local zVel
				if elapsed < freeTime then
					zVel = math.max(currentVel.z, -4.0)
				else
					local fallRate = svWallrunFallRate:GetFloat()
					local maxFall  = svWallrunMaxFall:GetFloat()
					zVel = math.max(currentVel.z - fallRate * FrameTime(), -maxFall)
				end

				-- Direction grace: blend entry heading → wall-run direction
				local spGrace = svWallrunSpeedGrace:GetFloat()
				local wallPushFlat = Vector(-wallNormal.x, -wallNormal.y, 0) * svWallrunWallForce:GetFloat()
				local targetFlat = moveDir * targetHorizSpeed

				local finalFlat
				if spGrace > 0 and elapsed < spGrace then
					local t = elapsed / spGrace
					local entryFlat = Vector(currentVel.x, currentVel.y, 0)
					if entryFlat:LengthSqr() < 0.001 then entryFlat = targetFlat end
					local blendedDir = LerpVector(t, entryFlat:GetNormalized(), moveDir)
					if blendedDir:LengthSqr() < 0.001 then blendedDir = moveDir end
					blendedDir:Normalize()
					finalFlat = blendedDir * targetHorizSpeed
				else
					finalFlat = targetFlat
				end

				mv:SetVelocity(finalFlat + wallPushFlat + Vector(0, 0, zVel))
				mv:SetSideSpeed(0)
				if mv:GetForwardSpeed() < 0 then mv:SetForwardSpeed(0) end
			end
		elseif ply:IsOnGround() then
			wallRunStartTime[ply] = nil
			wallRunEntrySpeed[ply] = nil
		end

		if duckHoldUntil[ply] and bit.band(ply:GetFlags(), FL_ONGROUND) ~= 0 then
			duckHoldUntil[ply] = nil
		end
		if duckUntilGround[ply] and bit.band(ply:GetFlags(), FL_ONGROUND) ~= 0 then
			duckUntilGround[ply] = nil
		end

		-- ── Sliding ───────────────────────────────────────────────────────────
		if svSlideEnable:GetBool() and not holding and not vrWallRunWants[ply] then
			local vel        = mv:GetVelocity()
			local onGround   = ply:IsOnGround()
			local frameTime  = FrameTime()
			-- Only use the client HMD-height signal. Do NOT use IN_DUCK as a fallback:
			-- VRmod sets IN_DUCK on every crouch-jump, which would silently trigger a
			-- fake slide on any fast sprint-jump and corrupt the jump direction.
			local low = wantsSlide[ply] == true

			-- Re-apply slide-jump horizontal momentum (first airborne tick).
			-- storedAt prevents the discard branch from firing on the same tick as the jump.
			-- Also discard if the player is no longer low - they stood up, so the slide
			-- momentum should not apply (and was likely a false trigger to begin with).
			if slideJumpMomentum[ply] then
				local mom = slideJumpMomentum[ply]
				local age = now - mom.storedAt
				if not onGround and not low then
					-- Player stood up mid-air: discard, do not apply locked direction.
					slideJumpMomentum[ply] = nil
				elseif not onGround and low then
					mv:SetVelocity(Vector(mom.dir.x * mom.speed, mom.dir.y * mom.speed, vel.z))
					slideJumpMomentum[ply] = nil
				elseif age > 0.3 then
					slideJumpMomentum[ply] = nil
				end
			end

			if isSliding[ply] then
				local dir   = slideDir[ply]
				local speed = slideSpeed[ply] or 0
				speed = math.max(speed - svSlideFriction:GetFloat() * frameTime, 0)
				slideSpeed[ply] = speed

				if not low or not onGround or speed < svSlideStopSpeed:GetFloat() then
					isSliding[ply]  = false
					slideDir[ply]   = nil
					slideSpeed[ply] = nil
				elseif ply:KeyPressed(IN_JUMP) then
					slideJumpMomentum[ply] = { dir = dir, speed = speed, storedAt = now }
					isSliding[ply]  = false
					slideDir[ply]   = nil
					slideSpeed[ply] = nil
				else
					mv:SetVelocity(dir * speed + Vector(0, 0, vel.z))
					mv:SetForwardSpeed(0)
					mv:SetSideSpeed(0)
					mv:SetUpSpeed(0)
					mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
				end

			elseif onGround and low then
				local hVel  = Vector(vel.x, vel.y, 0)
				local speed = hVel:Length()
				local boost = 0
				if wasAirLow[ply] then
					boost = svSlideAirBoost:GetFloat()
					wasAirLow[ply] = nil
				end
				if (speed + boost) >= svSlideMinSpeed:GetFloat() then
					local dir = slideDirWanted[ply]
					if not dir or dir:LengthSqr() < 0.01 then dir = hVel end
					dir = Vector(dir.x, dir.y, 0)
					if dir:LengthSqr() > 0.001 then
						dir:Normalize()
						local entrySpeed = speed + boost + svSlideEntryBoost:GetFloat()
						isSliding[ply]  = true
						slideDir[ply]   = dir
						slideSpeed[ply] = entrySpeed
						mv:SetVelocity(dir * entrySpeed + Vector(0, 0, vel.z))
						mv:SetForwardSpeed(0)
						mv:SetSideSpeed(0)
						mv:SetUpSpeed(0)
						mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
						ply:EmitSound("physics/concrete/concrete_scrape_smooth1.wav", 75, math.random(90, 110), 0.6)
					end
				end

			elseif not onGround and low then
				wasAirLow[ply] = true
			elseif onGround then
				wasAirLow[ply] = nil
			end
		end
		-- ── End Sliding ───────────────────────────────────────────────────────

		local forceDuck = (duckHoldUntil[ply] or 0) > now
		if svReduceCollider:GetBool() then
			forceDuck = forceDuck or holding or duckUntilGround[ply] == true
		end
		if forceDuck then
			mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
		end
	end)

	hook.Add("PlayerDisconnected", "vrmod_brush_climb_cleanup", function(ply)
		fallProtectUntil[ply] = nil
		nextLaunchTime[ply] = nil
		isBrushHolding[ply] = nil
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = nil
		duckUntilGround[ply] = nil
		vrWallRunWants[ply] = nil
		wallRunStartTime[ply] = nil
		wallRunEntrySpeed[ply] = nil
		isSliding[ply]         = nil
		slideDir[ply]          = nil
		slideSpeed[ply]        = nil
		wantsSlide[ply]        = nil
		slideDirWanted[ply]    = nil
		wasAirLow[ply]         = nil
		slideJumpMomentum[ply] = nil
	end)

	hook.Add("PlayerDeath", "vrmod_brush_climb_cleanup_death", function(ply)
		isBrushHolding[ply] = nil
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = nil
		duckUntilGround[ply] = nil
		vrWallRunWants[ply] = nil
		wallRunStartTime[ply] = nil
		wallRunEntrySpeed[ply] = nil
		isSliding[ply]         = nil
		slideDir[ply]          = nil
		slideSpeed[ply]        = nil
		wantsSlide[ply]        = nil
		slideDirWanted[ply]    = nil
		wasAirLow[ply]         = nil
		slideJumpMomentum[ply] = nil
	end)

	hook.Add("PlayerFootstep", "vrmod_wallrun_no_footstep", function(ply)
		if vrWallRunWants[ply] then return true end
	end)

	return
end

if not CLIENT then return end

g_VR = g_VR or {}
vrmod = vrmod or {}

local cvBindMode = CreateClientConVar("vrmod_brushclimb_bind_mode", "0", true, false, "0=Grip+Trigger, 1=Grip, 2=Trigger", 0, 2)
local cvEnable = CreateClientConVar("vrmod_brushclimb_enable", "1", true, false, "Enable VRMod brush climbing", 0, 1)
local cvGrabDistance = CreateClientConVar("vrmod_brushclimb_grab_distance", "22", true, false, "Brush grab trace range", 4, 48)
local cvLaunchMult = CreateClientConVar("vrmod_brushclimb_launch_mult", "1.35", true, false, "Release launch multiplier", 0, 4)
local cvLaunchMin = CreateClientConVar("vrmod_brushclimb_launch_min", "120", true, false, "Minimum hand speed for launch", 0, 500)
local cvLaunchMax = CreateClientConVar("vrmod_brushclimb_launch_max", "650", true, false, "Maximum added launch speed", 0, 1500)
local cvUseSounds = CreateClientConVar("vrmod_brushclimb_sounds", "1", true, false, "Play climbing sounds", 0, 1)
local cvClimbSoundVolume = CreateClientConVar("vrmod_brushclimb_sound_volume", "0.8", true, false, "Climbing sound volume", 0, 1)
local cvDebug = CreateClientConVar("vrmod_brushclimb_debug", "0", true, false, "Debug draw for brush climbing", 0, 1)
local cvDebugText = CreateClientConVar("vrmod_brushclimb_debug_text", "1", true, false, "Debug text above hands", 0, 1)
local cvHandInset = CreateClientConVar("vrmod_brushclimb_hand_inset", "1.1", true, false, "Push held hand slightly into surface", 0, 4)
local cvWallPushDist = CreateClientConVar("vrmod_brushclimb_wall_push_dist", "2.0", true, false, "Push player body away from wall while holding", 0, 12)
local cvCameraCollision = CreateClientConVar("vrmod_brushclimb_camera_collision", "1", true, false, "Prevent camera clipping into brushes while climbing", 0, 1)
local cvPalmOffsetForward = CreateClientConVar("vrmod_brushclimb_palm_offset_forward", "3.30", true, false, "Temporary palm center forward offset", -8, 8)
local cvPalmOffsetRight = CreateClientConVar("vrmod_brushclimb_palm_offset_right", "-2.32", true, false, "Temporary palm center right offset", -8, 8)
local cvPalmOffsetUp = CreateClientConVar("vrmod_brushclimb_palm_offset_up", "-0.05", true, false, "Temporary palm center up offset", -8, 8)
local cvPalmOffsetForwardRight = CreateClientConVar("vrmod_brushclimb_palm_offset_forward_right", "3.30", true, false, "Right hand palm center forward offset", -8, 8)
local cvPalmOffsetRightRight = CreateClientConVar("vrmod_brushclimb_palm_offset_right_right", "2.32", true, false, "Right hand palm center right offset", -8, 8)
local cvPalmOffsetUpRight = CreateClientConVar("vrmod_brushclimb_palm_offset_up_right", "0.05", true, false, "Right hand palm center up offset", -8, 8)
local cvWallrunHandRange = CreateClientConVar("vrmod_wallrun_hand_range", "20", true, false, "How close hand must be to wall for wall run", 4, 48)
local cvWallrunBindMode = CreateClientConVar("vrmod_wallrun_bind_mode", "1", true, false, "0=Grip, 1=Trigger", 0, 1)
local cvWallrunCooldown = CreateClientConVar("vrmod_wallrun_cooldown", "0.5", true, false, "Seconds before wall run can trigger again", 0, 5)
local cvWallrunAirRegen = CreateClientConVar("vrmod_wallrun_air_regen", "2.0", true, false, "Cooldown seconds recovered per second while airborne (0 = no air regen)", 0, 10)
local cvWallrunLookMaxDot = CreateClientConVar("vrmod_wallrun_look_max_dot", "0.45", true, false, "Max abs(dot(view, wall normal)) allowed for wallrun (lower = stricter along-wall look)", 0, 1)
local cvWallrunSoundEnable = CreateClientConVar("vrmod_wallrun_sounds", "1", true, false, "Play wallrun step sounds", 0, 1)
local cvWallrunSoundVolume = CreateClientConVar("vrmod_wallrun_sound_volume", "0.75", true, false, "Wallrun sound volume", 0, 1)
local cvWallrunSoundInterval = CreateClientConVar("vrmod_wallrun_sound_interval", "0.18", true, false, "Seconds between wallrun step sounds", 0.05, 1)
local cvAllowWalls      = CreateClientConVar("vrmod_brushclimb_allow_walls",      "1", true, false, "Allow grabbing wall surfaces (server must also permit)", 0, 1)
local cvAllowCeilings   = CreateClientConVar("vrmod_brushclimb_allow_ceilings",   "1", true, false, "Allow grabbing ceiling surfaces (server must also permit)", 0, 1)
local cvAllowLedges     = CreateClientConVar("vrmod_brushclimb_allow_ledges",     "1", true, false, "Allow grabbing ledge surfaces (server must also permit)", 0, 1)
local cvAllowFloor      = CreateClientConVar("vrmod_brushclimb_allow_floors",     "1", true, false, "Allow grabbing floor surfaces (server must also permit)", 0, 1)
local cvAllowDoors      = CreateClientConVar("vrmod_brushclimb_allow_doors",      "0", true, false, "Allow grabbing door entities (server must also permit)", 0, 1)
local cvAllowPushable   = CreateClientConVar("vrmod_brushclimb_allow_pushable",   "0", true, false, "Allow grabbing func_pushable entities (server must also permit)", 0, 1)
local cvAllowToggleable = CreateClientConVar("vrmod_brushclimb_allow_toggleable", "0", true, false, "Allow grabbing toggleable brush entities (server must also permit)", 0, 1)
local cvAllowLadders    = CreateClientConVar("vrmod_brushclimb_allow_ladders",    "1", true, false, "Allow grabbing ladder surfaces (always bypasses surface type filters)", 0, 1)
local cvSlideEnable     = CreateClientConVar("vrmod_slide_enable",      "1",  true, false, "Enable VRMod sliding", 0, 1)
local cvSlideHeadHeight = CreateClientConVar("vrmod_slide_head_height", "40", true, false, "HMD height above origin (units) at which you count as low enough to slide", 4, 120)
local cvSlideSoundEnable = CreateClientConVar("vrmod_slide_sounds", "1", true, false, "Play slide sounds", 0, 1)
local cvSlideSoundVolume = CreateClientConVar("vrmod_slide_sound_volume", "0.75", true, false, "Slide sound volume", 0, 1)
local zeroVec = Vector(0, 0, 0)
local zeroAng = Angle(0, 0, 0)

local HAND_LEFT = 1
local HAND_RIGHT = 2

local hands = {
	[HAND_LEFT] = {
		handId = HAND_LEFT,
		poseName = "pose_lefthand",
		pickupAction = "boolean_left_pickup",
		setPoseName = "SetLeftHandPose",
		triggerBooleans = {"boolean_reload", "boolean_left_primaryfire", "boolean_left_secondaryfire"},
		triggerAnalogs = {"vector1_left_primaryfire"},
		grabAngle = Angle(0, 0, 90),
	},
	[HAND_RIGHT] = {
		handId = HAND_RIGHT,
		poseName = "pose_righthand",
		pickupAction = "boolean_right_pickup",
		setPoseName = "SetRightHandPose",
		triggerBooleans = {"boolean_primaryfire", "boolean_secondaryfire"},
		triggerAnalogs = {"vector1_primaryfire"},
		grabAngle = Angle(0, 0, -90),
	},
}

local state = {
	running = false,
	locomotionStopped = false,
	lastSyncTime = 0,
	lastSyncPos = nil,
	lastUpdateFrame = -1,
	attachLerpTime = 0.09,
	hands = {
		[HAND_LEFT] = {want = false, holding = false, anchorPos = nil, anchorNormal = nil, gripDown = false, triggerDown = false, debugTraces = nil, debugBest = nil, nearWall = false, secondaryGrabBlend = false},
		[HAND_RIGHT] = {want = false, holding = false, anchorPos = nil, anchorNormal = nil, gripDown = false, triggerDown = false, debugTraces = nil, debugBest = nil, nearWall = false, secondaryGrabBlend = false},
	},
	wallRunActive = false,
	wallRunCooldownUntil = 0,
	wallRunHand = nil,
	wallRunWasOnGround = true,  -- tracks ground state for landing detection
	nextWallRunSoundAt = 0,
	slideActive = false,
}

local liveInput = {}

local climbSounds = {
	"vrclimb/handstep1.wav",
	"vrclimb/handstep2.wav",
	"vrclimb/handstep3.wav",
	"vrclimb/handstep4.wav",
}

local releaseSounds = {
	"vrclimb/release1.wav",
	"vrclimb/release2.wav",
	"vrclimb/release3.wav",
	"vrclimb/release4.wav",
	"vrclimb/release5.wav",
}

local wallrunSounds = {
	"vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast1.wav",
	"vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast2.wav",
	"vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast3.wav",
	"vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast5.wav",
}

local slideStartSounds = {
	"vrclimb/slide/concrete/me_concrete_slide1.wav",
	"vrclimb/slide/concrete/me_concrete_slide2.wav",
	"vrclimb/slide/concrete/me_concrete_slide3.wav",
	"vrclimb/slide/concrete/me_concrete_slide4.wav",
}
local slideLoopSoundPath = "vrclimb/slide/me_footstep_concreteslideloop.wav"
local slideLoopPatch = nil

local traceDirsLocal = {
	Vector(1, 0, 0), Vector(-1, 0, 0),
	Vector(0, 1, 0), Vector(0, -1, 0),
	Vector(0, 0, 1), Vector(0, 0, -1),
	Vector(1, 1, 0), Vector(1, -1, 0), Vector(-1, 1, 0), Vector(-1, -1, 0),
	Vector(1, 0, 1), Vector(1, 0, -1), Vector(-1, 0, 1), Vector(-1, 0, -1),
	Vector(0, 1, 1), Vector(0, 1, -1), Vector(0, -1, 1), Vector(0, -1, -1),
	Vector(1, 1, 1), Vector(1, 1, -1), Vector(1, -1, 1), Vector(1, -1, -1),
	Vector(-1, 1, 1), Vector(-1, 1, -1), Vector(-1, -1, 1), Vector(-1, -1, -1),
}

local clientNudgeDirs = {
	Vector(0, 0, 1), Vector(0, 0, -1),
	Vector(1, 0, 0), Vector(-1, 0, 0),
	Vector(0, 1, 0), Vector(0, -1, 0),
	Vector(1, 1, 0):GetNormalized(), Vector(1, -1, 0):GetNormalized(),
	Vector(-1, 1, 0):GetNormalized(), Vector(-1, -1, 0):GetNormalized(),
}

local function CanClientFitAt(ply, pos, useDuck)
	if not IsValid(ply) then return false end
	local mins, maxs
	if useDuck then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end
	local tr = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = mins,
		maxs = maxs,
		mask = MASK_PLAYERSOLID,
		filter = ply,
	})
	return not (tr.StartSolid or tr.AllSolid)
end

local function ResolveClientFeetPos(desiredPos, fallbackPos)
	local ply = LocalPlayer()
	if not IsValid(ply) then return desiredPos end
	if CanClientFitAt(ply, desiredPos, true) or CanClientFitAt(ply, desiredPos, false) then
		return desiredPos
	end

	for radius = 2, 12, 2 do
		for i = 1, #clientNudgeDirs do
			local testPos = desiredPos + clientNudgeDirs[i] * radius
			if CanClientFitAt(ply, testPos, true) or CanClientFitAt(ply, testPos, false) then
				return testPos
			end
		end
	end

	if fallbackPos and (CanClientFitAt(ply, fallbackPos, true) or CanClientFitAt(ply, fallbackPos, false)) then
		return fallbackPos
	end
	return desiredPos
end

local function ResolveCameraOriginCollision(targetOrigin)
	if not cvCameraCollision:GetBool() then return targetOrigin end
	if not g_VR or not g_VR.tracking then return targetOrigin end
	local hmd = g_VR.tracking.hmd
	local ply = LocalPlayer()
	if not hmd or not IsValid(ply) then return targetOrigin end

	local localHmd = hmd.pos - g_VR.origin
	local currentHmd = hmd.pos
	local targetHmd = targetOrigin + localHmd
	local radius = 4
	local padding = 1.5
	local tr = util.TraceHull({
		start = currentHmd,
		endpos = targetHmd,
		mins = Vector(-radius, -radius, -radius),
		maxs = Vector(radius, radius, radius),
		mask = MASK_SOLID,
		filter = ply,
	})
	if tr.StartSolid or tr.AllSolid then
		return g_VR.origin
	end
	if tr.Hit then
		local safeHmd = tr.HitPos + tr.HitNormal * (radius + padding)
		return safeHmd - localHmd
	end
	return targetOrigin
end

local function GetServerConVarBool(name, fallback)
	local cv = GetConVar(name)
	if not cv then return fallback end
	return cv:GetBool()
end

local function GetServerConVarFloat(name, fallback)
	local cv = GetConVar(name)
	if not cv then return fallback end
	return cv:GetFloat()
end

local function IsClimbableHit(trace)
	if not trace or not trace.Hit then return false end
	if trace.HitWorld then return true end
	local ent = trace.Entity
	if not IsValid(ent) then return false end

	if ent:GetSolid() == SOLID_NONE then return false end
	local cls = ent:GetClass() or ""

	-- Doors: server must permit AND client must permit
	local isDoor = cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating"
	if isDoor then
		return GetServerConVarBool("sv_vrmod_brushclimb_allow_doors", false) and cvAllowDoors:GetBool()
	end

	-- func_pushable: server must permit AND client must permit
	if cls == "func_pushable" then
		return GetServerConVarBool("sv_vrmod_brushclimb_allow_pushable", false) and cvAllowPushable:GetBool()
	end

	-- Toggleable brushes: server must permit AND client must permit
	local isToggleable = cls == "func_button" or cls == "func_rot_button"
		or cls == "momentary_rot_button" or cls == "momentary_door"
	if isToggleable then
		return GetServerConVarBool("sv_vrmod_brushclimb_allow_toggleable", false) and cvAllowToggleable:GetBool()
	end

	-- Static props are safe for grabbing.
	if cls == "prop_static" then
		return true
	end
	-- Dynamic props are allowed only when effectively static.
	if cls == "prop_dynamic" then
		return ent:GetMoveType() == MOVETYPE_NONE
	end
	-- Physics props stay blocked (moving networked bodies desync badly).
	if cls == "prop_physics" then
		return false
	end

	if string.StartWith(cls, "func_") then return true end

	local model = ent:GetModel()
	if isstring(model) and string.sub(model, 1, 1) == "*" then return true end

	if ent:GetMoveType() == MOVETYPE_NONE then
		return true
	end

	return false
end

local function IsLadderSurface(trace)
	if not trace or not trace.Hit then return false end
	if IsValid(trace.Entity) then
		local cls = string.lower(trace.Entity:GetClass() or "")
		if cls == "func_useableladder" or cls == "func_ladder" or cls == "func_climbable" then
			return true
		end
	end
	local tex = trace.HitTexture and string.lower(trace.HitTexture) or ""
	if tex ~= "" and string.find(tex, "ladder", 1, true) then
		return true
	end
	local samplePos = trace.HitPos + trace.HitNormal * 2
	return bit.band(util.PointContents(samplePos), CONTENTS_LADDER) ~= 0
end

-- Returns "floor", "ledge", "wall", or "ceiling" based on the surface normal.
-- Thresholds read from replicated server convars so clients stay in sync.
local function GetSurfaceType(normal)
	if not normal then return "wall" end
	local z = normal.z
	local floorMin  = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_floor_normal_min", 0.85),  0,  1)
	local ledgeMin  = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_ledge_normal_min", 0.55),  0,  1)
	local ceilMax   = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_ceil_normal_max",  -0.55), -1, 0)
	if z >= floorMin  then return "floor"   end
	if z >= ledgeMin  then return "ledge"   end
	if z <= ceilMax   then return "ceiling" end
	return "wall"
end

local function GetPalmOffsetForHand(handId)
	if handId == HAND_RIGHT then
		return Vector(
			cvPalmOffsetForwardRight:GetFloat(),
			cvPalmOffsetRightRight:GetFloat(),
			cvPalmOffsetUpRight:GetFloat()
		)
	end
	return Vector(
		cvPalmOffsetForward:GetFloat(),
		cvPalmOffsetRight:GetFloat(),
		cvPalmOffsetUp:GetFloat()
	)
end

local function GetHandCenterPos(handPose, handId)
	local offset = GetPalmOffsetForHand(handId)
	return LocalToWorld(offset, zeroAng, handPose.pos, handPose.ang)
end

local function PickSound(list, volume)
	if not cvUseSounds:GetBool() then return end
	if #list == 0 then return end
	local snd = list[math.random(1, #list)]
	local vol = math.Clamp(volume or cvClimbSoundVolume:GetFloat(), 0, 1)
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply:EmitSound(snd, 75, math.random(96, 104), vol, CHAN_AUTO)
	else
		surface.PlaySound(snd)
	end
end

local function MaybePlayWallRunStep(forceNow)
	if not (cvUseSounds:GetBool() and cvWallrunSoundEnable:GetBool()) then return end
	local now = CurTime()
	if not forceNow and now < (state.nextWallRunSoundAt or 0) then return end
	PickSound(wallrunSounds, cvWallrunSoundVolume:GetFloat())
	state.nextWallRunSoundAt = now + cvWallrunSoundInterval:GetFloat()
end

local function StopSlideLoopSound()
	if slideLoopPatch then
		slideLoopPatch:Stop()
		slideLoopPatch = nil
	end
end

local function EnsureSlideLoopSound()
	if not (cvUseSounds:GetBool() and cvSlideSoundEnable:GetBool()) then
		StopSlideLoopSound()
		return
	end
	local ply = LocalPlayer()
	if not IsValid(ply) then
		StopSlideLoopSound()
		return
	end
	if not slideLoopPatch then
		slideLoopPatch = CreateSound(ply, slideLoopSoundPath)
	end
	if not slideLoopPatch then return end
	if not slideLoopPatch:IsPlaying() then
		slideLoopPatch:PlayEx(cvSlideSoundVolume:GetFloat(), 100)
	else
		slideLoopPatch:ChangeVolume(cvSlideSoundVolume:GetFloat(), 0)
	end
end

local function IsLookingAlongWall(normal)
	local ply = LocalPlayer()
	if not IsValid(ply) or not normal then return false end
	local view = ply:EyeAngles():Forward()
	local viewFlat = Vector(view.x, view.y, 0)
	local wallFlat = Vector(normal.x, normal.y, 0)
	if viewFlat:LengthSqr() < 0.0001 or wallFlat:LengthSqr() < 0.0001 then return false end
	viewFlat:Normalize()
	wallFlat:Normalize()
	local maxDot = math.Clamp(cvWallrunLookMaxDot:GetFloat(), 0, 1)
	return math.abs(viewFlat:Dot(wallFlat)) <= maxDot
end

local function GetTriggerDown(handCfg)
	local input = g_VR.input or {}
	local boolKeys = handCfg.triggerBooleans or {}
	local hasBool = false
	for i = 1, #boolKeys do
		local val = liveInput[boolKeys[i]]
		if val == nil then
			val = input[boolKeys[i]]
		end
		if val ~= nil then
			hasBool = true
			if val then
				return true
			end
		end
	end
	if hasBool then
		return false
	end

	local analogKeys = handCfg.triggerAnalogs or {}
	local maxAnalog = nil
	for i = 1, #analogKeys do
		local val = input[analogKeys[i]]
		if val ~= nil then
			maxAnalog = math.max(maxAnalog or 0, val)
		end
	end
	if maxAnalog ~= nil then
		return maxAnalog > 0.6
	end

	return input[handCfg.pickupAction] or false
end

local function GetGripDown(handCfg)
	local input = g_VR.input or {}
	local val = liveInput[handCfg.pickupAction]
	if val ~= nil then
		return val
	end
	return input[handCfg.pickupAction] or false
end

local function WantsGrab(handId)
	local handCfg = hands[handId]
	local gripDown = GetGripDown(handCfg)
	local triggerDown = GetTriggerDown(handCfg)
	local mode = cvBindMode:GetInt()

	if mode == 1 then
		return gripDown
	elseif mode == 2 then
		return triggerDown
	end

	return gripDown and triggerDown
end

local function FindGrabSurface(handPose, handId)
	local bestTrace = nil
	local bestDist = math.huge
	local range = cvGrabDistance:GetFloat()
	local startPos = GetHandCenterPos(handPose, handId)
	-- Surface type permissions: both server AND client must allow
	local svWalls    = GetServerConVarBool("sv_vrmod_brushclimb_allow_walls",    true)
	local svCeilings = GetServerConVarBool("sv_vrmod_brushclimb_allow_ceilings", true)
	local svLedges   = GetServerConVarBool("sv_vrmod_brushclimb_allow_ledges",   true)
	local svFloors   = GetServerConVarBool("sv_vrmod_brushclimb_allow_floors",   true)
	local debugTraces = cvDebug:GetBool() and {} or nil
	for i = 1, #traceDirsLocal do
		local dir = LocalToWorld(traceDirsLocal[i]:GetNormalized(), zeroAng, zeroVec, handPose.ang)
		local trace = util.TraceLine({
			start = startPos,
			endpos = startPos + dir * range,
			mask = MASK_SOLID,
			filter = LocalPlayer(),
		})
		-- Ladders (func_ladder, func_useableladder, func_climbable, CONTENTS_LADDER) always
		-- bypass surface-type filters and entity filters — they are always climbable unless
		-- the client explicitly opts out with allow_ladders = 0.
		local isLadder = IsLadderSurface(trace)
		local valid
		if isLadder then
			valid = cvAllowLadders:GetBool()
		else
			-- Surface type filter (server ceiling AND client preference)
			local surfType = GetSurfaceType(trace.HitNormal)
			local surfaceAllowed
			if surfType == "floor" then
				surfaceAllowed = svFloors and cvAllowFloor:GetBool()
			elseif surfType == "ledge" then
				surfaceAllowed = svLedges and cvAllowLedges:GetBool()
			elseif surfType == "ceiling" then
				surfaceAllowed = svCeilings and cvAllowCeilings:GetBool()
			else -- wall
				surfaceAllowed = svWalls and cvAllowWalls:GetBool()
			end
			valid = IsClimbableHit(trace) and surfaceAllowed
		end
		if debugTraces then
			debugTraces[#debugTraces + 1] = {
				start = startPos,
				stop = startPos + dir * range,
				hit = trace.Hit,
				hitPos = trace.HitPos,
				valid = valid,
			}
		end
		if valid then
			local dist = startPos:DistToSqr(trace.HitPos)
			if dist < bestDist then
				bestDist = dist
				bestTrace = trace
			end
		end
	end
	return bestTrace, debugTraces
end

local function AnyHandHolding()
	return state.hands[HAND_LEFT].holding or state.hands[HAND_RIGHT].holding
end

local function SyncServerPos(pos, holding, force)
	if not IsValid(LocalPlayer()) then return end
	local now = CurTime()
	if not force then
		local minInterval = 0.05
		if now - state.lastSyncTime < minInterval then return end
		if state.lastSyncPos and state.lastSyncPos:DistToSqr(pos) < 4 then return end
	end

	state.lastSyncTime = now
	state.lastSyncPos = Vector(pos.x, pos.y, pos.z)
	net.Start("vrmod_brush_climb_sync")
	net.WriteVector(pos)
	net.WriteBool(holding)
	net.SendToServer()
end

local function UpdateLocomotionState()
	if AnyHandHolding() then
		if not state.locomotionStopped and vrmod.StopLocomotion then
			state.locomotionStopped = true
			vrmod.StopLocomotion()
		end
	elseif state.locomotionStopped then
		state.locomotionStopped = false
		if vrmod.StartLocomotion then
			vrmod.StartLocomotion()
		end
		if g_VR and g_VR.tracking and g_VR.tracking.hmd then
			local hmd = g_VR.tracking.hmd
			local releasePos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
			releasePos.z = g_VR.origin.z
			releasePos = ResolveClientFeetPos(releasePos, LocalPlayer():GetPos())
			SyncServerPos(releasePos, false, true)
		end
	end
end

local function ReleaseHand(handId, doLaunch)
	local handState = state.hands[handId]
	if not handState.holding then return end

	handState.holding = false
	handState.anchorPos = nil
	handState.anchorNormal = nil
	handState.anchorStartPos = nil
	handState.originAtGrab = nil
	handState.localHandAtGrab = nil
	handState.grabStartTime = nil
	handState.frozenHandAng = nil

	local handCfg = hands[handId]
	local pose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
	local handVel = pose and pose.vel or Vector()
	local launch = -handVel * cvLaunchMult:GetFloat()
	local minSpeed = cvLaunchMin:GetFloat()
	local maxSpeed = cvLaunchMax:GetFloat()
	local fullyReleased = not AnyHandHolding()

	local speed = launch:Length()
	local didLaunch = false
	if doLaunch and fullyReleased and speed > minSpeed then
		if speed > maxSpeed and speed > 0 then
			launch = launch:GetNormalized() * maxSpeed
		end
		net.Start("vrmod_brush_climb_launch")
		net.WriteVector(launch)
		net.SendToServer()
		didLaunch = true
	end

	if fullyReleased and didLaunch then
		PickSound(releaseSounds)
	end
end

local function GrabHand(handId)
	local handCfg = hands[handId]
	local pose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
	if not pose then return end

	local trace, debugTraces = FindGrabSurface(pose, handId)
	local handState = state.hands[handId]
	handState.debugTraces = debugTraces
	handState.debugBest = trace and trace.HitPos or nil
	if not trace then return end

	local inset = math.max(0, cvHandInset:GetFloat())
	local anchorPos = trace.HitPos - trace.HitNormal * inset
	local hadOtherHandHolding = false
	for otherHandId, otherState in pairs(state.hands) do
		if otherHandId ~= handId and otherState.holding then
			hadOtherHandHolding = true
			break
		end
	end

	handState.holding = true
	handState.anchorPos = anchorPos
	handState.anchorNormal = trace.HitNormal
	handState.anchorStartPos = GetHandCenterPos(pose, handId)
	handState.grabStartTime = CurTime()
	handState.frozenHandAng = Angle(pose.ang.pitch, pose.ang.yaw, pose.ang.roll)
	handState.secondaryGrabBlend = hadOtherHandHolding

	-- Smoothly pull from the grabbed hand pose to the wall anchor to avoid sudden snaps.
	handState.originAtGrab = Vector(g_VR.origin.x, g_VR.origin.y, g_VR.origin.z)
	handState.localHandAtGrab = handState.anchorStartPos - g_VR.origin

	PickSound(climbSounds)
end

local function UpdateHeldMovement()
	local desiredOrigin = Vector(0, 0, 0)
	local weightSum = 0
	local pushNormal = Vector(0, 0, 0)
	local pushCount = 0

	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		if handState.holding and handState.anchorPos then
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then
				local handCenterNow = GetHandCenterPos(pose, handId)
				local localHandNow = handCenterNow - g_VR.origin
				local anchorPos = handState.anchorPos
				local blendT = 1
				if handState.grabStartTime and handState.anchorStartPos then
					blendT = math.Clamp((CurTime() - handState.grabStartTime) / state.attachLerpTime, 0, 1)
					anchorPos = LerpVector(blendT, handState.anchorStartPos, handState.anchorPos)
				end
				local handWeight = 1
				if handState.secondaryGrabBlend then
					handWeight = math.max(0.001, blendT)
					if blendT >= 1 then
						handState.secondaryGrabBlend = false
					end
				end
				desiredOrigin = desiredOrigin + (anchorPos - localHandNow) * handWeight
				weightSum = weightSum + handWeight
				if handState.anchorNormal then
					pushNormal = pushNormal + handState.anchorNormal
					pushCount = pushCount + 1
				end
			end
		end
	end

	if weightSum <= 0 then return end

	local targetOrigin = desiredOrigin / weightSum
	if pushCount > 0 then
		local avgNormal = pushNormal / pushCount
		local lateral = Vector(avgNormal.x, avgNormal.y, 0)
		local lateralLenSqr = lateral:LengthSqr()
		local pushDist = math.max(0, cvWallPushDist:GetFloat())
		if lateralLenSqr > 0.0001 and pushDist > 0 then
			targetOrigin = targetOrigin + lateral:GetNormalized() * pushDist
		end
	end
	targetOrigin = ResolveCameraOriginCollision(targetOrigin)
	g_VR.origin = targetOrigin

	local hmd = g_VR.tracking.hmd
	if hmd and IsValid(LocalPlayer()) then
		local feetPos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
		feetPos.z = g_VR.origin.z
		local safeFeetPos = ResolveClientFeetPos(feetPos, LocalPlayer():GetPos())
		LocalPlayer():SetPos(safeFeetPos)
		SyncServerPos(safeFeetPos, true, false)
	end
end

local function UpdateHandPoses()
	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		if handState.holding and handState.anchorPos then
			local setPose = vrmod and vrmod[handCfg.setPoseName]
			if setPose then
				local targetPos = handState.anchorPos
				if handState.grabStartTime and handState.anchorStartPos then
					local t = math.Clamp((CurTime() - handState.grabStartTime) / state.attachLerpTime, 0, 1)
					targetPos = LerpVector(t, handState.anchorStartPos, handState.anchorPos)
				end
				local trackingPose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
				local frozenAng = handState.frozenHandAng or (trackingPose and trackingPose.ang) or zeroAng
				local palmOffset = GetPalmOffsetForHand(handId)
				local handRootPos = LocalToWorld(-palmOffset, zeroAng, targetPos, frozenAng)
				setPose(handRootPos, frozenAng)
			end
		end
	end
end

local function ResetState()
	for handId, handState in pairs(state.hands) do
		handState.want = false
		handState.gripDown = false
		handState.triggerDown = false
		handState.debugTraces = nil
		handState.debugBest = nil
		handState.anchorStartPos = nil
		handState.originAtGrab = nil
		handState.localHandAtGrab = nil
		handState.grabStartTime = nil
		handState.frozenHandAng = nil
		handState.nearWall = false
		handState.secondaryGrabBlend = false
		if handState.holding then
			ReleaseHand(handId, false)
		end
	end
	if state.wallRunActive then
		state.wallRunActive = false
		state.wallRunHand = nil
		state.wallRunCooldownUntil = CurTime() + cvWallrunCooldown:GetFloat()
		state.nextWallRunSoundAt = 0
		net.Start("vrmod_wallrun_sync")
		net.WriteBool(false)
		net.WriteVector(zeroVec)
		net.SendToServer()
	end
	if state.slideActive then
		state.slideActive = false
		net.Start("vrmod_slide_sync")
		net.WriteBool(false)
		net.WriteVector(zeroVec)
		net.SendToServer()
	end
	StopSlideLoopSound()
	UpdateLocomotionState()
end

-- ============================================================
-- Wall Run: hand-near-wall detection (client) → server physics
-- ============================================================

local function IsHandNearWall(handPose, handId)
	local range = cvWallrunHandRange:GetFloat()
	local startPos = GetHandCenterPos(handPose, handId)
	for i = 1, #traceDirsLocal do
		local dir = LocalToWorld(traceDirsLocal[i]:GetNormalized(), zeroAng, zeroVec, handPose.ang)
		local trace = util.TraceLine({
			start = startPos,
			endpos = startPos + dir * range,
			mask = MASK_SOLID,
			filter = LocalPlayer(),
		})
		if trace.Hit and math.abs(trace.HitNormal.z) < 0.3 then
			if trace.HitWorld or (IsValid(trace.Entity) and trace.Entity:GetSolid() ~= SOLID_NONE) then
				return true, trace.HitNormal
			end
		end
	end
	return false, nil
end

local function WallRunInputHeld()
	local mode = cvWallrunBindMode:GetInt()
	for handId, handCfg in pairs(hands) do
		if mode == 0 then
			if GetGripDown(handCfg) then return true end
		else
			if GetTriggerDown(handCfg) then return true end
		end
	end
	return false
end

local function StopWallRunSignal()
	if not state.wallRunActive then return end
	state.wallRunActive = false
	state.wallRunCooldownUntil = CurTime() + cvWallrunCooldown:GetFloat()
	state.nextWallRunSoundAt = 0

	-- Check off-hand velocity for a push launch (same as climb launch)
	local wallHand = state.wallRunHand
	state.wallRunHand = nil
	if wallHand and g_VR and g_VR.tracking then
		local otherHandId = wallHand == HAND_LEFT and HAND_RIGHT or HAND_LEFT
		local otherCfg = hands[otherHandId]
		local otherPose = g_VR.tracking[otherCfg.poseName]
		if otherPose and otherPose.vel then
			local launch = -otherPose.vel * cvLaunchMult:GetFloat()
			local speed = launch:Length()
			local minSpeed = cvLaunchMin:GetFloat()
			local maxSpeed = cvLaunchMax:GetFloat()
			if speed > minSpeed then
				if speed > maxSpeed then
					launch = launch:GetNormalized() * maxSpeed
				end
				net.Start("vrmod_brush_climb_launch")
				net.WriteVector(launch)
				net.SendToServer()
				PickSound(releaseSounds)
			end
		end
	end

	net.Start("vrmod_wallrun_sync")
	net.WriteBool(false)
	net.WriteVector(zeroVec)
	net.SendToServer()
end

local function UpdateWallRun()
	if not g_VR or not g_VR.tracking then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local onGround = ply:IsOnGround()

	-- Landing instantly restores the wall run cooldown.
	if onGround and not state.wallRunWasOnGround then
		state.wallRunCooldownUntil = 0
	end

	-- While airborne and not actively wall running, regenerate cooldown faster.
	if not onGround and not state.wallRunActive then
		local regen = cvWallrunAirRegen:GetFloat()
		if regen > 0 and state.wallRunCooldownUntil > CurTime() then
			state.wallRunCooldownUntil = state.wallRunCooldownUntil - regen * FrameTime()
		end
	end

	state.wallRunWasOnGround = onGround

	-- Don't wall run while climbing
	if AnyHandHolding() then
		StopWallRunSignal()
		for _, hs in pairs(state.hands) do hs.nearWall = false end
		return
	end

	-- Must be holding the bound button
	if not WallRunInputHeld() then
		StopWallRunSignal()
		for _, hs in pairs(state.hands) do hs.nearWall = false end
		return
	end

	-- Check each hand for wall proximity
	local found = false
	local hitNormal = nil
	local foundHand = nil
	for handId, handCfg in pairs(hands) do
		local pose = g_VR.tracking[handCfg.poseName]
		if pose then
			local near, normal = IsHandNearWall(pose, handId)
			state.hands[handId].nearWall = near
			if near and IsLookingAlongWall(normal) and not found then
				found = true
				hitNormal = normal
				foundHand = handId
			end
		else
			state.hands[handId].nearWall = false
		end
	end

	if found and not state.wallRunActive then
		if CurTime() < state.wallRunCooldownUntil then return end
		state.wallRunActive = true
		state.wallRunHand = foundHand
		state.nextWallRunSoundAt = 0
		net.Start("vrmod_wallrun_sync")
		net.WriteBool(true)
		net.WriteVector(hitNormal)
		net.SendToServer()
		MaybePlayWallRunStep(true)
	elseif found and state.wallRunActive then
		state.wallRunHand = foundHand
		MaybePlayWallRunStep(false)
	elseif not found and state.wallRunActive then
		StopWallRunSignal()
	end
end

local function UpdateSlide()
	if not cvSlideEnable:GetBool() then
		if state.slideActive then
			state.slideActive = false
			net.Start("vrmod_slide_sync")
			net.WriteBool(false)
			net.WriteVector(zeroVec)
			net.SendToServer()
		end
		StopSlideLoopSound()
		return
	end
	if not g_VR or not g_VR.active or not g_VR.tracking then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if AnyHandHolding() or state.wallRunActive then
		if state.slideActive then
			state.slideActive = false
			net.Start("vrmod_slide_sync")
			net.WriteBool(false)
			net.WriteVector(zeroVec)
			net.SendToServer()
		end
		StopSlideLoopSound()
		return
	end
	local hmd = g_VR.tracking.hmd
	if not hmd then return end
	local vel = ply:GetVelocity()
	local flatSpeed = Vector(vel.x, vel.y, 0):Length()
	local minSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_min_speed", 150)
	local canPlaySlideSound = ply:IsOnGround() and flatSpeed >= minSlideSpeed
	local isLow = (hmd.pos.z - g_VR.origin.z) <= cvSlideHeadHeight:GetFloat()
	if isLow == state.slideActive then
		if isLow and canPlaySlideSound then
			if not (slideLoopPatch and slideLoopPatch:IsPlaying()) then
				PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
			end
			EnsureSlideLoopSound()
		else
			StopSlideLoopSound()
		end
		return
	end
	state.slideActive = isLow
	if isLow and canPlaySlideSound then
		PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
		EnsureSlideLoopSound()
	else
		StopSlideLoopSound()
	end
	local flatDir = Vector(vel.x, vel.y, 0)
	if flatDir:LengthSqr() > 0.001 then flatDir:Normalize() end
	net.Start("vrmod_slide_sync")
	net.WriteBool(isLow)
	net.WriteVector(flatDir)
	net.SendToServer()
end

local function UpdateClimbing(renderPass)
	if not state.running then return end
	if not g_VR or not g_VR.active or not g_VR.tracking then return end
	if renderPass == "right" then return end
	local frameNum = FrameNumber()
	if state.lastUpdateFrame == frameNum then return end
	state.lastUpdateFrame = frameNum

	for handId, handState in pairs(state.hands) do
		local handCfg = hands[handId]
		handState.gripDown = GetGripDown(handCfg)
		handState.triggerDown = GetTriggerDown(handCfg)

		if cvDebug:GetBool() and not handState.holding then
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then
				local trace, debugTraces = FindGrabSurface(pose, handId)
				handState.debugTraces = debugTraces
				handState.debugBest = trace and trace.HitPos or nil
			end
		end

		local wantsGrab = WantsGrab(handId)
		if wantsGrab and not handState.want then
			GrabHand(handId)
		elseif (not wantsGrab) and handState.want then
			ReleaseHand(handId, true)
		end
		handState.want = wantsGrab
	end

	UpdateLocomotionState()
	UpdateHeldMovement()
	UpdateHandPoses()
	UpdateWallRun()
	UpdateSlide()
end

local function DrawDebug()
	if not state.running then return end
	if not cvDebug:GetBool() then return end
	if not g_VR or not g_VR.active or not g_VR.tracking then return end

	render.SetColorMaterial()
	local range = cvGrabDistance:GetFloat()
	local half = Vector(range, range, range)

	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		local pose = g_VR.tracking[handCfg.poseName]
		if pose then
			local color = Color(255, 255, 255, 160)
			if handState.gripDown then color = Color(255, 220, 80, 180) end
			if handState.triggerDown then color = Color(255, 150, 40, 180) end
			if handState.want then color = Color(80, 255, 120, 200) end
			if handState.holding then color = Color(80, 180, 255, 220) end

			render.DrawWireframeBox(pose.pos, Angle(), -half, half, color, true)
			render.DrawWireframeSphere(pose.pos, range, 10, 10, color, true)

			if handState.debugTraces then
				for i = 1, #handState.debugTraces do
					local tr = handState.debugTraces[i]
					local lineColor = tr.valid and Color(0, 255, 0, 180) or Color(255, 0, 0, 90)
					render.DrawLine(tr.start, tr.stop, lineColor, true)
					if tr.hit then
						render.DrawWireframeSphere(tr.hitPos, 0.8, 4, 4, lineColor, true)
					end
				end
			end

			if handState.holding and handState.anchorPos then
				render.DrawWireframeSphere(handState.anchorPos, 1.4, 6, 6, Color(100, 220, 255, 220), true)
			elseif handState.debugBest then
				render.DrawWireframeSphere(handState.debugBest, 1.2, 6, 6, Color(120, 255, 120, 210), true)
			end

			if cvDebugText:GetBool() then
				local viewPos = g_VR.tracking.hmd and g_VR.tracking.hmd.pos or EyePos()
				local txtPos = pose.pos + Vector(0, 0, 4)
				local txtAng = (viewPos - txtPos):Angle()
				txtAng = Angle(0, txtAng.yaw + 90, 90)
				local wrTag    = state.wallRunActive and "WR:ON" or (handState.nearWall and "WR:NEAR" or "WR:--")
				local slideTag = state.slideActive and "SLD:ON" or "SLD:--"
				cam.Start3D2D(txtPos, txtAng, 0.03)
					draw.SimpleTextOutlined(
						string.format(
							"%s G:%d T:%d W:%d H:%d %s %s",
							handId == HAND_LEFT and "L" or "R",
							handState.gripDown and 1 or 0,
							handState.triggerDown and 1 or 0,
							handState.want and 1 or 0,
							handState.holding and 1 or 0,
							wrTag,
							slideTag
						),
						"DermaLarge",
						0,
						0,
						state.slideActive and Color(80, 200, 255, 235) or (state.wallRunActive and Color(255, 200, 50, 235) or Color(255, 255, 255, 235)),
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_CENTER,
						1,
						Color(0, 0, 0, 220)
					)
				cam.End3D2D()
			end
		end
	end
end

local function StopClimbing()
	if not state.running then return end
	state.running = false
	ResetState()
	StopSlideLoopSound()
	state.lastSyncPos = nil
	state.lastSyncTime = 0
	state.lastUpdateFrame = -1
	if g_VR and g_VR.tracking and g_VR.tracking.hmd then
		local hmd = g_VR.tracking.hmd
		local stopPos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
		stopPos.z = g_VR.origin.z
		stopPos = ResolveClientFeetPos(stopPos, LocalPlayer():GetPos())
		SyncServerPos(stopPos, false, true)
	end
	hook.Remove("VRMod_PreRender", "vrmod_brush_climbing")
	hook.Remove("VRMod_Input", "vrmod_brush_climbing_inputcache")
	hook.Remove("PostDrawTranslucentRenderables", "vrmod_brush_climbing_debug")
end

local function StartClimbing()
	if state.running then return end
	if not cvEnable:GetBool() then return end
	state.running = true
	state.lastSyncPos = nil
	state.lastSyncTime = 0
	state.lastUpdateFrame = -1
	liveInput = {}
	for k, v in pairs(g_VR.input or {}) do
		liveInput[k] = v
	end
	hook.Add("VRMod_PreRender", "vrmod_brush_climbing", UpdateClimbing)
	hook.Add("VRMod_Input", "vrmod_brush_climbing_inputcache", function(action, pressed)
		liveInput[action] = pressed
	end)
	hook.Add("PostDrawTranslucentRenderables", "vrmod_brush_climbing_debug", function(depth, sky)
		if depth or sky then return end
		DrawDebug()
	end)
end

hook.Add("VRMod_Start", "vrmod_brush_climbing_start", function(ply)
	if ply ~= LocalPlayer() then return end
	StartClimbing()
end)

hook.Add("VRMod_Exit", "vrmod_brush_climbing_exit", function(ply)
	if ply ~= LocalPlayer() then return end
	StopClimbing()
end)

cvars.AddChangeCallback("vrmod_brushclimb_enable", function(_, _, newValue)
	if tobool(newValue) then
		if g_VR and g_VR.active then
			StartClimbing()
		end
		return
	end

	StopClimbing()
end, "vrmod_brush_climbing_enable")

local function BuildTabClimbing(form)
	if not IsValid(form) then return end

	form:CheckBox("Enable VRModClimbing", "vrmod_brushclimb_enable")

	local bindPanel = vgui.Create("DPanel")
	bindPanel:SetSize(300, 30)
	bindPanel.Paint = function() end
	local label = vgui.Create("DLabel", bindPanel)
	label:SetSize(120, 30)
	label:SetPos(0, -3)
	label:SetText("Grab input mode:")
	label:SetColor(Color(0, 0, 0))
	local combo = vgui.Create("DComboBox", bindPanel)
	combo:Dock(TOP)
	combo:DockMargin(115, 0, 0, 5)
	combo:AddChoice("Grip + Trigger")
	combo:AddChoice("Grip only")
	combo:AddChoice("Trigger only")
	combo.OnSelect = function(_, index) cvBindMode:SetInt(index - 1) end
	combo.Think = function(self)
		local mode = cvBindMode:GetInt()
		if self._mode ~= mode then
			self._mode = mode
			self:ChooseOptionID(mode + 1)
		end
	end
	form:AddItem(bindPanel)

	form:ControlHelp("Physics")
	local tmp = form:NumSlider("Grab distance", "vrmod_brushclimb_grab_distance", 4, 48, 0)
	tmp:SetToolTip("How far from your hand a brush can be grabbed.")
	tmp = form:NumSlider("Launch multiplier", "vrmod_brushclimb_launch_mult", 0, 4, 2)
	tmp:SetToolTip("Scales launch force from opposite hand velocity.")
	tmp = form:NumSlider("Launch minimum speed", "vrmod_brushclimb_launch_min", 0, 500, 0)
	tmp:SetToolTip("No launch below this hand speed.")
	tmp = form:NumSlider("Launch max speed", "vrmod_brushclimb_launch_max", 0, 1500, 0)
	tmp:SetToolTip("Clamp for launch speed.")
	tmp = form:NumSlider("Hand surface inset", "vrmod_brushclimb_hand_inset", 0, 4, 1)
	tmp:SetToolTip("Push held hand slightly into surfaces for tighter contact.")
	tmp = form:NumSlider("Wall body push distance", "vrmod_brushclimb_wall_push_dist", 0, 12, 1)
	tmp:SetToolTip("Keeps your body slightly away from walls while holding.")
	tmp = form:CheckBox("Camera anti-clip while climbing", "vrmod_brushclimb_camera_collision")
	tmp:SetToolTip("Pushes camera away from brushes while you are holding a climb point.")

	form:ControlHelp("")
	form:ControlHelp("Palm Offsets")
	form:NumSlider("Left palm offset forward",  "vrmod_brushclimb_palm_offset_forward",       -8, 8, 2)
	form:NumSlider("Left palm offset right",    "vrmod_brushclimb_palm_offset_right",          -8, 8, 2)
	form:NumSlider("Left palm offset up",       "vrmod_brushclimb_palm_offset_up",             -8, 8, 2)
	form:NumSlider("Right palm offset forward", "vrmod_brushclimb_palm_offset_forward_right",  -8, 8, 2)
	form:NumSlider("Right palm offset right",   "vrmod_brushclimb_palm_offset_right_right",    -8, 8, 2)
	form:NumSlider("Right palm offset up",      "vrmod_brushclimb_palm_offset_up_right",       -8, 8, 2)

	form:ControlHelp("")
	form:ControlHelp("Surface Filters  (server may restrict further)")
	form:CheckBox("Allow grabbing walls",              "vrmod_brushclimb_allow_walls")
		:SetToolTip("Allow grabbing near-vertical surfaces.")
	form:CheckBox("Allow grabbing ceilings",           "vrmod_brushclimb_allow_ceilings")
		:SetToolTip("Allow grabbing downward-facing surfaces.")
	form:CheckBox("Allow grabbing ledges",             "vrmod_brushclimb_allow_ledges")
		:SetToolTip("Allow grabbing slanted upward surfaces between wall and floor.")
	form:CheckBox("Allow grabbing floors",             "vrmod_brushclimb_allow_floors")
		:SetToolTip("Allow grabbing nearly-flat upward surfaces (floors).")

	form:ControlHelp("")
	form:ControlHelp("Entity Filters  (server may restrict further)")
	form:CheckBox("Allow grabbing doors",              "vrmod_brushclimb_allow_doors")
		:SetToolTip("Allow func_door, func_door_rotating and prop_door_rotating to be grabbed.")
	form:CheckBox("Allow grabbing pushables",          "vrmod_brushclimb_allow_pushable")
		:SetToolTip("Allow func_pushable entities to be grabbed.")
	form:CheckBox("Allow grabbing toggleable brushes", "vrmod_brushclimb_allow_toggleable")
		:SetToolTip("Allow func_button, func_rot_button, momentary_rot_button and momentary_door to be grabbed.")
	form:CheckBox("Allow grabbing ladders",            "vrmod_brushclimb_allow_ladders")
		:SetToolTip("Allow grabbing ladder surfaces (func_ladder, func_climbable, CONTENTS_LADDER). Ladders always bypass surface-type filters when enabled.")

	form:ControlHelp("")
	form:ControlHelp("Debug")
	form:CheckBox("Play climbing sounds",           "vrmod_brushclimb_sounds")
	form:NumSlider("Climb sound volume",            "vrmod_brushclimb_sound_volume", 0, 1, 2)
	form:CheckBox("Debug draw (grab cube + traces)", "vrmod_brushclimb_debug")
	form:CheckBox("Debug text above hands",          "vrmod_brushclimb_debug_text")
end

local function BuildTabWallRun(form)
	if not IsValid(form) then return end

	local wrBindPanel = vgui.Create("DPanel")
	wrBindPanel:SetSize(300, 30)
	wrBindPanel.Paint = function() end
	local wrLabel = vgui.Create("DLabel", wrBindPanel)
	wrLabel:SetSize(120, 30)
	wrLabel:SetPos(0, -3)
	wrLabel:SetText("Wall run bind:")
	wrLabel:SetColor(Color(0, 0, 0))
	local wrCombo = vgui.Create("DComboBox", wrBindPanel)
	wrCombo:Dock(TOP)
	wrCombo:DockMargin(115, 0, 0, 5)
	wrCombo:AddChoice("Grip")
	wrCombo:AddChoice("Trigger")
	wrCombo.OnSelect = function(_, index) cvWallrunBindMode:SetInt(index - 1) end
	wrCombo.Think = function(self)
		local mode = cvWallrunBindMode:GetInt()
		if self._mode ~= mode then
			self._mode = mode
			self:ChooseOptionID(mode + 1)
		end
	end
	form:AddItem(wrBindPanel)

	local wr = form:NumSlider("Hand range", "vrmod_wallrun_hand_range", 4, 48, 0)
	wr:SetToolTip("How close your hand must be to a wall to trigger wall running.")
	wr = form:NumSlider("Cooldown", "vrmod_wallrun_cooldown", 0, 5, 1)
	wr:SetToolTip("Seconds before wall run can activate again after ending.")
	wr = form:NumSlider("Airborne cooldown regen", "vrmod_wallrun_air_regen", 0, 10, 1)
	wr:SetToolTip("How fast the cooldown recovers while airborne (seconds/second). Landing always resets it instantly.")
	wr = form:NumSlider("Look-along strictness", "vrmod_wallrun_look_max_dot", 0, 1, 2)
	wr:SetToolTip("Lower value = must look more along the wall. Higher value = easier activation.")
	form:CheckBox("Play wallrun sounds", "vrmod_wallrun_sounds")
	wr = form:NumSlider("Wallrun sound volume", "vrmod_wallrun_sound_volume", 0, 1, 2)
	wr:SetToolTip("Wallrun sound loudness.")
	wr = form:NumSlider("Wallrun step interval", "vrmod_wallrun_sound_interval", 0.05, 1, 2)
	wr:SetToolTip("Delay between wallrun step sounds.")
end

local function BuildTabSlide(form)
	if not IsValid(form) then return end

	form:CheckBox("Enable sliding", "vrmod_slide_enable")
	local sh = form:NumSlider("Slide head height threshold", "vrmod_slide_head_height", 4, 120, 0)
	sh:SetToolTip("HMD height above feet (units) at which you count as low enough to slide. Sliding only activates while in VR.")
	form:CheckBox("Play slide sounds", "vrmod_slide_sounds")
	sh = form:NumSlider("Slide sound volume", "vrmod_slide_sound_volume", 0, 1, 2)
	sh:SetToolTip("Slide sound loudness.")
end

local function BuildTabbedSettings(parent)
	local sheet = vgui.Create("DPropertySheet", parent)
	sheet:Dock(FILL)
	sheet:DockMargin(2, 2, 2, 2)

	local function MakeTab(name, buildFn)
		local panel = vgui.Create("DPanel", sheet)
		panel:Dock(FILL)
		panel.Paint = function() end
		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)
		local form = vgui.Create("DForm", scroll)
		form:SetName(name)
		form:Dock(TOP)
		form.Header:SetVisible(false)
		form.Paint = function() end
		buildFn(form)
		sheet:AddSheet(name, panel)
	end

	MakeTab("Climbing",  BuildTabClimbing)
	MakeTab("Wall Run",  BuildTabWallRun)
	MakeTab("Slide",     BuildTabSlide)
end

local climbSettingsFrame = nil

local function OpenClimbSettingsWindow()
	if IsValid(climbSettingsFrame) then
		climbSettingsFrame:MakePopup()
		climbSettingsFrame:Center()
		return
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(450, 580)
	frame:SetTitle("VRModClimbing")
	frame:MakePopup()
	frame:Center()
	climbSettingsFrame = frame

	function frame:OnRemove()
		climbSettingsFrame = nil
	end

	BuildTabbedSettings(frame)
end

concommand.Add("vrmod_brushclimb_menu", function()
	OpenClimbSettingsWindow()
end)

hook.Add("VRMod_Menu", "vrmod_brush_climbing_menu", function(frame)
	if IsValid(frame.DPropertySheet) then
		local panel = vgui.Create("DPanel", frame.DPropertySheet)
		panel:Dock(FILL)
		BuildTabbedSettings(panel)
		frame.DPropertySheet:AddSheet("VRClimb", panel)
		return
	end

	local form = frame.SettingsForm
	if not IsValid(form) then return end
	form:ControlHelp("VRClimb - Climbing")
	BuildTabClimbing(form)
	form:ControlHelp("VRClimb - Wall Run")
	BuildTabWallRun(form)
	form:ControlHelp("VRClimb - Slide")
	BuildTabSlide(form)
end)

local function EnsureQuickMenuItem()
	if not vrmod or not vrmod.AddInGameMenuItem then return end
	vrmod.AddInGameMenuItem("VRClimb", 5, 3, function()
		RunConsoleCommand("vrmod_brushclimb_menu")
	end)
end

hook.Add("VRMod_Start", "vrmod_brush_climbing_menu_button", function(ply)
	if ply ~= LocalPlayer() then return end
	EnsureQuickMenuItem()
end)

timer.Simple(0, EnsureQuickMenuItem)

local function AddAdminCheckbox(form, labelText, cvarName, tooltipText)
	local row = vgui.Create("DCheckBoxLabel")
	row:SetText(labelText)
	row:SetValue(GetServerConVarBool(cvarName, false) and 1 or 0)
	row:SizeToContents()
	if tooltipText and tooltipText ~= "" then
		row:SetTooltip(tooltipText)
	end
	row.OnChange = function(_, val)
		if row._syncing then return end
		if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
		RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, val and "1" or "0")
	end
	row.Think = function(self)
		local desired = GetServerConVarBool(cvarName, false) and 1 or 0
		if self:GetChecked() ~= (desired == 1) then
			self._syncing = true
			self:SetValue(desired)
			self._syncing = false
		end
	end
	form:AddItem(row)
end

local function AddAdminSlider(form, labelText, cvarName, minValue, maxValue, decimals, tooltipText)
	local row = vgui.Create("DNumSlider")
	row:SetText(labelText)
	row:SetMin(minValue)
	row:SetMax(maxValue)
	row:SetDecimals(decimals or 0)
	row:SetValue(GetServerConVarFloat(cvarName, minValue))
	if tooltipText and tooltipText ~= "" then
		row:SetTooltip(tooltipText)
	end
	row.OnValueChanged = function(_, val)
		if row._syncing then return end
		if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
		RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, tostring(val))
	end
	row.Think = function(self)
		local current = GetServerConVarFloat(cvarName, minValue)
		if math.abs((self:GetValue() or 0) - current) > 0.001 then
			self._syncing = true
			self:SetValue(current)
			self._syncing = false
		end
	end
	form:AddItem(row)
end

hook.Add("PopulateToolMenu", "vrmod_brush_climbing_admin_utilities", function()
	spawnmenu.AddToolCategory("Utilities", "VRModClimbing", "VRModClimbing")

	-- Climbing tab
	spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_Climbing", "Climbing", "", "", function(panel)
		panel:ClearControls()
		local form = vgui.Create("DForm", panel)
		form:SetName("Climbing")
		form:Dock(TOP)
		form.Header:SetVisible(false)
		form.Paint = function() end
		BuildTabClimbing(form)

		form:ControlHelp("")
		if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
			form:Help("Server parameters can be changed only by admins.")
		else
			form:Help("Admin: Surface Permissions (set the ceiling for all clients)")
		end
		AddAdminCheckbox(form, "Allow walls",              "sv_vrmod_brushclimb_allow_walls",       "Permit clients to grab wall surfaces.")
		AddAdminCheckbox(form, "Allow ceilings",           "sv_vrmod_brushclimb_allow_ceilings",    "Permit clients to grab ceiling surfaces.")
		AddAdminCheckbox(form, "Allow ledges",             "sv_vrmod_brushclimb_allow_ledges",      "Permit clients to grab ledge surfaces.")
		AddAdminCheckbox(form, "Allow floors",             "sv_vrmod_brushclimb_allow_floors",      "Permit clients to grab floor surfaces.")
		AddAdminCheckbox(form, "Allow doors",              "sv_vrmod_brushclimb_allow_doors",       "Permit clients to grab door entities.")
		AddAdminCheckbox(form, "Allow pushables",          "sv_vrmod_brushclimb_allow_pushable",    "Permit clients to grab func_pushable entities.")
		AddAdminCheckbox(form, "Allow toggleable brushes", "sv_vrmod_brushclimb_allow_toggleable",  "Permit clients to grab func_button, etc.")

		form:ControlHelp("")
		form:Help("Admin: Behaviour")
		AddAdminCheckbox(form, "Reduce collider while climbing", "sv_vrmod_brushclimb_reduce_collider",  "Keep duck hull while climbing and after release.")

		form:ControlHelp("")
		form:Help("Admin: Surface Thresholds")
		AddAdminSlider(form, "Ledge normal min Z",  "sv_vrmod_brushclimb_ledge_normal_min", 0,  1,  2, "Minimum normal Z for a surface to be a ledge (vs wall).")
		AddAdminSlider(form, "Floor normal min Z",  "sv_vrmod_brushclimb_floor_normal_min", 0,  1,  2, "Minimum normal Z for a surface to be a floor (vs ledge).")
		AddAdminSlider(form, "Ceiling normal max Z", "sv_vrmod_brushclimb_ceil_normal_max", -1, 0, 2, "Maximum normal Z for a surface to be a ceiling (vs wall).")
		panel:AddItem(form)
	end)

	-- Wall Run tab
	spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_WallRun", "Wall Run", "", "", function(panel)
		panel:ClearControls()
		local form = vgui.Create("DForm", panel)
		form:SetName("Wall Run")
		form:Dock(TOP)
		form.Header:SetVisible(false)
		form.Paint = function() end
		BuildTabWallRun(form)

		form:ControlHelp("")
		if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
			form:Help("Server parameters can be changed only by admins.")
		else
			form:Help("Admin server parameters (replicated to clients).")
		end
		AddAdminSlider(form, "Jump force",            "sv_vrmod_wallrun_jump_force",    50,  800, 0, "Launch force when jumping off wall.")
		AddAdminSlider(form, "Wall push force",       "sv_vrmod_wallrun_wall_force",    10,  400, 0, "Force keeping player pressed into wall.")
		AddAdminSlider(form, "Free time (seconds)",   "sv_vrmod_wallrun_free_time",      0,    5, 1, "Seconds before gravity starts building.")
		AddAdminSlider(form, "Fall rate",             "sv_vrmod_wallrun_fall_rate",      0,  500, 0, "Downward acceleration after free time.")
		AddAdminSlider(form, "Max fall speed",        "sv_vrmod_wallrun_max_fall_speed", 0,  800, 0, "Maximum downward speed on wall.")
		AddAdminSlider(form, "Speed transfer grace",  "sv_vrmod_wallrun_speed_grace",    0,    1, 2, "Seconds to blend direction on wall contact.")
		AddAdminSlider(form, "Min jump contact time", "sv_vrmod_wallrun_min_jump_time",  0,    1, 2, "Min seconds on wall before wallrun jump fires.")
		panel:AddItem(form)
	end)

	-- Slide tab
	spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_Slide", "Slide", "", "", function(panel)
		panel:ClearControls()
		local form = vgui.Create("DForm", panel)
		form:SetName("Slide")
		form:Dock(TOP)
		form.Header:SetVisible(false)
		form.Paint = function() end
		BuildTabSlide(form)

		form:ControlHelp("")
		if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
			form:Help("Server parameters can be changed only by admins.")
		else
			form:Help("Admin server parameters (replicated to clients).")
		end
		AddAdminCheckbox(form, "Enable sliding",    "sv_vrmod_slide_enable",      "Allow players to slide when crouching at speed. VR only.")
		AddAdminSlider  (form, "Min entry speed",   "sv_vrmod_slide_min_speed",   0, 800, 0, "Minimum horizontal speed to start a slide.")
		AddAdminSlider  (form, "Entry boost",       "sv_vrmod_slide_entry_boost", 0, 600, 0, "Flat speed bonus at slide start.")
		AddAdminSlider  (form, "Slide friction",    "sv_vrmod_slide_friction",    0, 600, 0, "Horizontal deceleration (units/s^2).")
		AddAdminSlider  (form, "Stop speed",        "sv_vrmod_slide_stop_speed",  0, 400, 0, "Speed below which slide ends.")
		AddAdminSlider  (form, "Air-landing boost", "sv_vrmod_slide_air_boost",   0, 600, 0, "Extra speed when landing into a slide from air.")
		panel:AddItem(form)
	end)
end)

if g_VR and g_VR.active then
	timer.Simple(0, StartClimbing)
end
