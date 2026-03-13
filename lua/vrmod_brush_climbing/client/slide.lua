return function(ctx)
	if not istable(ctx) then return end
	local state = ctx.state
	local zeroVec = ctx.zeroVec
	local cvUseSounds = ctx.cvUseSounds
	local cvSlideEnable = ctx.cvSlideEnable
	local cvSlideHeadHeight = ctx.cvSlideHeadHeight
	local cvSlideSoundEnable = ctx.cvSlideSoundEnable
	local cvSlideSoundVolume = ctx.cvSlideSoundVolume
	local slideStartSounds = ctx.slideStartSounds or {}
	local slideLoopSoundPath = ctx.slideLoopSoundPath
	local GetServerConVarFloat = ctx.GetServerConVarFloat
	local AnyHandHolding = ctx.AnyHandHolding
	local PickSound = ctx.PickSound
	local slideLoopPatch = nil
	-- Stop slide loop sound
	local function StopSlideLoopSound()
		if slideLoopPatch then
			slideLoopPatch:Stop()
			slideLoopPatch = nil
		end
	end

	-- Ensure slide loop sound is playing
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

		if not slideLoopPatch then slideLoopPatch = CreateSound(ply, slideLoopSoundPath) end
		if not slideLoopPatch then return end
		if not slideLoopPatch:IsPlaying() then
			slideLoopPatch:PlayEx(cvSlideSoundVolume:GetFloat(), 100)
		else
			slideLoopPatch:ChangeVolume(cvSlideSoundVolume:GetFloat(), 0)
		end
	end

	-- Main slide update function
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
		local plyVel = ply:GetVelocity()
		local flatVel = Vector(plyVel.x, plyVel.y, 0)
		local flatSpeed = flatVel:Length()
		local minSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_min_speed", 90)
		local maxSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_max_speed", 400)
		-- Check if player is crouched below slide height
		local isLow = hmd.pos.z - g_VR.origin.z <= cvSlideHeadHeight:GetFloat()
		local shouldSlide = isLow and flatSpeed >= minSlideSpeed
		-- Trace downward under player for ground info
		local traceDown = {
			start = ply:GetPos() + Vector(0, 0, 10),
			endpos = ply:GetPos() - Vector(0, 0, 50),
			filter = ply
		}

		local trGround = util.TraceLine(traceDown)
		local currentGroundZ = trGround.HitPos.z
		local groundNormal = trGround.HitNormal
		-- Forward ground check to prevent stairs/uphill
		if flatVel:LengthSqr() > 0.001 then
			local dirNorm = flatVel:GetNormalized()
			local forwardCheckDist = 20
			local forwardTrace = {
				start = ply:GetPos() + Vector(0, 0, 10),
				endpos = ply:GetPos() + dirNorm * forwardCheckDist - Vector(0, 0, 50),
				filter = ply
			}

			local ftr = util.TraceLine(forwardTrace)
			if ftr.Hit and ftr.HitPos.z - currentGroundZ > 1 then
				shouldSlide = false -- uphill / stair ahead
			end
		end

		-- Initialize previous ground height for zDiff
		if not state.lastGroundZ then state.lastGroundZ = ply:GetPos().z end
		-- Player vertical movement detection for gentle uphill
		local zDiff = ply:GetPos().z - state.lastGroundZ
		state.lastGroundZ = ply:GetPos().z
		local uphillThreshold = 0.5 -- units per frame, tweak for sensitivity
		if zDiff > uphillThreshold then shouldSlide = false end
		-- Update slide state and sounds
		if shouldSlide ~= state.slideActive then
			state.slideActive = shouldSlide
			if shouldSlide then
				PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
				EnsureSlideLoopSound()
			else
				StopSlideLoopSound()
			end
		end

		-- Apply sliding movement, friction, and slope acceleration
		if state.slideActive then
			-- Compute slope along movement direction
			if flatVel:LengthSqr() > 0.001 then
				local moveDir = flatVel:GetNormalized()
				local slopeAlongMove = -groundNormal:Dot(Vector(moveDir.x, moveDir.y, 0))
				local slopeAccel = 50 -- tweak for stronger/weaker slope
				if slopeAlongMove > 0 then
					-- Downhill: accelerate
					flatVel = flatVel + moveDir * slopeAccel * slopeAlongMove * FrameTime()
				elseif slopeAlongMove < 0 then
					-- Uphill: decelerate
					flatVel = flatVel + moveDir * slopeAccel * slopeAlongMove * FrameTime() -- slopeAlongMove negative
				end
			end

			-- Clamp to max speed
			if flatVel:Length() > maxSlideSpeed then
				flatVel:Normalize()
				flatVel = flatVel * maxSlideSpeed
			end

			-- Apply friction
			local frictionPerSecond = GetServerConVarFloat("sv_vrmod_slide_friction")
			local frictionThisFrame = frictionPerSecond * FrameTime()
			local newSpeed = math.max(flatVel:Length() - frictionThisFrame, 0)
			if newSpeed < minSlideSpeed then
				newSpeed = 0
				state.slideActive = false
				StopSlideLoopSound()
			end

			if flatVel:LengthSqr() > 0.001 then
				flatVel:Normalize()
				flatVel = flatVel * newSpeed
			end

			ply:SetLocalVelocity(flatVel + Vector(0, 0, plyVel.z))
		end

		-- Send normalized direction to server
		local flatDir = flatVel
		if flatDir:LengthSqr() > 0.001 then flatDir:Normalize() end
		net.Start("vrmod_slide_sync")
		net.WriteBool(state.slideActive)
		net.WriteVector(flatDir)
		net.SendToServer()
	end

	-- Expose functions to ctx
	if isfunction(ctx.setStopSlideLoopSound) then ctx.setStopSlideLoopSound(StopSlideLoopSound) end
	if isfunction(ctx.setEnsureSlideLoopSound) then ctx.setEnsureSlideLoopSound(EnsureSlideLoopSound) end
	if isfunction(ctx.setUpdateSlide) then ctx.setUpdateSlide(UpdateSlide) end
end