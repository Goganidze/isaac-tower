return function(mod) --, Isaac_Tower)

local Isaac = Isaac

local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')


local function SpawnAfterImage(spr, pos, col, AlphaLos)
	local off = Isaac.Spawn(1000, IsaacTower_GibVariant, Isaac_Tower.ENT.GibSubType.AFTERIMAGE, pos, Vector(0,0), nil)
	off:GetSprite():Load(spr:GetFilename(), true)
	off:GetSprite():Play(spr:GetAnimation(), true)
	off:GetSprite():SetFrame(spr:GetFrame())
	off:GetData().color = col or Color(1,1,1,1)
	off:GetSprite().Color = off:GetData().color
	off:GetSprite().FlipX = spr.FlipX
	off:GetSprite().Rotation = spr.Rotation
	off:GetData().AlphaLoss = AlphaLos or 0.05
	return off
end

local function spawnSpeedEffect(pos, vec, angle, var)
	local eff = Isaac.Spawn(1000,16,0,pos,vec,nil):ToEffect()
	eff:Update()
	eff:GetSprite():Load("gfx/effects/spedd_effects.anm2", true)
	eff:GetSprite():Play(var == 1 and "кругляшка" or "полоска")
	eff:GetSprite().Rotation = angle or eff.SpriteRotation
	eff.Rotation = angle
	if var == 1 then
		eff.Variant = IsaacTower_GibVariant
		eff.SubType = Isaac_Tower.ENT.GibSubType.SOUND_BARRIER
		eff:AddEntityFlags(EntityFlag.FLAG_NO_SPRITE_UPDATE)
		eff.DepthOffset = 150
		--eff:GetSprite().PlaybackSpeed = 2
	end
	
	return eff
end

local function sign(num)
	return num < 0 and -1 or 1
end
local function sign0(num)
	if type(num) ~= "number" then error("[1] is not a number",2) end
	return num < 0 and -1 or num == 0 and 0 or 1
end

local function SetState(fent, state)
	fent.State = state
	fent.StateFrame = 0
	fent.InputWait = nil
end

local function CheckCanUp(ent)
	local result = true
	local d = ent:GetData()
	local fent = d.TSJDNHC_FakePlayer

	local half = fent.Half/1
	local offset = fent.CollisionOffset/1

	fent.Half = Vector(15,20)
	fent.CollisionOffset = Vector(0,0)

	local blockIndex = {}
	for i=-1,1 do   ---Half
		local pos = Vector(fent.Half.X*i+i,-10)
		local grid = Isaac_Tower.GridLists.Solid:GetGrid(fent.Position + pos)
		
		if grid and not blockIndex[grid.Index] and Isaac_Tower.ShouldCollide(ent, grid, true) then
			blockIndex[grid.Index] = true
			local hit = Isaac_Tower.CheckintersectAABB(fent, grid)
			if hit.delta.X ~= 0 or hit.delta.Y < 0 then
				result = false
			end
		end
		local grid = Isaac_Tower.GridLists.Obs:GetGrid(fent.Position + pos)
		
		if grid and not blockIndex[grid.Index] and Isaac_Tower.ShouldCollide(ent, grid, true) then
			blockIndex[grid.Index] = true
			local hit = Isaac_Tower.CheckintersectAABB(fent, grid)
			if hit.delta.X ~= 0 or hit.delta.Y < 0 then
				result = false
			end
		end
	end

	fent.Half = half
	fent.CollisionOffset = offset

	return result
end


local Inp = {}
function Inp.PressRight(idx)
	
	if idx == 0 then
		return Input.GetActionValue(ButtonAction.ACTION_SHOOTRIGHT, idx)
	else
		return Input.GetActionValue(ButtonAction.ACTION_RIGHT, idx)
	end
end
function Inp.PressLeft(idx)
	if idx == 0 then
		return Input.GetActionValue(ButtonAction.ACTION_SHOOTLEFT, idx)
	else
		return Input.GetActionValue(ButtonAction.ACTION_LEFT, idx)
	end
end
function Inp.PressDown(idx)
	if idx == 0 then
		return Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, idx)
	else
		return Input.IsActionPressed(ButtonAction.ACTION_DOWN, idx)
	end
end
function Inp.PressUp(idx)
	if idx == 0 then
		return Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, idx)
	else
		return Input.IsActionPressed(ButtonAction.ACTION_UP, idx)
	end
end
function Inp.PressRun(idx)
	if idx == 0 then
		return Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, idx)
	else
		return Input.IsActionPressed(ButtonAction.ACTION_DROP, idx) --ACTION_MENURT
	end
end
function Inp.PressJump(idx, fent)
	local ret
	if idx == 0 then
		ret = Input.IsActionPressed(ButtonAction.ACTION_ITEM, idx)
	else
		ret = Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM, idx)
	end
	if ret and not fent.OnGround then
		fent.PreJumpPressed = 5
	end
	return ret
end
function Inp.PressGrab(idx)
	if idx == 0 then
		return Input.IsButtonPressed(Keyboard.KEY_S, idx)
	else
		return Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, idx)
	end
end


local function spawnDust(pos, vec)
	local eff = Isaac.Spawn(1000,59,1,pos+vec*2,vec,nil):ToEffect() 
	eff.Timeout = 5
	eff.LifeSpan = 12
	eff.SpriteScale = Vector(0.2,0.2)
	eff.Color = Color(1,1,1,0.4)
	eff:SetColor(Color(1, 1, 1, 1), 5, 1, true, false)
	eff:Update()
	return eff
end

local function JumpButtonPressed(idx, fent)
	local press = Input.IsActionPressed(ButtonAction.ACTION_UP, idx)
	or Input.IsActionPressed(ButtonAction.ACTION_ITEM, idx)
	or Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM, idx)

	if not fent.OnGround and
	(Input.IsActionTriggered(ButtonAction.ACTION_UP, idx)
	or Input.IsActionTriggered(ButtonAction.ACTION_ITEM, idx)
	or Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, idx)) then
		fent.PreJumpPressed = 5
	end

	return press
end

Isaac_Tower.MovementHandlers = {}

function Isaac_Tower.MovementHandlers.AnimWalk(spr, Walkanim, idleAnim, vel)
	if math.abs(vel) < 0.1 then
		spr:Play(idleAnim)
	else
		spr:Play(Walkanim)
	end
end

function Isaac_Tower.MovementHandlers.JumpHandler(fent, Upspeed, PressTime, ActiveTime)
	local idx = fent.ControllerIndex
	if fent.CanJump and ((fent.OnGround or fent.jumpDelay>0) and fent.JumpPressed < PressTime or fent.JumpActive) then --15
		
		if Inp.PressJump(idx, fent) then
			if not fent.JumpActive then
				for i=-1,1 do
					if i~=0 then
						spawnDust(fent.Position+Vector(0,16), Vector(i*3,0.5))
					end
				end
			end

			--newVel = newVel + Vector(0,-15)
			fent.Velocity.Y = Upspeed -- -6
			fent.JumpActive = fent.JumpActive and fent.JumpActive-1 or ActiveTime --15
			fent.JumpPressed = math.max(30, fent.JumpPressed + 1)
			fent.OnGround = false
			fent.grounding = 0
		end
	elseif not fent.OnGround then 
		--if Inp.PressJump(idx, fent) then
		--	fent.JumpPressed = math.max(0, fent.JumpPressed + 1)
		--end
	end
	if fent.JumpActive and fent.JumpActive<=0 then
		fent.JumpActive = nil
		if fent.CanJump then --and not dontLoseY then
			fent.Velocity.Y = fent.Velocity.Y/2 --math.max(fent.Velocity.Y, -4.6)
		end
	end
	if fent.OnGround then --and not dontLoseY then --and not fent.JumpPressed then
	--	fent.IgnoreWallRot = nil
		if fent.Velocity.Y>5 then
			for i=-1,1 do
				if i~=0 then
					spawnDust(fent.Position+Vector(0,16), Vector(i*3,0.5))
				end
			end
		end
		fent.Velocity.Y =  math.min(0,fent.Velocity.Y)
	end
		
	if not Inp.PressJump(idx, fent) then
		if fent.JumpActive then
			fent.jumpDelay = 0
			fent.Velocity.Y =math.max(fent.Velocity.Y, -2.6)
		end
		fent.JumpActive = nil
		fent.JumpPressed = 0
	end

