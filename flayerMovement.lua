return function(mod) --, Isaac_Tower)

	
local Isaac = Isaac
local Isaac_Tower = Isaac_Tower

local function GenSprite(gfx, anim, frame)
	if gfx then
		local spr = Sprite()
		spr:Load(gfx, true)
		if anim then
			spr:Play(anim)
		else
			spr:Play(spr:GetDefaultAnimation())
		end
		if frame then
			spr:SetFrame(frame)
		end
		return spr
	end
end


Isaac_Tower.FlayerHandlers.WalkSpeed = 6
Isaac_Tower.FlayerHandlers.FallAccel = 0.4
Isaac_Tower.FlayerHandlers.FallMaxSpeed = 7
Isaac_Tower.FlayerHandlers.GrabSpeed = 7
Isaac_Tower.FlayerHandlers.RunSpeed = 8.  --7.4 --5.4
Isaac_Tower.FlayerHandlers.RunSpeed2 = 8.
Isaac_Tower.FlayerHandlers.RunSpeed3 = 9.5
Isaac_Tower.FlayerHandlers.Accel = 0.065 -- 0.035
Isaac_Tower.FlayerHandlers.Accel2 = 0.09
Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed = 10. -- 7.4
Isaac_Tower.FlayerHandlers.SuperJumpSpeed = 8

local handler = Isaac_Tower.FlayerHandlers

local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')

handler.FlayerState = {
	--[["Ходьба"
	|"Бег"
	|"Аперкот-не-кот"
	|"Бег_по_стене"
	|"Бег_смена_направления"
	|"Захват"
	|"Захватил ударил"
	|"Захватил"
	|"НачалоБега"
	|"Остановка_бега"
	|"Присел"
	|"Скольжение"
	|"Скольжение_Захват"
	|"Стомп"
	|"Стомп_импакт_пол"
	|"Супер_прыжок"
	|"Супер_прыжок_перенаправление"
	|"Супер_прыжок_подготовка"
	|"Удар_об_потолок"
	|"Урон"
	|"Cutscene"
	|"Впечатался"]]
}

do
	handler.PlayerAnimManager = { names = {}, anm2 = {}, AnimMap = {}, rightHand = {} }
	
	local manager = handler.PlayerAnimManager

	---@param anm2 string
	---@param animationMap string[] --Dont work with repentogon
	---@param RightHandGfx string|string[]?
	function manager.AddFile(name, anm2, animationMap, RightHandGfx)
		if anm2 and not manager.anm2[anm2] then
			manager.anm2[anm2] = name
			manager.names[name] = anm2
			if RightHandGfx then
				manager.rightHand[name] = RightHandGfx
			end
		end
		if manager.anm2[anm2] then
			if not REPENTOGON then
				for i,k in pairs(animationMap) do
					manager.AnimMap[k] = anm2
				end
			else
				local spr = GenSprite(anm2)
				for i,k in pairs(spr:GetAllAnimationData()) do
					manager.AnimMap[k:GetName()] = anm2
				end
			end
		end
	end

	---@return Sprite, Sprite -- Mainspr, RightHandSpr
	function manager.GetSpriteByName(name)
		local spr, righthand
		local categ = manager.names[name] or manager.anm2[name] and name
		if categ then
			spr = GenSprite(categ)
		
			if manager.rightHand[name] then
				---@type string|string[]?
				local gfx = manager.rightHand[name]
				if gfx == true and REPENTOGON then
					righthand = GenSprite(categ)
					local list = spr:GetAllLayers()
					for i = 0, #list do
						local layer = list[i]
						---@type string
						local gfxname = layer:GetSpritesheetPath()
						gfxname = string.sub(gfxname, utf8.len(gfxname)-4)
						righthand:ReplaceSpritesheet(i, gfxname)
					end
					righthand:LoadGraphics()
				else
					local istab = type(gfx) == "table"
					righthand = GenSprite(categ)
					for i=1, righthand:GetLayerCount() do
						righthand:ReplaceSpritesheet(i-1, istab and gfx[i] or gfx)
					end
					righthand:LoadGraphics()
				end
			end
		end
		return spr, righthand
	end

	manager.MetaSpr = {}
	manager.MetaSpr.meta = {}
	---@class Player_AnimManager
	manager.MetaSpr.spr = {}
	
	manager.MetaSpr.meta.__index = manager.MetaSpr.spr
	do
		local manspr = manager.MetaSpr.spr
		local anm2Table = manager.anm2
		local AnimMap = manager.AnimMap
		local names = manager.names

		function manager.MetaSpr.spr.GetSprite(self)
			return self.CurrentSpr
		end

		function manager.MetaSpr.spr.Play(self, anim, force)
			local replace = self.ReplaceOnce
			if replace and replace.T == anim then
				anim = replace.R
			end
			local anm2 = AnimMap[anim]
			if anm2 and self.CurrentAnm2 ~= anm2 then
				local name = anm2Table[anm2]
				if not self.Sprs[name] then
					self.Sprs[name], self.RightHandSprs[name] = manager.GetSpriteByName(name)
				end
				self.Sprs[name]:Play(anim)
				self.CurrentSpr = self.Sprs[name]
				self.CurrentRHSpr = self.RightHandSprs[name] or self.CurrentRHSpr
				self.CurrentAnm2 = anm2
			else
				self.CurrentSpr:Play(anim)
			end
		end

		function manager.MetaSpr.spr.SetAnimation(self, anim, reset)
			local replace = self.ReplaceOnce
			if replace and replace.T == anim then
				anim = replace.R
			end
			local anm2 = AnimMap[anim]
			local frame = self.CurrentSpr:GetFrame()
			if anm2 and self.CurrentAnm2 ~= anm2 then
				local name = anm2Table[anm2]
				if not self.Sprs[name] then
					self.Sprs[name], self.RightHandSprs[name] = manager.GetSpriteByName(name)
				end
				self.Sprs[name]:Play(anim)
				self.CurrentSpr = self.Sprs
				self.CurrentRHSpr = self.RightHandSprs[name] or self.CurrentRHSpr
				self.CurrentAnm2 = anm2
				if not reset then
					self.CurrentSpr:SetFrame(frame)
				end
			else
				self.CurrentSpr:Play(anim)
			end
		end

		function manager.MetaSpr.spr.PlayOverlay (self, ...)
			return self.CurrentSpr:PlayOverlay (...)
		end

		function manager.MetaSpr.spr.Render(self, ...)
			return self.CurrentSpr:Render(...)
		end

		function manager.MetaSpr.spr.RenderLayer(self, ...)
			return self.CurrentSpr:RenderLayer(...)
		end

		function manager.MetaSpr.spr.GetAnimation(self)
			return self.CurrentSpr:GetAnimation()
		end

		function manager.MetaSpr.spr.GetDefaultAnimation(self)
			return self.CurrentSpr:GetDefaultAnimation()
		end

		function manager.MetaSpr.spr.GetFilename(self)
			return self.CurrentSpr:GetFilename()
		end

		function manager.MetaSpr.spr.GetFrame(self, ...)
			return self.CurrentSpr:GetFrame(...)
		end

		function manager.MetaSpr.spr.GetOverlayAnimation(self)
			return self.CurrentSpr:GetOverlayAnimation()
		end

		function manager.MetaSpr.spr.GetOverlayFrame(self)
			return self.CurrentSpr:GetOverlayFrame()
		end

		function manager.MetaSpr.spr.IsPlaying(self, anim, ...)
			local replace = self.ReplaceOnce
			if replace and replace.T == anim then
				anim = replace.R
			end
			return self.CurrentSpr:IsPlaying(anim, ...)
		end

		function manager.MetaSpr.spr.IsEventTriggered(self, ...)
			return self.CurrentSpr:IsEventTriggered(...)
		end

		function manager.MetaSpr.spr.IsFinished(self, anim, ...)
			local replace = self.ReplaceOnce
			if replace and replace.T == anim then
				anim = replace.R
			end
			return self.CurrentSpr:IsFinished(anim, ...)
		end

		function manager.MetaSpr.spr.IsOverlayFinished(self, ...)
			return self.CurrentSpr:IsOverlayFinished(...)
		end

		function manager.MetaSpr.spr.IsOverlayPlaying(self, ...)
			return self.CurrentSpr:IsOverlayPlaying(...)
		end

		function manager.MetaSpr.spr.RemoveOverlay(self, ...)
			return self.CurrentSpr:RemoveOverlay(...)
		end

		function manager.MetaSpr.spr.SetFrame(self, frame, isActualeFrame, ...)
			if type(frame) == "string" then
				manspr.Play(self, frame, true)
				self.CurrentSpr:SetFrame(isActualeFrame)
			else
				self.CurrentSpr:SetFrame(frame, ...)
			end
		end

		function manager.MetaSpr.spr.SetLastFrame(self, ...)
			return self.CurrentSpr:SetLastFrame(...)
		end

		function manager.MetaSpr.spr.SetOverlayFrame(self, ...)
			return self.CurrentSpr:SetOverlayFrame(...)
		end

		function manager.MetaSpr.spr.SetOverlayRenderPriority(self, ...)
			self.CurrentSpr:SetOverlayRenderPriority(...)
		end

		function manager.MetaSpr.spr.Stop(self, ...)
			self.CurrentSpr:Stop(...)
		end

		function manager.MetaSpr.spr.Update(self, ...)
			self.CurrentSpr:Update(...)
			if self.CurrentRHSpr then
				self.CurrentRHSpr:SetFrame(self.CurrentRHSpr:GetFrame())
				if not self.RightHandSprs[anm2Table[self.CurrentAnm2]] then
					self.CurrentRHSpr = nil
				end
			end
		end

		function manager.MetaSpr.spr.WasEventTriggered(self, ...)
			return self.CurrentSpr:WasEventTriggered(...)
		end

		function manager.MetaSpr.spr.GetNullFrame(self, ...)
			return self.CurrentSpr:GetNullFrame(...)
		end

		function manager.MetaSpr.spr.SetQueue(self, anim, priority)
			if not self.QueuePrior then
				self.Queue = anim
				self.QueuePrior = priority
			elseif self.QueuePrior <= priority then
				self.Queue = anim
				self.QueuePrior = priority
			end
		end

		function manager.MetaSpr.spr.ClearQueue(self)
			self.Queue = -1
			self.QueuePrior = nil
		end

		function manager.MetaSpr.spr.ReplaceAnimOnce(self, target, replace)
			self.ReplaceOnce = {T = target, R = replace}
		end





		function manager.MetaSpr.spr.UpdateParam(self)
			local curSpr = self.CurrentSpr
			curSpr.Scale = self.Scale
			curSpr.Color = self.Color
			curSpr.FlipX = self.FlipX
			curSpr.FlipY = self.FlipY
			curSpr.Offset = self.Offset
			curSpr.Rotation = self.Rotation
		end
	end

	---@return Player_AnimManager
	function manager.GenPlayerMetaSprite(fent)
		---@type Player_AnimManager
		local tab = {
			CurrentSpr = nil, CurrentAnm2 = nil,
			Sprs = {}, --{main = Sprite(), grab = Sprite()},
			Queue = -1,
			SpeedEffectSprite = Sprite(),
			RightHandSprs = {},
			DefaultOffset = Vector(0,12),
			Shadow = Sprite(),
			Scale = Vector(1,1), Color = Color(1,1,1,1), FlipX = false, FlipY = false, Offset = Vector(0,12), Rotation = 0,
		}
		setmetatable(tab, manager.MetaSpr.meta)
		
		tab.Sprs.main, tab.RightHandSprs.main = manager.GetSpriteByName("main")    --:Load(manager.GetAnm2("main"), true)
		tab.Sprs.main.Offset = Vector(0,12)
		if tab.RightHandSprs.main then
			tab.RightHandSprs.main.Offset = Vector(0,12)
		end

		tab.Sprs.grab, tab.RightHandSprs.grab = manager.GetSpriteByName("grab") --:Load(tab.GetAnm2("grab"), true)
		tab.Sprs.grab.Offset = Vector(0,12)
		tab.RightHandSprs.grab.Offset = Vector(0,12)

		tab.SpeedEffectSprite:Load("gfx/fakePlayer/speedEffect.anm2", true)
		tab.SpeedEffectSprite:Play("effect")

		tab.Shadow = GenSprite("gfx/fakePlayer/flayer_shadow.anm2","shadow")
		tab.Shadow.Color = Color(1,1,1,2)

		tab.CurrentSpr = tab.Sprs.main
		tab.CurrentAnm2 = tab.Sprs.main:GetFilename()
		tab.CurrentRHSpr = tab.RightHandSprs.main

		return tab
	end






