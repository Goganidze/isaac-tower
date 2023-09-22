return function(mod)

local L54 = _G._VERSION == "Lua 5.4"
local Isaac_Tower = Isaac_Tower

local Isaac = Isaac
local game = Game()

local mainfilepath = 'gfx/doubleRender/'
local entCam = {ID = Isaac.GetEntityTypeByName('PIZTOW CamEnt'),VARIANT = Isaac.GetEntityVariantByName('PIZTOW CamEnt')}

local fastUpdate = not true

local BlackNotCube = Sprite()
BlackNotCube:Load(mainfilepath .. "black.anm2",true)
BlackNotCube:Play("ПрямоугольникМалевича",true)

--TSJDNHC_PT = {}
local TSJDNHC = {} --TSJDNHC_PT  

TSJDNHC.Callbacks = {}
local function addCallbackID(name)
	TSJDNHC.Callbacks[name] = setmetatable({},{__concat = function(_,b) return "[TSJDNHC] "..name..b end})
end 

local Callbacks = {
	PRE_BACKDROP_RENDER = {},
	FLOOR_BACKDROP_RENDER = {},
	WALL_BACKDROP_RENDER = {},
	GRID_BACKDROP_RENDER = {},
	SHADING_BACKDROP_RENDER = {},
	OVERLAY_BACKDROP_RENDER = {},
	GRID_POINTS_GEN = {},
	ENTITY_POSTRENDER = {},
	ISAAC_TOWER_POST_ALL_ENEMY_RENDER = {},
}
for i,k in pairs(Callbacks) do
	addCallbackID(i)
end

local Filepath = {
	FloorBackdrop = mainfilepath .. 'FloorBackdrop_cam.anm2',
	WallBackdrop = mainfilepath .. 'WallBackdrop_cam.anm2',
	RoomShading = mainfilepath .. 'RoomShading.anm2',
}

local CameraEntity
local callbackOn

local Wtr = 20/13 -- 1.54
local DefaultPos = Vector(0,0)
local CameraPos = Vector(0,0)
local CameraOffset = Vector(52,52)*Wtr --Vector(221,143)
local TopLeftPos = Vector(60,140)
local BDCenter = Vector(320,280)/Wtr  --Vector(221,143)*1.54
local bg_RenderPos = Vector(240,135)
local entitiesShadowOffset = Vector(0,1) --Vector(19,-7)
local fixpos = -Vector(221,143)+Vector(52,52)-TopLeftPos/Wtr

local fakeShadow

local ShapeToRoomShading = {
		[1] = mainfilepath .. 'fake_shading.png',
		[2] = mainfilepath .. 'fake_shading_ih.png',
		[3] = mainfilepath .. 'fake_shading_iv.png',		
		[4] = mainfilepath .. 'fake_shading_1x2.png',
		[5] = mainfilepath .. 'fake_shading_iiv.png',
		[6] = mainfilepath .. 'fake_shading_2x1.png',
		[7] = mainfilepath .. 'fake_shading_iih.png',
		[8] = mainfilepath .. 'fake_shading_2x2.png',
		[9] = mainfilepath .. 'fake_shading_ltl.png',
		[10] = mainfilepath .. 'fake_shading_ltr.png',
		[11] = mainfilepath .. 'fake_shading_lbl.png',
		[12] = mainfilepath .. 'fake_shading_lbr.png',
	}
local RoomClamp = {
		[1] = {0,0,0,0},
		[2] = {0,0,0,0},
		[3] = {0,0,0,0},
		[4] = {0,0,0,182},
		[5] = {0,0,0,182},
		[6] = {0,0,338,0},
		[7] = {0,0,338,0},
		[8] = {0,0,338,182},
		[9] = {0,0,338,182},
		[10] = {0,0,338,182},
		[11] = {0,0,338,182},
		[12] = {0,0,338,182},
	}

local CreepEffectVariant = { 
		[22] = true,
		[23] = true,
		[24] = true,
		[25] = true,
		[26] = true,
		[32] = true,
		[78] = true,
	}

local ShapeToWallAnm2Layers = {
    ["1x2"] = 58,
    ["2x2"] = 63,
    ["2x2X"] = 21,
    ["IIH"] = 62,
    ["LTR"] = 63,
    ["LTRX"] = 19,
    ["2x1"] = 63,
    ["2x1X"] = 7,
    ["1x1"] = 44,
    ["LTL"] = 63,
    ["LTLX"] = 19,
    ["LBR"] = 63,
    ["LBRX"] = 19,
    ["LBL"] = 63,
    ["LBLX"] = 19,
    ["IIV"] = 42,
    ["IH"] = 36,
    ["IV"] = 28
}

local ShapeToName = {
    [RoomShape.ROOMSHAPE_IV] = "IV",
    [RoomShape.ROOMSHAPE_1x2] = "1x2",
    [RoomShape.ROOMSHAPE_2x2] = "2x2",
    [RoomShape.ROOMSHAPE_IH] = "IH",
    [RoomShape.ROOMSHAPE_LTR] = "LTR",
    [RoomShape.ROOMSHAPE_LTL] = "LTL",
    [RoomShape.ROOMSHAPE_2x1] = "2x1",
    [RoomShape.ROOMSHAPE_1x1] = "1x1",
    [RoomShape.ROOMSHAPE_LBL] = "LBL",
    [RoomShape.ROOMSHAPE_LBR] = "LBR",
    [RoomShape.ROOMSHAPE_IIH] = "IIH",
    [RoomShape.ROOMSHAPE_IIV] = "IIV"
}

local function StageAPIRandom(a, b, rng)
    rng = rng 
    if a and b then
        return rng:Next() % (b - a + 1) + a
    elseif a then
        return rng:Next() % (a + 1)
    end
    return rng:Next()
end