end

function Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot)
	if rot == nil then error("[2] is not a number",2) end
	return (not fent.OnGround or fent.slopeAngle)
		--and sign0(rot) == sign0(fent.CollideWall) 
		and (not fent.IgnoreWallRot or fent.IgnoreWallRot ~= fent.CollideWall)
end


local walkRunState = {[1] = true,[2] = true,[3] = true}
local notWallClambingState = {[1]=true, [5] = true,[40] = true} --[1] = true,

function Isaac_Tower.MovementHandlers.GrabHandler(fent)
	local idx = fent.ControllerIndex
	local spr = fent.Flayer.Sprite
	local Flayer = fent.Flayer

	if Inp.PressGrab(idx) and fent.GrabDelay <= 0 and not fent.GrabPressed then
		fent.GrabPressed = true
			
		if fent.State == "Бег_по_стене" then
			local canBreak = false
			for i = -1, 1 do
				local grid = Isaac_Tower.rayCast((fent.Position - fent.Velocity + Vector(0,fent.Half.Y*i)), Vector(spr.FlipX and -1 or 1, 0), 10, 2) 
				if grid and grid.CanBeDestroyedWhenWallClambing then
					SetState(fent, "Захват")--fent.State = 20
					if Inp.PressLeft(idx)>0 then
						fent.RunSpeed = math.min(-5.0, fent.RunSpeed)
					elseif Inp.PressRight(idx)>0 then
						fent.RunSpeed = math.max(5.0, fent.RunSpeed)
					else
						fent.RunSpeed = spr.FlipX and -5.0 or 5.0
					end
					spr:Play("grab",true)
					spr.Rotation = 0
					spr.Offset = Vector(0,12)
						
					fent.Velocity.Y = math.max(0,fent.Velocity.Y/2)
					fent.AttackAngle = nil
					return --break
				end
			end
		else
			if Inp.PressDown(idx) then
				SetState(fent, "Стомп")
				spr:Play("grab_down_appear",true)
				Flayer.Queue = "grab_down_idle"
				spr.Rotation = 0
				spr.Offset = Vector(0,12)
				return true
			else
				SetState(fent, "Захват")--fent.State = 20
				if Inp.PressLeft(idx)>0 then
					fent.RunSpeed = math.min(-5.0, fent.RunSpeed)
				elseif Inp.PressRight(idx)>0 then
					fent.RunSpeed = math.max(5.0, fent.RunSpeed)
				else
					fent.RunSpeed = spr.FlipX and -3.0 or 3.0
				end
				spr:Play("grab",true)
				spr.Rotation = 0
				spr.Offset = Vector(0,12)

				fent.Velocity.Y = math.max(0,fent.Velocity.Y/2)
				return
			end
		end
	elseif not Inp.PressGrab(idx) and fent.GrabDelay <= 0 then
		fent.GrabPressed = false	
	end
end

function Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr, angle)
	if fent then
		local sig = spr.FlipX and -1 or 1
		if fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
			spawnSpeedEffect(fent.Position+Vector(sig*-15, (fent.StateFrame%24)*2-20):Rotated(sig*(angle or spr.Rotation)),
				fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
		if math.abs(fent.RunSpeed) > 10 then
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50)))), 4/math.abs(fent.RunSpeed) )
		end
	end
end


function Isaac_Tower.MovementHandlers.SetForsedVelocity(fent, vel, power, time, noGrav)
	if fent and vel then
		time = time or 60
		fent.ForsedVelocity = {} --vel
		fent.ForsedVelocity.Velocity = vel
		fent.ForsedVelocity.Power = power or 1
		fent.ForsedVelocity.Time = time
		fent.ForsedVelocity.noGrav = noGrav
		fent.ForsedVelocity.MaxTime = time
		fent.ForsedVelocity.Lerp = 0
	end
end

local walkanim = {walk = true, walk_jump_down = true}

Isaac_Tower.FlayerMovementState = {}
Isaac_Tower.FlayerMovementState["Ходьба"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		fent.CanJump = true

		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if rot<0 then --Inp.PressLeft(idx)>0 then
			fent.RunSpeed = Inp.PressLeft(idx)*-4
			rot = -4
			fent.PressMoveInLastFrame = true
		elseif rot>0 then --Inp.PressRight(idx)>0 then
			fent.RunSpeed = Inp.PressRight(idx)*4
			rot = 4
			fent.PressMoveInLastFrame = true
		elseif fent.PressMoveInLastFrame then
			fent.RunSpeed = 0
			fent.Velocity.X = (math.max(0,math.abs(fent.Velocity.X)-4))*0.5 * sign(fent.Velocity.X)
			fent.PressMoveInLastFrame = nil
		end

		if math.abs(fent.Velocity.X) > 0.2 and Inp.PressRun(idx) and fent.OnGround then
			SetState(fent,"НачалоБега")
			--Isaac_Tower.HandleMoving(player)
			--return
		--elseif Inp.PressRun(idx) then
		--	if not Inp.PressDown(idx) and fent.CollideWall and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
		--		spr.Rotation = 0
		--		spr.Offset = Vector(0,12)

		--		SetState(fent, "Бег_по_стене")--fent.State = 40
		--		fent.CanJump = false
		--		fent.grounding = 0
		--		spr:Play("wall_climbing", true)
		--		return
		--	end
		elseif Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent,"Присел")
			end
		
		end

		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
			return
		end
	end
	
	if fent.PressMoveInLastFrame then
		spr.FlipX = math.abs(fent.RunSpeed) < 0.001 and spr.FlipX or (fent.RunSpeed < 0)
	end
	if fent.OnGround then
		Isaac_Tower.MovementHandlers.AnimWalk(spr, "walk", "idle", fent.Velocity.X)
	else
		if fent.Velocity.Y < 0.0 then
			spr:Play("walk_jump_up")
		else
			if not walkanim[spr:GetAnimation()] then
				spr:Play("walk_jump_down")
				spr:SetFrame(4)
			else
				spr:Play("walk_jump_down")
			end
		end
	end
	if not fent.PressMoveInLastFrame then
		if fent.OnGround then
			fent.Velocity.X = fent.Velocity.X * 0.6
		end

		local toReturn = {}
		toReturn.donttransformRunSpeedtoX = true
		return toReturn
	end