end





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
	eff:GetSprite():Load("gfx/effects/it_spedd_effects.anm2", true)
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

---@param state "Ходьба"|"Бег"|"Аперкот-не-кот"|"Бег_по_стене"|"Бег_смена_направления"|"Захват"|"Захватил ударил"|"Захватил"|"НачалоБега"|"Остановка_бега"|"Присел"|"Скольжение"|"Скольжение_Захват"|"Стомп"|"Стомп_импакт_пол"|"Супер_прыжок"|"Супер_прыжок_перенаправление"|"Супер_прыжок_подготовка"|"Удар_об_потолок"|"Урон"|"Cutscene"|"Впечатался"|"стомп_в_беге"
local function SetState(fent, state)
	fent.PreviousState = fent.State
	fent.State = state
	fent.StateFrame = 0
	fent.InputWait = nil

	local auto = fent.AutoCleanKeys
	if auto and #auto>0 then
		for i=1, #auto do
			fent[auto[i]] = nil
		end
	end
end

local function CleanOnStateChange(fent, key)
	fent.AutoCleanKeys = fent.AutoCleanKeys or {}
	fent.AutoCleanKeys[#fent.AutoCleanKeys+1] = key
end

local function CheckCanUp(ent)
	local result = true
	local d = ent:GetData()
	local fent = d.Isaac_Tower_Data

	local half = fent.Half/1
	local offset = fent.CollisionOffset/1

	fent.Half = fent.DefaultHalf --Vector(15,20)
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
		--ret = Input.IsActionPressed(ButtonAction.ACTION_ITEM, idx)
		ret = Input.IsButtonPressed(Keyboard.KEY_V, idx)
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

function Inp.PressRightOnce(idx)
	
	if idx == 0 then
		return Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_RIGHT, idx)
	end
end
function Inp.PressLeftOnce(idx)
	if idx == 0 then
		return Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_LEFT, idx)
	end
end
function Inp.PressDownOnce(idx)
	if idx == 0 then
		return Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_DOWN, idx)
	end
end
function Inp.PressUpOnce(idx)
	if idx == 0 then
		return Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_UP, idx)
	end
end
function Inp.PressRunOnce(idx)
	if idx == 0 then
		return Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_DROP, idx) --ACTION_MENURT
	end
end
function Inp.PressJumpOnce(idx, fent)
	local ret
	if idx == 0 then
		ret = Input.IsButtonPressed(Keyboard.KEY_V, idx)
	else
		ret = Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM, idx)
	end
	if ret and not fent.OnGround then
		fent.PreJumpPressed = 5
	end
	return ret
end
function Inp.PressGrabOnce(idx)
	if idx == 0 then
		return Input.IsButtonPressed(Keyboard.KEY_S, idx)
	else
		return Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, idx)
	end
end

Isaac_Tower.Input = Inp

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

--Isaac_Tower.FlayerHandlers = {}

function Isaac_Tower.FlayerHandlers.AnimWalk(spr, Walkanim, idleAnim, vel)
	if math.abs(vel) < 0.1 then
		spr:Play(idleAnim)
	else
		spr:Play(Walkanim)
	end
end

---@param fent Flayer
---@param Upspeed number
---@param PressTime integer
---@param ActiveTime integer
function Isaac_Tower.FlayerHandlers.JumpHandler(fent, Upspeed, PressTime, ActiveTime)
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

function Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, rot)
	if rot == nil then error("[2] is not a number",2) end
	return (not fent.OnGround or fent.slopeAngle)
		--and sign0(rot) == sign0(fent.CollideWall) 
		and (not fent.IgnoreWallRot or fent.IgnoreWallRot ~= fent.CollideWall)
end


local walkRunState = {[1] = true,[2] = true,[3] = true}
local notWallClambingState = {[1]=true, [5] = true,[40] = true} --[1] = true,

---@param fent Flayer
---@return boolean?
function Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr)
	local idx = fent.ControllerIndex
	--local spr = fent.Flayer.Sprite
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
					spr.Offset = fent.Flayer.DefaultOffset
						
					if fent.Velocity.Y < 0 then
						fent.Velocity.Y = math.max(-5,fent.Velocity.Y * 2)
					end
					fent.AttackAngle = nil
					fent.UnStickWallTime = nil
					fent.UnStickWallMaxTime = nil
					fent.UnStickWallVel = nil

					return --break
				end
			end
		else
			--[[if Inp.PressDown(idx) and not fent.OnGround then
				SetState(fent, "Стомп")
				spr:Play("grab_down_appear",true)
				Flayer.Queue = "grab_down_idle"
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset
				fent.Velocity.Y = math.min(-1, fent.Velocity.Y)
				return true
			else]]
			if Inp.PressUp(idx) and not fent.UseApperkot then
				SetState(fent, "Аперкот-не-кот")
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset
			else
				SetState(fent, "Захват")--fent.State = 20
				if Inp.PressLeft(idx)>0 then
					fent.RunSpeed = math.min(-Isaac_Tower.FlayerHandlers.GrabSpeed, fent.RunSpeed)
				elseif Inp.PressRight(idx)>0 then
					fent.RunSpeed = math.max(Isaac_Tower.FlayerHandlers.GrabSpeed, fent.RunSpeed)
				else
					fent.RunSpeed = spr.FlipX and -Isaac_Tower.FlayerHandlers.GrabSpeed or Isaac_Tower.FlayerHandlers.GrabSpeed
				end
				spr:Play("grab",true)
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset

				if fent.Velocity.Y < 0 then
					fent.Velocity.Y = math.max(-5,fent.Velocity.Y * 2)
				end

				fent.UnStickWallTime = nil
				fent.UnStickWallMaxTime = nil
				fent.UnStickWallVel = nil
				return
			end
		end
	elseif not Inp.PressGrab(idx) and fent.GrabDelay <= 0 then
		fent.GrabPressed = false	
	end
end

---@param fent Flayer
---@param spr Player_AnimManager
---@return boolean?
function Isaac_Tower.FlayerHandlers.StompHandler(fent, spr, idx)
	idx = idx or fent.ControllerIndex
	if Inp.PressDownOnce(idx) and not fent.OnGround then
		SetState(fent, "Стомп")
		spr:Play("grab_down_appear",true)
		--Flayer.Queue = "grab_down_idle"
		spr:SetQueue("grab_down_idle", 0)
		spr.Rotation = 0
		spr.Offset = fent.Flayer.DefaultOffset
		fent.Velocity.Y = -6 -- math.min(-3, fent.Velocity.Y)
		return true
	end
end


function Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr, angle)
	if fent then
		local sig = spr.FlipX and -1 or 1
		if fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
			spawnSpeedEffect(fent.Position+Vector(sig*-15, (fent.StateFrame%24)*2-20):Rotated(sig*(angle or spr.Rotation)),
				fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
		if math.abs(fent.RunSpeed) > 10 then
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50))))) --, 4/math.abs(fent.RunSpeed) )
		end
	end
end


function Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, vel, power, time, noGrav)
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

---@param fent any
---@param Damage integer
---@param Flags integer
---@param Source Entity|Vector
---@param DamageCountdown integer
function Isaac_Tower.FlayerHandlers.TryTakeDamage(fent, Damage, Flags, Source, DamageCountdown)
	if not fent then error("expected Flayer on position [1]",2) end
	if type(Damage) ~= "number" then error("[2] is not a number",2) end
	if not Source then error("[4] is not a Entity or a Vector",2) end
	Flags = Flags or 0
	DamageCountdown = DamageCountdown or 120

	if fent.InvulnerabilityFrames and fent.InvulnerabilityFrames > 0 then return false end

	SetState(fent, "Урон")
	fent.DamageSource = Source
	fent.InvulnerabilityFrames = DamageCountdown
	fent.Velocity = Vector(0,0)
	fent.RunSpeed = 0
	fent.Flayer.Rotation = 0
	fent.Flayer.Offset = fent.Flayer.DefaultOffset

	if Isaac_Tower.ScoreHandler.Active then
		Isaac_Tower.ScoreHandler.AddScore(-50)
	end
	return true
end

function Isaac_Tower.FlayerHandlers.LiftEnemiesInRadius(pos, power, radius)
	radius = radius or 400
	local ents = Isaac_Tower.EnemyHandlers.GetRoomEnemies()
	--if #ents>0 then
		for i=1,#ents do
			local ent = ents[i]
			local edat = ent:GetData().Isaac_Tower_Data
			if edat.OnGround and edat.Position:Distance(pos) < radius then
				edat.Velocity = Vector(edat.Velocity.X, edat.Velocity.Y-power)
			end
		end
	--end
end

local walkanim = {walk = true, walk_jump_down = true}