local function LoadBackdropSprite(sprite, backdrop, mode) -- modes are 1 (walls A), 2 (floors), 3 (walls B)
    sprite = sprite or Sprite()
    local BackdropRNG = RNG()
    BackdropRNG:SetSeed(game:GetRoom():GetDecorationSeed(), 1)

    local needsExtra
    local roomShape = game:GetRoom():GetRoomShape()
    local shapeName = ShapeToName[roomShape]
    if ShapeToWallAnm2Layers[shapeName .. "X"] then
        needsExtra = true
    end

    if mode == 3 then
        shapeName = shapeName .. "X"
    end

    if mode == 1 or mode == 3 then
        sprite:Load(Filepath.WallBackdrop, false)

        local corners
        local walls

        walls = backdrop.Walls
        corners = backdrop.Corners
        

        if walls then
            for num = 1, ShapeToWallAnm2Layers[shapeName] do
                local wall_to_use = walls[StageAPIRandom(1, #walls, BackdropRNG)]
                sprite:ReplaceSpritesheet(num, wall_to_use)
            end
        end

        if corners and string.sub(shapeName, 1, 1) == "L" then
            local corner_to_use = corners[StageAPIRandom(1, #corners, BackdropRNG)]
            sprite:ReplaceSpritesheet(0, corner_to_use)
        end
    elseif mode == 2 then
        sprite:Load(Filepath.FloorBackdrop, false)

        if backdrop.PreFloorSheetFunc then
            backdrop.PreFloorSheetFunc(sprite, backdrop, mode, shapeName)
        end

        local floors
        floors = backdrop.Floors or backdrop.Walls

        if floors then
            local numFloors
            if roomShape == RoomShape.ROOMSHAPE_1x1 then
                numFloors = 4
            elseif roomShape == RoomShape.ROOMSHAPE_1x2 or roomShape == RoomShape.ROOMSHAPE_2x1 then
                numFloors = 8
            elseif roomShape == RoomShape.ROOMSHAPE_2x2 then
                numFloors = 16
            end

            if numFloors then
                for i = 0, numFloors - 1 do
                    sprite:ReplaceSpritesheet(i, floors[StageAPIRandom(1, #floors, BackdropRNG)])
                end
            end
        end

        if backdrop.NFloors and string.sub(shapeName, 1, 1) == "I" then
            for num = 18, 19 do
                sprite:ReplaceSpritesheet(num, backdrop.NFloors[StageAPIRandom(1, #backdrop.NFloors, BackdropRNG)])
            end
        end

        if backdrop.LFloors and string.sub(shapeName, 1, 1) == "L" then
            for num = 16, 17 do
                sprite:ReplaceSpritesheet(num, backdrop.LFloors[StageAPIRandom(1, #backdrop.LFloors, BackdropRNG)])
            end
        end
    end

    sprite:LoadGraphics()

    local renderPos = game:GetRoom():GetTopLeftPos()
    if mode ~= 2 then
        renderPos = renderPos - Vector(80, 80)
    end

    sprite:Play(shapeName, true)
    return renderPos, needsExtra, sprite
end

local DoubleRenderCondition = false
function TSJDNHC.ConditionUpdate()
	DoubleRenderCondition = false
	if (fastUpdate or Isaac.GetFrameCount()%2 == 0) and CameraEntity and CameraEntity.Ref then 
		local d = CameraEntity.Ref:GetData()
		if d.IsEnable and d.renderlist then --and not d.IsCamRender then
			DoubleRenderCondition = true
		end

		if d.CurrentCameraScale > 1 then
			fastUpdate = true
		else
			fastUpdate = false
		end
	end
	--print(DoubleRenderCondition)
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, TSJDNHC.ConditionUpdate)

local function RenTrack(_,ent)
	--if (fastUpdate or Isaac.GetFrameCount()%2 == 0) and CameraEntity and CameraEntity.Ref then 
	if DoubleRenderCondition then
		local d = CameraEntity.Ref:GetData()

		--if not d.SpecialRender.igronelist[ent.Index] and d.renderlist and not d.IsCamRender then
		if not d.IsCamRender and not d.SpecialRender.igronelist[ent.Index] then
			if Isaac_Tower.InAction then
				d.renderlist.entityAbove[#d.renderlist.entityAbove+1] = {ent,(ent.Position)/Wtr} 
			else
				d.renderlist.entity[#d.renderlist.entity+1] = {ent,(ent.Position)/Wtr,(ent.Size == 0 and 0 or (12+ent.Size/4)/25)} -- -Vector(320,280))/Wtr} 
			end
		end
	end
end
local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')
local function ERenTrack(_,ent)
	--if (fastUpdate or Isaac.GetFrameCount()%2 == 0) and CameraEntity and CameraEntity.Ref then 
	if DoubleRenderCondition and ent and ent:Exists() then
		local d = CameraEntity.Ref:GetData()

		if Isaac_Tower.InAction then
			--if not d.SpecialRender.igronelist[ent.Index] and d.renderlist and not d.IsCamRender and ent and ent:Exists() then
			if not d.IsCamRender and not d.SpecialRender.igronelist[ent.Index] then
				local data = ent:GetData()
				if data and (data.RA or not data.ml and 
				(data.Isaac_Tower_Data and data.Isaac_Tower_Data.GrabbedBy or Isaac_Tower.ENT.AboveRender[ent.Variant])) then
					d.renderlist.entityAbove[#d.renderlist.entityAbove+1] = {ent,(ent.Position)/Wtr} -- -Vector(320,280))/Wtr} 
				elseif ent.Type and (ent.Variant ~= entCam.VARIANT) then
					d.renderlist.entity[#d.renderlist.entity+1] = {ent,(ent.Position)/Wtr} -- -Vector(320,280))/Wtr} 
				end
			end
		else
			--if not d.SpecialRender.igronelist[ent.Index] and d.renderlist and not d.IsCamRender and ent and ent:Exists() then
			if not d.IsCamRender and not d.SpecialRender.igronelist[ent.Index] then
				if ent.Type  and CreepEffectVariant[ent.Variant] then --and ent.Type == 1000
					d.renderlist.creep[#d.renderlist.creep+1] = {ent,(ent.Position)/Wtr} -- -Vector(320,280))/Wtr} 
				elseif ent.Type and (ent.Type ~= 1000 or (ent.Type == 1000 and ent.Variant ~= entCam.VARIANT)) then
					d.renderlist.entity[#d.renderlist.entity+1] = {ent,(ent.Position)/Wtr} -- -Vector(320,280))/Wtr} 
				end
			end
		end
	end
end

local underGridType = {[1]=true,[7]=true,[8]=true,[9]=true,[10]=true,[17]=true,[18]=true, }

function TSJDNHC.CamEntUpdat(_,e)
	local s = e:GetSprite()
	local d = e:GetData()
	if e.SubType == 2 and d.init and d.IsEnable then

		bg_RenderPos = Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2)

		if not CameraEntity or CameraEntity.Ref == nil then
			CameraEntity = EntityPtr(e)
			if not callbackOn then
				mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, RenTrack)
				mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, RenTrack)
   				mod:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, RenTrack)
   				mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_LASER_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_KNIFE_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, ERenTrack)
				callbackOn = true
			end
		end

		local roomDescriptor = game:GetLevel():GetCurrentRoomDesc()
		local RoomIndex = roomDescriptor.ListIndex

		if d.TargetEntity and type(d.TargetEntity) == 'table' then
			for i=1, #d.TargetEntity do
				if not d.TargetEntity[i] or not d.TargetEntity[i]:Exists() then
					d.TargetEntity[i] = d.TargetEntity[i+1]
				end
			end
			if #d.TargetEntity == 0 then
				d.TargetEntity = nil
				local result = Isaac.RunCallback('TSJDNHC_FULL_FOCUS_LOST',e)
				if result ~= nil and result.Size then
					d.TargetEntity = result
				else
					TSJDNHC:ClearFocus()
				end
			end
		end

		if d.CurrentCameraPosition.X ~= d.CurrentCameraPosition.X then
			d.CurrentCameraPosition = Vector(0,0)
		end
		
		--d.CurrentCameraPosition = Vector(math.floor(d.CurrentCameraPosition.X*20)/20,math.floor(d.CurrentCameraPosition.Y*20)/20)
		
		e.DepthOffset = 21000000

		if not d.WallSprite then
			e:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

			d.RoomIndex = RoomIndex 
		else
			--print()
			d.CurrentCameraScale = (d.CurrentCameraScale*0.9 + d.CameraScale*0.1)
			if math.abs(d.CameraScale-d.CurrentCameraScale)<0.001 then
				d.CurrentCameraScale = d.CameraScale
			end
			local scale = Vector(d.CurrentCameraScale or 1,d.CurrentCameraScale or 1)
			d.FloorSprite.Scale = scale
			d.WallSprite.Scale = scale
			d.WallSprite2.Scale = scale
			d.RoomShading.Scale = scale
		end

		if d.RoomIndex ~= RoomIndex then
			d.RoomIndex = RoomIndex 
			d.renderlist.stein = {}
		end 

		if not d.renderlist then
			d.renderlist = {stein = {}, creep = {}, rock = {}, entity = {}, entityAbove = {} }
		end

		d.CameraOffset = Vector(-20,60) - e.Position
		local centerPos = game:GetRoom():GetRoomShape()>8 and Vector(580,420) or game:GetRoom():GetCenterPos()
		d.CenterPos = Isaac.WorldToRenderPosition(centerPos)*d.CurrentCameraScale+bg_RenderPos*(1-d.CurrentCameraScale)
		
		if #e:GetData().renderlist["stein"]>100 then
			for i=2,#e:GetData().renderlist["stein"]+1 do
				e:GetData().renderlist["stein"][i-1] = e:GetData().renderlist["stein"][i]
				if i<51 then
					if e:GetData().renderlist["stein"][i-1] and e:GetData().renderlist["stein"][i-1][2] then
						local clr = e:GetData().renderlist["stein"][i-1][3]
						--e:GetData().renderlist["stein"][i-1][2].Color = Color(clr.R,clr.G,clr.B, 1-(i/2)/50)
						clr.A = clr.A-0.02 
						d.renderlist.stein[i-1][2].Color = clr
					end
				elseif i>110 then
					d.renderlist.stein[i-1] = nil
				end
			end
		end
		d.renderlist.rock = {}
		d.renderlist.underrock = {}
		for i=0, game:GetRoom():GetGridSize() do
			local ent = game:GetRoom():GetGridEntity(i)
			if ent and ent:GetType() ~= 15 then
				local gesp = ent:GetSprite()
				local Pos --= Isaac.WorldToRenderPosition(ent.Position)
				local offset = ent:ToDoor() and ent:ToDoor():GetSpriteOffset()*Wtr or Vector(0,0)
				--d.renderlist.rock[i] = {Pos,spr,ent,(ent.Position-CameraEntity.Ref.Position-BDCenter+offset)/Wtr}
				local totab = underGridType[ent:GetType()] and "underrock" or "rock"
				d.renderlist[totab][i] = {nil,nil,ent,(ent.Position-Vector(320,280))/Wtr}
			end
		end
		--for i,ent in ipairs(d.SpecialRender.rock) do
		--	if ent and ent:Exists() then
		--		local gesp = ent:GetSprite()
		--		local Pos --= Isaac.WorldToRenderPosition(ent.Position)
		--		--d.renderlist.rock[i] = {Pos,nil,ent,(ent.Position-CameraEntity.Ref.Position-BDCenter)/Wtr}
		--		d.renderlist.rock[i] = {Pos,nil,ent,(ent.Position-Vector(320,280))/Wtr}
		--	end
		--end

		if d.CurrentCameraScale ~= 1 then
			for i=0,game:GetNumPlayers()-1 do
				local player = Isaac.GetPlayer(i) 
				player:AddCacheFlags(CacheFlag.CACHE_SIZE)
 				player:EvaluateItems()
			end
		end
		
	elseif e.SubType == 2 and not d.init  then --and e.FrameCount > 10
		d.init = true
		d.CameraScale = 1
		d.CurrentCameraScale = 1
		d.CurrentCameraPosition = Vector(0,0)
		d.FloorPersiOffset = Vector(0,0)
		d.WallPersiOffset = Vector(0,0)

		d.FloorSprite = Sprite()

		d.WallSprite = Sprite()

		d.WallSprite2 = Sprite()

		d.RoomShading = Sprite()
		d.RoomShading:Load(Filepath.RoomShading,false)
		d.RoomShading:ReplaceSpritesheet(0,ShapeToRoomShading[game:GetRoom():GetRoomShape()])
		d.RoomShading:LoadGraphics()
		d.RoomShading:Play(tostring(game:GetRoom():GetRoomShape()))

		d.SpecialRender = {igronelist = {}, room = {}, stein = {}, creep = {}, rock = {}, underrock = {}, entity = {} }
		d.renderlist = {stein = {}, creep = {}, rock = {}, underrock = {}, entity = {}, entityAbove = {} }
		--e:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

		local roomDescriptor = game:GetLevel():GetCurrentRoomDesc()
		local RoomIndex = roomDescriptor.ListIndex
		d.RoomIndex = RoomIndex 

		d.fakeShadow = Sprite()
		d.fakeShadow:Load(mainfilepath .. "shadiv.anm2",true)
		d.fakeShadow:Play('shadiv')
		d.fakeShadow.Offset = entitiesShadowOffset --Vector(0,1)
		d.fakeShadow.Color = Color(1,1,1,0.2)

		d.CenterPos = Isaac.WorldToRenderPosition(game:GetRoom():GetCenterPos())
		d.ofsset = 1
		d.FocusMode = 1
		d.StainVisible = true
		d.RoomShadingVisible = true

		if not CameraEntity or CameraEntity.Ref == nil then
			CameraEntity = EntityPtr(e)

			if not callbackOn then
				mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, RenTrack)
				mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, RenTrack)
   				mod:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, RenTrack)
   				mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_LASER_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_KNIFE_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, RenTrack)
    				mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, ERenTrack)
				callbackOn = true
			end
		else
			CameraEntity.Ref:Remove()
			CameraEntity = EntityPtr(e)
		end
	end
end

function TSJDNHC.ChangeCamSpriteOffsets()
	if CameraEntity and CameraEntity.Ref ~= nil then
		local d = CameraEntity.Ref:GetData()

		if d.StageAPIGfx then
			local offs,needextra,WallSprite = LoadBackdropSprite(nil, d.StageAPIGfx, 1)
			d.WallSprite = WallSprite
			
			_,_,FloorSprite = LoadBackdropSprite(nil, d.StageAPIGfx, 2) 
			d.FloorSprite = FloorSprite
			if needextra then
				d.WallSprite2.Color = Color(1,1,1,1)
				_,_,WallSprite2 = LoadBackdropSprite(nil, d.StageAPIGfx, 3)
				d.WallSprite2 = WallSprite2
			else
				d.WallSprite2.Color = Color(1,1,1,0)
			end
		end

		d.RoomShading:Play(game:GetRoom():GetRoomShape())
		d.RoomShading:ReplaceSpritesheet(0,ShapeToRoomShading[game:GetRoom():GetRoomShape()])
		d.RoomShading:LoadGraphics()

		d.CenterPos = Vector(0,0) --Isaac.WorldToRenderPosition(Game():GetRoom():GetCenterPos())*d.CurrentCameraScale+bg_RenderPos*(1-d.CurrentCameraScale)

		if d.TargetEntity then
			local clsh = RoomClamp[game:GetRoom():GetRoomShape()]
			if type(d.TargetEntity) ~= 'table' then
				local targetPos = ((d.TargetEntity.Position+d.TargetEntity.Velocity*15)/Wtr+fixpos)
				if d.TargetEntity.Type == 1 then
					LerpPower = 0.05
				end
				d.CameraPosition = targetPos
			else
				local cenpos = Vector(0,0)
				for i,ent in pairs(d.TargetEntity) do
					if ent and ent.Position then
						cenpos = cenpos + ent.Position
					end
				end
				cenpos = cenpos/#d.TargetEntity
				cenpos = (cenpos/Wtr+fixpos)
				d.CameraPosition = cenpos
			end
		end
		if d.CameraPosition then
			local clsh = RoomClamp[game:GetRoom():GetRoomShape()]
			local targetPos = d.CameraPosition
			if d.FocusMode == 2 then	
				local scaleclamp = Vector(140,97)*(d.CurrentCameraScale-1)
				local dr = {(clsh[1]-scaleclamp.X), (clsh[2]-scaleclamp.Y), (clsh[3]+scaleclamp.X), (clsh[4]+scaleclamp.Y)}
				targetPos:Clamp(clsh[1]-scaleclamp.X,clsh[2]-scaleclamp.Y,
					clsh[3]+scaleclamp.X,clsh[4]+scaleclamp.Y)
			end
			d.CurrentCameraPosition = targetPos
		end
	end
end

local font = Font()
font:Load("font/upheaval.fnt")

local maxTime = 0
local t = 0
function TSJDNHC.FakeCamfloorRender(_, e, ofsset)
  local d = e:GetData()
  t = Isaac.GetTime()
  if e.SubType == 2 and e:Exists() and d.renderlist and d.WallSprite and d.IsEnable then
	local s = e:GetSprite()
	local d = e:GetData()


	local LerpPower = 0.05 
	local scale = d.CurrentCameraScale --math.floor(d.CurrentCameraScale*40)/40
	
	if not game:IsPaused() then
		if d.FocusMode ~= 1 then
			d.ofsset = d.ofsset and (d.ofsset*0.95 + 0) or 0
		elseif d.FocusMode == 1 then
			d.ofsset = d.ofsset and (d.ofsset*0.95 + 0.05) or 1
		end
		if d.TargetEntity then
			
			local clsh = RoomClamp[game:GetRoom():GetRoomShape()]
			if type(d.TargetEntity) ~= 'table' then
				local targetPos = ((d.TargetEntity.Position+d.TargetEntity.Velocity*45)/Wtr+fixpos)
				if d.TargetEntity.Type == 1 then
					LerpPower = 0.05
				end
				d.CameraPosition = targetPos
			else
				local cenpos = Vector(0,0)
				for i,ent in pairs(d.TargetEntity) do
					if ent and ent.Position then
						cenpos = cenpos + ent.Position
					end
				end
				cenpos = cenpos/#d.TargetEntity
				cenpos = (cenpos/Wtr+fixpos)
				d.CameraPosition = cenpos
			end
		end
		if d.CameraPosition or d.FocusCameraPosition then
			local LerpP = d.FocusLerp or LerpPower
			local clsh = d.RoomClamp or RoomClamp[game:GetRoom():GetRoomShape()]

			local targetPos = d.FocusCameraPosition or d.CameraPosition
 			if d.FocusCameraPosition and d.CameraPosition and (d.CameraPosition.X~=0 or d.CameraPosition.Y~=0) then
				targetPos = (d.FocusCameraPosition*LerpP + d.CameraPosition*(1-LerpP))/2
			end

			if d.CurrentCameraPosition.X ~= targetPos.X or d.CurrentCameraPosition.Y ~= targetPos.Y then
				d.CurrentCameraPosition = d.CurrentCameraPosition*(1-LerpPower) + targetPos*LerpPower
			end

			if d.FocusMode == 2 then	
				local scaleclamp = Vector(140,97)*(scale-1)
				local dr = {(clsh[1]-scaleclamp.X), (clsh[2]-scaleclamp.Y), (clsh[3]+scaleclamp.X), (clsh[4]+scaleclamp.Y)}
				d.CurrentCameraPosition:Clamp(math.min(dr[1],dr[1]+scaleclamp.X), math.min(dr[2],dr[2]+scaleclamp.Y),
					math.max(dr[3],dr[3]-scaleclamp.X), math.max(dr[4],dr[4]-scaleclamp.Y))
			end

			if d.FocusLerp then
				if d.FocusCameraPosition then
					--local Xl,Yl = math.floor(d.CurrentCameraPosition.X), math.floor(d.CurrentCameraPosition.Y)
					local Xl = math.floor(d.CurrentCameraPosition.X)
					if Xl == math.floor(d.FocusCameraPosition.X) then
						local Yl = math.floor(d.CurrentCameraPosition.Y)
						if Yl == math.floor(d.FocusCameraPosition.Y) then
							d.FocusLerp = nil
						end
					end
				else
					d.FocusLerp = nil
				end
			end

			--d.CurrentCameraPosition = Vector(math.floor(d.CurrentCameraPosition.X*20)/20,math.floor(d.CurrentCameraPosition.Y*20)/20)
		end
	end
	--d.CurrentCameraPosition = Vector(math.floor(d.CurrentCameraPosition.X*10)/10,math.floor(d.CurrentCameraPosition.Y*10)/10)

	local CameraPosition = d.CurrentCameraPosition*scale or Vector(0,0)

	ofsset = ofsset*d.ofsset*scale

	d.IsCamRender = true

	local zeroPos = Isaac.WorldToRenderPosition(Vector(0,0)) --ofsset
	local zeroOffset = BDCenter*(scale-1)
	
	local CameraOffset = ofsset-CameraPosition
	
	local Pos = d.CenterPos+CameraOffset --d.CenterPos and d.CenterPos+ofsset+CameraPosition or Vector(0,0)
	
	BlackNotCube:Render(bg_RenderPos)

	Isaac.RunCallback(TSJDNHC.Callbacks.PRE_BACKDROP_RENDER, Pos, CameraOffset, scale)

	d.FloorSprite:Render(Pos) 
	--d.SpecialRender.room[id] = {Wall = tab.Wall, Floor = tab.Floor, Shading = tab.Shading, Overlay = tab.Overlay}
	for i,k in pairs(d.SpecialRender.room) do
		if k.Floor then
			k.Floor.Scale = Vector(1,1)*scale
			k.Floor:Render(Pos+k.Offset*scale)
		end
	end

	Isaac.RunCallback(TSJDNHC.Callbacks.FLOOR_BACKDROP_RENDER, Pos, CameraOffset, scale)

	--print(d.StainVisible)
	if d.CurrentCameraScale>0.4 and d.StainVisible then
	    for i,k in pairs(d.renderlist.stein) do
		if k and k[2] then
			if scale~=1 then
				local sclae = -(k[1]-Vector(320,280))/Wtr
				local scaledOffset = ((scale-1)*sclae) or Vector(0,0) ---sclae
				local trueScale = k[2].Scale*1
				k[2].Scale = k[2].Scale*scale
				k[2]:Render(k[4]-scaledOffset+CameraOffset) --Isaac.WorldToRenderPosition(k[1])
				k[2].Scale = trueScale
			else
				k[2]:Render(k[4]+CameraOffset)
			end
		end
	    end
	end

	for i,k in pairs(d.renderlist.creep) do
		if k then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = ((scale-1)*k[2]) or Vector(0,0) ---k[2]
				local trueScale = k[1]:GetSprite().Scale*1
				k[1]:GetSprite().Scale = k[1]:GetSprite().Scale*scale
				k[1]:Render(scaledOffset+CameraOffset)
				k[1]:GetSprite().Scale = trueScale
			else
				k[1]:Render(CameraOffset)
			end
		end
	end 

	for i,k in pairs(d.renderlist.entity) do
		if k and k[1] and k[1].Type<1000 then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = ((scale-1)*(k[2])-zeroOffset) or Vector(0,0) ---k[2]
				local ShadowScale = ( k[3] or (k[1].Size == 0 and 0 or ((12+k[1].Size/4)/25)) )*scale
				d.fakeShadow.Scale = Vector(ShadowScale,ShadowScale)
				d.fakeShadow:Render(k[2]+scaledOffset+CameraOffset+zeroPos)
			else
				local ShadowScale = k[3] or (k[1].Size == 0 and 0 or (12+k[1].Size/4)/25)  --*d.CurrentCameraScale
				d.fakeShadow.Scale = Vector(ShadowScale,ShadowScale)
				d.fakeShadow:Render(k[2]+CameraOffset+zeroPos) --zeroPos+bg_RenderPos
			end
			
		end
	end 

	if d.WallSprite and d.WallSprite:GetAnimation() then
		d.WallSprite:Render(Pos)
	end
	if d.WallSprite2 then
		d.WallSprite2:Render(Pos)
	end

	Isaac.RunCallback(TSJDNHC.Callbacks.WALL_BACKDROP_RENDER, Pos, CameraOffset, scale)

	for i,k in pairs(d.SpecialRender.room) do
		if k.Wall then
			if d.CurrentCameraScale ~= 1 then
				local trueScale = k.Wall.Scale/1
				k.Wall.Scale = k.Wall.Scale*scale
				k.Wall:Render(Pos+k.Offset*scale)
				k.Wall.Scale = trueScale
			end
			k.Wall:Render(Pos+k.Offset*scale)
		end
	end

	for i,k in pairs(d.renderlist.underrock) do
		if k and k[4] and k[3] then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = ((scale-1)*k[4]) or Vector(0,0) ---k[4]
				local trueScale = k[3]:GetSprite().Scale/1
				k[3]:GetSprite().Scale = k[3]:GetSprite().Scale*scale
				k[3]:Render(scaledOffset+CameraOffset)
				k[3]:GetSprite().Scale = trueScale
			else
				k[3]:Render(CameraOffset)
			end
		end
	end

	Isaac.RunCallback(TSJDNHC.Callbacks.GRID_BACKDROP_RENDER, Pos, CameraOffset, scale)

	for i,k in pairs(d.renderlist.rock) do
		if k and k[4] and k[3] then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = ((scale-1)*k[4]) or Vector(0,0) ---k[4]
				local trueScale = k[3]:GetSprite().Scale/1
				k[3]:GetSprite().Scale = k[3]:GetSprite().Scale*scale
				k[3]:Render(scaledOffset+CameraOffset)
				k[3]:GetSprite().Scale = trueScale
			else
				k[3]:Render(CameraOffset)
			end
		end
	end 

	if d.RoomShadingVisible and d.RoomShading and d.RoomShading:GetFrame()>=0 then
		d.RoomShading:Render(Pos)
	end

	for i,k in pairs(d.SpecialRender.room) do
		if k.Shading then
			k.Shading.Scale = Vector(1,1)*scale
			k.Shading:Render(Pos+k.Offset*scale)
		end
	end
	Isaac.RunCallback(TSJDNHC.Callbacks.SHADING_BACKDROP_RENDER, Pos, CameraOffset, scale)
	
	for i,k in pairs(d.renderlist.entity) do
		
		if k and k[1] and k[1]:Exists() then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = k[2]*(scale-1)-zeroOffset  -- -k[2]--(d.CurrentCameraScale*k[2]-k[2]) or Vector(0,0)
				local trueScale = k[1]:GetSprite().Scale/1
				local TruePositionOfset = k[1].PositionOffset/1
			
				if k[1].Type == 1 then
					--local trueScale = k[1].SpriteScale/1
					k[1].PositionOffset = k[1].PositionOffset*scale
					--k[1].SpriteScale = k[1].SpriteScale*d.CurrentCameraScale
					k[1]:Render(scaledOffset+CameraOffset)
					--k[1]:ToPlayer():RenderGlow(Vector(120,120))
					k[1].PositionOffset = TruePositionOfset
					--if not Game():IsPaused() then
						--k[1].Size = k[1].Size / d.CurrentCameraScale 
					--end
				else
					k[1].PositionOffset = k[1].PositionOffset*scale
					k[1]:GetSprite().Scale = k[1]:GetSprite().Scale*scale
					k[1]:Render(scaledOffset+CameraOffset)
					k[1]:GetSprite().Scale = trueScale
					k[1].PositionOffset = TruePositionOfset
				end
			else
				k[1]:Render(CameraOffset)
			end
			
			Isaac.RunCallbackWithParam(TSJDNHC.Callbacks.ENTITY_POSTRENDER, k[1].Type, k[1], Pos-d.CenterPos, CameraOffset, d.CurrentCameraScale)
		end
	end 

	Isaac.RunCallback(TSJDNHC.Callbacks.ISAAC_TOWER_POST_ALL_ENEMY_RENDER, Pos, CameraOffset, scale)

	for i,k in pairs(d.renderlist.entityAbove) do
		
		if k and k[1] and k[1]:Exists() then
			if d.CurrentCameraScale~=1 then
				local scaledOffset = k[2]*(scale-1)-zeroOffset
				local trueScale = k[1]:GetSprite().Scale/1
				local TruePositionOfset = k[1].PositionOffset/1
			
				if k[1].Type == 1 then
					k[1].PositionOffset = k[1].PositionOffset*scale
					k[1]:Render(scaledOffset+CameraOffset)
					k[1].PositionOffset = TruePositionOfset
				else
					k[1].PositionOffset = k[1].PositionOffset*scale
					k[1]:GetSprite().Scale = k[1]:GetSprite().Scale*scale
					k[1]:Render(scaledOffset+CameraOffset)
					k[1]:GetSprite().Scale = trueScale
					k[1].PositionOffset = TruePositionOfset
				end
			else
				k[1]:Render(CameraOffset)
			end
			
			Isaac.RunCallbackWithParam(TSJDNHC.Callbacks.ENTITY_POSTRENDER, k[1].Type, k[1], Pos-d.CenterPos, CameraOffset, d.CurrentCameraScale)
		end
	end 


	if d.State then
		if d.State == 2 then
			d.BlackAlpha = d.BlackAlpha and (d.BlackAlpha-0.1) or 1 
			BlackNotCube.Color = Color(1,1,1,d.BlackAlpha)
			BlackNotCube:Render(bg_RenderPos)
			if d.BlackAlpha <= 0 then
				d.State = nil
				d.BlackAlpha = nil
			end
			BlackNotCube.Color = Color(1,1,1,1)
		elseif d.State == 3 then
			d.BlackAlpha = d.BlackAlpha and (d.BlackAlpha+0.1) or 0 
			BlackNotCube.Color = Color(1,1,1,d.BlackAlpha)
			BlackNotCube:Render(bg_RenderPos)
			if d.BlackAlpha >= 1 then
				d.State = 4
				d.BlackAlpha = nil
				d.IsEnable = false
				for i=0,game:GetNumPlayers()-1 do
					local player = Isaac.GetPlayer(i) 
					player:AddCacheFlags(CacheFlag.CACHE_SIZE)
 					player:EvaluateItems()
				end
			end
			BlackNotCube.Color = Color(1,1,1,1)
		end
	end

	for i,k in pairs(d.SpecialRender.room) do
		if k.Overlay then
			k.Overlay.Scale = Vector(1,1)*scale
			k.Overlay:Render(Pos+k.Offset*scale)
		end
	end
	Isaac.RunCallback(TSJDNHC.Callbacks.OVERLAY_BACKDROP_RENDER, Pos, CameraOffset, scale)

	if fastUpdate or Isaac.GetFrameCount()%2 == 0 then
	d.renderlist = {stein = d.renderlist.stein or {}, 
		creep = {}, 
		rock = d.renderlist.rock, 
		underrock = d.renderlist.underrock, 
		entity = {},
		entityAbove = {}, } 
	end
	d.IsCamRender = false

	--local time = Isaac.GetTime()-t
	--font:DrawStringUTF8(time,100,20,KColor(1,1,1,1),1,true)
	--maxTime = maxTime*0.8+time*0.2   --math.max(maxTime, time)
	--font:DrawStringUTF8(math.ceil(maxTime),70,20,KColor(1,1,1,1),1,true)
	--if Isaac.GetFrameCount()%200 == 0 then
	--	maxTime = 0
	--end
	--t = Isaac.GetTime()
  elseif e.SubType == 2 and e:Exists() and d.renderlist and d.WallSprite and not d.IsEnable then
	if d.State then
		if d.State == 1 then
			d.BlackAlpha = d.BlackAlpha and (d.BlackAlpha+0.1) or 0 
			BlackNotCube.Color = Color(1,1,1,d.BlackAlpha)
			BlackNotCube:Render(bg_RenderPos)
			if d.BlackAlpha >= 1 then
				d.IsEnable = 1
				d.State = 2 
				d.BlackAlpha = nil
				for i=0,game:GetNumPlayers()-1 do
					local player = Isaac.GetPlayer(i) 
					player:AddCacheFlags(CacheFlag.CACHE_SIZE)
 					player:EvaluateItems()
				end
			end
		elseif d.State == 4 then
			d.BlackAlpha = d.BlackAlpha and (d.BlackAlpha-0.1) or 1 
			BlackNotCube.Color = Color(1,1,1,d.BlackAlpha)
			BlackNotCube:Render(bg_RenderPos)
			if d.BlackAlpha <= 0 then
				d.State = nil
				d.BlackAlpha = nil
			end
			BlackNotCube.Color = Color(1,1,1,1)
		end
	end
  end
end

--mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, -1000, function ()
	--local time = Isaac.GetTime()-t
	--font:DrawStringUTF8(time,130,20,KColor(1,1,1,1),1,true)
	--maxTime = (maxTime + time)/2   --math.max(maxTime, time)
	--font:DrawStringUTF8("render",50,20,KColor(1,1,1,1),1,true)
	--font:DrawStringUTF8(math.ceil(maxTime),100,20,KColor(1,1,1,1),1,true)
	--if Isaac.GetFrameCount()%60 == 0 then
	--	maxTime = 0
	--end
--end)

local function FakeCamstein(_,e)
	if e:HasEntityFlags(EntityFlag.FLAG_RENDER_WALL) or e:HasEntityFlags(EntityFlag.FLAG_RENDER_FLOOR) and e.Variant ~= entCam.VARIANT then
	    if CameraEntity and CameraEntity.Ref ~= nil then
		local floor = CameraEntity.Ref 
		if floor and floor:Exists() and floor:GetData().StainVisible and floor:GetData().renderlist and floor:GetData().renderlist["stein"] then

			local spr = Sprite()
			spr:Load(e:GetSprite():GetFilename(),true)
			spr:Play(e:GetSprite():GetAnimation())
			spr:SetFrame(e:GetSprite():GetFrame())
			spr.Color = e.Color --e:GetSprite().Color
			if CameraEntity.Ref:GetData().StainColor and (e.Position.X<40 or e.Position.Y<80) then
				spr.Color = CameraEntity.Ref:GetData().StainColor 
				e.Color = CameraEntity.Ref:GetData().StainColor
			end
			spr.Scale = e:GetSprite().Scale
			spr.Rotation = e:GetSprite().Rotation
	
			local Pos = Isaac.WorldToRenderPosition(e.Position)

			floor:GetData().renderlist.stein[#floor:GetData().renderlist.stein+1] = {e.Position, 
				spr,
				e.Color, 
				Pos,
			}
		end
	    end
	end
end

local function PlayerScale(_,e,cache) 
	if cache == CacheFlag.CACHE_SIZE and CameraEntity and CameraEntity.Ref ~= nil then
		local d = CameraEntity.Ref:GetData()
		if d.IsEnable then
			e.SpriteScale = e.SpriteScale * d.CurrentCameraScale
			e.SizeMulti = Vector(10,10)*0.1 / math.max(0.3,math.min(1,d.CurrentCameraScale)) -- math.min(1,-d.CurrentCameraScale)
		end
	end
end

local function BDCommand(_, cmd, params)
	if cmd == "RemoveCameraEnt" then
		for i, p in pairs(Isaac.FindByType(entCam.ID, entCam.VARIANT, 2, true, false)) do
			p:Remove()
		end
	elseif cmd == "SetCamPos" then
		if CameraEntity and CameraEntity.Ref ~= nil then
			
			local d = CameraEntity.Ref:GetData()
			local leg = params:find(',')
			TSJDNHC:ClearFocus()
			if leg then
				local v1,v2 = tonumber(params:sub(1,leg-1)) , tonumber(params:sub(leg+1))
				if v1 and v2 then
					d.CameraPosition = Vector(v1,v2)
				else
					d.CameraPosition = Vector(0,0)
				end
			else
				d.CameraPosition = Vector(0,0)
				TSJDNHC:SetFocusEntity(Isaac.GetPlayer(), 2)
			end
		end
	elseif cmd == "SetCamScale" then
		local d = CameraEntity.Ref:GetData()
		if tonumber(params) and CameraEntity and CameraEntity.Ref ~= nil then
			d.CameraScale = tonumber(params)
		else
			d.CameraScale = 1
		end
		--TSJDNHC:SetFocusEntity(Isaac.GetPlayer(), 2)
	elseif cmd == "SetWallGfx" then
		if CameraEntity and CameraEntity.Ref ~= nil then
			local d = CameraEntity.Ref:GetData()
			for i=0,8 do
				if i~=4 then
					CameraEntity.Ref:GetSprite():ReplaceSpritesheet(i,params)
					d.WallSprite:ReplaceSpritesheet(i,params)
				end
			end
			CameraEntity.Ref:GetSprite():LoadGraphics()
			d.WallSprite:LoadGraphics()
		end
	elseif cmd == "SetFocus" then
		if CameraEntity and CameraEntity.Ref ~= nil then
			
			local d = CameraEntity.Ref:GetData()
			local leg = params:find(',')
			if leg then
				local v1,v2 = tonumber(params:sub(1,leg-1)) , tonumber(params:sub(leg+1))
				if v1 and v2 then
					d.FocusPosition = Vector(v1,v2)
				else
					d.FocusPosition = Vector(0,0)
				end
			else
				d.FocusPosition = nil
			end
		end
	end
end

function TSJDNHC:IsCamRender()
    if CameraEntity and CameraEntity.Ref then
	return CameraEntity.Ref:GetData().IsCamRender
    end
end

function TSJDNHC:SetScale(scale, noLerp)
    if CameraEntity and CameraEntity.Ref then
	local d = CameraEntity.Ref:GetData()
	if type(scale) == 'number' then
		d.CameraScale = scale
		if noLerp then
			d.CurrentCameraScale = scale
			local vec = Vector(scale,scale)
			d.FloorSprite.Scale = vec
			d.WallSprite.Scale = vec
			d.WallSprite2.Scale = vec
			d.RoomShading.Scale = vec
			local centerPos = game:GetRoom():GetRoomShape()>8 and Vector(580,420) or game:GetRoom():GetCenterPos()
			d.CenterPos = Isaac.WorldToRenderPosition(centerPos)*scale+bg_RenderPos*(1-scale)
			for i=0,game:GetNumPlayers()-1 do
				local player = Isaac.GetPlayer(i) 
				player:AddCacheFlags(CacheFlag.CACHE_SIZE)
 				player:EvaluateItems()
			end
		end
	else
		d.CameraScale = 1
	end
    end
end

function TSJDNHC:SetWallGfx(tab)
    if tab and CameraEntity and CameraEntity.Ref then
	local _,need = LoadBackdropSprite(CameraEntity.Ref:GetData().WallSprite, tab[1], 1)
	LoadBackdropSprite(CameraEntity.Ref:GetData().FloorSprite, tab[1], 2)
	if need then
		LoadBackdropSprite(CameraEntity.Ref:GetData().WallSprite2, tab[1], 3)
	end

	CameraEntity.Ref:GetData().StageAPIGfx = tab[1]
    end
end

function TSJDNHC:SpawnCamera(bool)
    if CameraEntity and CameraEntity.Ref then
	CameraEntity.Ref.FrameCount = 0
	if bool then
		CameraEntity.Ref:GetData().IsEnable = bool
	else
		CameraEntity.Ref:GetData().IsEnable = true
	end
	return CameraEntity.Ref
    else
	local cam = Isaac.Spawn(1000,entCam.VARIANT,2,game:GetRoom():GetTopLeftPos()-CameraOffset,Vector(0,0),nil)
	cam:Update()
	cam:GetData().IsEnable = bool
	return cam
    end
end

function TSJDNHC:GetCameraEnt()
	if CameraEntity and CameraEntity.Ref then
		return CameraEntity.Ref
	end
end

function TSJDNHC:EnableCamera(bool,force)
    if CameraEntity and CameraEntity.Ref then
	if bool == true then
		if not force then
			CameraEntity.Ref:GetData().State = 1
		else
			CameraEntity.Ref:GetData().IsEnable = true
			CameraEntity.Ref:GetData().State = nil
		end
	elseif bool == false then
		if not force then
			CameraEntity.Ref:GetData().State = 3
		else
			CameraEntity.Ref:GetData().IsEnable = false
			CameraEntity.Ref:GetData().State = nil
		end
	end
    end
end

function TSJDNHC:SetFocusMode(arg)
	 if arg and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.FocusMode = arg
	end
end

function TSJDNHC:SetFocusPosition(pos, lerp)
	 if pos and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.FocusLerp = lerp or 0.05
		d.FocusMode = d.FocusMode~= 1 and d.FocusMode or 0
		d.FocusCameraPosition = pos/Wtr+fixpos
		if lerp == 1 then
			d.CurrentCameraPosition = pos/Wtr+fixpos
		end
	end
end

function TSJDNHC:ClearFocus()
	 if CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.FocusMode = 1
		d.CameraPosition = Vector(0,0)
		d.TargetEntity = nil
		d.FocusCameraPosition = nil
		d.FocusLerp = nil
	end
end

function TSJDNHC:SetFocusEntity(ent, focus)
	 if ent and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.FocusMode = d.FocusMode ~= 1 and d.FocusMode or focus or 2
		d.TargetEntity = ent
	end
end

function TSJDNHC:AddFocusEntity(ent)
	 if ent and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.FocusMode = d.FocusMode~= 1 and d.FocusMode or 2
		if type(d.TargetEntity) ~= 'table' then
			local tab = {[1] = d.TargetEntity}
			d.TargetEntity = tab
			TSJDNHC:AddFocusEntity(ent)
		else
			d.TargetEntity[#d.TargetEntity+1] = ent
		end
	end
end

function TSJDNHC:SetCameraClamp(tab)
	if type(tab) ~= "table" and tab ~= nil then error("arg[2] is not table or nil",2) end
	if CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.RoomClamp = nil
		d.RoomClamp = tab
	end
end

function TSJDNHC:RemoveCam()
	if CameraEntity and CameraEntity.Ref then
		CameraEntity.Ref:Remove()
		CameraEntity = nil
	end
end

--d.SpecialRender = {igronelist = {}, stein = {}, creep = {}, rock = {}, entity = {} }
function TSJDNHC:AddToGridRender(ent)
	 if ent and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.SpecialRender.igronelist[ent.Index] = true
		d.SpecialRender.rock[#d.SpecialRender.rock+1] = ent
	end
end

function TSJDNHC:IgnoreThisEnt(ent)
	if ent and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.SpecialRender.igronelist[ent.Index] = true
	end
end

function TSJDNHC:SetStainColor(col)
	if col and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.StainColor = col
	end
end

function TSJDNHC:SetStainVisible(bol)
	if CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.StainVisible = bol
	end
end

function TSJDNHC:AddRoomRender(tab)
	 if tab and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		local id = #d.SpecialRender.room+1
		d.SpecialRender.room[id] = {Wall = tab.Wall, Floor = tab.Floor, Shading = tab.Shading, Overlay = tab.Overlay, Offset = tab.Offset}
		return id, d.SpecialRender.room[id]
	end
end

function TSJDNHC:SetRoomShadingVisible(bol)
	if CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		d.RoomShadingVisible = bol
	end
end

function TSJDNHC:WorldToScreen(pos)
	if pos and CameraEntity and CameraEntity.Ref then
		local d = CameraEntity.Ref:GetData()
		local scrPos = Isaac.WorldToScreen(pos)
		local Scale = d.CurrentCameraScale

		if Scale ~= 1 then
			local revScale = (Scale-1)
			local RenderPos = scrPos * Scale
			local zeroOffset = BDCenter*revScale
			--local scaledOffset = (revScale*(pos/Wtr)) 
			RenderPos = RenderPos  - (d.CurrentCameraPosition*d.CurrentCameraScale) - zeroOffset

			return RenderPos
		else
			return scrPos - d.CurrentCameraPosition*d.CurrentCameraScale
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------

local function PrintTab(tab, level)
	level = level or 0
	
	if type(tab) == "table" then
		for i,k in pairs(tab) do
			local offset = ""
			if level and level>0 then
				for j = 0, level do
					offset = offset .. " "
				end
			end
			print(offset .. i,k)
			if type(k) == "table" then
				PrintTab(k, level+1)
			end
		end
	end
end
local DeepPrint = function(...)
	for i,k in pairs({...}) do
		if type(k) == "table" then 
			print(k)
			PrintTab(k,1)
		else
			print(k)
		end
	end
end

---@class mapStyle
---@field size Vector
---@field animName string
---@field affl table
---@field sprs table
---@field bigs table


TSJDNHC.GridsList = {}
TSJDNHC.IndexsList = {}
TSJDNHC.Frid_Is_Active = false

TSJDNHC.FGrid = {}
---@class GridList
---@field X integer
---@field Y integer
---@field Grid table
---@field GridSprites table
---@field SpriteSheep string|nil
---@field Anm2File string
---@field RenderGridList table
---@field StartPos Vector
---@field CenterPos Vector
---@field CornerPos Vector
---@field RenderCenterPos Vector
---@field Xsize number
---@field Ysize number
---@field RenderMethod integer
---@field ManualRender boolean
---@field ListID integer
---@field TileStyle integer
---@field MapStyle mapStyle
TSJDNHC.Grid = {}
local MaxIndex = 0

function TSJDNHC:SetActivity(bool)
	TSJDNHC.Frid_Is_Active = bool
end

---@class Frid
---@field XY Vector
---@field GridList GridList
---@field Index integer
---@field Position Vector
---@field RenderPos Vector
---@field Half Vector
---@field CenterPos Vector
---@field Collision integer

---@param pos Vector
---@param y number 
---@param x number
---@param xs number
---@param ys number
---@return GridList
function TSJDNHC:MakeGridList(pos,y,x,xs,ys) --y = столбцы, x = ячейки
		if type(x) ~= "number" then
			error("[2] is not number", 2)
		elseif type(y) ~= "number" then
			error("[3] is not number", 2)
		end
		pos = pos or Vector(0, 0)
		if pos and x and y then
			local tab = {}
			setmetatable(tab, TSJDNHC.FGrid)

			tab.X, tab.Y = x, y
			tab.Xsize, tab.Ysize = xs or 40, ys or 40
			tab.StartPos = pos
			tab.CornerPos = pos + Vector(x * tab.Xsize, y * tab.Ysize)
			tab.CenterPos = pos + Vector(x * tab.Xsize, y * tab.Ysize)/2  --специально для isaac tower
			tab.RenderCenterPos = tab.CenterPos/Wtr - BDCenter
			tab.Grid = {}
			--local CornerAngles = Vector(tab.Xsize, tab.Ysize):GetAngleDegrees()
			--tab.CornerAngles = {CornerAngles, (180-math.abs(CornerAngles))/(math.abs(CornerAngles)/CornerAngles),
			--	-CornerAngles, -(180-math.abs(CornerAngles))/(math.abs(CornerAngles)/CornerAngles)  }

			tab.FirstIndex = MaxIndex / 1
			local lastIndex = 0
			for i = 1, y do
				tab.Grid[i] = {}
				for j = 1, x do
					tab.Grid[i][j] = {}

					tab.Grid[i][j].XY = Vector(j, i)
					tab.Grid[i][j].GridList = tab
					tab.Grid[i][j].Index = (i - 1) * x + j + MaxIndex
					tab.Grid[i][j].Position = Vector(tab.Xsize * (j - 1), tab.Ysize * (i - 1)) + pos
					tab.Grid[i][j].RenderPos = Vector(tab.Xsize * (j - 1) / Wtr, tab.Ysize * (i - 1) / Wtr)
					--tab.Grid[i][j].RenderPos = Vector(math.floor(tab.Xsize*(j-1)/Wtr), math.floor(tab.Ysize*(i-1)/Wtr)) --Isaac.WorldToScreenDistance (tab.Grid[i][j].Position-pos)
					tab.Grid[i][j].Half = Vector(tab.Xsize / 2, tab.Ysize / 2)
					tab.Grid[i][j].CenterPos = tab.Grid[i][j].Position + tab.Grid[i][j].Half
					tab.Grid[i][j].Collision = 0
					-- tab.Grid[i][j].angles = tab.CornerAngles

					lastIndex = tab.Grid[i][j].Index
					TSJDNHC.IndexsList[tab.Grid[i][j].Index] = tab.Grid[i][j]
				end
			end
			MaxIndex = lastIndex

			TSJDNHC.GridsList[#TSJDNHC.GridsList + 1] = tab
			tab.ListID = #TSJDNHC.GridsList
			tab.RenderMethod = 0

			return TSJDNHC.GridsList[tab.ListID] --tab
		end
end

function TSJDNHC.Grid.Delete(self) --оно не удаляет, только обрывает ссылки
	--self = nil
	TSJDNHC.GridsList[self.ListID] = nil
	for i,k in pairs(self) do
		self[i] = nil
	end
	self = nil
end

function TSJDNHC.Grid.GetGridsAsTable(self)
	local tab = {}
	for y, ycol in pairs(self.Grid) do
		for x, grid in pairs(ycol) do
			tab[#tab+1] = grid
		end
	end
	return tab
end

function TSJDNHC.Grid.SetGridGfxImage(self, gfx, animNum)
	self.SpriteSheep = gfx
	if type(self.GridSprites) == "table" then
		for i,k in pairs(self.GridSprites) do
			for layer = 0, k:GetLayerCount()-1 do
				k:ReplaceSpritesheet(layer, gfx)
			end
			k:LoadGraphics()
		end
		if self.MapStyle then
			for i,k in pairs(self.MapStyle.sprs) do
				for layer = 0, k:GetLayerCount()-1 do
					k:ReplaceSpritesheet(layer, gfx)
				end
				k:LoadGraphics()
			end
			if self.GridSprites[self.MapStyle.animName] then
				self.GridSprites[self.MapStyle.animName].Color = Color(1,1,1,0)
			end
		end
	end
end

function TSJDNHC.Grid.SetDefaultGridAnim(self, gfx, animNum)
	self.GridSprites = {}
	self.SpriteSheep = gfx
	self.Anm2File = "gfx/fakegrid/grid.anm2"
	
	for i=0, animNum do 
		self.GridSprites[i] = Sprite()
		self.GridSprites[i]:Load("gfx/fakegrid/grid.anm2", false)
		for layer = 0, self.GridSprites[i]:GetLayerCount()-1 do
			self.GridSprites[i]:ReplaceSpritesheet(layer, gfx)
		end
		self.GridSprites[i]:LoadGraphics()
		self.GridSprites[i]:Play(tostring(i))
		if self.TileStyle == 0 then
			self.GridSprites[i]:PlayOverlay(tostring(i).."_o")
		end
	end
end
function TSJDNHC.Grid.SetGridAnim(self, anm, animNum)
	self.GridSprites = {}
	self.SpriteSheep = self.SpriteSheep or nil
	self.Anm2File = anm
	
	if animNum then
		for i=0, animNum do 
			self.GridSprites[i] = Sprite()
			self.GridSprites[i]:Load(anm, true)
			if self.SpriteSheep then
				for layer = 0, self.GridSprites[i]:GetLayerCount()-1 do
					self.GridSprites[i]:ReplaceSpritesheet(layer, self.SpriteSheep)
				end
				self.GridSprites[i]:LoadGraphics()
			end
			self.GridSprites[i]:Play(tostring(i))
			if self.TileStyle == 0 then
				self.GridSprites[i]:PlayOverlay(tostring(i).."_o")
			end
		end
	end
end

function TSJDNHC.Grid.AddGridAnim(self, anim)
	--if not self.GridSprites[tostring(anim)] then error("[2] is not a string",2) end
	self.GridSprites[tostring(anim)] = Sprite()
	self.GridSprites[tostring(anim)]:Load(self.Anm2File, true)
	if self.SpriteSheep then
		for layer = 0, self.GridSprites[anim]:GetLayerCount()-1 do
			self.GridSprites[anim]:ReplaceSpritesheet(layer, self.SpriteSheep)
		end
	end
	self.GridSprites[tostring(anim)]:LoadGraphics()
	self.GridSprites[tostring(anim)]:Play(anim)
	if self.TileStyle == 0 then
		self.GridSprites[tostring(anim)]:PlayOverlay(anim.."_o")
	end
end

-- 0: standard, 1: Em? Map?
-- [3] это имя анимации, [4] это размер, [5] это список из влияющих анимации
---@param self GridList
---@param num 0|1
---@param ... unknown
function TSJDNHC.Grid.SetTileStyle(self, num, ...)
	local tab = {...}
	self.TileStyle = num
	if num == 1 then
		self.MapStyle = {
			animName = tab[1],
			size = tab[2],
			affl = tab[3],
			bigs = {}, --tab[4],
			sprs = {},
		}
		if self.GridSprites[tab[1]] then
			self.GridSprites[tab[1]].Color = Color(1,1,1,0)
		end
		for i=1, tab[2].X do
			for j=1, tab[2].Y do
				local spr = Sprite()
				spr:Load(self.Anm2File, true)
				if self.SpriteSheep then
					for layer = 0, spr:GetLayerCount()-1 do
						spr:ReplaceSpritesheet(layer, self.SpriteSheep)
					end
				end
				--spr:Play(tab[1])
				local id = (i-1)*(tab[2].Y)+j-1
				spr:Play(tab[1]..math.ceil(id))
				--spr:SetFrame(id)
				self.MapStyle.sprs[id] = spr
				for ha=1,#tab[4] do
					local name = tab[4][ha]
					self.MapStyle.bigs[name] = true

					local spr = Sprite()
					spr:Load(self.Anm2File, true)
					if self.SpriteSheep then
						for layer = 0, spr:GetLayerCount()-1 do
							spr:ReplaceSpritesheet(layer, self.SpriteSheep)
						end
					end
					local id = (i-1)*(tab[2].Y)+j-1
					local ani = name .. "_" .. math.ceil(id)
					spr:Play(ani)
					self.MapStyle.sprs[ani] = spr
				end
			end
		end
	else
		self.MapStyle = nil
	end
end

function TSJDNHC.Grid.UpdateGridSprites(self)
	if type(self.GridSprites) == "table" then
		for i, spr in pairs(self.GridSprites) do
			spr:Update()
		end
	end
end


function TSJDNHC.Grid.UpdateRenderTab(self)
	self.RenderGridList = {}
	--local startPos = Isaac.WorldToRenderPosition(self.StartPos)
	for i=self.Y, 1,-1 do
		for j=self.X, 1,-1 do
			if self.Grid[i][j].SpriteAnim then
				--print(self.Grid[i][j].SpriteAnim, self.GridSprites[self.Grid[i][j].SpriteAnim])
				self.RenderGridList[#self.RenderGridList+1] = {
					pos = self.Grid[i][j].RenderPos,
					spr = self.GridSprites[self.Grid[i][j].SpriteAnim] or self.GridSprites[tostring(self.Grid[i][j].SpriteAnim)]}
			end
			if self.Grid[i][j].Sprite then
				self.RenderGridList[#self.RenderGridList+1] = {
					pos = self.Grid[i][j].RenderPos,
					spr = self.Grid[i][j].Sprite}
			end
		end
	end
end

local ScreenWidth, ScreenHeight = 0,0

function TSJDNHC.Grid.RenderGrid(self, grid, vec, scale)
	local zeroOffset
	if scale ~= 1 then
		zeroOffset = BDCenter*(scale-1)+self.StartPos/Wtr*(1-scale)
	end

	local renderPos = grid.RenderPos*scale + (vec + Isaac.WorldToRenderPosition(self.StartPos))
	if scale ~= 1 then
		renderPos = renderPos -zeroOffset
	end
	if grid.Mapspr then
		grid.Mapspr:Render(renderPos)
	end
	if grid.Sprite then
		if scale ~= 1 then
			local preScale = grid.Sprite.Scale/1
			grid.Sprite.Scale = grid.Sprite.Scale*scale
			grid.Sprite:Render(renderPos)
			grid.Sprite.Scale = preScale
		else
			grid.Sprite:Render(renderPos)
		end
	end
	local anim = grid.SpriteAnim and (self.GridSprites[grid.SpriteAnim] or self.GridSprites[tostring(grid.SpriteAnim)])
	if anim then
		anim:Render(renderPos)
	end
end

function TSJDNHC.Grid.Render(self, vec, scale)
	--local t = Isaac.GetTime()

	local zeroOffset --= BDCenter*(scale)-BDCenter+self.StartPos/Wtr*(1-scale)
	if scale ~= 1 then
		zeroOffset = BDCenter*(scale-1)+self.StartPos/Wtr*(1-scale) ---BDCenter
	end

	if not self.RenderMethod or self.RenderMethod == 0 then
		if not self.RenderGridList then
			self:UpdateRenderTab()
		end
		local startPos = Isaac.WorldToRenderPosition(self.StartPos) + vec
		for i, tab in pairs(self.RenderGridList) do
			if tab.spr then
				local renderPos = tab.pos + startPos
				if scale ~= 1 then
					local scaledOffset = (scale*tab.pos-tab.pos) or Vector(0,0)
					renderPos = renderPos + scaledOffset-zeroOffset --+ vec
				end
				if scale ~= 1 then
					local preScale = tab.spr.Scale/1
					tab.spr.Scale = tab.spr.Scale*scale
					tab.spr:Render(renderPos)
					tab.spr.Scale = preScale
				else
					tab.spr:Render(renderPos)
				end
			end
		end
	elseif self.RenderMethod == 1 then
		local modScale = math.abs(scale)
		local zer = -vec - Isaac.WorldToRenderPosition(self.StartPos)
		local modZer = Vector(math.abs(zer.X), math.abs(zer.Y))
		local startPosRender = modZer - Vector(26,26) + (zeroOffset or Vector(0,0))
		local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(self.Xsize/Wtr*modScale)), math.ceil(startPosRender.Y/(self.Ysize/Wtr*modScale)))
		local EndPosRender = modZer + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())*(math.max(1,modScale)) -- + Vector(26*2,26*2)
		local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(self.Xsize/Wtr*modScale)), math.ceil(EndPosRender.Y/(self.Ysize/Wtr*modScale)))
		
		local startPos = -zer --Isaac.WorldToRenderPosition(self.StartPos) + vec

		local ignoreList = {}
		local revScale = scale-1 -- math.floor((scale-1)*4)/4
		local vScale = scale -- math.floor((scale)*10000)/10000
		local scaleComp = scale --+0.01*Options.MaxRenderScale

		--local Xsize, Ysize
		--if scale ~= 1 then
		--	Xsize, Ysize =  math.floor((self.Xsize*vScale/Wtr)*1000)/1000, math.floor((self.Ysize*vScale/Wtr)*1000)/1000
		--end
		local backscale = {}
		local mbackscale = {}
		if scale ~= 1 then
			for i,l in pairs(self.GridSprites) do
				backscale[l] = l.Scale/1
				l.Scale = l.Scale*(scaleComp)
			end
			if self.MapStyle then
				for i,l in pairs(self.MapStyle.sprs) do
					mbackscale[l] = l.Scale/1
					l.Scale = l.Scale*(scaleComp)
				end
			end
		end

		--for y=math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, self.Y) do
		for y=math.min(EndPosRenderGrid.Y, self.Y), math.max(1,StartPosRenderGrid.Y),-1 do
			for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, self.X) do
				local tab = self.Grid[y][x]
				if tab.Sprite or tab.SpriteAnim or tab.Parent then
					local renderPos = tab.RenderPos*vScale + startPos
					--if scale == 1 then
						--renderPos = tab.RenderPos*vScale + startPos
					if scale ~= 1 then
						--local scaledOffset = (revScale*tab.RenderPos) or Vector(0,0) ---tab.RenderPos
						--renderPos = Vector(Xsize * (x - 1), Ysize * (y - 1)) + startPos
						renderPos = renderPos -zeroOffset --+ vec
						--renderPos = renderPos
						--renderPos = Vector(math.floor(renderPos.X), math.floor(renderPos.Y))
						--print(y,x, renderPos, revScale,vScale)
					end

					if not ignoreList[tab] then
						if tab.Mapspr then
							tab.Mapspr:Render(renderPos)
							ignoreList[tab] = true
						end
						if tab.Sprite then
							if scale ~= 1 then
								local preScale = tab.Sprite.Scale/1
								tab.Sprite.Scale = tab.Sprite.Scale*scale
								tab.Sprite:Render(renderPos)
								tab.Sprite.Scale = preScale
							else
								tab.Sprite:Render(renderPos)
							end
							ignoreList[tab] = true
						end
						local anim = tab.SpriteAnim and (self.GridSprites[tab.SpriteAnim] or self.GridSprites[tostring(tab.SpriteAnim)])
						if anim then
							--if scale ~= 1 then
							--	local preScale = anim.Scale/1
							--	anim.Scale = anim.Scale*(scaleComp)
							--	--print(anim.Scale)
							--	--anim.Scale = Vector(math.ceil(anim.Scale.X*20)/20,math.ceil(anim.Scale.Y*20)/20)
							--	anim:Render(renderPos)
							--	--if scale>1 then
							--	--	anim:Render(renderPos+Vector(0.5*scale,0.5*scale))
							--	--end
							--	anim.Scale = preScale
							--else
								anim:Render(renderPos)
							--end
							ignoreList[tab] = true
						end
					end

					if tab.Parent and not ignoreList[tab.Parent] then
						local renderPos = tab.Parent.RenderPos*vScale + startPos
						if scale ~= 1 then
							renderPos = renderPos -zeroOffset
						end
						ignoreList[tab.Parent] = true
						if tab.Parent.Sprite then
							if scale ~= 1 then
								local preScale = tab.Parent.Sprite.Scale/1
								tab.Parent.Sprite.Scale = tab.Parent.Sprite.Scale*scale
								tab.Parent.Sprite:Render(renderPos)
								tab.Parent.Sprite.Scale = preScale
							else
								tab.Parent.Sprite:Render(renderPos)
							end
						end
						if tab.Parent.Mapspr then
							tab.Parent.Mapspr:Render(renderPos)
						end
						local anim = tab.Parent.SpriteAnim and (self.GridSprites[tab.Parent.SpriteAnim] or self.GridSprites[tostring(tab.Parent.SpriteAnim)])
						if anim then
							if scale ~= 1 then
								local preScale = anim.Scale/1
								anim.Scale = anim.Scale*scale
								local renderPos = tab.Parent.RenderPos + startPos
								local scaledOffset = (scale*tab.Parent.RenderPos-tab.Parent.RenderPos) or Vector(0,0)
								renderPos = renderPos + scaledOffset-zeroOffset
								anim:Render(renderPos)
								anim.Scale = preScale
							else
								anim:Render((tab.Parent.RenderPos + startPos)*scale)
							end
						end
					end
				end
			end
		end

		if scale ~= 1 then
			for i,l in pairs(self.GridSprites) do
				l.Scale = backscale[l]
			end
			if self.MapStyle then
				for i,l in pairs(self.MapStyle.sprs) do
					l.Scale = mbackscale[l]
				end
			end
		end
	end
	--print(Isaac.GetTime()-t)
end

--0 static 
--1 dynamic
function TSJDNHC.Grid.SetRenderMethod(self, num)
	self.RenderMethod = num
end

function TSJDNHC.Grid.SetManualRender(self, num)
	self.ManualRender = num and true or false
end

local function findIndex(index, tab, loc)
	if loc and tab then
		local x,y = tab.X,tab.Y
		local ret1,ret2 = math.floor(index/y), index%x
		return tab.Grid[ret1][ret2] 
	else
		return TSJDNHC.IndexsList[index]
	end
end

---@return Frid
function TSJDNHC.Grid.GetGrid(self, vec)
	vec = vec - self.StartPos
	local xs,ys = math.ceil(vec.X/self.Xsize), math.ceil(vec.Y/self.Ysize)
	local grid = self.Grid[ys] and self.Grid[ys][xs]
	if grid and grid.Parent then
		grid = grid.Parent
	end
	return grid
end

---@return Frid
function TSJDNHC.Grid.GetRawGrid(self, vec)
	vec = vec - self.StartPos
	local xs,ys = math.ceil(vec.X/self.Xsize), math.ceil(vec.Y/self.Ysize)
	local grid = self.Grid[ys] and self.Grid[ys][xs]
	return grid
end


local clearingingonelist = {Index = true, XY = true, GridList = true, RenderPos = true}
local function clearGridData(grid)
	for key, data in pairs(grid) do
		if not clearingingonelist[key] then
			grid[key] = nil
		end
	end
	grid.Position = Vector(grid.GridList.Xsize * (grid.XY.X-1) , grid.GridList.Ysize * (grid.XY.Y-1)) + grid.GridList.StartPos
	grid.Half = Vector(grid.GridList.Xsize/2 , grid.GridList.Ysize/2)
	grid.CenterPos = grid.Position + grid.Half
	grid.Collision = 0
end

function TSJDNHC.Grid.DestroyGrid(self, x, y)
	if x and not y and x.Y then
		y = x.Y
		x = x.X
	end
	local grid = self.Grid[y] and self.Grid[y][x]
	if grid then
		if grid.Parent then
			self:DestroyGrid(grid.Parent.XY)
		elseif grid.Type and TSJDNHC.GridTypes[grid.Type].PostDestroy then
			TSJDNHC.GridTypes[grid.Type].PostDestroy(grid, self)
		end
		if grid.Childs then
			for i,k in pairs(grid.Childs) do
				--[[self.Grid[k.XY.Y][k.XY.X] = {}
				--self.Grid[k.XY.Y][k.XY.X].XY = Vector(j,i)
				--self.Grid[k.XY.Y][k.XY.X].GridList = tab
           			--self.Grid[k.XY.Y][k.XY.X].Index = grid.Index  --(i-1) * x + j + MaxIndex
           			self.Grid[k.XY.Y][k.XY.X].Position = Vector(self.Xsize * (k.XY.X-1) , self.Ysize * (k.XY.Y-1)) + self.StartPos
				--self.Grid[k.XY.Y][k.XY.X].RenderPos = Vector(tab.Xsize * (j-1) / Wtr, tab.Ysize * (i-1) / Wtr)
				self.Grid[k.XY.Y][k.XY.X].Half = Vector(self.Xsize/2 , self.Ysize/2)
           			self.Grid[k.XY.Y][k.XY.X].CenterPos = self.Grid[k.XY.Y][k.XY.X].Position + self.Grid[k.XY.Y][k.XY.X].Half
            			self.Grid[k.XY.Y][k.XY.X].Collision = 0]]
				clearGridData(self.Grid[k.XY.Y][k.XY.X])
			end
		end
		--[[self.Grid[grid.XY.Y][grid.XY.X] = {}
		--self.Grid[grid.XY.Y][grid.XY.X].Index
		self.Grid[grid.XY.Y][grid.XY.X].Position = Vector(self.Xsize * (grid.XY.X-1) , self.Ysize * (grid.XY.Y-1)) + self.StartPos
		self.Grid[grid.XY.Y][grid.XY.X].Half = Vector(self.Xsize/2 , self.Ysize/2)
		self.Grid[grid.XY.Y][grid.XY.X].CenterPos = self.Grid[grid.XY.Y][grid.XY.X].Position + self.Grid[grid.XY.Y][grid.XY.X].Half
		self.Grid[grid.XY.Y][grid.XY.X].Collision = 0]]
		clearGridData(self.Grid[grid.XY.Y][grid.XY.X])

		self:UpdateRenderTab()
	end
end

function TSJDNHC.Grid.GetGridPos(self, index)
	local grid = findIndex(index, self)
	if grid and grid.Parent then
		grid = grid.Parent
	end
	return (self.StartPos + grid.CenterPos)
end

function TSJDNHC.Grid.MakeMegaGrid(self, pos, x, y)
	local grid = type(pos) == "number" and findIndex(pos, self) or self.Grid[pos.Y][pos.X]
	
	if grid and x>0 and y>0 then
	    local XY = grid.XY
	    grid.Half = Vector(self.Xsize/2*x , self.Ysize/2*y) --Vector(grid.Half.X*x,grid.Half.Y*y)
	    grid.CenterPos = grid.Position + grid.Half
	    grid.Childs = grid.Childs or {}

	    for i=1,y do
		for j=1,x do
		  if i ~= 1 or j ~= 1 then 
			local ngrid = self.Grid[XY.Y+i-1] and self.Grid[XY.Y+i-1][XY.X+j-1]
			
			if ngrid then
				--[[for param, data in pairs(ngrid) do
					if param ~= "Index" then
						ngrid[param] = data
					end
				end]]
				--ngrid.Half =
				ngrid.Parent = grid
				grid.Childs[#grid.Childs+1] = ngrid
				ngrid = grid
			end
		  end
		end
	    end
	end
end

function TSJDNHC.Grid.LinkGrids(self, parent, child, autoSize)
	if parent and child then
		child.Parent = parent
		parent.Childs = parent.Childs or {}
		parent.Childs[#parent.Childs+1] = child
		if autoSize then
			local xpos,ypos
			local xsize,ysize
			if child.CenterPos.X < parent.CenterPos.X then
				xpos = (child.CenterPos.X-child.Half.X) + (parent.CenterPos.X+parent.Half.X)
				xsize = (child.CenterPos.X-child.Half.X) - (parent.CenterPos.X+parent.Half.X)
			else
				xpos = (child.CenterPos.X+child.Half.X) + (parent.CenterPos.X-parent.Half.X)
				xsize = (child.CenterPos.X+child.Half.X) - (parent.CenterPos.X-parent.Half.X)
			end
			
			if child.CenterPos.Y < parent.CenterPos.Y then
				ypos = (child.CenterPos.Y-child.Half.Y) + (parent.CenterPos.Y+parent.Half.Y)
				ysize = (child.CenterPos.Y-child.Half.Y) - (parent.CenterPos.Y+parent.Half.Y)
			else
				ypos = (child.CenterPos.Y+child.Half.Y) + (parent.CenterPos.Y-parent.Half.Y)
				ysize = (child.CenterPos.Y+child.Half.Y) - (parent.CenterPos.Y-parent.Half.Y)
			end
			parent.Half = Vector(math.abs(xsize/2),math.abs(ysize/2))
			parent.CenterPos = Vector(xpos/2,ypos/2)
			--print("inside", parent.Half, parent.CenterPos)
		end
	end
end

function TSJDNHC.Grid.SetGridFromList(self, list)
	if type(list) ~= "table" then error("arg[2] is not table",2) end

	if list.dgfx then
		self:SetDefaultGridAnim(list.dgfx, list.animNum or 1)
	end
	if list.anm2 then
		self:SetGridAnim(list.anm2, self.GridSprites and #self.GridSprites or 0)
	end
	if list.extraAnim then
		for i, anim in ipairs(list.extraAnim) do
			self:AddGridAnim(anim)
		end
	end
	if list.gfx then
		self:SetGridGfxImage(list.gfx) --, list.animNum or 1)
	end
	if list.TileMap then
		self:SetTileStyle(1, list.TileMap[1], list.TileMap[2], list.TileMap[3], list.TileMap[4])
	end

	local toInit = {}
	for i, tab in ipairs(list) do
		---@type Frid
		local grid
		if list.useWorldPos then
			grid = self:GetGrid(tab.pos)
		else
			grid = type(tab.pos) == "number" and findIndex(tab.pos, self) or self.Grid[tab.pos.Y][tab.pos.X]
		end
		if grid then
			toInit[#toInit+1] = grid

			for k, dat in pairs(tab) do
				if k ~= "pos" then
					grid[k] = dat
				end
			end
			--[[if self.MapStyle and grid.SpriteAnim and self.MapStyle.affl[grid.SpriteAnim] then
				local id = (grid.XY.X%self.MapStyle.size.X)+((grid.XY.Y-1)%self.MapStyle.size.Y)*self.MapStyle.size.Y
				local mapSpr = self.MapStyle.sprs[id]
				grid.Mapspr = mapSpr
				print(grid.SpriteAnim, grid.SpriteAnim .. "_" .. id)
				if self.MapStyle.bigs[grid.SpriteAnim] then
					grid.Mapspr = self.MapStyle.sprs[grid.SpriteAnim .. "_" .. id]
				end
			end]]
		end
		--grid.SpriteAnim = tab.SpriteAnim or grid.SpriteAnim
		--grid.Sprite = tab.Sprite or grid.Sprite
		--grid.Collision = tab.Collision or grid.Collision
		--grid.Type = tab.Type or grid.Type
		--grid.Slip = tab.Slip or grid.Slip
	end
	for i, grid in pairs(toInit) do
		local gtype = grid.Type and TSJDNHC.GridTypes[grid.Type]
		if gtype and gtype.Init then
			gtype.Init(grid, self)
		end
		if self.MapStyle and grid.SpriteAnim and (self.MapStyle.affl[grid.SpriteAnim] or self.MapStyle.bigs[grid.SpriteAnim]) then
			local id = (grid.XY.X%self.MapStyle.size.X)+((grid.XY.Y-1)%self.MapStyle.size.Y)*self.MapStyle.size.Y
			local mapSpr = self.MapStyle.sprs[id]
			grid.Mapspr = mapSpr
			if self.MapStyle.bigs[grid.SpriteAnim] then
				grid.Mapspr = self.MapStyle.sprs[grid.SpriteAnim .. "_" .. math.ceil(id)]
			end
		end
	end
end

function TSJDNHC.DeleteAllGridList()
	TSJDNHC.GridsList = {}
	TSJDNHC.IndexsList = {}
	MaxIndex = 0
end

TSJDNHC.GridTypes = {}
function TSJDNHC.AddGridType(name, initFunc, updateFunc, destroyFunc)
	if name and initFunc then
		TSJDNHC.GridTypes[name] = TSJDNHC.GridTypes[name] or {}
		TSJDNHC.GridTypes[name].Init = initFunc
		TSJDNHC.GridTypes[name].Update = updateFunc
		TSJDNHC.GridTypes[name].PostDestroy = destroyFunc
	end
end


---@return Frid
function TSJDNHC.GetGrid(vec)
    if vec then
	for _, k in pairs(TSJDNHC.GridsList) do
		if vec.X > k.StartPos.X and vec.Y > k.StartPos.Y 
		and vec.X < k.CornerPos.X and vec.Y < k.CornerPos.Y then
			local result = k:GetGrid(vec)
			if result then
				return result
			end
		end
	end
    end
end
function TSJDNHC.GetGridPos(index)
	local grid = TSJDNHC.IndexsList[index]
	if grid and grid.Parent then
		grid = grid.Parent
	end
	if grid then
		return (grid.Position + grid.CenterPos)
	end
end
function TSJDNHC.GetGridAtIndex(index)
	local grid = TSJDNHC.IndexsList[index]
	if grid and grid.Parent then
		grid = grid.Parent
	end
	return grid
end

TSJDNHC.FGrid.__index = TSJDNHC.Grid


function TSJDNHC.ShouldCollide(entCol, gridColl)
	if entCol == 1 and gridColl == 1 then
		return true
	end
end

local function StardartGridPoints(_, ent)
	local grid = {}
	for i = 1,32 do
		local d = ent:GetData()
		local vec = Vector(ent.Size,0):Rotated(360/32*i)
		grid[i] = {vec, vec:Resized(1):Rotated(180)}
	end
	return grid
end
mod:AddPriorityCallback(TSJDNHC.Callbacks.GRID_POINTS_GEN, CallbackPriority.LATE, StardartGridPoints)

function TSJDNHC.StandartEntGridCollision(ent) --, entCol, gridColl)
	local d = ent:GetData()

	local ofsetPos = Vector(0,0)
	local ofsetVec = Vector(0,0)
	for i,k in pairs(d.TSJDNHC_GridPoints) do
		local grid = TSJDNHC.GetGrid(ent.Position + k[1])
		
		if grid and TSJDNHC.ShouldCollide(d.TSJDNHC_GridColl, grid.Collision) then
			ofsetPos = ofsetPos + k[2] * 0.20
			ofsetVec = ofsetVec + k[2] * 0.15
		end
	end
	ent.Position = ent.Position + ofsetPos --:Resized(1.2)
	ent.Velocity = ent.Velocity + ofsetVec --:Resized(1.2)
end

function TSJDNHC.GridCollHandler(_, ent)
	local d = ent:GetData()
	if not d.TSJDNHC_GridPoints then
		d.TSJDNHC_GridPoints = {}
		d.TSJDNHC_GridColl = 1
		d.TSJDNHC_GridPoints = Isaac.RunCallback(TSJDNHC.Callbacks.GRID_POINTS_GEN, ent)
	elseif TSJDNHC.Frid_Is_Active then
		if d.TSJDNHC_GridColFunc then
			d.TSJDNHC_GridColFunc(ent)
		else
			TSJDNHC.StandartEntGridCollision(ent)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TSJDNHC.GridCollHandler)
--mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	--if not Game():IsPaused() then
	--print(Isaac.GetFrameCount()) end
--end)

local IsOddRenderFrame = false
function TSJDNHC.GridRender(_, Pos, Offset, Scale)
	IsOddRenderFrame = not IsOddRenderFrame
	--local t = Isaac.GetTime()
	if IsOddRenderFrame then
		--for i,k in pairs(TSJDNHC.GridsList) do
		--	k:UpdateGridSprites()
		--end
	end
	--local d = CameraEntity.Ref:GetData()
		-- d.CurrentCameraPosition
	ScreenWidth, ScreenHeight = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	--for i,k in pairs(TSJDNHC.GridsList) do
	for i=1, #TSJDNHC.GridsList do
		local k = TSJDNHC.GridsList[i]
		if not k.ManualRender then
			k:Render(Offset, Scale)
		end
	end
	--Isaac_Tower.font:DrawStringUTF8(Isaac.GetTime()-t,130,60,KColor(1,1,1,1),1,true)
end
mod:AddCallback(TSJDNHC.Callbacks.GRID_BACKDROP_RENDER, TSJDNHC.GridRender)

---------------------------------------------------------------------

TSJDNHC.DebugFlag = 0
function TSJDNHC.debug(num)
	TSJDNHC.DebugFlag = TSJDNHC.DebugFlag ~ 2^(num-1)
end
function TSJDNHC.Isdebug(num)
	return TSJDNHC.DebugFlag & 2^(num-1) ~= 0
end

local Col0Grid = Sprite()
Col0Grid:Load(mainfilepath .. "gridDebug/debug.anm2")
Col0Grid.Color = Color(0.5,0.5,0.5,0.5)
Col0Grid:Play(0)
--Col1Grid.Offset = Vector()
local Col1Grid = Sprite()
Col1Grid:Load(mainfilepath .. "gridDebug/debug.anm2")
Col1Grid.Color = Color(0.5,0.5,0.5,0.5)
Col1Grid:Play(1)

local GridCollPoint = Sprite()
GridCollPoint:Load(mainfilepath .. "gridDebug/debug.anm2")
GridCollPoint.Scale = Vector(0.5,0.5)
GridCollPoint:Play("point")

local GridCollVer = Sprite()
GridCollVer:Load(mainfilepath .. "gridDebug/debug.anm2")
GridCollVer.Scale = Vector(2.5,2.5)
GridCollVer.Color = Color(0,4,2,1)
GridCollVer:Play("point")



local PlayerColor = Color(2,0,2,1)

local function EntityfrigPoint(_, Pos, Offset, Scale)
  if TSJDNHC.Isdebug(2) or TSJDNHC.Isdebug(3) then
    for pl=0,game:GetNumPlayers()-1 do
	local ent = Isaac.GetPlayer(pl)
	local d = ent:GetData()
	if d.TSJDNHC_GridPoints then
		if TSJDNHC.Isdebug(2) then
			for i,k in pairs(d.TSJDNHC_GridPoints) do
				GridCollPoint:Render(Isaac.WorldToRenderPosition(ent.Position) + k[1]/Wtr + Offset)
				--GridCollVer:Render(Isaac.WorldToRenderPosition(ent.Position) + k[1]/Wtr - k[2]*Wtr)
	
				--local pos = Isaac.WorldToRenderPosition(ent.Position) + Vector(k[1].X,k[1].Y)*5 - k[2]*1
				--Isaac.RenderText(i, pos.X, pos.Y, 2,1,0,1)
			end
			if d.DebugGridRen then
				for i,k in pairs(d.DebugGridRen) do
					GridCollVer:Render(Isaac.WorldToRenderPosition(k) + Offset)
				end
			end
		end
		if TSJDNHC.Isdebug(3) then
			if d.Isaac_Tower_Data then
				GridCollPoint.Scale = (d.Isaac_Tower_Data.Half/1.5) --Vector(1,1)*
				GridCollPoint:Render(Isaac.WorldToRenderPosition(d.Isaac_Tower_Data.Position+d.Isaac_Tower_Data.CollisionOffset) + Offset)
				GridCollPoint.Scale = Vector(0.5,0.5)
				
				local pos = Isaac.WorldToRenderPosition(ent.Position) + Offset
				Isaac.RenderText(d.Isaac_Tower_Data.Velocity.X, pos.X, pos.Y, 2,1,0,1)
			end
		end
	end
    end
  end
end    --TSJDNHC_PT.Callbacks.PRE_BACKDROP_RENDER
mod:AddCallback(TSJDNHC.Callbacks.OVERLAY_BACKDROP_RENDER, EntityfrigPoint)
--mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, EntityfrigPoint)

local function debugFridRender(_, Pos, Offset, Scale)
  if TSJDNHC.Isdebug(2) then

	for _, k in pairs(TSJDNHC.GridsList) do
		local playerIndex = k:GetGrid(Isaac.GetPlayer().Position)
		local w,h = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()

		local start = Isaac.WorldToRenderPosition(k.StartPos)*Scale + Pos*(1-Scale) + Offset
		for i, colum in pairs(k.Grid) do
			local xpos = Vector(0, (i-1) * k.Ysize/Wtr)
			xpos = xpos * Scale
			for j, grid in pairs(colum) do
				local renderPos = start + xpos + Vector((j-1)*k.Xsize/Wtr, 0)* Scale

				if renderPos.X>0 and renderPos.Y>0 and renderPos.X<w and renderPos.Y<h then

					if playerIndex and playerIndex.Index == grid.Index then
						Col0Grid.Color = PlayerColor
					else
						Col0Grid.Color = Color(0.5,0.5,0.5,0.5)-- Color.Default
					end
					if grid.Collision == 0 then
						Col0Grid.Scale = Scale*Vector(k.Xsize/35, k.Ysize/35)
						Col0Grid:Render(renderPos)
					elseif grid.Collision == 1 then
						Col1Grid.Scale = Scale*Vector(k.Xsize/35, k.Ysize/35)
						Col1Grid:Render(renderPos)
					end
					Isaac.RenderText(grid.Index, renderPos.X, renderPos.Y, 1,1,1,0.3)
				end
			end
		end
	end	
  end
end
mod:AddCallback(TSJDNHC.Callbacks.GRID_BACKDROP_RENDER, debugFridRender)

function TSJDNHC.TestGridColl()
	
    for pid=0,game:GetNumPlayers()-1 do
	local d = Isaac.GetPlayer(pid):GetData()
	d.TSJDNHC_GridPoints = {}
	for i=0,360-45,45 do    --i=-0,3 do
		--[[local ang = 90*(i)
		for j=-2,2 do
			local pos = Vector(Isaac.GetPlayer(i).Size*1.3,Isaac.GetPlayer(i).Size*(j/1.5)):Rotated(ang) + Vector(0,-7)
			local vec = Vector(-1,0):Rotated(ang)
			--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
			d.TSJDNHC_GridPoints[i*5+j] = {pos, vec}
		end]]

		local ang = i --90*(i)+45
		local size = Isaac.GetPlayer(pid).Size*1.3
		local pos = Vector(size*1.5,0):Rotated(ang):Clamped(-size,-size,size,size) -- + Vector(0,-7)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.TSJDNHC_GridPoints[i] = {pos, vec}
	end
	d.TSJDNHC_GridColFunc = function(ent)
		local d = ent:GetData()


		d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed or 0


		if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, ent.ControllerIndex) 
		and (d.TSJDNHC_OnFloor>0) -- or ent.Velocity.Y>-1 and ent.Velocity.Y<1) 
		or Input.IsActionTriggered(ButtonAction.ACTION_UP, ent.ControllerIndex) then
			--ent.Velocity = Vector(ent.Velocity.X, -25)
			d.TSJDNHC_fallspeed = -8
			d.TSJDNHC_JumpFrame = 0
		end
		--print(d.TSJDNHC_OnFloor,ent.Velocity.Y)
		d.TSJDNHC_OnFloor = d.TSJDNHC_OnFloor and (d.TSJDNHC_OnFloor - 1) or 0
		d.TSJDNHC_JumpFrame = d.TSJDNHC_JumpFrame and (d.TSJDNHC_JumpFrame + 1) or 0

		ent.Velocity = Vector(ent.Velocity.X, ent.Velocity.Y*0.5 + d.TSJDNHC_fallspeed*0.5)
		--ent.Position = ent.Position + Vector(0,d.TSJDNHC_fallspeed*0.5)
		--if ent.Velocity.Y <= 0 then
		--	d.TSJDNHC_fallspeed = 0
		--end



		local ofsetPos = Vector(0,0)
		local ofsetVec = Vector(0,0)
		--local curPos = ent.Position --+ent.Velocity*2  --angles

		local collidedGrid = {}
		for i,k in pairs(d.TSJDNHC_GridPoints) do
			--[[local grid = TSJDNHC.GetGrid(curPos + k[1])
			--print(i, i, k[1], k[2], "col", grid and grid.Index)
			if grid and d.TSJDNHC_GridColl == 1 and grid.Collision == 1 then
				--print(i, k[1], k[2])
				
				--ent.Position = ent.Position + k[2] * 0.10
				curPos = curPos + k[2] * 0.10
				--ofsetPos = ofsetPos + k[2] * 0.10
				local checkof = Vector(0,0)
				for j=1,15 do
					checkof = checkof + k[2] * 0.10 * j
					local grid1 = TSJDNHC.GetGrid(curPos + checkof + k[1])
					if not grid1 or d.TSJDNHC_GridColl == 1 and grid1.Collision == 0 then
						--ent.Position = ent.Position + checkof --+ k[2] * 0.10
						curPos = curPos + checkof
						goto skip
					end
				end
				::skip::

				ofsetVec = ofsetVec + k[2] * 0.25
			
				if k[1].Y>2 then
					d.TSJDNHC_OnFloor = 8
				end
			end]]

			local grid = TSJDNHC.GetGrid(ent.Position + ent.Velocity + k[1])
			if grid and TSJDNHC.ShouldCollide(d.TSJDNHC_GridColl, grid.Collision) then
				collidedGrid[grid] = collidedGrid[grid] or {} --true
				collidedGrid[grid][i] = k[1] + ent.Position -- ent.Velocity
			end
		end
			
		ent:GetData().DebugGridRen = {}
		for i,k in pairs(collidedGrid) do
			local gridpos = (i.Position + i.CenterPos)
			local entpos = ent.Position - i.Position - ent.Velocity
			local nearPoint 
			local maxd = 1000000
			for num,pos in pairs(k) do
				local dist = gridpos:Distance(pos)  --i.CenterPos:Distance(pos)
				--print(num,pos,dist,gridpos,entpos)
				if dist<maxd then
					--print(num,pos,dist,pos+entpos)
					nearPoint = pos-i.Position
					maxd = dist
				end
			end
			--print(nearPoint )
			--GridCollVer:Render(Isaac.WorldToRenderPosition(nearPoint+i.Position))
			ent:GetData().DebugGridRen[i] = nearPoint + i.Position
			local ang = (i.CenterPos - nearPoint ):GetAngleDegrees()
			
			--print(ang, i.angles[1],i.angles[2],i.angles[3],i.angles[4] )
			if ang > i.angles[1] and ang <= i.angles[2] then
				local movePos = -0.0 - (nearPoint.Y)
				--print(movePos,nearPoint.Y,i.CenterPos.Y )
				ent.Position = ent.Position + Vector(0,movePos) --ofsetPos:Resized(2.4)
				--ent.Velocity = ent.Velocity - Vector(0,-1):Resized(0.33)

				if d.TSJDNHC_JumpFrame>=0 then
					d.TSJDNHC_fallspeed = 0
				end

			elseif ang > i.angles[2] or ang < i.angles[4] then
				--print(ang,nearPoint, 40 - (nearPoint.X))
				local movePos = 40 - (nearPoint.X)
				ent.Position = ent.Position + Vector(movePos,0) 
			elseif ang < i.angles[1] or ang >= i.angles[3] then
				--print(ang,nearPoint, 40 - (nearPoint.X))
				local movePos = 0 - (nearPoint.X)
				ent.Position = ent.Position + Vector(movePos,0) 
			elseif ang < i.angles[1] or ang >= i.angles[3] then
				--print(ang,nearPoint, 40 - (nearPoint.X))
				local movePos = 0 - (nearPoint.X)
				ent.Position = ent.Position + Vector(movePos,0) 
			end
		end
		--ent.Position = curPos --ent.Position + 

		--ent.Position = ent.Position + ofsetPos:Resized(0.2)
		--print("off",ofsetVec)
		if ofsetVec:Length()>0 then

			local angle = math.floor(ofsetVec:GetAngleDegrees()/90)*90
			ofsetVec = Vector.FromAngle(angle)
			--print(ofsetVec)

			if ofsetVec.Y<0.5 and d.TSJDNHC_fallspeed>0 then
				d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed * 0.8 + -0.0
				
			--elseif ofsetVec.Y>0.5 and d.TSJDNHC_fallspeed<0 then
			--	d.TSJDNHC_fallspeed = 0
			else
				d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed and math.min(6,d.TSJDNHC_fallspeed + 0.4) or 0
			end
			--ent.Position = ent.Position + ofsetPos:Resized(0.2)

			local pow = ent.Velocity:Length()
			ofsetVec = ofsetVec:Normalized():Rotated(180)
			local revvec = {-1,-1,1,1}

			if ofsetVec.X > 0 then revvec[1] = revvec[1]+ofsetVec.X end
			if ofsetVec.X < 0 then revvec[3] = revvec[3]+ofsetVec.X end
			if ofsetVec.Y > 0 then revvec[2] = revvec[2]+ofsetVec.Y end
			if ofsetVec.Y < 0 then revvec[4] = revvec[4]+ofsetVec.Y end

			local nvec = ent.Velocity:Clamped(revvec[1]*50,revvec[2]*50,revvec[3]*50,revvec[4]*50)
			nvec = Vector(nvec.X < 0.01 and nvec.X > -0.01 and 0 or nvec.X, 
				nvec.Y < 0.01 and nvec.Y > -0.01 and 0 or nvec.Y)
			--print(ent.Velocity,nvec) --,revvec[1],revvec[2],revvec[3],revvec[4]
			--ent.Velocity = nvec --+ ofsetVec*0.1 --* pow --ent.Velocity + ofsetVec:Resized(1.0)

			--ent.Position = ent.Position + ofsetPos:Resized(2.4)
			ent.Velocity = ent.Velocity - ofsetVec:Resized(0.33)
		end
			d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed and math.min(6,d.TSJDNHC_fallspeed + 0.4) or 0
		--end
	end
    end
end


--local function jump(_,_,_,player)
--	if Input.IsActionTriggered(ButtonAction.ACTION_BOMB, 0) then
--		player.Velocity = player.Velocity + Vector(0,-15)
--	end
--end
--mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, jump)

---------------------------------------------------------------------
--[[
   	mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, RenTrack)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, RenTrack)
   	mod:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, RenTrack)
   	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_LASER_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_KNIFE_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, RenTrack)
    	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, ERenTrack)
	callbackOn = true
]]    
    --mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, BDCommand)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, TSJDNHC.CamEntUpdat, entCam.VARIANT)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, TSJDNHC.FakeCamfloorRender, entCam.VARIANT)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, FakeCamstein, 1000)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TSJDNHC.ChangeCamSpriteOffsets)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PlayerScale, CacheFlag.CACHE_SIZE)	
    --mod:AddCallback('TSJDNHC_FULL_FOCUS_LOST', FocusLost)

TSJDNHC_PT = TSJDNHC

end