end
Isaac_Tower.FlayerMovementState["НачалоБега"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		local press = Inp.PressLeft(idx) + Inp.PressRight(idx) ~= 0
		local nextVel = 0

		if not Inp.PressDown(idx) and fent.CollideWall == sign0(rot) then
			if Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then --not fent.OnGround and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = Vector(0,12)

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			--elseif fent.OnGround and fent.slopeRot and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
			--	spr.Rotation = 0
			--	spr.Offset = Vector(0,12)

			--	SetState(fent, "Бег_по_стене")--fent.State = 40
			--	fent.CanJump = false
			--	fent.grounding = 0
			--	spr:Play("wall_climbing", true)
			--	return
			elseif (fent.OnGround or fent.CollideWall ~= sign0(rot)) then 
				fent.InputWait = fent.InputWait and (fent.InputWait - 1) or 5
				if fent.InputWait and fent.InputWait <= 0 then
					SetState(fent, "Остановка_бега") --fent.State = 5
					fent.InputWait = nil
				end
			end
		end

		if rot~=0 and fent.OnGround then
			if math.abs(fent.RunSpeed) < 4 then
				fent.RunSpeed = 4*sign(rot)
			end
			nextVel = 0.028*sign(rot)
			if math.abs(fent.RunSpeed) > 6.4 then
				SetState(fent, "Бег") --fent.State = 3
				spr:Play("run", true)
				if fent.StateFrame>60 then
					player:SetColor(Color(1,1,1,1,0.5,0.5,0.5),3,1,false,false)
					spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, -12),
						fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees(),1)
				end
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
				--goto Moving
			end
		elseif rot~=0 then
			if math.abs(fent.RunSpeed) < 2 then
				SetState(fent, "Ходьба") --fent.State = 1
			end
			if fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
				spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-16),
					fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
			end
			if math.abs(fent.RunSpeed) > 10 then
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50)))), 4/math.abs(fent.RunSpeed) )
			end
		elseif fent.OnGround then
			fent.RunSpeed = fent.RunSpeed*0.7	
		end
		
		if fent.OnGround and (not press or (nextVel~= 0 and sign(nextVel) ~= sign(fent.RunSpeed))) and math.abs(fent.RunSpeed) > 3 then
			SetState(fent,  "Остановка_бега") --fent.State = 5
		end		

		fent.RunSpeed = (fent.RunSpeed + nextVel)

		if spr:GetAnimation() ~= "pre_run" then
			spr:Play("pre_run", true)
		end
		if Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent, "Скольжение")
			else
				spr:Play("lunge_down")
				fent.Velocity.Y = 8
				fent.CanBreakPoop = true
			end
		elseif fent.OnGround and not Inp.PressRun(idx) then
			SetState(fent, "Остановка_бега") --SetState(fent, "Ходьба")	
		end

		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
			return
		end
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.001 and spr.FlipX or (fent.Velocity.X < 0)
	if spr:GetAnimation() == "run" and math.abs(fent.RunSpeed) < 3.7 then
		spr:Play("pre_run")
	elseif math.abs(fent.Velocity.X) < 0.1 then
		spr:Play("idle")
	end
end
Isaac_Tower.FlayerMovementState["Бег"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		local press = Inp.PressLeft(idx) + Inp.PressRight(idx) ~= 0

		if fent.slopeAngle and fent.OnGround then
			local tarAngl = spr.FlipX and fent.slopeAngle or -fent.slopeAngle
			spr.Rotation = spr.Rotation*0.8 + tarAngl*0.2 
			spr.Offset = Vector(0,14)
		else
			spr.Rotation = spr.Rotation*0.8
			spr.Offset = Vector(0,12)
		end
		
		if not Inp.PressDown(idx) then

			if fent.StateFrame%4 == 0 then
				if spr.Rotation < -10 then
					spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-32),
						fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
				else
					spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-16),
						fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
				end
			end

			if fent.CollideWall and fent.slopeAngle and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = Vector(0,12)

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			elseif fent.CollideWall and not fent.OnGround and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = Vector(0,12)

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			elseif fent.CollideWall and fent.OnGround then --fent.Velocity.X == 0 then
				fent.InputWait = fent.InputWait and (fent.InputWait - 1) or 5
				if fent.InputWait and fent.InputWait <= 0 then
					SetState(fent, "Остановка_бега") --fent.State = 5
					spr.Rotation = 0
					spr.Offset = Vector(0,12)
					fent.InputWait = nil
				end
			end
		end

		if rot and press then
			fent.RunUnpressDelay = 5
			if press and sign0(rot) ~= sign0(fent.RunSpeed) and math.abs(fent.RunSpeed) > 6.4 and fent.OnGround then
				fent.NewRotate = -sign(fent.RunSpeed)
				SetState(fent, "Бег_смена_направления")--fent.State = 4
				fent.RunSpeed = 7.4*sign(fent.RunSpeed)
				spr.Rotation = 0
				spr.Offset = Vector(0,12)
			elseif fent.OnGround then
				fent.RunSpeed = (fent.RunSpeed + 0.075/math.abs(fent.RunSpeed+1)*sign(rot)) 
				if player.FrameCount%5 == 0 then
					spawnDust(fent.Position+Vector(0,5), Vector(sign(rot)*-5,-1))
				end
				if fent.StateFrame>1 and fent.StateFrame%120 == 0 then
					spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -26 or 26, -16),
						Vector(fent.TrueVelocity.X, 0), spr.FlipX and 180 or 0,1).Color = Color(1,1,1,0.5)
				end
				--if math.abs(fent.RunSpeed) > 10 then
				--	SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/100)))) )
				--end
			end
			if math.abs(fent.RunSpeed) > 10 then
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50)))), 4/math.abs(fent.RunSpeed) )
			end
		end

		if fent.OnGround then
			if (not press and fent.RunUnpressDelay and fent.RunUnpressDelay < 0) or not Inp.PressRun(idx) then
				fent.RunUnpressDelay = nil
				SetState(fent, "Остановка_бега") --fent.State = 5
				spr.Rotation = 0
				spr.Offset = Vector(0,12)
			end
			if Inp.PressUp(idx) then
				fent.PressUpDelay = fent.PressUpDelay and (fent.PressUpDelay-1) or 5
				if fent.PressUpDelay and fent.PressUpDelay <= 0 then
					fent.PressUpDelay = nil
					SetState(fent, "Супер_прыжок_подготовка")
					spr.Rotation = 0
					spr.Offset = Vector(0,12)
				end
			end
		end
		if spr:GetAnimation() ~= "run" then
			spr:Play("run", true)
		end
		fent.RunUnpressDelay = fent.RunUnpressDelay and (fent.RunUnpressDelay-1) or nil
		if Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent, "Скольжение")--fent.State = 15
				spr.Rotation = 0
				spr.Offset = Vector(0,12)
			else
				spr:Play("lunge_down")
				fent.Velocity.Y = 8
				fent.CanBreakPoop = true
			end
		else
			fent.OnAttack = true
			fent.CanBreakPoop = true
			fent.CanBreakMetal = true

			fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
			fent.ShowSpeedEffect = fent.AttackAngle
		end
			
		if fent.State ~= "Бег" then
			spr.Rotation = 0
			spr.Offset = Vector(0,12)
		end

		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
			return
		end
	end
	
	spr.FlipX = math.abs(fent.RunSpeed) < 0.1 and spr.FlipX or (fent.RunSpeed < 0)
end
Isaac_Tower.FlayerMovementState["Бег_смена_направления"] = function(player, fent, spr, idx)
	local toReturn = {}
	fent.CanJump = false
	if spr:GetAnimation() ~= "run_change_dir" then
		spr:Play("run_change_dir", true)
	end
		
	fent.RunSpeed = fent.RunSpeed - sign0(fent.RunSpeed)*0.28   --fent.RunSpeed*0.90 0.14
	toReturn.newVel = Vector(fent.RunSpeed,0)

	if player.FrameCount%2 == 0 then
		local vec = Vector(-fent.NewRotate,0)
		spawnDust(fent.Position+Vector(0,16)+vec*4, vec*12)
	end
	if spr:IsFinished("run_change_dir") and fent.OnGround then
		spr:Play("run", true)
		SetState(fent, "Бег")--fent.State = 3
		fent.RunSpeed = 7.4 * fent.NewRotate
		spr.FlipX = not spr.FlipX
		fent.CanJump = true

		spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -26 or 26, -8),
			Vector(spr.FlipX and -8 or 8, 0), spr.FlipX and 180 or 0,1).Color = Color(1,1,1,0.5)
	end
end
Isaac_Tower.FlayerMovementState["Присел"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		fent.Half = Vector(15,10)
		fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1 --Vector(0,10)

		if Inp.PressLeft(idx)>0 then
			fent.RunSpeed = Inp.PressLeft(idx)*-3
		elseif Inp.PressRight(idx)>0 then
			fent.RunSpeed = Inp.PressRight(idx)*3
		else
			fent.RunSpeed = 0
		end
		if not Inp.PressDown(idx) and CheckCanUp(player) then
			SetState(fent, "Ходьба")--fent.State = 1
			fent.Half = fent.DefaultHalf/1 --Vector(15,20)
			fent.CollisionOffset = Vector(0,0)
		end
	end

	if CheckCanUp(player) then
		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 7)
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.1 and spr.FlipX or (fent.Velocity.X < 0)
	Isaac_Tower.MovementHandlers.AnimWalk(spr, "duck_move", "duck_idle", fent.Velocity.X)