Isaac_Tower.FlayerMovementState = {}
Isaac_Tower.FlayerMovementState["Ходьба"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		fent.CanJump = true
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if fent.StateFrame == 1 and fent.OnGround and math.abs(fent.Velocity.X) > 0.2 
		and Inp.PressRun(idx) and sign(rot) == sign(fent.Velocity.X) then
			SetState(fent,"НачалоБега")
			Isaac_Tower.HandleMoving(player) --player:Update()
			return
		end

		if rot<0 then --Inp.PressLeft(idx)>0 then
			fent.RunSpeed = fent.RunSpeed * .75 + (Inp.PressLeft(idx)*-4) * .25
			rot = -Isaac_Tower.FlayerHandlers.WalkSpeed --4
			fent.PressMoveInLastFrame = true
		elseif rot>0 then --Inp.PressRight(idx)>0 then
			fent.RunSpeed = fent.RunSpeed * .75 + (Inp.PressRight(idx)*4) * .25
			rot = Isaac_Tower.FlayerHandlers.WalkSpeed --4
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

		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr) then
			return
		elseif Isaac_Tower.FlayerHandlers.StompHandler(fent, spr, idx) then
			return
		end
	end
	
	local WalkFlyReplace = fent.WalkFlyReplace
	if not WalkFlyReplace and fent.PressMoveInLastFrame then
		spr.FlipX = math.abs(fent.RunSpeed) < 0.001 and spr.FlipX or (fent.RunSpeed < 0)
	end
	if fent.OnGround then
		Isaac_Tower.FlayerHandlers.AnimWalk(spr, "walk", "idle", fent.Velocity.X)
		fent.WalkFlyReplace = nil
	else
		if WalkFlyReplace then
			if spr:GetAnimation() ~= WalkFlyReplace then
				spr:Play(WalkFlyReplace)
			elseif spr:IsFinished(WalkFlyReplace) then
				fent.WalkFlyReplace = nil
			end
			--[[local up, down
			if type(WalkFlyReplace) == "table" then
				up, down = WalkFlyReplace[1], WalkFlyReplace[2]
			else
				up, down = WalkFlyReplace, WalkFlyReplace
			end

			if fent.Velocity.Y < 0.0 then
				spr:Play(up)
			else
				local curanim = spr:GetAnimation()
				if not walkanim[curanim] and curanim ~= "super_jump_fall" then
					spr:Play(down)
					spr:SetFrame(4)
				else
					spr:Play(down)
				end
			end]]
		else
			if fent.Velocity.Y < 0.0 then
				spr:Play("walk_jump_up")
			else
				local curanim = spr:GetAnimation()
				if not walkanim[curanim] and curanim ~= "super_jump_fall" then
					spr:Play("walk_jump_down")
					spr:SetFrame(4)
				else
					spr:Play("walk_jump_down")
				end
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
	local toReturn = {}
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		local press = Inp.PressLeft(idx) + Inp.PressRight(idx) ~= 0
		local nextVel = 0

		if fent.CollideWall and not Inp.PressDown(idx) then --and fent.CollideWall == sign0(rot) then
			
			if Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, rot) then --not fent.OnGround and Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset

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
		--[[elseif not Inp.PressDown(idx) and fent.CollideWall then --and fent.CollideWall ~= sign0(rot) then
			spr:Play("lunge_down_wall")
			fent.Velocity.Y = fent.Velocity.Y*0.9 - 0.0*0.1
			--fent.TempLoseY = fent.TempLoseY and math.min(1,fent.TempLoseY + 0.02) or 0
			Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(fent.RunSpeed,0), fent.TempLoseY, 1, false)
			--if fent.Velocity.Y == 0 
			--or (fent.CollideWall == sign0(-rot) and fent.TempLoseY > 0.6) then
			--	SetState(fent, "Ходьба")
			--	Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(spr.FlipX and 5 or -5,-1), 0.5, 10, false)
			--	fent.RunSpeed = 0
			--end

			if Inp.PressJump(idx, fent) and not fent.JumpActive and fent.JumpPressed < 15 then
				--local runrot = spr.FlipX and -1 or 1
				fent.IgnoreWallRot = sign0(fent.RunSpeed)
				fent.IgnoreWallTime = 5
				fent.Position.X = fent.Position.X - sign0(fent.RunSpeed)*10
				fent.Velocity.X = -fent.RunSpeed
				fent.Velocity.Y = -6
				fent.RunSpeed =  -fent.RunSpeed
				fent.JumpPressed = 0
				fent.JumpActive = 15
	
				fent.InputWait = nil
	
				local puf = spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 26 or -26, -16), 
					Vector(-0, 0), spr.FlipX and 0 or 0,1) --fent.RunSpeed
				puf.Color = Color(1,1,1,0.5)
				puf.SpriteScale = Vector(math.min(1,fent.RunSpeed/20), math.min(1,fent.RunSpeed/20))
			end]]
		--elseif not fent.CollideWall and fent.TempLoseY then
		--	fent.TempLoseY = nil
		--	spr:Play("pre_run")
		elseif fent.CollideWall then
			SetState(fent, "Стомп_импакт_пол")
			spr:Play("lunge_down_wall")
		end
		local curanm = spr:GetAnimation()
		if rot~=0 and fent.OnGround then
			fent.IsLunge = nil
			if math.abs(fent.RunSpeed) < 4 then
				fent.RunSpeed = 4*sign(rot)
			end
			local accel = Isaac_Tower.FlayerHandlers.Accel -- 0.035  --0.028
			if fent.slopeAngle and sign0(-fent.slopeAngle) == rot then
				accel = accel * (1+math.abs(fent.slopeAngle)/45)
			end
			
			nextVel = accel*sign(rot)
			if math.abs(fent.RunSpeed) > Isaac_Tower.FlayerHandlers.RunSpeed then
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
			if curanm ~= "lunge_down_wall" and fent.StateFrame%4 == 0 and math.abs(fent.RunSpeed) > 5 then
				spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 15 or -15, (fent.StateFrame%24)*2-16),
					fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
			end
			if math.abs(fent.RunSpeed) > 10 then
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50))))) --, 4/math.abs(fent.RunSpeed) )
			end
		elseif fent.OnGround then
			fent.RunSpeed = fent.RunSpeed*0.7	
		end
		
		if fent.OnGround and (not press or (nextVel~= 0 and sign(nextVel) ~= sign(fent.RunSpeed))) and math.abs(fent.RunSpeed) > 3 then
			SetState(fent,  "Остановка_бега") --fent.State = 5
		end

		fent.RunSpeed = (fent.RunSpeed + nextVel)

		--local curanm = spr:GetAnimation()
		if curanm ~= "pre_run" then
			if curanm ~= "lunge_down" and curanm ~= "lunge_down_wall" or fent.OnGround then
				spr:Play("pre_run", true)
				fent.TempLoseY = nil
			end
		end
		if Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent, "Скольжение")
			elseif fent.StateFrame > 5 then
				if fent.CollideWall then
					spr:Play("lunge_down_wall")
					fent.Velocity.Y = fent.Velocity.Y*0.9 - 0.0*0.1
					fent.TempLoseY = fent.TempLoseY and math.min(1,fent.TempLoseY + 0.02) or 0
					Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(fent.RunSpeed,0), fent.TempLoseY, 1, false)
					if fent.Velocity.Y == 0 then
						SetState(fent, "Ходьба")
						Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(spr.FlipX and 5 or -5,-5), 0.5, 10, false)
						fent.RunSpeed = 0
						--fent.Velocity = Vector(spr.FlipX and 5 or -5,-2)
					end
				else
					fent.TempLoseY = nil
					spr:Play("lunge_down")
					spr:ClearQueue()
					fent.JumpActive = nil
					fent.IsLunge = true
					CleanOnStateChange(fent, "IsLunge")
					fent.Velocity.Y = 8
				end
				--fent.Velocity.Y = 8
				fent.CanBreakPoop = true
			end
		elseif fent.OnGround and not Inp.PressRun(idx) then
			SetState(fent, "Остановка_бега") --SetState(fent, "Ходьба")	
		end
		if fent.IsLunge then
			if Inp.PressJumpOnce(fent.ControllerIndex, fent) then
				print(spr:GetAnimation())
				SetState(fent, "стомп_в_беге")
				spr:ClearQueue()
				return
			end
		end

		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr) then
			return
		end
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.001 and spr.FlipX or (fent.Velocity.X < 0)
	if spr:GetAnimation() == "run" and math.abs(fent.RunSpeed) < 3.7 then
		spr:Play("pre_run")
	elseif fent.OnGround and math.abs(fent.Velocity.X) < 0.1 then
		spr:Play("idle")
	end
	return toReturn
end
---@param fent Flayer
---@param spr Player_AnimManager
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
			spr.Offset = fent.Flayer.DefaultOffset
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

			if fent.CollideWall and fent.slopeAngle and Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				fent.JumpActive = 30
				return
			elseif fent.CollideWall and not fent.OnGround and Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset

				SetState(fent, "Бег_по_стене")--fent.State = 40
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			elseif fent.CollideWall and fent.OnGround then --fent.Velocity.X == 0 then
				fent.InputWait = fent.InputWait and (fent.InputWait - 1) or 3
				if fent.InputWait and fent.InputWait <= 0 then
					SetState(fent, "Впечатался") --fent.State = 5
					spr:Play("lunge_down_wall")
					spr.Rotation = 0
					spr.Offset = fent.Flayer.DefaultOffset
					fent.InputWait = nil
					fent.RunSpeed = 0
					fent.Velocity = Vector(spr.FlipX and 5 or -5, -4)
					fent.grounding = 0
					return
				end
			end
		end

		if rot and press then
			fent.RunUnpressDelay = 5
			if press and sign0(rot) ~= sign0(fent.RunSpeed) and math.abs(fent.RunSpeed) > 6.4 and fent.OnGround then
				fent.NewRotate = -sign(fent.RunSpeed)
				SetState(fent, "Бег_смена_направления")--fent.State = 4
				fent.RunSpeed = Isaac_Tower.FlayerHandlers.RunSpeed2*sign(fent.RunSpeed)
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset
			elseif fent.OnGround then
				local accel = handler.Accel2    --0.075
				if fent.slopeAngle and sign0(-fent.slopeAngle) == rot then
					accel = accel * (1+math.abs(fent.slopeAngle)/45)
				end
				fent.RunSpeed = (fent.RunSpeed + accel/math.abs(fent.RunSpeed+1)*sign(rot)) 
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
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50))))) --, 4/math.abs(fent.RunSpeed) )
			end
		end

		if fent.OnGround then
			if fent.IsLunge then
				fent.Half = fent.DefaultHalf/1 --Vector(15,20)
				fent.CollisionOffset = Vector(0,0)
			end
			fent.IsLunge = nil
			

			if (not press and fent.RunUnpressDelay and fent.RunUnpressDelay < 0) or not Inp.PressRun(idx) then
				fent.RunUnpressDelay = nil
				SetState(fent, "Остановка_бега") --fent.State = 5
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset
			end
			if Inp.PressUp(idx) then
				fent.PressUpDelay = fent.PressUpDelay and (fent.PressUpDelay-1) or 5
				if fent.PressUpDelay and fent.PressUpDelay <= 0 then
					fent.PressUpDelay = nil
					SetState(fent, "Супер_прыжок_подготовка")
					spr.Rotation = 0
					spr.Offset = fent.Flayer.DefaultOffset
				end
			end
		end

		if fent.OnGround or "lunge_down" ~= spr:GetAnimation() then
			if spr:GetAnimation() ~= "run" and math.abs(fent.RunSpeed) < handler.RunSpeed3 then
				spr:Play("run", true)
			elseif spr:GetAnimation() ~= "superrun" and math.abs(fent.RunSpeed) >= handler.RunSpeed3 then
				spr:Play("superrun", true)
			end
		end
		fent.RunUnpressDelay = fent.RunUnpressDelay and (fent.RunUnpressDelay-1) or nil
		if Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent, "Скольжение")--fent.State = 15
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset
			else --if Inp.PressDownOnce(idx) then
				if fent.CollideWall then
					SetState(fent, "Стомп_импакт_пол")
					spr:Play("lunge_down_wall")
					--[[fent.Velocity.Y = fent.Velocity.Y*0.9 - 0.0*0.1
					fent.TempLoseY = fent.TempLoseY and math.min(1,fent.TempLoseY + 0.02) or 0
					Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(fent.RunSpeed,0), fent.TempLoseY, 1, false)
					if fent.Velocity.Y == 0 then
						SetState(fent, "Ходьба")
						Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(spr.FlipX and 5 or -5,-5), 0.5, 10, false)
						fent.RunSpeed = 0
						--fent.Velocity = Vector(spr.FlipX and 5 or -5,-2)
					end]]
				elseif fent.StateFrame > 5 then
					spr:Play("lunge_down")
					spr:ClearQueue()
					fent.JumpActive = nil
					fent.IsLunge = true
					CleanOnStateChange(fent, "IsLunge")
					fent.Velocity.Y = 8
				end
				--fent.Velocity.Y = 8
				fent.CanBreakPoop = true
			end
		else
			fent.OnAttack = true
			fent.CanBreakPoop = true
			if not fent.IsLunge then
				fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
				fent.ShowSpeedEffect = fent.AttackAngle
				fent.CanBreakMetal = true
			end

			--fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
			--fent.ShowSpeedEffect = fent.AttackAngle
		end
		if fent.IsLunge then
			fent.Half = fent.DefaultCroachHalf
			fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1
			if Inp.PressJumpOnce(fent.ControllerIndex, fent) then
				SetState(fent, "стомп_в_беге")
				spr:ClearQueue()
				return
			end
		end
			
		if fent.State ~= "Бег" then
			spr.Rotation = 0
			spr.Offset = fent.Flayer.DefaultOffset
		end

		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 15)
		if Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr) then
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
		fent.RunSpeed = Isaac_Tower.FlayerHandlers.RunSpeed2 * fent.NewRotate
		spr.FlipX = not spr.FlipX
		fent.CanJump = true

		spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -26 or 26, -8),
			Vector(spr.FlipX and -8 or 8, 0), spr.FlipX and 180 or 0,1).Color = Color(1,1,1,0.5)
	end