end
Isaac_Tower.FlayerMovementState["Скольжение"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)

		if fent.Velocity.X == 0 then
			fent.InputWait = fent.InputWait and (fent.InputWait - 1) or 2
			if fent.InputWait <= 0 then
				SetState(fent, "Остановка_бега")--fent.State = 5
				fent.InputWait = nil
			end
		else
			fent.InputWait = nil

			if fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
				spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-16),
					fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
			end
			if math.abs(fent.RunSpeed) > 10 then
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50)))), 4/math.abs(fent.RunSpeed) )
			end
		end
		if spr:GetAnimation() ~= "duck_roll" then
			spr:Play("duck_roll", true)
		end
		fent.Half = Vector(15,10)
		fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1 --Vector(0,9)

		if not Inp.PressRun(idx) and fent.OnGround then
			fent.RunSpeed = fent.RunSpeed*0.92
		end
		if Inp.PressRun(idx) and not fent.OnGround then
			if math.abs(fent.RunSpeed) > 5.4 then
				SetState(fent, "Бег")
			else
				SetState(fent, "НачалоБега")
			end
			--goto Moving
		end
		if math.abs(fent.RunSpeed)<=0.1 then
			fent.RunUnpressDelay = nil
			SetState(fent, "Присел")--fent.State = 10
		end
		if not Inp.PressDown(idx) and CheckCanUp(player) then
			SetState(fent, "НачалоБега")--fent.State = 2
			fent.Half = fent.DefaultHalf/1 --Vector(15,20)
			fent.CollisionOffset = Vector(0,0)
		end

		fent.CanBreakPoop = true
		fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
	end
end
Isaac_Tower.FlayerMovementState["Скольжение_Захват"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)

		fent.SlideTime = fent.SlideTime or 0
		fent.SlideTime = fent.SlideTime - 1
		if fent.Velocity.X == 0 then
			if CheckCanUp(player) then
				if fent.RunSpeed >= 7.4 then
					SetState(fent, "Бег")--fent.State = 5
				else
					SetState(fent, "НачалоБега")
				end
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			else
				SetState(fent, "Присел")
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			end
		end
		if fent.StateFrame <= 1 and spr:GetAnimation() ~= "slide" then
			spr:Play("slide", true)
		end
		if Inp.PressJump(idx, fent) then
			if CheckCanUp(player) then
				if fent.RunSpeed >= 7.4 then
					SetState(fent, "Бег")--fent.State = 5
				else
					SetState(fent, "НачалоБега")
				end
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			end
		end

		fent.Half = Vector(15,10)
		fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1 --Vector(0,9)

		--if fent.StateFrame%8 == 0 then
		--	spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -15 or 15, (fent.StateFrame%24)/4), Vector(0,0), fent.TrueVelocity:GetAngleDegrees())
		--end
		Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr)
			
		if fent.SlideTime<=0 and not Inp.PressDown(idx) and CheckCanUp(player) then
			SetState(fent, "Бег")--fent.State = 3
			fent.Half = fent.DefaultHalf/1 --Vector(15,20)
			fent.CollisionOffset = Vector(0,0)
		elseif fent.SlideTime <= 0 then
			if sign(rot) == sign(fent.RunSpeed) then
				SetState(fent, "Скольжение")
				spr:Play("duck_roll", true)
			else
				if CheckCanUp(player) then
					fent.RunSpeed = fent.RunSpeed*0.6
				--elseif spr:GetAnimation() == "slide"  then
				--	spr:Play("duck_roll", true)
				end
			end
		else
			fent.RunSpeed = math.max(7.4, math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
		end

		fent.OnAttack = true
		fent.CanBreakPoop = true
		fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
	end
	
	spr.FlipX = math.abs(fent.Velocity.X) < 0.1 and spr.FlipX or (fent.Velocity.X < 0)
end
Isaac_Tower.FlayerMovementState["Захват"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	if fent.StateFrame == 1 then
		spr:Play("grab",true)
	end
	local result = {}

	fent.RunSpeed = math.max(5,math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
	
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx)+Inp.PressRight(idx)

		if fent.StateFrame > 1 and not Inp.PressDown(idx) and Inp.PressRun(idx) 
		and fent.CollideWall and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
			
			--if Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = Vector(0,12)

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			--end
		elseif fent.StateFrame > 1 and not Inp.PressDown(idx) and fent.CollideWall then
			SetState(fent, "Остановка_бега")
		end
			
		if Inp.PressDown(idx) then
			if fent.OnGround and fent.StateFrame < 15 then
				SetState(fent, "Скольжение_Захват")--fent.State = 16
				fent.SlideTime = 40
				fent.RunSpeed = math.max(5.4, math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
			elseif fent.StateFrame < 6 then
				SetState(fent, "Стомп")
				spr:Play("grab_down_appear",true)
				Flayer.Queue = "grab_down_idle"
			end
		end
		if spr:IsFinished(spr:GetAnimation()) and fent.OnGround then
			if Inp.PressRun(idx) then
				SetState(fent, "НачалоБега")--fent.State = 2
			else
				SetState(fent, "Ходьба")--fent.State = 1
			end
			if Inp.PressDown(idx) then
				SetState(fent, "Скольжение")--fent.State = 15
			end
			fent.GrabDelay = 30
		end

		fent.OnAttack = true
		fent.CanBreakPoop = true

		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 15)
	end

	Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr)

	if fent.StateFrame <= 15 then
		--result.dontLoseY = true
		fent.Velocity.Y = fent.Velocity.Y < 1 and (fent.Velocity.Y * (math.max(0,fent.StateFrame)/15)) or fent.Velocity.Y
	end

	spr.FlipX = math.abs(fent.RunSpeed) < 0.1 and spr.FlipX or (fent.RunSpeed < 0)

	return result
end
--mod:AddPriorityCallback(Isaac_Tower.Callbacks.FLAYER_PRE_COLLIDING_ENEMY, CallbackPriority.LATE, function(_, fent, target)
function Isaac_Tower.MovementHandlers.EnemyGrabCollision(fent, target)
	if fent.State == "Захват" and not target:GetData().Isaac_Tower_Data.NoGrabbing and target.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
		fent.GrabTarget = target
		SetState(fent, "Захватил")
		target:GetData().Isaac_Tower_Data.State  = Isaac_Tower.EnemyHandlers.EnemyState.GRABBED
		target:GetData().Isaac_Tower_Data.GrabbedBy = fent
		target:GetSprite():Play("stun")
	end
end
Isaac_Tower.MovementHandlers.CrashState = { --true or function(fent, target)
	["Бег_по_стене"] = true,
	["Бег"] = true,
	["Скольжение_Захват"] = true,
	["Стомп"] = function(fent, target)
		if fent.Flayer.Sprite:IsPlaying("grab_down_idle") then
			return true
		end
	end,
	["Супер_прыжок"] = true,
	["Супер_прыжок_перенаправление"] = function (fent, target)
		if fent.Flayer.Sprite:IsFinished(fent.Flayer.Sprite:GetAnimation()) then
			return true
		end
	end,
}
function Isaac_Tower.MovementHandlers.EnemyCrashCollision(fent, target)
	local stateCheck = Isaac_Tower.MovementHandlers.CrashState[fent.State]
	if type(stateCheck) == "function" then
		stateCheck = stateCheck(fent, target)
	end
	if stateCheck and not target:GetData().Isaac_Tower_Data.Flags.Invincibility then
		target:GetData().Isaac_Tower_Data.State  = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
		target:GetData().Isaac_Tower_Data.DeadFlyRot = fent.Position.X<target.Position.X and 1 or -1
	end
end
function Isaac_Tower.MovementHandlers.EnemyStandeartCollision(fent, ent, dist)
	local data = ent:GetData().Isaac_Tower_Data
	if not ent:GetData().Isaac_Tower_Data.Flags.Invincibility then
		if fent.OnGround and data.State == Isaac_Tower.EnemyHandlers.EnemyState.STUN then
			if fent.Position.X < ent.Position.X then
				ent.Velocity = Vector(ent.Velocity.X*0.8 - sign(fent.Position.X-ent.Position.X)*(dist/20), ent.Velocity.Y )
			else
				ent.Velocity = Vector(ent.Velocity.X*0.8 + sign(ent.Position.X-fent.Position.X)*(dist/20), ent.Velocity.Y )
			end
		elseif fent.Position.Y< ent.Position.Y and data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
			if not data.Flags.NoStun then
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
				data.StateFrame = 0
			end
			if fent.Position.X < ent.Position.X then
				ent.Velocity =  Vector(ent.Velocity.X*0.8 - sign(fent.Position.X-ent.Position.X)*(40-dist)/2, ent.Velocity.Y )
			else
				ent.Velocity = Vector(ent.Velocity.X*0.8 + sign(ent.Position.X-fent.Position.X)*(40-dist)/2, ent.Velocity.Y )
			end
			fent.Velocity.Y = -4
		end
	end
end
mod:AddPriorityCallback(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, CallbackPriority.LATE, function(_, target, Pos, Offset, Scale)
	local data = target:GetData().Isaac_Tower_Data
	if data.GrabbedBy then
		local fent = data.GrabbedBy
		local spr = fent.Flayer.RightHandSprite
		spr.Color = fent.Flayer.Sprite.Color
		
		--local RenderPos =  Pos + fent.Position/(20/13) + fent.Velocity/(20/13)*Isaac_Tower.GetProcentUpdate() + Isaac_Tower.GetRenderZeroPoint()
		--local RenderPos = TSJDNHC_PT:WorldToScreen(fent.Position+fent.Velocity*Isaac_Tower.GetProcentUpdate())

		--local RenderPos = TSJDNHC_PT:WorldToScreen(fent.Position + fent.Velocity*Isaac_Tower.GetProcentUpdate())

		--spr:SetFrame(fent.Flayer.Sprite:GetAnimation(), fent.Flayer.Sprite:GetFrame())
		spr.FlipX = fent.Flayer.Sprite.FlipX
		--if Scale ~= 1 then
			--local preScale = spr.Scale/1
			--spr.Scale = spr.Scale * Scale
			--spr:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1)))
			fent.Flayer.RenderRightHandSprite()
			--spr.Scale = preScale
		--else
			--spr:Render(RenderPos)
			--fent.Flayer.RenderRightHandSprite()
		--end
	end