end
Isaac_Tower.FlayerMovementState["Присел"] = function(player, fent, spr, idx)
	if player.ControlsEnabled then
		fent.Half = fent.DefaultCroachHalf --Vector(15,10)
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
		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 7)
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.1 and spr.FlipX or (fent.Velocity.X < 0)
	Isaac_Tower.FlayerHandlers.AnimWalk(spr, "duck_move", "duck_idle", fent.Velocity.X)
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
				SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.RunSpeed)/50))))) --, 4/math.abs(fent.RunSpeed) )
			end
		end
		if spr:GetAnimation() ~= "duck_roll" then
			spr:Play("duck_roll", true)
		end
		fent.Half = fent.DefaultCroachHalf
		fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1 --Vector(0,9)

		if not Inp.PressRun(idx) and fent.OnGround then
			fent.RunSpeed = fent.RunSpeed*0.92
		end
		if Inp.PressRun(idx) and not fent.OnGround then
			if math.abs(fent.RunSpeed) > Isaac_Tower.FlayerHandlers.RunSpeed then
				SetState(fent, "Бег")
			else
				SetState(fent, "НачалоБега")
			end
			if Inp.PressDown(idx) then
				spr:Play("lunge_down")
				spr:ClearQueue()
				fent.JumpActive = nil
				fent.IsLunge = true
				CleanOnStateChange(fent, "IsLunge")
				fent.Velocity.Y = 8
			end
			Isaac_Tower.HandleMoving(player) --player:Update()
			return
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
				if fent.RunSpeed >= Isaac_Tower.FlayerHandlers.RunSpeed2 then
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
		--[[if Inp.PressJump(idx, fent) then
			if CheckCanUp(player) then
				if fent.RunSpeed >= Isaac_Tower.FlayerHandlers.RunSpeed2 then
					SetState(fent, "Бег")--fent.State = 5
				else
					SetState(fent, "НачалоБега")
				end
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			end
		end]]

		fent.Half = fent.DefaultCroachHalf
		fent.CollisionOffset = fent.CroachDefaultCollisionOffset/1 --Vector(0,9)

		--if fent.StateFrame%8 == 0 then
		--	spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -15 or 15, (fent.StateFrame%24)/4), Vector(0,0), fent.TrueVelocity:GetAngleDegrees())
		--end
		Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr)
			
		if not fent.OnGround then
			SetState(fent, "Бег")--fent.State = 3
			fent.Half = fent.DefaultHalf/1 --Vector(15,20)
			fent.CollisionOffset = Vector(0,0)
			fent.IsLunge = true
			CleanOnStateChange(fent, "IsLunge")
			spr:Play("lunge_down")
			spr:ClearQueue()
			fent.JumpActive = nil
			fent.Velocity.Y = 8

			Isaac_Tower.HandleMoving(player) --player:Update()
			return
		end
		if fent.SlideTime<=0 and not Inp.PressDown(idx) and CheckCanUp(player) then
			SetState(fent, "Бег")--fent.State = 3
			fent.Half = fent.DefaultHalf/1 --Vector(15,20)
			fent.CollisionOffset = Vector(0,0)
			fent.IsLunge = true
			--CleanOnStateChange(fent, "IsLunge")
			--spr:Play("lunge_down")
			--spr:ClearQueue()
			--fent.JumpActive = nil
			--fent.Velocity.Y = 8

			Isaac_Tower.HandleMoving(player) --player:Update()
			return
		elseif fent.SlideTime <= 0 and not Inp.PressDown(idx) then
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
			fent.RunSpeed = math.max(Isaac_Tower.FlayerHandlers.RunSpeed2, math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
		end

		fent.OnAttack = true
		fent.CanBreakPoop = true
		fent.AttackAngle = fent.RunSpeed>0 and 0 or 180
	end
	
	spr.FlipX = math.abs(fent.Velocity.X) < 0.1 and spr.FlipX or (fent.Velocity.X < 0)
end
---@param spr Player_AnimManager
Isaac_Tower.FlayerMovementState["Захват"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	if fent.StateFrame == 1 then
		spr:Play("grab",true)
	end
	local result = {}

	fent.RunSpeed = math.max(6,math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
	
	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx)+Inp.PressRight(idx)

		if fent.StateFrame > 1 and not Inp.PressDown(idx) --and Inp.PressRun(idx) 
		and fent.CollideWall and Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, rot) then
			
			--if Isaac_Tower.MovementHandlers.IsCanWallClamb(fent, rot) then
				spr.Rotation = 0
				spr.Offset = fent.Flayer.DefaultOffset

				SetState(fent, "Бег_по_стене")--fent.State = 40
				
				fent.CanJump = false
				fent.grounding = 0
				spr:Play("wall_climbing", true)
				return
			--end
		elseif fent.StateFrame > 1 and not Inp.PressDown(idx) and fent.CollideWall then
			SetState(fent, "Остановка_бега")
		end
		
		if Inp.PressUp(idx) then
			if fent.StateFrame < 6 and not fent.UseApperkot then
				SetState(fent, "Аперкот-не-кот")
			end
		end
		if Inp.PressDown(idx) then
			if fent.OnGround and fent.StateFrame < 15 then
				SetState(fent, "Скольжение_Захват")--fent.State = 16
				fent.SlideTime = 30
				fent.RunSpeed = math.max(Isaac_Tower.FlayerHandlers.RunSpeed, math.abs(fent.RunSpeed)) * sign0(fent.RunSpeed)
				Isaac_Tower.HandleMoving(player)
				return
			--[[elseif fent.StateFrame < 6 then
				SetState(fent, "Стомп")
				spr:Play("grab_down_appear",true)
				Flayer.Queue = "grab_down_idle"
				fent.Velocity.Y = math.min(-1, fent.Velocity.Y)
				Isaac_Tower.HandleMoving(player)
				return]]
			end
		end
		local curanim = spr:GetAnimation()
		if (spr:IsFinished(curanim) or curanim == "grab_air_loop") and fent.OnGround then
			if Inp.PressRun(idx) then
				SetState(fent, "НачалоБега")--fent.State = 2
			else
				SetState(fent, "Ходьба")--fent.State = 1
			end
			if Inp.PressDown(idx) then
				SetState(fent, "Скольжение")--fent.State = 15
			end
			fent.GrabDelay = 15
		elseif not fent.OnGround then
			if spr:IsPlaying("grab") then
				fent.GrabFrameBeforeAir = spr:GetFrame()
				CleanOnStateChange(fent, "GrabFrameBeforeAir")
				spr:Play("grab_air_start")
				--spr:SetQueue("grab_air_loop", 0)
			elseif spr:IsFinished("grab_air_start") then
				spr:Play("grab_air_loop")
			end
		elseif fent.OnGround then
			if spr:IsPlaying("grab_air_start") and spr:GetFrame() < 4 then
				spr:Play("grab")
				spr:SetFrame(fent.GrabFrameBeforeAir or 1)
				fent.GrabFrameBeforeAir = nil
			end
		end
		local signrot = sign0(rot)
		if signrot ~= 0 and signrot ~= sign0(fent.RunSpeed) then
			SetState(fent, "Ходьба")
			fent.GrabDelay = 15
			spr:ClearQueue()
			fent.WalkFlyReplace = "grab_stop"
		end

		fent.OnAttack = true
		fent.CanBreakPoop = true

		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 15)
	end

	Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr)

	--if fent.StateFrame <= 15 then
		--result.dontLoseY = true
		--fent.Velocity.Y = fent.Velocity.Y < 1 and (fent.Velocity.Y * (math.max(0,fent.StateFrame)/15)) or fent.Velocity.Y
	--end

	spr.FlipX = math.abs(fent.RunSpeed) < 0.1 and spr.FlipX or (fent.RunSpeed < 0)

	return result
end
--mod:AddPriorityCallback(Isaac_Tower.Callbacks.FLAYER_PRE_COLLIDING_ENEMY, CallbackPriority.LATE, function(_, fent, target)
function Isaac_Tower.FlayerHandlers.EnemyGrabCollision(fent, target)
	if fent.State == "Захват" and not target:GetData().Isaac_Tower_Data.NoGrabbing and target.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
		fent.GrabTarget = target
		SetState(fent, "Захватил")
		fent.GrabDelay = 3
		target:GetData().Isaac_Tower_Data.State  = Isaac_Tower.EnemyHandlers.EnemyState.GRABBED
		target:GetData().Isaac_Tower_Data.GrabbedBy = fent
		target:GetSprite():Play("stun")
	end
end
Isaac_Tower.FlayerHandlers.CrashState = { --true or function(fent, target)
	["Бег_по_стене"] = true,
	["Бег"] = true,
	["Бег_смена_направления"] = true,
	["Скольжение_Захват"] = true,
	["Стомп"] = function(fent, target)
		if fent.Flayer:IsPlaying("grab_down_idle") then
			return true
		end
	end,
	["стомп_в_беге"] = function(fent, target)
		if fent.Velocity.Y > 0 then
			return true
		end
	end,
	["Супер_прыжок"] = true,
	["Супер_прыжок_перенаправление"] = function (fent, target)
		if fent.Flayer:IsFinished(fent.Flayer:GetAnimation()) then
			return true
		end
	end,
	["Аперкот-не-кот"] = function(fent, target)
		if fent.ShowSpeedEffect then
			return true
		end
	end,
}
Isaac_Tower.FlayerHandlers.UnGrabState = {
	["Ходьба"]=true,["НачалоБега"]=true,["Бег"]=true,["Урон"] = true,
}
Isaac_Tower.FlayerHandlers.BounceIgnoreState = {
	["Стомп"]=true,
}
Isaac_Tower.FlayerHandlers.WalkRunState = {
	["Ходьба"]=true,["НачалоБега"]=true,["Бег"]=true,
}
Isaac_Tower.FlayerHandlers.PushState = {
	["НачалоБега"]=true,["Скольжение"]=true,
}

function Isaac_Tower.FlayerHandlers.EnemyCrashCollision(fent, target)
	local stateCheck = Isaac_Tower.FlayerHandlers.CrashState[fent.State]
	if type(stateCheck) == "function" then
		stateCheck = stateCheck(fent, target)
	end
	if stateCheck and not target:GetData().Isaac_Tower_Data.Flags.Invincibility then
		target:GetData().Isaac_Tower_Data.State  = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
		target:GetData().Isaac_Tower_Data.DeadFlyRot = fent.Position.X<target:GetData().Isaac_Tower_Data.Position.X and 1 or -1
	end
end
function Isaac_Tower.FlayerHandlers.EnemyStandeartCollision(fent, ent, dist)
	local data = ent:GetData().Isaac_Tower_Data
	--if fent.InvulnerabilityFrames and fent.InvulnerabilityFrames>0 then return end
	if not ent:GetData().Isaac_Tower_Data.Flags.Invincibility
	and (not fent.DamageSource or fent.DamageSource.Index and fent.DamageSource.Index ~= ent.Index) then
		local sholdJump = data.Position.Y-data.Half.Y>fent.Position.Y
		if --not (fent.InvulnerabilityFrames and fent.InvulnerabilityFrames>0) and fent.OnGround
		--data.State == Isaac_Tower.EnemyHandlers.EnemyState.STUN and
		not sholdJump and
		not Isaac_Tower.FlayerHandlers.BounceIgnoreState[fent.State] and Isaac_Tower.FlayerHandlers.PushState[fent.State] then
			if not data.Flags.NoStun then
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
				data.StateFrame = 0
			end
			--[[if fent.Position.X < data.Position.X then
				data.Velocity = Vector(data.Velocity.X*0.8 - sign(fent.Position.X-data.Position.X)*(dist/20), data.Velocity.Y )
			else
				data.Velocity = Vector(data.Velocity.X*0.8 + sign(data.Position.X-fent.Position.X)*(dist/20), data.Velocity.Y )
			end]]
			local power = data.FlayerDistanceCheck/1.2-dist
			local vec = (data.Position-fent.Position) --+Vector(0,-math.abs(fent.Velocity.X)-4.5))
			vec.Y = vec.Y - math.abs(fent.Velocity.X)*2-4.5
			--print(vec, power, vec:Resized(power))
			data.Position = data.Position + vec:Resized(power/1.8)
			data.Velocity = data.Velocity + vec:Resized(power/6+math.abs(fent.Velocity.X)/2)
		elseif not Isaac_Tower.FlayerHandlers.BounceIgnoreState[fent.State] and not fent.OnGround 
		and fent.Velocity.Y>0 and data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then --fent.Position.Y<ent.Position.Y and fent.Velocity.Y>0 and
			if not data.Flags.NoStun then
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
				data.StateFrame = 0
			end
			if fent.InvulnerabilityFrames and fent.InvulnerabilityFrames>0 then return end
			local nextvel
			local pow = data.OnGround and 2 or 5
			local adist = data.FlayerDistanceCheck+5 --40
			if fent.Position.X < ent.Position.X then
				nextvel = data.Velocity.X*0.8 - sign(fent.Position.X-data.Position.X)*(adist-dist)/pow
				data.Velocity.X = math.min((adist-dist)/pow, nextvel )
			else
				nextvel = data.Velocity.X*0.8 + sign(data.Position.X-fent.Position.X)*(adist-dist)/pow
				data.Velocity.X = math.max(-(adist-dist)/pow, nextvel )
			end
			--local power = data.FlayerDistanceCheck-dist
			--data.Position = data.Position + (fent.Position-data.Position):Resized(power/15)
			--print(power)


			fent.Velocity.Y = -4
			fent.JumpActive = 15
			fent.UseApperkot = nil
		elseif not Isaac_Tower.FlayerHandlers.BounceIgnoreState[fent.State] 
		and Isaac_Tower.FlayerHandlers.PushState[fent.State] then
			if not data.Flags.NoStun then
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
				data.StateFrame = 0
			end
			if fent.InvulnerabilityFrames and fent.InvulnerabilityFrames>0 then return end
			--[[local nextvel
			local pow = data.OnGround and 2 or 5
			if fent.Position.X < ent.Position.X then
				nextvel = data.Velocity.X*0.8 - sign(fent.Position.X-data.Position.X)*(40-dist)/pow
				data.Velocity.X = math.min((40-dist)/pow, nextvel )
			else
				nextvel = data.Velocity.X*0.8 + sign(data.Position.X-fent.Position.X)*(40-dist)/pow
				data.Velocity.X = math.max(-(40-dist)/pow, nextvel )
			end]]
			local power = data.FlayerDistanceCheck/1.2-dist
			local vec = (data.Position-fent.Position) --+Vector(0,-math.abs(fent.Velocity.X)-4.5))
			vec.Y = vec.Y - math.abs(fent.Velocity.X)-8.5
			data.Position = data.Position + vec:Resized(power/3)
			data.Velocity = data.Velocity + vec:Resized(power/9)
		end
	end
end
mod:AddPriorityCallback(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, CallbackPriority.LATE, function(_, target, Pos, Offset, Scale)
	local data = target:GetData().Isaac_Tower_Data
	if data.GrabbedBy then
		local fent = data.GrabbedBy
		local spr = fent.Flayer.CurrentRHSpr
		if not spr then return end
		spr.Color = fent.Flayer.Color
		
		--local RenderPos =  Pos + fent.Position/(20/13) + fent.Velocity/(20/13)*Isaac_Tower.GetProcentUpdate() + Isaac_Tower.GetRenderZeroPoint()
		--local RenderPos = TSJDNHC_PT:WorldToScreen(fent.Position+fent.Velocity*Isaac_Tower.GetProcentUpdate())

		--local RenderPos = TSJDNHC_PT:WorldToScreen(fent.Position + fent.Velocity*Isaac_Tower.GetProcentUpdate())

		--spr:SetFrame(fent.Flayer.Sprite:GetAnimation(), fent.Flayer.Sprite:GetFrame())
		spr.FlipX = fent.Flayer.FlipX
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
	
	if player.ControlsEnabled then --and not spr:IsPlaying("holding_appear") then
		
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

		Isaac_Tower.FlayerHandlers.JumpHandler(fent, -6, 15, 15)
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
		elseif Inp.PressDown(idx) then
			if fent.OnGround then
				SetState(fent,"Присел")
				fent.GrabTarget:GetData().Isaac_Tower_Data.Position = fent.Position+Vector(0,-20)
				Isaac_Tower.EnemyHandlers.UngrabEnemy(fent.GrabTarget)
				fent.GrabTarget = nil
			end
		end
	end

	spr.FlipX = math.abs(fent.Velocity.X) < 0.001 and spr.FlipX or (fent.Velocity.X < 0)
	if not spr:IsPlaying("holding_appear") then
		if fent.OnGround then
			Isaac_Tower.FlayerHandlers.AnimWalk(spr, "holding_move", "holding_idle", fent.Velocity.X)
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
		local oldpos = tarData.Position/1
		local extraoffset = Isaac_Tower.FlayerHandlers.GetGrabNullOffset 
			and Isaac_Tower.FlayerHandlers.GetGrabNullOffset(spr)
		--fent.GrabTarget:Update()
		tarData.Position = fent.Position + (extraoffset or TargetPos) + fent.TrueVelocity
		tarData.Velocity = Vector(0,0) -- tarData.Position - fent.GrabTarget.Position   --Vector(0,0) --oldpos-fent.GrabTarget.Position  --Vector(0,0)
		fent.GrabTarget:Update()
		fent.GrabTarget.DepthOffset = 110
		--fent.GrabTarget.SpriteOffset = TargetPos
		--fent.GrabTarget:GetData().TSJDNHC_GridColl = 0

		if fent.StateFrame%8 == 0 then
			local rot = spr.FlipX and -1 or 1
			local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,Isaac_Tower.ENT.GibSubType.SWEET,fent.Position+Vector(10*rot,-20), Vector(0,0), nil)
			--grid.DepthOffset = 310
			--grid:GetData().Color = Color(1,1,1,1)

			local rng = RNG()
			rng:SetSeed(grid.InitSeed,35)

			grid.Position = grid.Position + Vector(-rng:RandomInt(10)/1,rng:RandomInt(10)/1) * Vector(rot,1)
			local vec = Vector.FromAngle(rng:RandomInt(91)-45 - 15 or 0):Resized((rng:RandomInt(20)/3+2)) --math.random(15,25)
			vec = Vector(vec.X*rot,vec.Y)
			grid.Velocity = vec + fent.TrueVelocity*2
			grid:Update()
			
			--grid:GetSprite():Load("gfx/effects/it_sweet.anm2",true)
			--grid:GetSprite():Play("drop", true)
			--grid:Update()
		end
	else
		SetState(fent, "Ходьба")
		fent.GrabTarget = nil
	end