end)
Isaac_Tower.FlayerMovementState["Захватил"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	if fent.StateFrame == 1 then
		spr:Play("holding_appear",true)
		--Flayer.Queue = "holding_idle"
	end
	
	if player.ControlsEnabled and not spr:IsPlaying("holding_appear") then
		
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if rot<0 then --Inp.PressLeft(idx)>0 then
			fent.RunSpeed = Inp.PressLeft(idx)*-4
			rot = -4
		elseif rot>0 then --Inp.PressRight(idx)>0 then
			fent.RunSpeed = Inp.PressRight(idx)*4
			rot = 4
		else
			fent.RunSpeed = 0
		end

		Isaac_Tower.MovementHandlers.JumpHandler(fent, -6, 15, 15)
		--if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
		--	return
		--end
		if Inp.PressGrab(idx) and fent.GrabDelay <= 0 and not fent.GrabPressed then
			fent.GrabPressed = true
			SetState(fent, "Захватил ударил")
			spr:Play("kick_hori")
			if rot<0 then
				spr.FlipX = true
			elseif rot>0 then
				spr.FlipX = false
			end
			if Inp.PressUp(idx) then
				fent.PunchRot = Vector(0,-1)
			elseif Inp.PressDown(idx) then
				fent.PunchRot = Vector(0,1)
			--else
			--	fent.PunchRot = Vector(rot,0)
			end
			return
		end
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.001 and spr.FlipX or (fent.Velocity.X < 0)
	if not spr:IsPlaying("holding_appear") then
		if fent.OnGround then
			Isaac_Tower.MovementHandlers.AnimWalk(spr, "holding_move", "holding_idle", fent.Velocity.X)
		else
			if fent.Velocity.Y < 0.0 then
				spr:Play("holding_jump_up")
			else
				spr:Play("holding_jump_down")
			end
		end
	end

	local TargetPos = Vector(0,-50)
	if fent.GrabTarget and fent.GrabTarget:Exists() then
		local tarData = fent.GrabTarget:GetData().Isaac_Tower_Data
		local oldpos = fent.GrabTarget.Position/1
		local extraoffset = Isaac_Tower.MovementHandlers.GetGrabNullOffset 
			and Isaac_Tower.MovementHandlers.GetGrabNullOffset(spr)
		fent.GrabTarget.Position = fent.Position + (extraoffset or TargetPos) + fent.TrueVelocity
		fent.GrabTarget.Velocity = Vector(0,0) --oldpos-fent.GrabTarget.Position  --Vector(0,0)
		fent.GrabTarget.DepthOffset = 110
		--fent.GrabTarget.SpriteOffset = TargetPos
		fent.GrabTarget:GetData().TSJDNHC_GridColl = 0

		if fent.StateFrame%8 == 0 then
			local rot = spr.FlipX and -1 or 1
			local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,Isaac_Tower.ENT.GibSubType.SWEET,fent.Position+Vector(10*rot,-20), Vector(0,0), nil)
			grid.DepthOffset = 310
			grid:GetData().Color = Color(1,1,1,1)

			local rng = RNG()
			rng:SetSeed(grid.InitSeed,35)

			grid.Position = grid.Position + Vector(-rng:RandomInt(10)/1,rng:RandomInt(10)/1) * Vector(rot,1)
			local vec = Vector.FromAngle(rng:RandomInt(91)-45 - 15 or 0):Resized((rng:RandomInt(20)/3+2)) --math.random(15,25)
			vec = Vector(vec.X*rot,vec.Y)
			grid.Velocity = vec + fent.TrueVelocity*2
			
			grid:GetSprite():Load("gfx/effects/sweet.anm2",true)
			grid:GetSprite():Play("drop", true)
			grid:Update()
		end
	else
		SetState(fent, "Ходьба")
		fent.GrabTarget = nil
	end
end
Isaac_Tower.FlayerMovementState["Захватил ударил"] = function(player, fent, spr, idx)
	
	local toReturn = {}
	toReturn.donttransformRunSpeedtoX = true

	if fent.StateFrame < 3 then
		if Inp.PressUp(idx) then
			fent.PunchRot = Vector(0,-1)
		elseif Inp.PressDown(idx) then
			fent.PunchRot = Vector(0,1)
		--else
		--	fent.PunchRot = Vector(rot,0)
		end
	end

	if spr:IsEventTriggered("hit") then
		--fent.GrabTarget.Position = fent.Position + Vector(0,-10)
		fent.GrabTarget:GetData().Isaac_Tower_Data.State  = Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED
		local rot = spr.FlipX and -1 or 1
		fent.GrabTarget.Velocity = fent.PunchRot and (fent.PunchRot:Resized(29)) or Vector(29*rot,0)
		fent.GrabTarget.Position = fent.GrabTarget.Position - fent.GrabTarget.Velocity
		--print(fent.GrabTarget.Velocity, fent.PunchRot,  fent.PunchRot:Resized(29))
		fent.GrabTarget:GetData().Isaac_Tower_Data.GrabbedBy = nil
		fent.GrabTarget:GetData().TSJDNHC_GridColl = 1
		fent.GrabTarget:GetData().Isaac_Tower_Data.CanBreakPoop = true
		fent.GrabTarget:GetData().Isaac_Tower_Data.prePosition = fent.GrabTarget.Position/1
		fent.GrabTarget:GetData().Isaac_Tower_Data.StateFrame = 0
		fent.GrabTarget:Update()
		fent.GrabTarget = nil
		fent.PunchRot = nil

		Isaac_Tower.MovementHandlers.SetForsedVelocity(fent, Vector(-2*rot,-4), 0.5, 30)
		fent.grounding = -1

		spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -26 or 26, -16),
			Vector(fent.TrueVelocity.X, 0), spr.FlipX and 180 or 0,1).Color = Color(1,1,1,0.5)
	elseif not spr:WasEventTriggered("hit") then
		fent.Velocity = fent.Velocity * 0.55
		fent.RunSpeed = fent.RunSpeed * 0.55

		local rot = spr.FlipX and -1 or 1
		local extraoffset = Isaac_Tower.MovementHandlers.GetGrabNullOffset 
			and Isaac_Tower.MovementHandlers.GetGrabNullOffset(spr)
		fent.GrabTarget.Position = fent.Position + (extraoffset and (extraoffset*Vector(rot,1)) or Vector(rot*30,-10))
	end
	if spr:IsFinished(spr:GetAnimation()) then
		fent.GrabDelay = 0
		SetState(fent, "Ходьба")
		Isaac_Tower.HandleMoving(player)
		return
	end
	return toReturn