end
Isaac_Tower.FlayerMovementState["Захватил ударил"] = function(player, fent, spr, idx)
	
	--[[if not fent.GrabTarget or not fent.GrabTarget:Exists() then
		SetState(fent, "Ходьба")
		Isaac_Tower.HandleMoving(player)
		return
	end]]

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
		if not fent.GrabTarget or not fent.GrabTarget:Exists() then
			SetState(fent, "Ходьба")
			Isaac_Tower.HandleMoving(player)
			return
		end
		local edata = fent.GrabTarget:GetData().Isaac_Tower_Data
		--fent.GrabTarget.Position = fent.Position + Vector(0,-10)
		edata.State  = Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED
		local rot = spr.FlipX and -1 or 1
		edata.Velocity = fent.PunchRot and (fent.PunchRot:Resized(29)) or Vector(29*rot,0)
		edata.Position = edata.Position - edata.Velocity
		--print(fent.GrabTarget.Velocity, fent.PunchRot,  fent.PunchRot:Resized(29))
		edata.GrabbedBy = nil
		--fent.GrabTarget:GetData().TSJDNHC_GridColl = 1
		edata.CanBreakPoop = true
		edata.prePosition = edata.Position/1
		edata.StateFrame = 0
		--fent.GrabTarget:Update()
		Isaac_Tower.EnemyUpdate(nil,fent.GrabTarget)
		fent.GrabTarget = nil
		fent.PunchRot = nil

		--Isaac_Tower.FlayerHandlers.SetForsedVelocity(fent, Vector(-2*rot,-4), 0.2, 20)
		fent.Velocity = Vector(-1.5*rot,-4)
		fent.RunSpeed = -2*rot
		fent.grounding = -1

		spawnSpeedEffect(fent.Position+Vector(spr.FlipX and -26 or 26, -16),
			Vector(fent.TrueVelocity.X, 0), spr.FlipX and 180 or 0,1).Color = Color(1,1,1,0.5)
	elseif not spr:WasEventTriggered("hit") then
		fent.Velocity = fent.Velocity * 0.55
		fent.RunSpeed = fent.RunSpeed * 0.55

		local rot = spr.FlipX and -1 or 1
		local extraoffset = Isaac_Tower.FlayerHandlers.GetGrabNullOffset 
			and Isaac_Tower.FlayerHandlers.GetGrabNullOffset(spr)
		fent.GrabTarget:GetData().Isaac_Tower_Data.Position = fent.Position + (extraoffset and (extraoffset*Vector(rot,1)) or Vector(rot*30,-10))
	else
		fent.Velocity.Y = fent.Velocity.Y - .13
	end
	if spr:IsFinished(spr:GetAnimation()) then
		fent.GrabDelay = 0
		SetState(fent, "Ходьба")
		Isaac_Tower.HandleMoving(player)
		return
	end
	return toReturn
end

local appercotAnims = {["attack_up"]=true,["attack_up_end"]=true,["attack_up_loop"]=true}
Isaac_Tower.FlayerMovementState["Аперкот-не-кот"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	local toReturn = {}
	fent.UseApperkot = true
	if fent.StateFrame <= 1 or not appercotAnims[spr:GetAnimation()] then
		spr:Play("attack_up")
		fent.TempSpeedRun = fent.Velocity.X  --fent.RunSpeed/1
	end
	if spr:IsFinished("attack_up_end") then
		SetState(fent, "Ходьба")
		spr.Rotation = 0
		spr.Offset = fent.Flayer.DefaultOffset
	elseif spr:IsPlaying("attack_up") then
		fent.Velocity.Y = fent.Velocity.Y * 0.8 + -1.5 * 0.2
		fent.Velocity.X = fent.Velocity.X * 0.85
		toReturn.donttransformRunSpeedtoX = true

		spr.Rotation = spr.Rotation * 0.8 + 
			math.abs(Vector(fent.TrueVelocity.X,math.min(-1,fent.TrueVelocity.Y)):GetAngleDegrees()+90)*math.max(0,70-30)/50 * 0.2
	elseif spr:IsFinished("attack_up") then
		spr:Play("attack_up_loop")
		fent.Velocity.Y = -6
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if sign0(rot) == sign0(fent.TempSpeedRun) then
			fent.RunSpeed = fent.TempSpeedRun
		else
			fent.RunSpeed = math.max(2,math.abs(fent.RunSpeed)*0.2)*sign0(fent.TempSpeedRun)
		end
		fent.TempSpeedRun = nil
		spr.Rotation = spr.Rotation * 0.8 + 
			math.abs(Vector(fent.TrueVelocity.X,math.min(-1,fent.TrueVelocity.Y)):GetAngleDegrees()+90)*math.max(0,70-30)/50 * 0.2

		spawnSpeedEffect(fent.Position,-Vector(fent.RunSpeed,-6):Normalized(),spr.Rotation*sign0(fent.RunSpeed)-90,1 ).Color = Color(1,1,1,0.5)
	elseif spr:IsPlaying("attack_up_loop") or spr:IsPlaying("attack_up_end") then
		fent.grounding = 0
		fent.Velocity.Y = math.max(-5, fent.Velocity.Y + (-1.5 * math.max(0,40-fent.StateFrame)/30))

		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		if rot<0 and fent.RunSpeed>-2 then --Inp.PressLeft(idx)>0 then
			fent.RunSpeed = fent.RunSpeed + Inp.PressLeft(idx)*-2 * 0.07 --* 0.95
		elseif rot>0 and fent.RunSpeed<2 then --Inp.PressRight(idx)>0 then
			fent.RunSpeed = fent.RunSpeed + Inp.PressRight(idx)*2 * 0.07
		end
		local mis = spr.FlipX and -1 or 1
		spr.Rotation = (Vector(fent.TrueVelocity.X*mis,math.min(-1,fent.TrueVelocity.Y)):GetAngleDegrees()+90)*math.max(0,70-fent.StateFrame)/50 
			--math.abs(Vector(fent.TrueVelocity.X,math.min(-1,fent.TrueVelocity.Y)):GetAngleDegrees()+90)*math.max(0,70-fent.StateFrame)/50
		spr.Offset = Vector(-spr.Rotation/6,16)

		if fent.StateFrame > 40 then
			spr:Play("attack_up_end")
		end
		if fent.Velocity.Y > 0 and fent.OnGround and fent.StateFrame>30 then
			SetState(fent, "Ходьба")
			spr.Rotation = 0
			spr.Offset = fent.Flayer.DefaultOffset
		end

		fent.CanBreakPoop = true
		fent.OnAttack = true
		if spr:IsPlaying("attack_up_loop") then
			fent.ShowSpeedEffect = spr.Rotation*mis-90 --sign0(fent.RunSpeed)-90
		end
		SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.2*(math.max(1,fent.StateFrame/60))))
		Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr)
	elseif spr:IsPlaying("attack_up_end")  then
		spr.Rotation = spr.Rotation * 0.8
	end

	--if Isaac_Tower.MovementHandlers.GrabHandler(fent) then
	--	return
	--end
	return toReturn
end
---@param fent Flayer
Isaac_Tower.FlayerMovementState["Стомп"] = function(player, fent, spr, idx)
	--local Flayer = fent.Flayer

	--if fent.StateFrame <= 1 then
		--fent.Velocity.Y = 0
	--end

	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		fent.CanJump = false
		fent.RunSpeed = fent.RunSpeed * 0.9
		if math.abs(fent.RunSpeed)>3 then
			fent.Velocity.X = fent.Velocity.X * 0.8
		end

		if fent.RunSpeed>-3 and fent.RunSpeed<3 then
			fent.RunSpeed = fent.RunSpeed + sign0(rot)*2*0.2
		end
		
		--if spr:IsPlaying("grab_down_appear") then
		if spr:IsPlaying("grab_down_appear") then -- and fent.Velocity.Y < 0 then
			fent.Velocity.Y = fent.Velocity.Y * 0.98  --+ -3.5 * 0.2
			--if spr:GetFrame()>7 then
			--	spr:SetFrame(7)
			--end
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.2), .05)
		elseif spr:IsPlaying("grab_down_idle") then
			
			if fent.Velocity.Y < Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
				fent.Velocity.Y = fent.Velocity.Y * 0.92 + Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed * 0.09 --8
			else
				--fent.Velocity.Y = fent.Velocity.Y + 1.575/math.abs(fent.Velocity.Y+1)
				fent.Velocity.Y = fent.Velocity.Y * 0.95 + Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed * 0.06 --8
			end

			fent.OnAttack = true
			if fent.OnGround then
				if not fent.slopeAngle then
					SetState(fent, "Стомп_импакт_пол")
					--fent.NextState = 1
					spr:Play("grab_down_landing")
					if fent.Velocity.Y > Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
						Isaac_Tower.game:ShakeScreen(10)
						Isaac_Tower.FlayerHandlers.LiftEnemiesInRadius(fent.Position, math.min(10, 5+fent.Velocity.Y-8))

						local fpos = fent.Position
						--local solid = Isaac_Tower.GridLists.Solid
						local Obs = Isaac_Tower.GridLists.Obs
						for i = -2, 2 do
							--[[local grid = solid:GetGrid(fpos + Vector(7.5*i, fent.Half.Y+5))
							if grid and grid.HighImpactDestroy then
								solid:DestroyGrid(grid.XY)
							end]]
							local grid = Obs:GetGrid(fpos + Vector(7.5*i, fent.Half.Y+5))
							if grid and grid.HighImpactDestroy then
								grid.HitAngle =  90
								grid.HitPower = 3
								Obs:DestroyGrid(grid.XY)
							end
						end
					end
					
					if fent.CanBreakMetal then
						print("bera")
					end
				else
					if Inp.PressDown(idx) then
						--local power = math.cos(math.rad(fent.slopeAngle+90))
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle) -- * power --(fent.slopeAngle<90 and -1 or 1)
						SetState(fent, "Скольжение_Захват")
						fent.SlideTime = math.min(30, fent.Velocity.Y *5)
					else
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle) * 0.8
						if math.abs(fent.RunSpeed) < 2 then
							SetState(fent, "Стомп_импакт_пол")
							spr:Play("grab_down_landing")
						elseif math.abs(fent.RunSpeed) < Isaac_Tower.FlayerHandlers.RunSpeed2 then
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
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.4), .05) --*(math.max(1,fent.StateFrame/60))))
			if fent.Velocity.Y > Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
				--local off = Isaac.Spawn(1000, IsaacTower_GibVariant, 100, fent.Position, Vector(0,0), player)
				--off:GetSprite():Load(spr:GetFilename(), true)
				--off:GetSprite():Play(spr:GetAnimation(), true)
				--SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.2*(math.max(1,fent.StateFrame/60))))
				--fent.CanBreakMetal = true
				fent.ShowSpeedEffect = 90
			end
		end
	end
	return {DontHelpCollisionUpping = true, HelpCollisionHori = false}
end
---@param fent Flayer
Isaac_Tower.FlayerMovementState["стомп_в_беге"] = function(player, fent, spr, idx)
	--local Flayer = fent.Flayer

	if fent.StateFrame <= 1 then
		fent.Velocity.Y = -5
		--local vel = fent.Velocity.X
		--if math.abs(vel) > 8 then
		--	fent.Velocity.X = vel - ((math.abs(vel) - 8) * .7) * sign(vel)
		--end
		fent.RunSpeed = 0
		spr:Play("lunge_drop")
	end

	if player.ControlsEnabled then
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		fent.CanJump = false
		--fent.RunSpeed = fent.RunSpeed * 0.9
		--if math.abs(fent.RunSpeed)>3 then
		--	fent.Velocity.X = fent.Velocity.X * 0.8
		--end

		--if fent.RunSpeed>-3 and fent.RunSpeed<3 then
		local run = fent.Velocity.X
		if run <= 0 then
			fent.Velocity.X = math.max(math.min(-5, run), run + rot*0.3)
		else
			fent.Velocity.X = math.min(math.max(5, run), run + rot*0.3)
			--math.max(-3, run, math.min(3, run, run + sign0(rot)*2*0.2 ))
		end
		
		--if true then --spr:IsPlaying("grab_down_appear") then
			if fent.Velocity.Y < 0 then
				fent.Velocity.Y = fent.Velocity.Y * 0.995 + Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed * 0.005
			elseif fent.Velocity.Y < Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
				fent.Velocity.Y = fent.Velocity.Y * 0.94 + Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed * 0.08 --8
				fent.Velocity.X = fent.Velocity.X * 0.98
			else
				fent.Velocity.Y = fent.Velocity.Y * 0.95 + Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed * 0.06 --8
				fent.Velocity.X = fent.Velocity.X * 0.98
			end

			fent.OnAttack = true
			if fent.OnGround then
				if not fent.slopeAngle then
					SetState(fent, "Стомп_импакт_пол")
					spr:Play("grab_down_landing")
					if fent.Velocity.Y > Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
						Isaac_Tower.game:ShakeScreen(10)
						Isaac_Tower.FlayerHandlers.LiftEnemiesInRadius(fent.Position, math.min(10, 5+fent.Velocity.Y-8))

						local fpos = fent.Position
						local Obs = Isaac_Tower.GridLists.Obs
						for i = -2, 2 do
							local grid = Obs:GetGrid(fpos + Vector(7.5*i, fent.Half.Y+5))
							if grid and grid.HighImpactDestroy then
								grid.HitAngle =  90
								grid.HitPower = 3
								Obs:DestroyGrid(grid.XY)
							end
						end
					end
				else
					if Inp.PressDown(idx) then
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle)
						SetState(fent, "Скольжение_Захват")
						fent.SlideTime = math.min(30, fent.Velocity.Y *5)
					else
						fent.RunSpeed = fent.Velocity.Y * -sign(fent.slopeAngle) * 0.8
						if math.abs(fent.RunSpeed) < 2 then
							SetState(fent, "Стомп_импакт_пол")
							spr:Play("grab_down_landing")
						elseif math.abs(fent.RunSpeed) < Isaac_Tower.FlayerHandlers.RunSpeed2 then
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
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,0.4), .05)
			if fent.Velocity.Y > Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed then
				fent.ShowSpeedEffect = 90
			end
		--end
	end
	return {DontHelpCollisionUpping = true, HelpCollisionHori = false, donttransformRunSpeedtoX = true,}
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

	fent.Velocity.Y = -Isaac_Tower.FlayerHandlers.SuperJumpSpeed --Isaac_Tower.FlayerHandlers.FallBlockBreakSpeed
	toReturn.newVel = Vector(0, -Isaac_Tower.FlayerHandlers.SuperJumpSpeed)
	fent.grounding = 0
	if fent.CollideCeiling then
		SetState(fent, "Удар_об_потолок")
		fent.RunSpeed = 0
		fent.Velocity = Vector(0,0)
		spr:Play("super_jump_collide")
		--fent.Flayer.Queue = "super_jump_fall"

		Isaac_Tower.game:ShakeScreen(10)
	else
		fent.RunSpeed = 0
		fent.Velocity.X = 0
		fent.CanBreakMetal = true
		fent.CanBreakPoop = true
		fent.AttackAngle = 270
		fent.ShowSpeedEffect = 270

		Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr, -90)
		local sig = spr.FlipX and -1 or 1
		if fent.StateFrame%4 == 0 then
			spawnSpeedEffect(fent.Position+Vector(sig*-15, (fent.StateFrame%24)*2-20):Rotated(sig*(-90)),
				fent.TrueVelocity, (fent.TrueVelocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
		--if math.abs(fent.RunSpeed) > 10 then
			SpawnAfterImage(spr, fent.Position+Vector(0,20), Color(1,1,1,math.min(1, (math.max(0,math.abs(fent.Velocity.Y)/20))))) --, 4/math.abs(fent.Velocity.Y) )
		--end

		if Inp.PressGrab(idx) then
			if Inp.PressRight(idx)>0 then
				SetState(fent, "Супер_прыжок_перенаправление")
				fent.RunSpeed = Isaac_Tower.FlayerHandlers.RunSpeed
				fent.Velocity.Y = 0
			elseif Inp.PressLeft(idx)>0 then
				SetState(fent, "Супер_прыжок_перенаправление")
				fent.RunSpeed = -Isaac_Tower.FlayerHandlers.RunSpeed
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
			if not fent.OnGround and Inp.PressDown(idx) then
				SetState(fent, "Бег")--fent.State = 3
				fent.Half = fent.DefaultHalf/1 --Vector(15,20)
				fent.CollisionOffset = Vector(0,0)
				fent.IsLunge = true
				CleanOnStateChange(fent, "IsLunge")
				spr:Play("lunge_down")
				spr:ClearQueue()
				fent.JumpActive = nil
				fent.Velocity.Y = 8

				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			end

			if not Inp.PressDown(idx) and fent.CollideWall == sign0(fent.RunSpeed) then
				if Isaac_Tower.FlayerHandlers.IsCanWallClamb(fent, fent.RunSpeed) then
					spr.Rotation = 0
					spr.Offset = fent.Flayer.DefaultOffset

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

				Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr)
			end
		end
	else
		toReturn.donttransformRunSpeedtoX = true
		toReturn.dontLoseY = true
		fent.DontHelpCollisionUpping = true
	end

	return toReturn
end
---@param fent Flayer
Isaac_Tower.FlayerMovementState["Бег_по_стене"] = function(player, fent, spr, idx)
	local toReturn = {}
	if player.ControlsEnabled then
		--if fent.StateFrame == 1 then
		--	fent.WallRunSpeed = fent.RunSpeed * (1 - math.min(.2, math.max(0, (fent.Velocity.Y-3)/20)))
		--end
		local rptate = spr.FlipX and -1 or 1
		fent.grounding = 0
		toReturn.donttransformRunSpeedtoX = true
		fent.DontHelpCollisionUpping = true
		fent.Velocity.X = 0 -- sign(fent.RunSpeed) --*3

		local CollideWall = false
		for i=0, 1 do
			local nexpos = fent.Position + Vector((fent.Half.X+2)*rptate,fent.Half.Y - 1 - 37*i)
			Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, Isaac_Tower.WorldToScreen(nexpos), 1)
			local grid = Isaac_Tower.GridLists.Solid:GetGrid(nexpos)
			if grid and Isaac_Tower.ShouldCollide(player, grid) then
				CollideWall = true
				break
			end
			local grid = Isaac_Tower.GridLists.Obs:GetGrid(nexpos)
			if grid and Isaac_Tower.ShouldCollide(player, grid) then
				CollideWall = true
				break
			end
		end
		--print(tostring(CollideWall))
		---Isaac_Tower.DebugRenderText(CollideWall, Vector(20, 20), 2)
		--fent.Position.X = fent.Position.X + sign0(fent.RunSpeed) --*1
		--Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, Isaac_Tower.WorldToScreen(fent.Position), 1)
			
		local rot = -Inp.PressLeft(idx) + Inp.PressRight(idx)
		
		if (Inp.PressRun(idx) or fent.InputWait)  and CollideWall then --(sign0(rot) == sign0(fent.RunSpeed)
			--dontLoseY = true
			--fent.Velocity.X = 0
			--local s = spr.FlipX and -1 or 1
			fent.Velocity.Y = -math.abs(fent.RunSpeed)*0.95 -- -fent.RunSpeed*0.95 * s 
			fent.CanJump = false
			local absrun = math.abs(fent.RunSpeed)
			if absrun > handler.RunSpeed then
				local accel = handler.Accel    -- 0.075
				fent.RunSpeed = (fent.RunSpeed + accel/math.abs(fent.RunSpeed+1)) --*sign(rot)) 
				fent.CanBreakMetal = true
			else
				if absrun < 1 then
					fent.RunSpeed = (fent.RunSpeed + 0.018*sign(fent.RunSpeed))
				else
					fent.RunSpeed = (fent.RunSpeed + 0.028*sign(fent.RunSpeed))
				end
			end

			fent.CanBreakPoop = true
			fent.AttackAngle = 270 + -sign(fent.RunSpeed)*math.abs(fent.RunSpeed/2)

			if not ( Inp.PressRun(idx)) then --sign0(rot) == sign0(fent.RunSpeed)
				fent.InputWait = fent.InputWait - 1
				if fent.InputWait <= 0 then
					fent.InputWait = nil
					local runrot = spr.FlipX and -1 or 1
					fent.Position.X = fent.Position.X - sign0(fent.RunSpeed)*5
					--fent.Velocity.X = -sign0(fent.RunSpeed)*5
					--handler.SetForsedVelocity(fent, Vector(-sign0(fent.RunSpeed)*5,0),1,13, false)
					fent.UnStickWallVel = Vector(-sign0(fent.RunSpeed)*4,0)
					fent.UnStickWallTime = 13

					fent.Velocity.X = 0
					fent.Velocity.Y = 0
					fent.RunSpeed = 0
					fent.CanJump = true
					fent.GrabDelay = 2
					SetState(fent, "Ходьба")--fent.State = 1
					return
				end
			end
			if fent.CollideCeiling and fent.StateFrame > 2 then
				SetState(fent, "Удар_об_потолок")
				fent.RunSpeed = 0
				fent.Velocity = Vector(0,0)
				spr:Play("wall_climbing_land")
				--fent.Flayer.Queue = "super_jump_fall"
			end
				
		elseif  Inp.PressRun(idx) or fent.InputWait then --sign0(rot) == sign0(fent.RunSpeed)
			local CollideWall
			
			local nexpos = fent.Position + Vector((fent.Half.X+2)*rptate, 10)
			Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, Isaac_Tower.WorldToScreen(nexpos), 1)
			local grid = Isaac_Tower.GridLists.Solid:GetGrid(nexpos)
			if Isaac_Tower.ShouldCollide(player, grid) then
				CollideWall = grid
			end
			local grid = Isaac_Tower.GridLists.Obs:GetGrid(nexpos)
			if Isaac_Tower.ShouldCollide(player, grid) then
				CollideWall = grid
			end
			
			if fent.CollideCeiling and fent.StateFrame > 2 then
				SetState(fent, "Удар_об_потолок")
				fent.RunSpeed = 0
				fent.Velocity = Vector(0,0)
				spr:Play("super_jump_collide")
				--fent.Flayer.Queue = "super_jump_fall"
				return
			else
				fent.Position.Y = CollideWall and CollideWall.Position.Y or fent.Position.Y
				fent.Velocity.Y = 0
				fent.Velocity.X = -fent.RunSpeed
				if math.abs(fent.RunSpeed) >= Isaac_Tower.FlayerHandlers.RunSpeed then
					SetState(fent, "Бег")
				else
					SetState(fent, "НачалоБега")--fent.State = 3
				end
				fent.CanJump = true
				fent.InputWait = nil
				Isaac_Tower.HandleMoving(player) --player:Update()
				return
			end
		else
			if not fent.InputWait then
				fent.InputWait = 15 --10
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
		--if fent.CollideCeiling then
		--	SetState(fent, "Удар_об_потолок")
		--	fent.RunSpeed = 0
		--	fent.Velocity = Vector(0,0)
		--	spr:Play("super_jump_collide")
		--	fent.Flayer.Queue = "super_jump_fall"
		--	return
		--end

		if math.abs(fent.RunSpeed) > Isaac_Tower.FlayerHandlers.RunSpeed then
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
		Isaac_Tower.FlayerHandlers.SpeedEffects(fent, spr, -90)

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
			spr.FlipX = not spr.FlipX

			local puf = spawnSpeedEffect(fent.Position+Vector(spr.FlipX and 26 or -26, -16), 
				Vector(-0, 0), spr.FlipX and 0 or 0,1) --fent.RunSpeed
			puf.Color = Color(1,1,1,0.5)
			puf.SpriteScale = Vector(math.min(1,fent.RunSpeed/20), math.min(1,fent.RunSpeed/20))
		end

		if Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr) then
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
		fent.RunSpeed = Isaac_Tower.FlayerHandlers.RunSpeed2 * fent.NewRotate
		fent.IgnoreSpeedCheck = true
		fent.CanJump = true
	end