end

Isaac_Tower.FlayerMovementState["Стомп"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer

	if fent.StateFrame <= 1 then
		fent.Velocity.Y = 0
	end

	if player.ControlsEnabled then
		fent.CanJump = false
		fent.RunSpeed = fent.RunSpeed * 0.9
		fent.Velocity.X = fent.Velocity.X * 0.6

		if spr:IsPlaying("grab_down_appear") then
			fent.Velocity.Y = fent.Velocity.Y * 0.9 + -1.5 * 0.1
		elseif spr:IsPlaying("grab_down_idle") then
			if fent.Velocity.Y<8 then
				fent.Velocity.Y = fent.Velocity.Y * 0.92 + 8.2 * 0.08 --8
			else
				fent.Velocity.Y = fent.Velocity.Y + 1.575/math.abs(fent.Velocity.Y+1)
			end

			fent.OnAttack = true
			if fent.OnGround then
				if not fent.slopeAngle then
					SetState(fent, "Стомп_импакт_пол")
					--fent.NextState = 1
					spr:Play("grab_down_landing")
				else
					if Inp.PressDown(idx) then
						--local power = math.cos(math.rad(fent.slopeAngle+90))
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle) -- * power --(fent.slopeAngle<90 and -1 or 1)
						SetState(fent, "Скольжение_Захват")
						fent.SlideTime = math.min(40, fent.Velocity.Y *5)
					else
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle) * 0.8
						if math.abs(fent.RunSpeed) < 2 then
							SetState(fent, "Стомп_импакт_пол")
							spr:Play("grab_down_landing")
						elseif math.abs(fent.RunSpeed) < 7.4 then
							SetState(fent, "НачалоБега")
						else
							player:SetColor(Color(1,1,1,1,0.5,0.5,0.5),3,1,false,false)
							SetState(fent, "Бег")
						end
					end
				end
			end

			fent.CanBreakPoop = true
			fent.AttackAngle = 90
			if fent.Velocity.Y > 7.4 then
				--local off = Isaac.Spawn(1000, IsaacTower_GibVariant, 100, fent.Position, Vector(0,0), player)
				--off:GetSprite():Load(spr:GetFilename(), true)
				--off:GetSprite():Play(spr:GetAnimation(), true)
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.2*(math.max(1,fent.StateFrame/60))))
				fent.CanBreakMetal = true
				fent.ShowSpeedEffect = 90
			end
		end
	end
end
Isaac_Tower.FlayerMovementState["Супер_прыжок_подготовка"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	if fent.StateFrame <= 1 then
		spr:Play("pre_super_jump_appear")
		spr.FlipX = false
		Flayer.Queue = "pre_super_jump"
	end

	if player.ControlsEnabled and Flayer.Queue == -1 then
		fent.CanJump = false

		if Inp.PressUp(idx) and fent.OnGround then
			local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
			if rot<0 then
				fent.RunSpeed = Inp.PressLeft(idx)*-1.4
				spr:Play("pre_super_jump_left")
			elseif rot>0 then
				fent.RunSpeed = Inp.PressRight(idx)*1.4
				spr:Play("pre_super_jump_right")
			else
				fent.RunSpeed = 0
				spr:Play("pre_super_jump")
			end
			fent.InputWait = nil
		else
			fent.InputWait = fent.InputWait and (fent.InputWait - 1) or 5
			if fent.InputWait and fent.InputWait <= 0 then
				SetState(fent, "Супер_прыжок")
				fent.grounding = 0
				fent.InputWait = nil
			end
		end
		
	end
end
Isaac_Tower.FlayerMovementState["Супер_прыжок"] = function(player, fent, spr, idx)
	local toReturn = {}
	toReturn.donttransformRunSpeedtoX = true
	toReturn.dontLoseY = true
	fent.DontHelpCollisionUpping = true

	if fent.StateFrame <= 1 then
		spr:Play("super_jump")
	end

	fent.Velocity.Y = -7.4
	toReturn.newVel = Vector(0, -7.4)
	fent.grounding = 0
	if fent.CollideCeiling then
		SetState(fent, "Удар_об_потолок")
		fent.RunSpeed = 0
		fent.Velocity = Vector(0,0)
		spr:Play("super_jump_collide")
		fent.Flayer.Queue = "super_jump_fall"
	else
		fent.RunSpeed = 0
		fent.Velocity.X = 0
		fent.CanBreakMetal = true
		fent.CanBreakPoop = true
		fent.AttackAngle = 270
		fent.ShowSpeedEffect = 270

		Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr, -90)
		local sig = spr.FlipX and -1 or 1
		if fent.StateFrame%4 == 0 then
			spawnSpeedEffect(fent.Position+Vector(sig*-15, (fent.StateFrame%24)*2-20):Rotated(sig*(-90)),
				fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
		--if math.abs(fent.RunSpeed) > 10 then
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.Velocity.Y)/20)))), 4/math.abs(fent.Velocity.Y) )
		--end

		if Inp.PressGrab(idx) then
			if Inp.PressRight(idx)>0 then
				SetState(fent, "Супер_прыжок_перенаправление")
				fent.RunSpeed = 7.4
				fent.Velocity.Y = 0
			elseif Inp.PressLeft(idx)>0 then
				SetState(fent, "Супер_прыжок_перенаправление")
				fent.RunSpeed = -7.4
				fent.Velocity.Y = 0
			end
		end
	end
	return toReturn
end
Isaac_Tower.FlayerMovementState["Супер_прыжок_перенаправление"] = function(player, fent, spr, idx)
	local toReturn = {}
	--toReturn.donttransformRunSpeedtoX = true
	--fent.DontHelpCollisionUpping = true

	if fent.StateFrame <= 1 then
		spr.FlipX = fent.RunSpeed < 0
		spr:Play("punch")
	end

	if spr:IsFinished(spr:GetAnimation()) then
		if fent.OnGround then
			SetState(fent, "НачалоБега")
		else
			if not Inp.PressDown(idx) and fent.CollideWall == sign0(fent.RunSpeed) then
				if Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, fent.RunSpeed) then
					spr.Rotation = 0
					spr.Offset = Vector(0,12)

					SetState(fent, "Бег_по_стене")
					fent.CanJump = false
					fent.grounding = 0
					spr:Play("wall_climbing", true)
					return
				elseif (fent.OnGround or fent.CollideWall and (fent.CollideWall ~= sign0(fent.RunSpeed))) then
					SetState(fent, "Остановка_бега")
				end
			elseif (fent.OnGround or fent.CollideWall and (fent.CollideWall ~= sign0(fent.RunSpeed))) then
				SetState(fent, "Остановка_бега")
			else
				fent.OnAttack = true
				fent.CanBreakPoop = true
				fent.CanBreakMetal = true

				fent.ShowSpeedEffect = fent.RunSpeed>0 and 0 or 180

				Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr)
			end
		end
	else
		toReturn.donttransformRunSpeedtoX = true
		toReturn.dontLoseY = true
		fent.DontHelpCollisionUpping = true
	end

	return toReturn
end
Isaac_Tower.FlayerMovementState["Бег_по_стене"] = function(player, fent, spr, idx)
	local toReturn = {}
	if player.ControlsEnabled then
		fent.grounding = 0
		toReturn.donttransformRunSpeedtoX = true
		fent.DontHelpCollisionUpping = true
		fent.Velocity.X = sign(fent.RunSpeed)*3
		--fent.Position.X = fent.Position.X + sign0(fent.RunSpeed) --*1
			
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if (sign0(rot) == sign0(fent.RunSpeed) and Inp.PressRun(idx) or fent.InputWait)  and fent.CollideWall then
			--dontLoseY = true
			--fent.Velocity.X = 0
			fent.Velocity.Y = -math.abs(fent.RunSpeed)*0.95
			fent.CanJump = false
			if math.abs(fent.RunSpeed) > 5.4 then
				fent.RunSpeed = (fent.RunSpeed + 0.075/math.abs(fent.RunSpeed+1)*sign(rot)) 
				fent.CanBreakMetal = true
			else
				fent.RunSpeed = (fent.RunSpeed + 0.028*sign(fent.RunSpeed))
			end

			fent.CanBreakPoop = true
			fent.AttackAngle = 270 + -sign(fent.RunSpeed)*math.abs(fent.RunSpeed/2)

			if not (sign0(rot) == sign0(fent.RunSpeed) and Inp.PressRun(idx)) then
				fent.InputWait = fent.InputWait - 1
				if fent.InputWait <= 0 then
					fent.InputWait = nil
					local runrot = spr.FlipX and -1 or 1
					fent.Position.X = fent.Position.X - sign0(fent.RunSpeed)*5
					fent.Velocity.X = - sign0(fent.RunSpeed)*5
					fent.RunSpeed = 0
					fent.CanJump = true
					SetState(fent, "Ходьба")--fent.State = 1
				end
			end
			if fent.CollideCeiling then
				SetState(fent, "Удар_об_потолок")
				fent.RunSpeed = 0
				fent.Velocity = Vector(0,0)
				spr:Play("super_jump_collide")
				fent.Flayer.Queue = "super_jump_fall"
			end
				
		elseif sign0(rot) == sign0(fent.RunSpeed) and Inp.PressRun(idx) or fent.InputWait then
			fent.Velocity.Y = 0
			fent.Velocity.X = -fent.RunSpeed
			SetState(fent, "НачалоБега")--fent.State = 3
			fent.CanJump = true
			fent.InputWait = nil
			Isaac_Tower.HandleMoving(player) --player:Update()
			return
		else
			if not fent.InputWait then
				fent.InputWait = 10
			elseif fent.InputWait > 0 then
				fent.InputWait = fent.InputWait - 1
			else
				fent.InputWait = nil
				local runrot = spr.FlipX and -1 or 1
				fent.Position.X = fent.Position.X - sign0(fent.RunSpeed)*5
				fent.Velocity.X = - sign0(fent.RunSpeed)*5
				fent.RunSpeed = 0
				fent.CanJump = true
				SetState(fent, "Ходьба")--fent.State = 1
			end
		end

		if math.abs(fent.RunSpeed) > 5.4 then
			fent.OnAttack = true
			fent.CanBreakMetal = true
			--fent.AttackAngle = 270 
			fent.ShowSpeedEffect = 270
		end
		
		--if fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
		--	spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-16),
		--		fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		--end
		--if math.abs(fent.RunSpeed) > 10 then
		--	SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50)))), 4/math.abs(fent.RunSpeed) )
		--end
		Isaac_Tower.MovementHandlers.SpeedEffects(fent, spr, -90)

		if Inp.PressJump(idx, fent) and not fent.JumpActive and fent.JumpPressed < 15 then
			--local runrot = spr.FlipX and -1 or 1
			fent.IgnoreWallRot = sign0(fent.RunSpeed)
			fent.IgnoreWallTime = 5
			fent.Position.X = fent.Position.X - sign0(fent.RunSpeed)*10
			fent.Velocity.X = -fent.RunSpeed
			fent.Velocity.Y = -6
			SetState(fent, "НачалоБега")--fent.State = 2
			fent.CanJump = true
			fent.RunSpeed =  -fent.RunSpeed
			fent.JumpPressed = 0
			fent.JumpActive = 15

			fent.InputWait = nil

			local puf = spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 26 or -26, -16), 
				Vector(-0, 0), spr.FlipX and 0 or 0,1) --fent.RunSpeed
			puf.Color = Color(1,1,1,0.5)
			puf.SpriteScale = Vector(math.min(1,fent.RunSpeed/20), math.min(1,fent.RunSpeed/20))
		end

		if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
			return
		end
	end

	return toReturn
end
--[[Isaac_Tower.FlayerMovementState["Бег_смена_направления"] = function(player, fent, spr, idx)
	local toReturn = {}
	fent.CanJump = false
	if spr:GetAnimation() ~= "run_change_dir" then
		spr:Play("run_change_dir", true)
	end
		
	fent.RunSpeed = fent.RunSpeed - sign0(fent.RunSpeed)*0.14    --fent.RunSpeed*0.90
	toReturn.newVel = Vector(fent.RunSpeed,0)

	if player.FrameCount%2 == 0 then
		local vec = Vector(-fent.NewRotate,0)
		spawnDust(fent.Position+Vector(0,16)+vec*4, vec*12)
	end
	if spr:IsFinished("run_change_dir") and fent.OnGround then
		spr:Play("run", true)
		SetState(fent, "Бег")--fent.State = 3
		fent.RunSpeed = 7.4 * fent.NewRotate
		fent.IgnoreSpeedCheck = true
		fent.CanJump = true
	end
end]]
Isaac_Tower.FlayerMovementState["Остановка_бега"] = function(player, fent, spr, idx)
	fent.CanJump = false
	if spr:GetAnimation() ~= "stopping_run" then
		spr:Play("stopping_run", true)
		spr.Rotation = 0
		spr.Offset = Vector(0,12)
	end
	--fent.RunSpeed = fent.RunSpeed - sign0(fent.RunSpeed)*0.17
	fent.RunSpeed = fent.RunSpeed<0 and math.min(0,fent.RunSpeed+0.14)
		or math.max(0, fent.RunSpeed-0.14)
	fent.RunSpeed = fent.RunSpeed*0.9
	if fent.RunSpeed == 0 then --spr:IsFinished("stopping_run") then
		SetState(fent, "Ходьба")--fent.State = 1
	end