end]]
Isaac_Tower.FlayerMovementState["Остановка_бега"] = function(player, fent, spr, idx)
	fent.CanJump = false
	if spr:GetAnimation() ~= "stopping_run" then
		spr:Play("stopping_run", true)
		spr.Rotation = 0
		spr.Offset = fent.Flayer.DefaultOffset
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

	if spr:IsPlaying("super_jump_fall") then
		spr:Play("super_jump_landing", true)
	end

	if spr:IsFinished(spr:GetAnimation()) and Flayer.Queue == -1 or fent.StateFrame > 360 then
		if fent.NextState then
			SetState(fent, fent.NextState)
		else
			SetState(fent, "Ходьба")
		end
	end
	return toReturn
end
Isaac_Tower.FlayerMovementState["Впечатался"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	local toReturn = {}
	--fent.CanJump = false
	toReturn.donttransformRunSpeedtoX = true
	--fent.RunSpeed = 0
	--fent.Velocity = Vector(0,0)

	if fent.OnGround and spr:IsFinished(spr:GetAnimation()) and Flayer.Queue == -1 or fent.StateFrame > 360 then
		if fent.NextState then
			SetState(fent, fent.NextState)
		else
			SetState(fent, "Ходьба")
		end
	end
	return toReturn
end
---@param spr Player_AnimManager
Isaac_Tower.FlayerMovementState["Удар_об_потолок"] = function(player, fent, spr, idx)
	local Flayer = fent.Flayer
	local toReturn = {}
	fent.CanJump = false
	toReturn.donttransformRunSpeedtoX = true
	--toReturn.dontLoseY = true
	--fent.RunSpeed = 0
	--fent.Velocity = Vector(0,0)

	if spr:IsFinished() then
		SetState(fent, "Ходьба")
		spr:Play("walk_jump_down", true)
		spr:ReplaceAnimOnce("walk_jump_down", "super_jump_fall")
	else
		toReturn.dontLoseY = true
		fent.RunSpeed = 0
		fent.Velocity = Vector(0,0)
	end

	--[[if spr:GetAnimation() ~= "super_jump_fall" then
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
			
			if Isaac_Tower.FlayerHandlers.GrabHandler(fent, spr) then
				return
			end
		end
		if fent.OnGround then
			SetState(fent, "Стомп_импакт_пол")
			spr:Play("super_jump_landing", true)
		end
	end]]
	

	--[[if spr:IsFinished(spr:GetAnimation()) and Flayer.Queue == -1 then
		if fent.NextState then
			SetState(fent, fent.NextState)
		else
			SetState(fent, "Ходьба")
		end
	end]]
	return toReturn
end
Isaac_Tower.FlayerMovementState["Урон"] = function(player, fent, spr, idx)
	local toReturn = {}
	toReturn.donttransformRunSpeedtoX = true
	if fent.DamageSource and fent.StateFrame <= 1 then
		local srcPos
		if fent.DamageSource.X then
			srcPos = fent.DamageSource
		else
			srcPos = fent.DamageSource.Position
		end
		if srcPos then
			local v = srcPos.X>fent.Position.X and -5 or 5
			fent.Velocity = Vector(v, -6)
			fent.grounding = 0
			local anm = v == 5 and true or false
			if spr.FlipX then 
				anm = not anm 
			end
			anm = anm and "hitb" or "hit"
			spr:Play(anm, true)
		end
		--fent.DamageSource = nil
		fent.InvulnerabilityFrames = fent.InvulnerabilityFrames or 120
	end
	if fent.OnGround and fent.StateFrame > 30 then
		SetState(fent, "Ходьба")
		fent.DamageSource = nil
	--elseif not (spr:IsPlaying("hit") or spr:IsPlaying("hitb")) then
	--	spr:Play("hit", true)
	end

	if fent.OnGround then
		fent.Velocity.X = fent.Velocity.X * 0.9
		if fent.Velocity.Y > 5 then
			for i = -1, 1 do
				if i ~= 0 then
					spawnDust(fent.Position + Vector(0, 16), Vector(i * 3, 0.5))
				end
			end
		end
		fent.Velocity.Y = math.min(0, fent.Velocity.Y)
	end
	return toReturn
end
Isaac_Tower.FlayerMovementState["Cutscene"] = function(player, fent, spr, idx)
	local toReturn = {donttransformRunSpeedtoX=true,dontLoseY=true}
	if fent.CutsceneLogic then
		fent.CutsceneLogic(player, fent, spr, idx)
	end

	return toReturn
end




function Isaac_Tower.HandleMoving(player)
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end

	player = player:ToPlayer() or player
	local idx = player.ControllerIndex
	local fent = player:GetData().Isaac_Tower_Data
	---@type Player_AnimManager
	local spr = fent.Flayer --and fent.Flayer --.Sprite
	--local Flayer = fent.Flayer and fent.Flayer --Flayer.Queue

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
	fent.HelpCollisionHori = nil
	fent.ShowSpeedEffect = nil
	if not spr then return end

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
			fent.HelpCollisionHori = result.HelpCollisionHori
		end
		--newVel.X = newVel.X + fent.RunSpeed
		
	end
	--print(spr:GetAnimation(), Flayer.Queue)
	if fent.StateFrame then
		fent.StateFrame = fent.StateFrame + 1
	end

	if fent.InvulnerabilityFrames then
		fent.InvulnerabilityFrames = fent.InvulnerabilityFrames - 1
		if fent.InvulnerabilityFrames <= 0 then
			fent.InvulnerabilityFrames = nil
		end
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
			fent.UseApperkot = nil
			fent.Velocity.Y =  math.min(0,fent.Velocity.Y)
			--newVel.Y = math.min(0,fent.Velocity.Y)
		end
		--fent.Velocity.Y = fent.Velocity.Y < 6 and fent.Velocity.Y + 0.4 or fent.Velocity.Y
		newVel.Y = fent.Velocity.Y < handler.FallMaxSpeed and fent.Velocity.Y + handler.FallAccel or fent.Velocity.Y  -- 6 0.4
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
		--[[local forvel = fent.ForsedVelocity.Velocity
		if not fent.ForsedVelocity.noGrav then
			forvel = Vector(fent.ForsedVelocity.Velocity.X, math.max(-6, fent.ForsedVelocity.Velocity.Y))
		end
		local revpower = 1-fent.ForsedVelocity.Power
		local power = fent.ForsedVelocity.Power
		--fent.Velocity = fent.Velocity*0.85 + forvel * 0.15 + newVel * (0.15 * fent.ForsedVelocity.Lerp)
		local lerp = 1-0.15*power
		local rlerp = 0.15*revpower --1 - lerp
		
		fent.Velocity = fent.Velocity*lerp + forvel * (0.15*power)
			+ newVel * (rlerp * (1-fent.ForsedVelocity.Lerp)*revpower)
		fent.ForsedVelocity.Time = fent.ForsedVelocity.Time - 1
		--print("ar",lerp,rlerp, fent.ForsedVelocity.Power, fent.ForsedVelocity.Lerp)
		--print("gg",fent.Velocity,newVel , (rlerp * fent.ForsedVelocity.Lerp*revpower))
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
		end]]
		----@type ForsedVelocity
		local ForsedVelocity = fent.ForsedVelocity
		ForsedVelocity.Time = ForsedVelocity.Time - 1

		if ForsedVelocity.MaxTime*0.66 < ForsedVelocity.Time then
			ForsedVelocity.Lerp = ForsedVelocity.Lerp*0.7 + 0.3
		else
			local ler = 1/(ForsedVelocity.MaxTime*0.66)
			ForsedVelocity.Lerp = ForsedVelocity.Lerp * (1-ler)
		end
		if not ForsedVelocity.noGrav then
			if fent.OnGround then
				ForsedVelocity.Velocity.Y = math.min(0, ForsedVelocity.Velocity.Y)
				ForsedVelocity.Velocity.X = ForsedVelocity.Velocity.X * 0.8
			else
				ForsedVelocity.Velocity.Y = ForsedVelocity.Velocity.Y < 6 and (ForsedVelocity.Velocity.Y + 0.4) or ForsedVelocity.Velocity.Y
			end
		end

		if ForsedVelocity.Time <= 0 then
			fent.ForsedVelocity = nil
		end
	else
		fent.Velocity = newVel
	end

	fent.Velocity.X = math.abs(fent.Velocity.X)>0.01 and fent.Velocity.X or 0
	fent.Velocity.Y = math.abs(fent.Velocity.Y)>0.001 and fent.Velocity.Y or 0

	--[[if fent.UnStickWallVel then
		fent.UnStickWallMaxTime = fent.UnStickWallTime or fent.UnStickWallMaxTime
		local lerp = fent.UnStickWallTime / fent.UnStickWallMaxTime
		fent.Velocity.X = fent.Velocity.X * (lerp-1) + fent.UnStickWallVel.X * lerp
		fent.Velocity.Y = 0
		fent.UnStickWallTime = fent.UnStickWallTime - 1
		if fent.UnStickWallTime <= 0 then
			fent.UnStickWallTime = nil
			fent.UnStickWallMaxTime = nil
			fent.UnStickWallVel = nil
		end
	end]]

	fent.RunSpeed = fent.RunSpeed<0 and math.min(fent.RunSpeed,fent.Velocity.X)
		or math.max(fent.RunSpeed, fent.Velocity.X)
	fent.RunSpeed = math.abs(fent.RunSpeed)>0.001 and fent.RunSpeed or 0

	fent.GrabDelay = fent.GrabDelay>0 and (fent.GrabDelay - 1) or fent.GrabDelay
	
	if spr then
		local curspr = spr.CurrentSpr
		local rep = spr.ReplaceOnce
		if rep then
			if not rep.T or not rep.R then
				spr.ReplaceOnce = nil
				--print("loss 1")
			else
				local cur = curspr:GetAnimation()
				if cur == rep.T then
					curspr:SetAnimation(rep.R)
					if curspr:GetFrame() == -1 then
						curspr:SetFrame(0)
					end
				elseif cur ~= rep.R then
					spr.ReplaceOnce = nil
					--print("loss 2", cur, rep.R, rep.T)
				end
				if cur == rep.R and curspr:IsFinished(rep.R) then
					spr.ReplaceOnce = nil
					--print("loss 3", cur, rep.R, rep.T)
				end
			end
		end

		if spr and spr.Queue ~= -1 and spr:IsFinished(spr:GetAnimation()) then
			spr:Play(spr.Queue, true)
			spr.Queue = -1
			spr.QueuePrior = nil
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