end
Isaac_Tower.FlayerMovementState["Стомп_импакт_пол"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	local toReturn = {}
	fent.CanJump = false
	toReturn.donttransformRunSpeedtoX = true
	fent.RunSpeed = 0
	fent.Velocity = Vector(0,0)
	if spr:IsFinished(spr:GetAnimation()) and Flayer.Queue == -1 then
		if fent.NextState then
			SetState(fent, fent.NextState)
		else
			SetState(fent, "Ходьба")
		end
	end
	return toReturn
end
Isaac_Tower.FlayerMovementState["Удар_об_потолок"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	local toReturn = {}
	fent.CanJump = false
	toReturn.donttransformRunSpeedtoX = true
	--toReturn.dontLoseY = true
	--fent.RunSpeed = 0
	--fent.Velocity = Vector(0,0)

	if spr:GetAnimation() ~= "super_jump_fall" then
		toReturn.dontLoseY = true
		fent.RunSpeed = 0
		fent.Velocity = Vector(0,0)
	end

	if player.ControlsEnabled then
		if spr:GetAnimation() == "super_jump_fall" then
			toReturn.dontLoseY = nil
			toReturn.donttransformRunSpeedtoX = nil
			local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
			local targetVel = 0
			if rot<0 then --Inp.PressLeft(idx)>0 then
				targetVel = Inp.PressLeft(idx)*-4
			elseif rot>0 then --Inp.PressRight(idx)>0 then
				targetVel = Inp.PressRight(idx)*4
			end
			--fent.Velocity.X = fent.Velocity.X * 0.9 + targetVel * 0.1 fent.RunSpeed
			fent.RunSpeed = fent.RunSpeed * 0.9 + targetVel * 0.1
			
			if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
				return
			end
		end
		if fent.OnGround then
			SetState(fent, "Стомп_импакт_пол")
			spr:Play("super_jump_landing", true)
		end
	end
	

	--[[if spr:IsFinished(spr:GetAnimation()) and Flayer.Queue == -1 then
		if fent.NextState then
			SetState(fent, fent.NextState)
		else
			SetState(fent, "Ходьба")
		end
	end]]
	return toReturn
end



function Isaac_Tower.HandleMoving(player)
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	
	player = player:ToPlayer() or player
	local idx = player.ControllerIndex
	local fent = player:GetData().TSJDNHC_FakePlayer
	local spr = player:GetData().TSJDNHC_FakePlayer.Flayer and player:GetData().TSJDNHC_FakePlayer.Flayer.Sprite
	local Flayer = player:GetData().TSJDNHC_FakePlayer.Flayer and player:GetData().TSJDNHC_FakePlayer.Flayer --Flayer.Queue

	local newVel = Vector(0,0)
	fent.GrabDelay = fent.GrabDelay or 0
	fent.RunSpeed = fent.RunSpeed or 0

	local dontLoseY
	local donttransformRunSpeedtoX
	fent.OnAttack = false
	fent.CanBreakPoop = false
	fent.CanBreakMetal = false
	fent.CanJump = true
	fent.AttackAngle = nil
	fent.DontHelpCollisionUpping = nil
	fent.ShowSpeedEffect = nil
	

	fent.Half = fent.DefaultHalf/1 --Vector(15,20)
	fent.CollisionOffset = Vector(0,0)
	fent.ControllerIndex = idx
	
	
	if player.ControlsEnabled then
		local presedMov

		::Moving::

		local result
		if Isaac_Tower.FlayerMovementState[fent.State] then
			result = Isaac_Tower.FlayerMovementState[fent.State](player, fent, spr, idx)
		else
			fent.State = "Ходьба"
		end
		if type(result) == "table" then
			newVel = result.newVel or newVel
			donttransformRunSpeedtoX = result.donttransformRunSpeedtoX
			dontLoseY = result.dontLoseY
		end
		--newVel.X = newVel.X + fent.RunSpeed
		
	end
	--print(spr:GetAnimation(), Flayer.Queue)
	if fent.StateFrame then
		fent.StateFrame = fent.StateFrame + 1
	end

	if Inp.PressJump(idx, fent) then
		fent.JumpPressed = math.max(0, fent.JumpPressed + 1)
	elseif not Inp.PressJump(idx, fent) then
		fent.JumpActive = nil
		fent.JumpPressed = 0
	end

	if not Inp.PressGrab(idx) and fent.GrabDelay <= 0 then
		fent.GrabPressed = false	
	end

	if fent.IgnoreWallTime then
		if fent.IgnoreWallTime > 0 then
			fent.IgnoreWallTime = fent.IgnoreWallTime - 1 
		else
			fent.IgnoreWallTime = nil
			fent.IgnoreWallRot = nil
		end
	end
	
	if not dontLoseY then
		if fent.OnGround then
			fent.Velocity.Y =  math.min(0,fent.Velocity.Y)
			--newVel.Y = math.min(0,fent.Velocity.Y)
		end
		--fent.Velocity.Y = fent.Velocity.Y < 6 and fent.Velocity.Y + 0.4 or fent.Velocity.Y
		newVel.Y = fent.Velocity.Y < 6 and fent.Velocity.Y + 0.4 or fent.Velocity.Y
	end

	if not donttransformRunSpeedtoX then
		--fent.Velocity.X = fent.Velocity.X*0.4 + fent.RunSpeed*0.6   --0.4   0.6 
		newVel.X = fent.Velocity.X*0.4 + fent.RunSpeed*0.6
	else
		newVel.X = fent.Velocity.X
	end

	--fent.ForsedVelocity
	--fent.ForsedVelocityPower
	--fent.ForsedVelocityTime
	--fent.ForsedVelocitynoGrav
	if fent.ForsedVelocity then
		local forvel = fent.ForsedVelocity.Velocity
		if not fent.ForsedVelocity.noGrav then
			forvel = Vector(fent.ForsedVelocity.Velocity.X, math.max(-6, fent.ForsedVelocity.Velocity.Y))
		end
		fent.Velocity = fent.Velocity*0.85 + forvel * 0.15 + newVel * (0.15 * fent.ForsedVelocity.Lerp)
		fent.ForsedVelocity.Time = fent.ForsedVelocity.Time - 1
		
		if not fent.ForsedVelocity.noGrav then
			if fent.OnGround then
				fent.ForsedVelocity.Velocity.Y = math.min(0, fent.ForsedVelocity.Velocity.Y)
				fent.ForsedVelocity.Velocity.X = fent.ForsedVelocity.Velocity.X * 0.8
			else
				fent.ForsedVelocity.Velocity.Y = fent.ForsedVelocity.Velocity.Y < 6 and (fent.ForsedVelocity.Velocity.Y + 0.4) or fent.ForsedVelocity.Velocity.Y
			end
		end
		if fent.ForsedVelocity.MaxTime < fent.ForsedVelocity.Time*0.66 then
			fent.ForsedVelocity.Lerp = fent.ForsedVelocity.Lerp*0.7 + 0.3
		else
			local ler = 1/(fent.ForsedVelocity.MaxTime*0.66)
			fent.ForsedVelocity.Lerp = fent.ForsedVelocity.Lerp * (1-ler)
		end
		if fent.ForsedVelocity.Time <= 0 then
			fent.ForsedVelocity = nil
		end
	else
		fent.Velocity = newVel
	end

	fent.Velocity.X = math.abs(fent.Velocity.X)>0.01 and fent.Velocity.X or 0
	fent.Velocity.Y = math.abs(fent.Velocity.Y)>0.001 and fent.Velocity.Y or 0

	fent.RunSpeed = fent.RunSpeed<0 and math.min(fent.RunSpeed,fent.Velocity.X)
		or math.max(fent.RunSpeed, fent.Velocity.X)
	fent.RunSpeed = math.abs(fent.RunSpeed)>0.001 and fent.RunSpeed or 0

	fent.GrabDelay = fent.GrabDelay>0 and (fent.GrabDelay - 1) or fent.GrabDelay
	
	if spr then
		
		if Flayer and Flayer.Queue ~= -1 and spr:IsFinished(spr:GetAnimation()) then
			spr:Play(Flayer.Queue, true)
			Flayer.Queue = -1
		end

		spr:Update()
		fent.Flayer.SpeedEffectSprite:Update()
	end
end

------------------------------------------
--[[local Vector2 = {}

function Vector2.Length(vec)
	if not vec then error("[1] is not a Vector", 2) end
	return math.sqrt( vec.X*vec.X + vec.Y*vec.Y )
end

function Vector2.Distance(vec1,vec2)
	if not vec1 then error("[1] is not a Vector", 2) end
	if not vec2 then error("[2] is not a Vector", 2) end
	local ofVec = vec2 - vec1
	return math.sqrt( ofVec.X*ofVec.X + ofVec.Y*ofVec.Y )
end

function Vector2.Normalized(vec)
	if not vec then error("[1] is not a Vector", 2) end
	local dis = Vector2.Length(vec)
	return vec/dis
end

function Vector2.Resised(vec, num)
	if not vec then error("[1] is not a Vector", 2) end
	local dis = Vector2.Length(vec)
	return vec/dis*num
end]]


end


