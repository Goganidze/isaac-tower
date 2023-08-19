local mod = RegisterMod("platwormer", 1)

local Isaac = Isaac
local math = math
local Vector = Vector
local pairs = pairs
--local Render = getmetatable(Sprite).__class.Render

local Wtr = 20/13
local reloadData
if Isaac_Tower and Isaac_Tower.CurrentRoom and Isaac.GetPlayer() then
	reloadData = {roomName =  Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name, inEditor = Isaac_Tower.editor.InEditor}
end
Isaac_Tower = {
	game = Game(),
	sprites = {},
}
--local Isaac_Tower = Isaac_Tower 

local camfunc = include("nocamera")
camfunc(mod)

local IsaacTower_Type = Isaac.GetPlayerTypeByName("Isaac Tower")
local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')
local IsaacTower_Enemy = Isaac.GetEntityVariantByName("PIZTOW Enemi")

Isaac_Tower.StartRoom = "tutorial_1"

			--ИНИТ
------------------------------------------------------------------

local function TabDeepCopy(tbl)
    local t = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            t[k] = TabDeepCopy(v)
        else
            t[k] = v
        end
    end

    return t
end

local function GenSprite(gfx, anim, frame)
	if gfx and anim then
		local spr = Sprite()
		spr:Load(gfx, true)
		spr:Play(anim)
		if frame then
			spr:SetFrame(frame)
		end
		return spr
	end
end

if Renderer then
	Isaac_Tower.RG = true
end


Isaac_Tower.InAction = false
Isaac_Tower.Pause = true
Isaac_Tower.UpdateSpeed = 1
Isaac_Tower.Rooms = {}
--Isaac_Tower.CurrentRoom
Isaac_Tower.SpawnPoint = Vector(0,0)
Isaac_Tower.SmoothPlayerPos = Vector(0,0)
Isaac_Tower.GridLists = {
	Solid = false,
	Obs = false
}

Isaac_Tower.Callbacks = {
	FLAYER_GRID_SCANING = {},
	GRID_SHOULD_COLLIDE = {},
	ROOM_LOADING = {},
	EDITOR_POST_MENUS_RENDER = {},
	EDITOR_CONVERTING_CURRENT_ROOM_TO_EDITOR = {},
	EDITOR_CONVERTING_EDITOR_ROOM = {},
	EDITOR_CONVERTING_EDITOR_ROOM_STRING = {},
	PRE_EDITOR_CONVERTING_EDITOR_ROOM = {},
	EDITOR_SPECIAL_UPDATE = {},
	EDITOR_SPECIAL_TILE_RENDER = {},
	SPECIAL_UPDATE = {},
	SPECIAL_COLLISION = {},
	SPECIAL_RENDER = {},
	SPECIAL_POINT_COLLISION = {},
	PLAYER_OUT_OF_BOUNDS = {},
	FLAYER_PRE_COLLIDING_ENEMY = {},
	FLAYER_POST_RENDER = {},

	ENEMY_POST_INIT = {},
	ENEMY_POST_UPDATE = {},
	ENEMY_POST_RENDER = {},
}

Isaac_Tower.ENT = {}
Isaac_Tower.ENT.GIB = {ID = EntityType.ENTITY_EFFECT, VAR = IsaacTower_GibVariant}
Isaac_Tower.ENT.GibSubType = {
	GIB = 0,
	AFTERIMAGE = 100,
	SWEET = 101,
	SOUND_BARRIER = 110,
}
Isaac_Tower.ENT.Enemy = {ID = EntityType.ENTITY_EFFECT, VAR = IsaacTower_Enemy}

Isaac_Tower.sprites.BlackNotCube = Sprite()
Isaac_Tower.sprites.BlackNotCube:Load("gfx/doubleRender/black.anm2",true)
Isaac_Tower.sprites.BlackNotCube:Play("ПрямоугольникМалевича",true)

function Isaac_Tower.RenderBlack(alpha)
	local pos = Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2)
	Isaac_Tower.sprites.BlackNotCube.Color = Color(1,1,1,alpha)
	Isaac_Tower.sprites.BlackNotCube:Render(pos)
	Isaac_Tower.sprites.BlackNotCube.Color = Color(1,1,1,1)
end

local ZeroPoint = Vector(0,0)
local function UpdateZeroPoint()
	ZeroPoint = Isaac.WorldToRenderPosition(Vector(0,0))
end
--mod:AddCallback(ModCallbacks.MC_POST_UPDATE, UpdateZeroPoint) --MC_POST_UPDATE
function Isaac_Tower.GetRenderZeroPoint()
	return ZeroPoint
end

Isaac_Tower.Menus = {}
Isaac_Tower.Menus.Fade = 0
Isaac_Tower.Menus.FadeDelay = 0
Isaac_Tower.Menus.FadeState = 0
Isaac_Tower.Menus.Speed = 0
function Isaac_Tower.FadeInWithReaction(time, timeInFade, reactFunc)
	--if speed and type(speed) == "number" then error("arg[1] is not number",2) end

	Isaac_Tower.Menus.Fade = 0
	Isaac_Tower.Menus.FadeState = 1
	Isaac_Tower.Menus.Speed = 1/time
	Isaac_Tower.Menus.FadeDelay = timeInFade or 0
	Isaac_Tower.Menus.FadeReaction = reactFunc	
end
function Isaac_Tower.Menus.Fading()
    if Isaac_Tower.Menus.FadeState == 1 then
	Isaac_Tower.RenderBlack(Isaac_Tower.Menus.Fade)
	Isaac_Tower.Menus.Fade = Isaac_Tower.Menus.Fade + Isaac_Tower.Menus.Speed

	if Isaac_Tower.Menus.Fade >= 1 then
		Isaac_Tower.Menus.FadeState = 2
		--if Isaac_Tower.Menus.FadeReaction and type(Isaac_Tower.Menus.FadeReaction) == "function" then
		--	Isaac_Tower.Menus.FadeReaction()
		--end
	end
    elseif Isaac_Tower.Menus.FadeState == 2 then
	Isaac_Tower.RenderBlack(Isaac_Tower.Menus.Fade)
	Isaac_Tower.Menus.FadeDelay = Isaac_Tower.Menus.FadeDelay - 1
	if Isaac_Tower.Menus.FadeDelay <= 0 then
		Isaac_Tower.Menus.FadeDelay = 0
		Isaac_Tower.Menus.FadeState = 3
		if Isaac_Tower.Menus.FadeReaction and type(Isaac_Tower.Menus.FadeReaction) == "function" then
			Isaac_Tower.Menus.FadeReaction()
		end
	end
    elseif Isaac_Tower.Menus.FadeState == 3 then
	Isaac_Tower.RenderBlack(Isaac_Tower.Menus.Fade)
	Isaac_Tower.Menus.Fade = Isaac_Tower.Menus.Fade - Isaac_Tower.Menus.Speed

	if Isaac_Tower.Menus.Fade <= 0 then
		Isaac_Tower.Menus.Fade = 0
		Isaac_Tower.Menus.FadeState = 0
	end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, Isaac_Tower.Menus.Fading)

function Isaac_Tower.GameExit()
	TSJDNHC_PT.DeleteAllGridList()
	Isaac_Tower.CurrentRoom = nil
	Isaac_Tower.CloseEditor()
	Isaac_Tower.InAction = false
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Isaac_Tower.GameExit)

--room.Name
--room.Size
--room.SolidList
--room.ObsList
--room.DefSpawnPoint
--room.EntersSpawn
function Isaac_Tower.AddRoom(tab)
  if type(tab) == "table" and tab.Name then
	Isaac_Tower.Rooms[tab.Name] = tab
  end
end

local function GetLinkedGrid(grid, pos, size, fill)
	if size and pos then
		local tab = {}
		local Sx,Sy = pos.X,pos.Y
		for i=1, size.Y do
			for j=1, size.X do
				if i ~= 1 or j ~= 1 then
					local index = tostring(math.ceil(Sx+j-1)) .. "." .. tostring(math.ceil(Sy+i-1))
					local Hasgrid = grid[index]
					if Hasgrid or fill then
						tab[#tab+1] = {index}
					end
				end
			end
		end
		return tab
	end
end


--Isaac_Tower.TransitionSpawnOffset
function Isaac_Tower.SetRoom(roomName, preRoomName, TargetSpawnPoint)
	--if not Isaac_Tower.InAction then error("Func called outside the Isaac Tower mod",2) end
    if Isaac_Tower.Rooms[roomName] then

	for i, ent in pairs(Isaac.FindByType(1000, IsaacTower_Enemy, -1)) do
		if not ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT) then
			ent:Remove()
		end
	end
	for i, ent in pairs(Isaac.FindByType(1000, IsaacTower_GibVariant, -1)) do
		if not ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT) then
			ent:Remove()
		end
	end

	TSJDNHC_PT.DeleteAllGridList()
	local oldRoomName = preRoomName or Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name
	local newRoom = Isaac_Tower.Rooms[roomName]
	Isaac_Tower.GridLists = {
		Solid = false,
		Obs = false,
		Special = {},
		Evri = {},
	}
	Isaac_Tower.GridLists.Solid = TSJDNHC_PT:MakeGridList(Vector(-40,100),newRoom.Size.Y,newRoom.Size.X, 40,40)
	Isaac_Tower.GridLists.Obs = TSJDNHC_PT:MakeGridList(Vector(-40,100),newRoom.Size.Y*2,newRoom.Size.X*2, 20,20)
	Isaac_Tower.GridLists.Solid:SetGridAnim("gfx/fakegrid/grid2.anm2", 9)
	Isaac_Tower.GridLists.Solid:SetGridFromList(newRoom.SolidList)
	Isaac_Tower.GridLists.Obs:SetGridFromList(newRoom.ObsList or {})
	Isaac_Tower.GridLists.Solid:SetRenderMethod(1)
	--Isaac_Tower.GridLists.Obs:SetRenderMethod(1)

	if newRoom.EnviList then
		local list = Isaac_Tower.GridLists.Evri
		list.List = {}
		local CustomType = {}
		if newRoom.EnviList.CT and newRoom.EnviList.CF then
			for i, k in pairs(newRoom.EnviList.CT) do
				local size, pivot = Vector(k[3][1],k[3][2]), Vector(k[4][1],k[4][2])
				local anm2, anim = newRoom.EnviList.CF[k[1]], k[2]
				local GType = anm2..anim
				CustomType[i] = GType

				local ingridSpr = GenSprite(anm2,anim)
				ingridSpr.Scale =  Vector(.5,.5)
				Isaac_Tower.editor.AddEnvironment(GType,
					GenSprite(anm2,anim),
					function() return GenSprite(anm2,anim) end,
					ingridSpr,
					size,
					pivot)
			end
			newRoom.EnviList.CT = nil
			newRoom.EnviList.CF = nil
		end
		for i, k in pairs(newRoom.EnviList) do
			if Isaac_Tower.editor.GridTypes["Environment"][k.name or CustomType[k.ct]] then
				if k.ct and CustomType[k.ct] then
					k.name = CustomType[k.ct]
				end
				
				local spr = Isaac_Tower.editor.GridTypes["Environment"][k.name or CustomType[k.ct]].info()
				list.List[i] = {pos = k.pos, spr = spr, l = k.l or 0}
				local layer = k.l or 0

				list[layer] = list[layer] or {}
				for _, index in pairs(k.chl) do 
					local gridlist = list[layer]
					gridlist[index[1] ] = gridlist[index[1] ] or {}
					gridlist[index[1] ][index[2] ] = gridlist[index[1] ][index[2] ] or {}
					gridlist[index[1] ][index[2] ].Ps = gridlist[index[1] ][index[2] ].Ps or {}
					gridlist[index[1] ][index[2] ].Ps[i] = true
				end
			end
		end
	end

	if newRoom.Enemy then
		for i, k in pairs(newRoom.Enemy) do
			local data = Isaac_Tower.Enemies[k.name]
			print(data, k.name)
			if data then
				Isaac_Tower.Spawn(k.name, k.st, k.pos*40 + Vector(-60,80), Vector(0,0))
			end
		end
	end

	local EntersSpawn = {}
	local SpawnPoints = {}
	if newRoom.Special then
		for gType, tab in pairs(newRoom.Special) do
			if gType ~= "spawnpoint_def" and gType ~= "" then
				Isaac_Tower.GridLists.Special[gType] = {}
				for i, grid in ipairs(tab) do
					local index = math.ceil(grid.XY.X) .. "." .. math.ceil(grid.XY.Y)
					Isaac_Tower.GridLists.Special[gType][index] = TabDeepCopy(grid)
					Isaac_Tower.GridLists.Special[gType][index].pos = grid.XY*40 + Vector(-60,80)
					Isaac_Tower.GridLists.Special[gType][index].FrameCount = 0
					if Isaac_Tower.GridLists.Special[gType][index].Size then
						for i,k in pairs(GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].Size, true)) do
							Isaac_Tower.GridLists.Special[gType][k[1]] = {Parent = index}
						end
					end
					if gType == "Room_Transition" then
						EntersSpawn[#EntersSpawn+1] = {Name = grid.Name, pos = Isaac_Tower.GridLists.Special[gType][index].pos, HasOffset = true}
					elseif gType == "spawnpoint" then
						SpawnPoints[grid.Name] = {Name = grid.Name, pos = Isaac_Tower.GridLists.Special[gType][index].pos}
					end
				end
			end
		end
	end

	Isaac_Tower.SpawnPoint = newRoom.DefSpawnPoint
	--if oldRoomName and newRoom.EntersSpawn and newRoom.EntersSpawn[oldRoomName] then
	--	Isaac_Tower.SpawnPoint = newRoom.EntersSpawn[oldRoomName]
	--end
	local useOffset = false
	local targetName
	for i,k in pairs(EntersSpawn) do
		--[[if k.FromRoom and preRoomName == k.FromRoom then
			if TargetSpawnPoint and TargetSpawnPoint == k.Name then
				--if TargetSpawnPoint == k.Name then
					Isaac_Tower.SpawnPoint = k.pos
					useOffset = k.HasOffset
				--end
			else
				Isaac_Tower.SpawnPoint = k.pos
				useOffset = k.HasOffset
			end
		else
			if TargetSpawnPoint and TargetSpawnPoint == k.Name then
				Isaac_Tower.SpawnPoint = k.pos
				useOffset = k.HasOffset
			end
		end]]

		if not TargetSpawnPoint then
			if k.FromRoom and preRoomName == k.FromRoom then
				Isaac_Tower.SpawnPoint = k.pos
				useOffset = k.HasOffset
			end
		elseif TargetSpawnPoint == k.Name then
			targetName = k.Name
			if k.FromRoom and preRoomName == k.FromRoom then
				Isaac_Tower.SpawnPoint = k.pos
				useOffset = k.HasOffset
			elseif not k.FromRoom then
				Isaac_Tower.SpawnPoint = k.pos
				useOffset = k.HasOffset
			end
		end
	end

	Isaac.RunCallback(Isaac_Tower.Callbacks.ROOM_LOADING, newRoom, roomName, oldRoomName)

	Isaac_Tower.CurrentRoom = newRoom

	Isaac_Tower.RoomPostCompilator()

	local offset = useOffset and Isaac_Tower.TransitionSpawnOffset or Vector(0,0)
	Isaac_Tower.autoRoomClamp(Isaac_Tower.GridLists.Solid)
	for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
		Isaac_Tower.SetPlayerPos(Isaac.GetPlayer(i), Isaac_Tower.SpawnPoint + offset)
	end
	TSJDNHC_PT:SetFocusPosition(Isaac.GetPlayer():GetData().Isaac_Tower_Data.Position, 1)
	Isaac_Tower.SmoothPlayerPos = Isaac.GetPlayer():GetData().Isaac_Tower_Data.Position
	Isaac_Tower.TransitionSpawnOffset = nil
	
	if targetName and SpawnPoints[targetName] then
		Isaac_Tower.SpawnPoint = SpawnPoints[targetName].pos - Vector(7,7)
	end
    end
end

function Isaac_Tower.RoomTransition(roomName, force, preRoomName, TargetSpawnPoint)
	--if not Isaac_Tower.InAction then error("Func called outside the Isaac Tower mod",2) end
    if Isaac_Tower.Rooms[roomName] then
	if force then
		Isaac_Tower.SetRoom(roomName, preRoomName, TargetSpawnPoint)
		Isaac_Tower.Pause = false
	else
		Isaac_Tower.Pause = true
		Isaac_Tower.FadeInWithReaction(10, 5, function()
			Isaac_Tower.SetRoom(roomName, preRoomName, TargetSpawnPoint)
			Isaac_Tower.Pause = false
		end)
	end
    end
end

--Name = "testRoom",
--SolidList = list,
--ObsList = {},
--Size = Vector(64,14),
--DefSpawnPoint = Vector(140,280)
--{pos = Vector(120,310), Collision = 1, SpriteAnim = 2 },
--	dgfx = "gfx/fakegrid/basement.png",
--	animNum = 14,
--	extraAnim = {"45r","45l","30r","30l","half_up"},
--	useWorldPos = true,

function Isaac_Tower.GetForFileCurrentRoom()
	local str = "local roomdata = {"
	str = str .. "Name='" .. Isaac_Tower.CurrentRoom.Name .. "',"
	str = str .. "Size=Vector(" .. Isaac_Tower.GridLists.Solid.X .. "," .. Isaac_Tower.GridLists.Solid.Y .. "),"
	str = str .. "DefSpawnPoint=Vector(".. Isaac_Tower.CurrentRoom.DefSpawnPoint.X .. "," .. Isaac_Tower.CurrentRoom.DefSpawnPoint.Y .. "),"
	str = str .. "SolidList={\n"
	local solidTab = ""
	for _, y in pairs(Isaac_Tower.GridLists.Solid.Grid) do
		for x, grid in pairs(y) do
			if grid.SpriteAnim or grid.Sprite or grid.Type then
				solidTab = solidTab .. "{pos=Vector(" .. grid.CenterPos.X .. "," .. grid.CenterPos.Y .. ")" 
				solidTab = solidTab .. ",Collision=" .. grid.Collision .. ","
				if grid.SpriteAnim then
					solidTab = solidTab.."SpriteAnim='"..grid.SpriteAnim.."',"
				end
				if grid.Sprite then
					solidTab = solidTab.."Sprite="..grid.Sprite..","
				end
				if grid.Type then
					solidTab = solidTab.."Type='"..grid.Type.."',"
				end
				solidTab = solidTab.."},\n"
			end
		end
	end
	str = str .. solidTab .. "},\n}"
	Isaac.DebugString(str)
end

function Isaac_Tower.PrintWarn(text, level)
	level = level + 1
	error(text, level)
end

local function TowerInit(bool)
    local IsTower = false
    for pid=0,Isaac_Tower.game:GetNumPlayers()-1 do
		local player = Isaac.GetPlayer(pid)
		if player:GetPlayerType() == IsaacTower_Type then
			IsTower = true
			break
		end
    end
    if IsTower then
		Isaac.ExecuteCommand("stage 1")
		--Isaac_Tower.game:GetLevel():SetStage(1,0)
		Isaac_Tower.game:GetLevel():RemoveCurses( Isaac_Tower.game:GetLevel():GetCurses() )
		Isaac_Tower.game:GetHUD():SetVisible(false)

		TSJDNHC_PT:SpawnCamera(true)
		TSJDNHC_PT:SetFocusMode(2)
		
		TSJDNHC_PT.DeleteAllGridList()
		Isaac_Tower.RoomTransition(Isaac_Tower.StartRoom, true)
		--Isaac_Tower.SetRoom(Isaac_Tower.StartRoom)

		for i=0, DoorSlot.NUM_DOOR_SLOTS-1 do
			Isaac_Tower.game:GetRoom():RemoveDoor(i)
		end
		Isaac_Tower.autoRoomClamp(Isaac_Tower.GridLists.Solid)
		TSJDNHC_PT:SetRoomShadingVisible(false)
		TSJDNHC_PT:SetStainVisible(false)
		TSJDNHC_PT:SetActivity(true)

		Isaac_Tower.InAction = true
		TSJDNHC_PT:EnableCamera(true, true)
    else
		TSJDNHC_PT.DeleteAllGridList()
		TSJDNHC_PT:SetActivity(false)
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.LATE, TowerInit)

local function Init_Player(_,player)
	if player:GetPlayerType() == IsaacTower_Type and not player:GetData().Isaac_Tower_Data then
		Isaac_Tower.INIT_FLAYER(player)
	elseif player:GetPlayerType() == IsaacTower_Type then
		player.GridCollisionClass = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Init_Player,0)

------------------------------к

function Isaac_Tower.RoomPostCompilator()
    local t = Isaac.GetTime()
    local ignorelist = {}
    for i, grid in pairs(Isaac_Tower.GridLists.Solid:GetGridsAsTable()) do
        if not ignorelist[i] then
            if grid.slope then
                local num = 1
		::retu::
                if grid.Type == "45l" then
                    local upgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num-2] and Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num-2][grid.XY.X-num+1]
                    if num > 1 and upgrid then
			if upgrid.Collision == 0 and not upgrid.Type then
				Isaac_Tower.GridLists.Solid:LinkGrids( grid, upgrid, true)
			end
                    end
                    local nextgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num] and Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num][grid.XY.X-num]
                    if nextgrid then
			if nextgrid.Type and nextgrid.Type == grid.Type then
				ignorelist[nextgrid.Index] = true
				Isaac_Tower.GridLists.Solid:LinkGrids( grid, nextgrid, true)
				grid.slope = Vector(grid.Half.Y*2,0)
				num = num + 1
				goto retu
			end
                    end
		elseif grid.Type == "45r" then
                    local upgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num-2] and Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num-2][grid.XY.X+num-1]
                    if num > 1 and upgrid then
			if upgrid.Collision == 0 and not upgrid.Type then
				Isaac_Tower.GridLists.Solid:LinkGrids( grid, upgrid, true)
			end
                    end
                    local nextgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num] and Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y+num][grid.XY.X+num]
                    if nextgrid then
			if nextgrid.Type and nextgrid.Type == grid.Type then
				ignorelist[nextgrid.Index] = true
				Isaac_Tower.GridLists.Solid:LinkGrids( grid, nextgrid, true)
				grid.slope = Vector(0,grid.Half.Y*2)
				num = num + 1
				goto retu
			end
                    end
                end
            end 
        end
    end
    print(Isaac.GetTime()-t)
end

local updateframe = 0
local updateframe30 = 0
local UpdatesInThatFrame = 0
local UpdatesInThatFrame30 = 0

local ScrenX,ScrenY = 0, 0
local ScrenXX,ScrenYY = 0, 0
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not Isaac_Tower.InAction or (Isaac_Tower.Pause and Isaac_Tower.game:IsPaused()) then return end
	ScrenXX,ScrenYY = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	if Isaac_Tower.GridLists.Solid and ScrenX ~= Isaac.GetScreenWidth() and ScrenY ~= Isaac.GetScreenHeight() then
		ScrenX,ScrenY = ScrenXX,ScrenYY --Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
		Isaac_Tower.autoRoomClamp(Isaac_Tower.GridLists.Solid)
	end

	updateframe = updateframe + Isaac_Tower.UpdateSpeed
	UpdatesInThatFrame = 0
	if updateframe >= 1 then
		for i=1, math.floor(updateframe) do
			updateframe = updateframe - 1
			UpdatesInThatFrame = UpdatesInThatFrame + 1
		end
	end
end)

function Isaac_Tower.GetScreenCenter()
	return Vector(ScrenXX/2, ScrenYY/2)
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	UpdateZeroPoint()

	updateframe30 = updateframe30 + Isaac_Tower.UpdateSpeed
	UpdatesInThatFrame30 = 0
	if updateframe30 >= 1 then
		for i=1, math.floor(updateframe30) do
			updateframe30 = updateframe30 - 1
			UpdatesInThatFrame30 = UpdatesInThatFrame30 + 1
		end
	end
end)

function Isaac_Tower.UpdateSpeedHandler(func, ...)
	if UpdatesInThatFrame >= 1 then
		for i=1, UpdatesInThatFrame do
			func(...)
		end
	end
end

function Isaac_Tower.UpdateSpeedHandler30(func, ...)
	if UpdatesInThatFrame30 >= 1 then
		for i=1, UpdatesInThatFrame30 do
			func(...)
		end
	end
end

function Isaac_Tower.GetProcentUpdate()
	return updateframe%1
end

function Isaac_Tower.HandleUpdateSpeedPos(pos,vel)
	if Isaac_Tower.UpdateSpeed > 1 then
		pos = pos + vel
	else
		pos = pos - vel*Isaac_Tower.GetProcentUpdate()
	end
	return pos
end

function Isaac_Tower.SetUpdateSpeed(num)
	Isaac_Tower.UpdateSpeed = num
	updateframe = 0
end

local enemyIndexReaction = {
	Position = function(self)
		return rawget(self, "Self").Position
	end,
	Velocity = function(self)
		return rawget(self, "Self").Velocity
	end,
}

local enemyMetatable = {}
enemyMetatable.__index  = function(self, key)
	--if not Game():IsPaused() then print(key) end
	--if enemyIndexReaction[key] then
	--	return rawget(self, "Self").Position
	--end
	return enemyIndexReaction[key] and enemyIndexReaction[key](self) or rawget(self, key)
end

Isaac_Tower.Enemies = {}
---@param name string
---@param gfx string
---@param size Vector
---@param flags table
--Flags: EntityCollision, CollisionOffset, NoGrabbing, Invincibility, NoStun
function Isaac_Tower.RegisterEnemy(name, gfx, size, flags)
	if name then
		if size and type(size) ~= "userdata" then error("[3] is not a vector") end
		if flags and type(flags) ~= "table" then error("[4] is not a table",2) end
		Isaac_Tower.Enemies[name] = {Name = name, gfx = gfx, Size = size, Flags = flags or {}}
	end
end

function Isaac_Tower.Spawn(name, subtype, pos, vec, spawner)
	local data = Isaac_Tower.Enemies[name]
	local ent = Isaac.Spawn(EntityType.ENTITY_EFFECT, IsaacTower_Enemy, subtype or 0, pos, vec, spawner)
	ent:GetSprite():Load(data.gfx, true)
	ent:GetSprite():Play(ent:GetSprite():GetDefaultAnimation())
	ent:GetData().Isaac_Tower_Data = {Type = name, GridPoints = {}, --Position = ent.Position, Velocity = ent.Velocity,
		LastPosition = pos, Half = data.Size, grounding = 0}
	local d = ent:GetData().Isaac_Tower_Data
	d.Self = ent

	local size = d.Half.X > d.Half.Y and d.Half.X*1.2 or d.Half.Y*1.2   --d.Half:Length()*2
	for i=0,360-45,45 do
		local ang = i --90*(i)+45
		local pos = Vector(d.Half:Length()*3.5,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.GridPoints[i] = {pos, vec}
	end
	d.GridPoints[" "] = {Vector(0,0), Vector(-1,0)}

	ent:GetData().TSJDNHC_GridColl = data.Flags.GridCollision or 1
	ent.EntityCollisionClass = data.Flags.EntityCollision or 1
	d.CollisionOffset = data.Flags.CollisionOffset or Vector(0,0)
	d.FlayerDistanceCheck = d.Half:Length()
	d.State = 1

	if data.Flags then
		if type(data.Flags) == "table" then
			d.Flags = TabDeepCopy(data.Flags)
		end
	end

	local spawnXY = pos - Isaac_Tower.GridLists.Solid.StartPos
	local xs,ys = math.ceil(spawnXY.X/40), math.ceil(spawnXY.Y/40)
	d.SpawnXY = Vector(xs,ys)

	local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
	ent:AddEntityFlags(addflag)

	--setmetatable(d, enemyMetatable)

	--d.RNG = RNG()
	--d.RNG:SetSeed(ent.GetDropRNG)

	Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_INIT, name, ent)
	return ent
end

Isaac_Tower.EnemyHandlers = {}
Isaac_Tower.EnemyHandlers.FlayerCollision = {}

function Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent, CollideWithPlayers)
	local data = ent:GetData().Isaac_Tower_Data
	local tab = {}
	if data and data.Half then
		for i, col in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, IsaacTower_Enemy, -1)) do
			if col.Index ~= ent.Index and col.EntityCollisionClass == 1 then
				local colData = col:GetData().Isaac_Tower_Data
				if colData then
					local box1 = {pos = ent.Position, half = data.Half}
					local box2 = {pos = col.Position, half = colData.Half}
					if Isaac_Tower.NoType_CheckAABB(box1, box2) then
						tab[#tab+1] = col
					end
				end
			end
		end
		if CollideWithPlayers then
			for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
				local colData = Isaac.GetPlayer(i):GetData().Isaac_Tower_Data
				if colData then
					local box1 = {pos = ent.Position, half = data.Half}
					local box2 = {pos = colData.Position, half = colData.Half}
					if Isaac_Tower.NoType_CheckAABB(box1, box2) then
						tab[#tab+1] = Isaac.GetPlayer(i)
					end
				end
			end
		end
	end
	return tab
end

function Isaac_Tower.EnemyHandlers.GetRoomEnemies(cache)
	local tab = {}
	for i,k in pairs(Isaac.FindByType(Isaac_Tower.ENT.Enemy.ID,Isaac_Tower.ENT.Enemy.VAR,-1,cache)) do
		if k:GetData().Isaac_Tower_Data then
			tab[#tab+1] = k
		end
	end
	return tab
end

function Isaac_Tower.GerNearestFlayer(pos)
	if not pos then error("[1] is not a Vector") end
	local maxdist = 100000
	local pls = Isaac_Tower.GetFlayer()
	for i=0, Isaac_Tower.game:GetNumPlayers() do
		local flayer = Isaac_Tower.GetFlayer(i)
		local dist = flayer.Position:Distance(pos)
		if dist < maxdist then
			maxdist = dist
			pls = flayer
		end
	end
	return pls
end

--.....................................................................................................



local function sign(num)
	return num < 0 and -1 or 1
end
local function sign0(num)
	return num < 0 and -1 or num == 0 and 0 or 1
end

local function hitG()
	local tab = {}
	tab.delta = Vector(0,0) --{x = 0, y = 0}
	tab.normal = Vector(0,0) --{x = 0, y = 0}
	tab.pos = Vector(0,0) --{x = 0, y = 0}
	tab.SlopeAngle = 0
	return tab
end

--[[local function intersectAABB(self, box) --example
    local dx = box.pos.x - this.pos.x
    local px = (box.half.x + this.half.x) - math.abs(dx)
    if px <= 0 then
      return
    end

    local dy = box.pos.y - this.pos.y
    local py = (box.half.y + this.half.y) - math.abs(dy)
    if py <= 0 then
      return
    end

    local hit = hitG()
    if (px < py) then
      local sx = sign(dx)
      hit.delta.x = px * sx
      hit.normal.x = sx
      hit.pos.x = this.pos.x + (this.half.x * sx)
      hit.pos.y = box.pos.y
    else 
      local sy = sign(dy);
      hit.delta.y = py * sy;
      hit.normal.y = sy;
      hit.pos.x = box.pos.x;
      hit.pos.y = this.pos.y + (this.half.y * sy);
    end
    return hit
end]]


function Isaac_Tower.ShouldCollide(ent, grid, check) --d.TSJDNHC_GridColl, grid.Collision
	local entCol, gridColl = ent:GetData().TSJDNHC_GridColl, grid.Collision
	local fent = ent:GetData().Isaac_Tower_Data or ent:GetData().Isaac_Tower_Data
	
	if not check and grid.OnCollisionFunc and grid.OnCollisionFunc(ent, grid) then
		return false
	end
	
	local result = Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.GRID_SHOULD_COLLIDE, ent, grid, check)
	if result then
		return result
	end

	if entCol == 1 and gridColl == 1 then
		if grid.OnlyUp then
			if not ent:ToPlayer() then

				if ent.Position.Y > (grid.CenterPos.Y-grid.Half.Y) then
					return
				elseif (ent.Position.Y+fent.CollisionOffset.Y+fent.Half.Y) <= (grid.CenterPos.Y-grid.Half.Y+2) then
					return true
				end
			else
				if fent.Position.Y > (grid.CenterPos.Y-grid.Half.Y) then
					return
				elseif (fent.Position.Y+fent.CollisionOffset.Y+fent.Half.Y) <= (grid.CenterPos.Y-grid.Half.Y+2) then
					return true
				end
			end
		else
			return true
		end
	end
end

local function RayCastShouldCollide(pos, grid)
	local gridColl = grid.Collision
	if grid.OnlyUp then
		if pos.Y > (grid.CenterPos.Y-grid.Half.Y) then
			return
		elseif (pos.Y) <= (grid.CenterPos.Y-grid.Half.Y+2) then
			return true
		end
		--return true
	elseif gridColl == 1 then
		return true
	end
end

function Isaac_Tower.rayCast( startPos, rot, step, stepLimit)
	stepLimit = stepLimit or 100
	for i = 0, stepLimit do
		local pos = startPos + rot:Resized(step*i)
		local grid = Isaac_Tower.GridLists.Solid:GetGrid(pos)
		if grid and RayCastShouldCollide(startPos, grid) then
			return grid
		end
		local obs = Isaac_Tower.GridLists.Obs:GetGrid(pos)
		if obs and RayCastShouldCollide(startPos, obs) then
			return obs
		end
	end
end

local function GetDeepSlope(this, box)
	if not box.slope then return 0 end
	local addv = box.slope.X<box.slope.Y and this.Half.X-1 or -this.Half.X+1

	local pos = this.Position.X - (box.CenterPos.X-box.Half.X) - addv -- this.Velocity.X
	local proc = box.slope.X<box.slope.Y and
		math.max(-0.00, math.min(1.10, pos/(box.Half.X*2)) )
		or math.max(-0.10, math.min(1.00, pos/(box.Half.X*2)) )
	local offset 
	
	if box.slope.X<box.slope.Y then
		offset = box.slope.X*(1-proc) - box.slope.Y*(proc)
	else
		--proc = proc 
		offset = -(box.slope.X*(1-proc) - box.slope.Y*(proc))
	end
	
	return offset
end

function Isaac_Tower.CheckintersectAABB(this, box)
    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) -- - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then --and box.CenterPos.Y>=(this.Position.Y-this.Half.X) then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) -- - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)

    local upbox = box.GridList.Grid[box.XY.Y-1] and box.GridList.Grid[box.XY.Y-1][box.XY.X]

    if (px < py) and not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )  then --and (py>5)
      local sx = sign(dx)
      hit.delta.X = px * sx
      --hit.normal.X = sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      --hit.normal.Y = sy;
      hit.pos.X = box.CenterPos.X;
      hit.pos.Y = this.Position.Y + (this.Half.Y * sy);
    end

    return hit
end

---@param box1 table
---@param box2 table
--box = { pos = Vector, half = Vector }
function Isaac_Tower.NoType_intersectAABB(box1,box2)
	local dx = box1.pos.X - box2.pos.x
    local px = (box1.half.X + box2.half.X) - math.abs(dx)
    if px <= 0 then
      return
    end

    local dy = box1.pos.Y - box2.pos.Y
    local py = (box1.half.Y + box2.half.Y) - math.abs(dy)
    if py <= 0 then
      return
    end

    local hit = hitG()
    if (px < py) then
      local sx = sign(dx)
      hit.delta.X = px * sx
      hit.normal.X = sx
      hit.pos.X = box2.pos.X + (box2.half.X * sx)
      hit.pos.Y = box1.pos.Y
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.normal.Y = sy;
      hit.pos.X = box1.pos.X;
      hit.pos.Y = box2.pos.Y + (box2.half.Y * sy);
    end
    return hit
end

---@param box1 table
---@param box2 table
--box = { pos = Vector, half = Vector }
function Isaac_Tower.NoType_CheckAABB(box1,box2)
	local dx = box1.pos.X - box2.pos.X
    local px = (box1.half.X + box2.half.X) - math.abs(dx)
    if px <= 0 then
      return
    end

    local dy = box1.pos.Y - box2.pos.Y
    local py = (box1.half.Y + box2.half.Y) - math.abs(dy)
    if py <= 0 then
      return
    end

    return true
end


local function intersectAABB(this, box)
    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then --and box.CenterPos.Y>=(this.Position.Y-this.Half.X) then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
      --hit.Slope = (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)
    
    if py <= 0 then
      return
    end

    local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2) --box.GridList.Grid[box.XY.Y-1] and box.GridList.Grid[box.XY.Y-1][box.XY.X]

    local smoothup = this.DontHelpCollisionUpping or not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
    if (px < py) and smoothup then 
      local sx = sign(dx)
      hit.delta.X = px * sx
      --hit.normal.X = sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY

      --local Nextbox = box.GridList.Grid[box.XY.Y][box.XY.X-sx]
      --if not Nextbox or Nextbox.Collision == 0 then
        this.CollideWall = sx
      --end
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      --hit.normal.Y = sy;
      hit.pos.X = box.CenterPos.X;
      hit.pos.Y = this.Position.Y + (this.Half.Y * sy);

      if sy == 1 then
        this.OnGround = true 
        this.jumpDelay = 10
        hit.SlopeAngle = box.MovingMulti
        --this.grounding = 10
        if (px < py) and (dy>0 and py<20) then
            hit.SmoothUp = true
        end
      else
        this.Velocity.Y = math.max(0, this.Velocity.Y)
        this.CollideCeiling = true
        this.JumpActive = nil
		print("Ceiling", box.Index)
      end
    end

    return hit
end

local function intersectAABB_X(this, box)
    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)
    
    if py <= 0 then
      return
    end

    local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2)

    local smoothup = this.DontHelpCollisionUpping or not (this.Position.Y>=0 and dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
    if (px < py) and smoothup then 
      local sx = sign(dx)
      hit.delta.X = px * sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY
      this.CollideWall = sx
    else
      return
    end

    return hit
end

local function intersectAABB_Y(this, box)
    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)
    
    if py <= 0 then
      return
    end

    local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2)

    --local smoothup = this.DontHelpCollisionUpping or not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
    if (px < py) then --and smoothup then 
		
	  if this.Position.Y>=0 and (dy>0 and py<20) then
		local sy = sign(dy);
        hit.delta.Y = py * sy;
        hit.pos.X = box.CenterPos.X;
        hit.pos.Y = this.Position.Y + (this.Half.Y * sy);
		this.OnGround = true 
        this.jumpDelay = 10
        hit.SlopeAngle = box.MovingMulti

        this.SmoothUp = true
		return hit
      end
      return
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.pos.X = box.CenterPos.X;
      hit.pos.Y = this.Position.Y + (this.Half.Y * sy);

      if sy == 1 then
        this.OnGround = true 
        this.jumpDelay = 10
        hit.SlopeAngle = box.MovingMulti
      else
        this.Velocity.Y = math.max(0, this.Velocity.Y)
        this.CollideCeiling = true
        this.JumpActive = nil
		--print("Ceiling", box.Index, px , py)
      end
    end

    return hit
end

local function EnemyintersectAABB_X(ent, box)
	local this = ent:GetData().Isaac_Tower_Data
	this.Position = ent.Position
	this.Velocity = ent.Velocity

    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)
    
    if py <= 0 then
      return
    end

    local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2)

    local smoothup = this.DontHelpCollisionUpping or not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
	
    if (px < py) and smoothup then
      local sx = sign(dx)
      hit.delta.X = px * sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY
      this.CollideWall = sx
    else 
      return
    end

    return hit
end

local function EnemyintersectAABB_Y(ent, box)
	local this = ent:GetData().Isaac_Tower_Data
	this.Position = ent.Position
	this.Velocity = ent.Velocity

    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y+0

    if box.slope then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)

    if py <= 0 then
      return
    end

    local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2)

    --local smoothup = this.DontHelpCollisionUpping or not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
    if (px < py) then --and smoothup then 
      return
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.pos.X = box.CenterPos.X;
      hit.pos.Y = this.Position.Y + (this.Half.Y * sy);

      if sy == 1 then
        this.OnGround = true 
        this.jumpDelay = 10
        hit.SlopeAngle = box.MovingMulti
        if (px < py) and (dy>0 and py<20) then
            hit.SmoothUp = true
        end
      else
        this.Velocity.Y = math.max(0, this.Velocity.Y)
		--this.Velocity = Vector(this.Velocity.X, math.max(0, this.Velocity.Y))
        this.CollideCeiling = true
        this.JumpActive = nil
		--print("Ceiling", box.Index, px , py)
      end
    end

    return hit
end




Isaac_Tower.sprites.GridCollPoint = Sprite()
Isaac_Tower.sprites.GridCollPoint:Load("gfx/doubleRender/gridDebug/debug.anm2")
Isaac_Tower.sprites.GridCollPoint.Scale = Vector(0.5,0.5)
Isaac_Tower.sprites.GridCollPoint:Play("point")


local function CheckCanUp(ent)
	local result = true
	local d = ent:GetData()
	local fent = d.Isaac_Tower_Data

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
	end

	fent.Half = half
	fent.CollisionOffset = offset

	return result
end

local function GetDeepSlopeForShadow(this, box)
	if not box.slope then return 0 end
	local addv = box.slope.X<box.slope.Y and this.Half.X-1 or -this.Half.X+1

	local pos = this.Position.X - (box.CenterPos.X-box.Half.X) - addv -- this.Velocity.X
	local proc = pos/(box.Half.X*2) --box.slope.X<box.slope.Y and pos/(box.Half.X*2) or pos/(box.Half.X*2)
		--math.max(-0.00, math.min(1.10, pos/(box.Half.X*2)) )
		--or math.max(-0.10, math.min(1.00, pos/(box.Half.X*2)) )
	local offset 
	
	if box.slope.X<box.slope.Y then
		offset = box.slope.X*(1-proc) - box.slope.Y*(proc)
	else
		--proc = proc 
		offset = -(box.slope.X*(1-proc) - box.slope.Y*(proc))
	end
	
	return offset
end



function Isaac_Tower.SetPlayerPos(ent, pos)
	local d = ent:GetData()
	local fent = d.Isaac_Tower_Data
	if not fent then error("Func called outside the Isaac Tower mod",2) end
	fent.Position = pos
	fent.Velocity = Vector(0,0)
end

function Isaac_Tower.autoRoomClamp(GridList)
	local Wtr = 20/13
	local clamp = {
		-208+Isaac.GetScreenWidth()/2, -91+Isaac.GetScreenHeight()/2,  --Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
		GridList.CornerPos.X/Wtr + GridList.StartPos.X/Wtr - Isaac.GetScreenWidth()/2 - 184 - 26,  --+ GridList.StartPos.X/1.54,
		GridList.CornerPos.Y/Wtr + GridList.StartPos.Y/Wtr - Isaac.GetScreenHeight()/2 - 247.5 - 26 --GridList.StartPos.Y/1.54 --
	}
	--print(clamp[1],clamp[2],clamp[3],clamp[4])
	TSJDNHC_PT:SetCameraClamp(clamp)
end


function Isaac_Tower.PlatformerCollHandler(_, ent)
	if ent:GetPlayerType() ~= IsaacTower_Type then return end
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end

	local d = ent:GetData()
	local fent = d.Isaac_Tower_Data

	Isaac_Tower.UpdateSpeedHandler(function()
		Isaac_Tower.HandleMoving(ent)

		--d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed or 0

		if not Isaac_Tower.GridLists.Solid:GetGrid(fent.Position) then
			local result = Isaac.RunCallback(Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, ent)
			if type(result) == "userdata" and result.X then
				Isaac_Tower.SetPlayerPos(ent, result)
			elseif result ~= true then
				Isaac_Tower.SetPlayerPos(ent, Isaac_Tower.SpawnPoint or Vector(320, 280))
			end
		end

		-------------------------
		fent.slopeAngle = nil
		local collidedGrid = {}
		ent:GetData().LastcollidedGrid = {}

		fent.CollideWall = nil
		fent.OnGround = false
		fent.CollideCeiling = false
		fent.jumpDelay = fent.jumpDelay - 1

		fent.LastVelocity = fent.Velocity / 1
		fent.LastPosition = fent.Position / 1

		local repeatNum = math.max(1, math.ceil(fent.Velocity:Length() / 8))

		local origVelocity = fent.Velocity / 1
		fent.Velocity = fent.Velocity / repeatNum
		local slowedVelocity = fent.Velocity / 1
		fent.RepeatingNum = repeatNum
		
		for i = 1, repeatNum do
			local indexs = {}
			local pointIndex = Isaac_Tower.GridLists.Solid:GetGrid(fent.Position)
			pointIndex = pointIndex and (math.ceil(pointIndex.XY.X) .. "." .. math.ceil(pointIndex.XY.Y))
			for ia, k in pairs(d.TSJDNHC_GridPoints) do
				local grid = Isaac_Tower.GridLists.Solid:GetGrid(fent.Position + Vector(0, 12) + fent.Velocity + k[1])

				if grid then
					if Isaac_Tower.ShouldCollide(ent, grid) then
						collidedGrid[grid] = collidedGrid[grid] or {}
						--collidedGrid[grid][i] = k[1] + fent.Position
						ent:GetData().LastcollidedGrid[#ent:GetData().LastcollidedGrid + 1] = grid
					end
					local index = math.ceil(grid.XY.X) .. "." .. math.ceil(grid.XY.Y)
					indexs[index] = true
				end
				--fent.Velocity = origVelocity
				local obs = Isaac_Tower.GridLists.Obs:GetGrid(fent.Position + Vector(0, 12) + fent.Velocity + k[1])
				if obs and Isaac_Tower.ShouldCollide(ent, obs) then
					collidedGrid[obs] = collidedGrid[grid] or {} --true
					--collidedGrid[obs][i] = k[1] + fent.Position -- ent.Velocity
					ent:GetData().LastcollidedGrid[#ent:GetData().LastcollidedGrid + 1] = obs
				end
				--fent.Velocity = slowedVelocity
			end

			for ia, k in pairs(indexs) do
				for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
					local spec = tab[ia]
					if spec then
						if spec.Parent then
							spec = tab[spec.Parent]
						end
						Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spec)
					end
				end
			end
			if pointIndex then
				for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
					local spec = tab[pointIndex]
					if spec then
						if spec.Parent then
							spec = tab[spec.Parent]
						end
						Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, gtype, ent, spec)
					end
				end
			end

			for ia, k in pairs(Isaac.GetCallbacks(Isaac_Tower.Callbacks.FLAYER_GRID_SCANING)) do
				local result = k.Function(k.Mod, ent, fent)
				if result then
					collidedGrid[result] = collidedGrid[result] or {}
				end
			end

			ent:GetData().DebugGridRen = ent:GetData().DebugGridRen or {}

			ent:GetData().DebugGridRen = {}
			
			for ia, k in pairs(collidedGrid) do
				--local gridpos = (i.Position + i.CenterPos)
				--local entpos = fent.Position - i.Position - fent.Velocity
				--local nearPoint
				--local maxd = 1000000

				local hit = intersectAABB_X(fent, ia) ---разделить проверку на x и y

				if hit and hit.delta.X ~= 0 then
					if not fent.slopeRot --hit.Slope
						or ((fent.Position.Y > hit.pos.Y or not fent.slopeRot == sign(hit.delta.X))
							and fent.slopeRot == sign(hit.delta.X)) then
						d.DebugGridRen[#d.DebugGridRen + 1] = hit.pos
						fent.Position.X = fent.Position.X - hit.delta.X + fent.Velocity.X

						if sign(fent.Velocity.X) == sign(hit.delta.X) then
							fent.Velocity.X = 0
						end
					end
				end
			end
			
			local hasUpHelp = false
			for ia, k in pairs(collidedGrid) do
				local hitY = intersectAABB_Y(fent, ia)

				--print(hitY, fent.SmoothUp)
				if hitY and hitY.delta.Y ~= 0 then
					d.DebugGridRen[#d.DebugGridRen + 1] = hitY.pos
					if fent.SmoothUp then
						hasUpHelp = true
						
						fent.Position.Y = fent.Position.Y - hitY.delta.Y / math.max(1, (30 / (math.abs(fent.Velocity.X)+2))) --10
						
						if hitY.delta.Y < 6 then
							fent.SmoothUp = nil
						end
					else
						fent.Position.Y = fent.Position.Y - hitY.delta.Y --Vector(0, hitY.delta.Y)
					end
					if hitY.SlopeAngle then
						fent.slopeAngle = hitY.SlopeAngle
					end
				elseif not hasUpHelp then
					fent.SmoothUp = nil
				end
			end
			local prePosition = fent.Position / 1

			fent.Position = fent.Position + fent.Velocity -- * Isaac_Tower.UpdateSpeed
			ent.Position = Vector(-200, fent.Position.Y + 50)


			if fent.TrueVelocity.Y >= 0 and fent.grounding and fent.grounding > 0 then
				local collGrid = {}
				for i = -1, 1 do
					local grid = Isaac_Tower.rayCast((fent.Position - fent.Velocity + Vector(fent.Half.X * i, -10)),
						Vector(0, 1), 10, 6)                                                                               -- Vector(fent.Half.X*i,-10)

					if grid and Isaac_Tower.ShouldCollide(ent, grid) then                                                  --and grid.slope
						collGrid[grid] = collGrid[grid] or true
					end
				end
				local groundMinOffset = -200
				local ignoreGrounding = false
				for ia, k in pairs(collGrid) do
					local hit = Isaac_Tower.CheckintersectAABB(fent, ia)

					if hit.delta.Y > -40 and hit.delta.Y <= 10 and groundMinOffset < hit.delta.Y then
						groundMinOffset = math.min(0, hit.delta.Y) -- 1

						--[[local GridCollPoint = Sprite()
							GridCollPoint:Load("gfx/doubleRender/gridDebug/debug.anm2")
							GridCollPoint.Scale = Vector(2.5,2.5)
							GridCollPoint:Play("point")
							Isaac_Tower.DebugRenderThis(GridCollPoint, Isaac.WorldToRenderPosition(hit.pos), 1)]]

						if not ignoreGrounding and not ia.slope then
							ignoreGrounding = true
						elseif ignoreGrounding and ia.slope then
							ignoreGrounding = false
						end
					end
				end
				if not ignoreGrounding and groundMinOffset > -40 and groundMinOffset < 0 then
					fent.Position.Y = fent.Position.Y - groundMinOffset --+ math.max(0, fent.Velocity.Y-4)
					fent.OnGround = true
					fent.jumpDelay = 10
					fent.Velocity.Y = math.min(0, fent.Velocity.Y)
				end
			end
		end
		fent.Velocity = fent.Velocity * repeatNum
		fent.RepeatingNum = 1

		fent.TrueVelocity = fent.Position - fent.LastPosition     --prePosition
		

		if fent.OnGround then
			fent.grounding = 5
		else
			fent.grounding = fent.grounding - 1
		end

		if fent.OnAttack and fent.FrameCount % 7 == 0 then
			table.insert(fent.PosRecord, { fent.Position / 1, fent.FrameCount % 14 == 0 })
			if fent.FrameCount % 21 == 0 then
				fent.PosRecord = {}
			end
		elseif not fent.OnAttack then
			fent.PosRecord = {}
		end

		--fent.SmoothUp = nil
		fent.FrameCount = fent.FrameCount + 1
	end)

	--Flayer.Shadow 

	fent.Shadowposes = {}

	for i=-1,1 do
		local grid = Isaac_Tower.rayCast(fent.Position+Vector(i*10,21),Vector(0,1),20,3)
		
		if grid and not grid.slope then
			--local hit = Isaac_Tower.CheckintersectAABB(fent, grid)
			--if hit then
				local alpha = math.min(1, 1.85-(grid.Position.Y-fent.Position.Y)/40) ---19
				local pos = grid.CenterPos.Y-grid.Half.Y-1 ---Vector(0,grid.Half.Y)
				local rezl = math.max(0, (grid.CenterPos.X-grid.Half.X-fent.Position.X)/Wtr+11)
				local resp = math.max(0, (fent.Position.X-grid.CenterPos.X-grid.Half.X)/Wtr+9)
				fent.Shadowposes[grid.Index] = {Vector(fent.Position.X, pos), rezl, resp, alpha}
			--end
		elseif grid and grid.slope then
			local angleMulti = math.abs(grid.MovingMulti)/90
			local center = grid.CenterPos.Y - grid.Half.Y - GetDeepSlopeForShadow(
				{Position = Vector(fent.Position.X, grid.CenterPos.Y), Half = fent.Half}, grid)+((angleMulti)*20)
			local alpha = math.min(1, 1.85-(center-fent.Position.Y)/40) ---19
			local pos = center-1 ---Vector(0,grid.Half.Y)
			local ls = grid.CenterPos.X-grid.Half.X
			local ps = grid.CenterPos.X+grid.Half.X
			local rezl = math.max(0, (ls-fent.Position.X)/Wtr+11)
			local resp = math.max(0, (fent.Position.X-ps)/Wtr+9)
			if grid.MovingMulti>0 then
				local xpos = fent.Position.X --math.max(ls, math.min(ps-fent.Half.X/2, fent.Position.X ) )
				fent.Shadowposes[grid.Index] = {Vector(xpos, pos), rezl, resp, alpha, grid.MovingMulti}
			else
				local xpos = fent.Position.X --math.max(ls+fent.Half.X/2, math.min(ps-fent.Half.X/2, fent.Position.X ) )
				fent.Shadowposes[grid.Index] = {Vector(xpos, pos), rezl, resp, alpha, grid.MovingMulti}
			end
		end
	end

	--[[if fent.TrueVelocity:Length()==0 and fent.CorrectPosDelay ~= true then
		fent.CorrectPosDelay = fent.CorrectPosDelay and (fent.CorrectPosDelay-1) or 5
		if fent.CorrectPosDelay <= 0 then
			fent.CorrectPosDelay = true
			fent.Position = Vector(math.floor(fent.Position.X), math.floor(fent.Position.Y))
		end
	elseif fent.TrueVelocity:Length()~=0 then
		fent.CorrectPosDelay = nil
	end]]

	--local prePlayerPos = Isaac_Tower.SmoothPlayerPos/1
	Isaac_Tower.SmoothPlayerPos = Isaac_Tower.SmoothPlayerPos * 0.8 
		+ (fent.Position + Vector(fent.Velocity.X, 0) * 5) * 0.2

	--if prePlayerPos:Distance(Isaac_Tower.SmoothPlayerPos) > 1 then
		Isaac_Tower.SmoothPlayerPos = Vector( math.floor(Isaac_Tower.SmoothPlayerPos.X*20)/20, math.floor(Isaac_Tower.SmoothPlayerPos.Y*20)/20 )
	--end
	TSJDNHC_PT:SetFocusPosition(Isaac_Tower.SmoothPlayerPos, 1) --0.98
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Isaac_Tower.PlatformerCollHandler)

function Isaac_Tower.INIT_FLAYER(player)
	
	local d = player:GetData()
	local ent = player
	--TSJDNHC_PT:SetFocusEntity(ent, 2)
	d.TSJDNHC_GridColl = 1
	ent.GridCollisionClass = 0

	d.TSJDNHC_GridPoints = {}
	for i=0,360-30,30 do   

		local ang = i --90*(i)+45
		local size = Isaac.GetPlayer(pid).Size*2.1
		local pos = Vector(ent.Size*3.2,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.TSJDNHC_GridPoints[i] = {pos, vec}
	end

	d.Isaac_Tower_Data = {
		FrameCount = 0,
		Position = Isaac.GetPlayer(pid).Position,
		Velocity = Vector(0,0),
		TrueVelocity = Vector(0,0),
		Half = Vector(15,19), --Vector(ent.Size, ent.Size),
		DefaultHalf = Vector(15,19),
		CollisionOffset = Vector(0,0),
		CroachDefaultCollisionOffset = Vector(0,9),
		jumpDelay = 0,
		State = 1,
		StateFrame = 0,
		JumpPressed = 0,
		CanJump = true,
		grounding = 5,
		Flayer = {
			Sprite = Sprite(),
			Queue = -1,
			SpeedEffectSprite = Sprite(),
			RightHandSprite = Sprite(),
		},
		PosRecord = {},
	}
	d.Isaac_Tower_Data.Flayer.Sprite:Load("gfx/fakePlayer/flayer.anm2", true)
	d.Isaac_Tower_Data.Flayer.Sprite:Play("idle")
	d.Isaac_Tower_Data.Flayer.Sprite.Offset = Vector(0,12)

	d.Isaac_Tower_Data.Flayer.SpeedEffectSprite:Load("gfx/fakePlayer/speedEffect.anm2", true)
	d.Isaac_Tower_Data.Flayer.SpeedEffectSprite:Play("effect")
	--d.Isaac_Tower_Data.Flayer.SpeedEffectSprite.Offset = Vector(0,12)

	d.Isaac_Tower_Data.Flayer.RightHandSprite:Load("gfx/fakePlayer/flayer.anm2", true)
	for i=1,d.Isaac_Tower_Data.Flayer.RightHandSprite:GetLayerCount() do
		d.Isaac_Tower_Data.Flayer.RightHandSprite:ReplaceSpritesheet(i-1,"gfx/fakePlayer/flayer_rightHand.png")
	end
	d.Isaac_Tower_Data.Flayer.RightHandSprite:LoadGraphics()
	d.Isaac_Tower_Data.Flayer.RightHandSprite:Play("idle")
	d.Isaac_Tower_Data.Flayer.RightHandSprite.Offset = Vector(0,12)

	d.Isaac_Tower_Data.Flayer.Shadow = GenSprite("gfx/fakePlayer/flayer_shadow.anm2","shadow")
	d.Isaac_Tower_Data.Flayer.Shadow.Color = Color(1,1,1,2)

	--d.TSJDNHC_GridColFunc = Isaac_Tower.PlatformerCollHandler
end

--local ZeroPoint = Vector(0,0)
local BDCenter = Vector(320,280)/1.54
local GridListStartPos = Vector(-40,100)/Wtr

local RunSpeedColors = {
	[true] = Color(1,1,1,0.5), --Color(2,0.5,0.5, 0.5),
	[false] = Color(1,1,1,0.5), --Color(0.5,0.65,0.95, 0.5),
}
RunSpeedColors[true]:SetColorize(2,0.5,0.5, 1)
RunSpeedColors[false]:SetColorize(0.5,0.65,0.95, 1)

Isaac_Tower.FlayerExtraInfo = {

}
local nilFunc = function() end

function Isaac_Tower.FlayerRender(_, player, Pos, Offset, Scale)
	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) --BDCenter --+GridListStartPos*(1-Scale)
	end
	local fent = player:GetData().Isaac_Tower_Data
	local spr = player:GetData().Isaac_Tower_Data.Flayer.Sprite
	
	if fent.Shadowposes then
		for i,k in pairs(fent.Shadowposes) do
			local rpos = k[1]/Wtr
			local renpos = Pos + rpos*Scale + ZeroPoint
			if Scale ~= 1 then
				--local scaledOffset = ((Scale-1)*rpos)-zeroOffset ---rpos
				renpos = renpos-zeroOffset --+scaledOffset
				if k[5] then
					local preScale = fent.Flayer.Shadow.Scale/1
					fent.Flayer.Shadow.Scale = fent.Flayer.Shadow.Scale*Scale
					fent.Flayer.Shadow.Rotation = -k[5]
					fent.Flayer.Shadow.Color = Color(1,1,1,k[4])
					fent.Flayer.Shadow:Render(renpos, Vector(k[2],0), Vector(k[3],0))
					fent.Flayer.Shadow.Rotation = 0
					fent.Flayer.Shadow.Scale = preScale
				else
					local preScale = fent.Flayer.Shadow.Scale/1
					fent.Flayer.Shadow.Scale = fent.Flayer.Shadow.Scale*Scale
					fent.Flayer.Shadow.Color = Color(1,1,1,k[4])
					fent.Flayer.Shadow:Render(renpos, Vector(k[2],0), Vector(k[3],0))
					fent.Flayer.Shadow.Scale = preScale
				end
			else
				if k[5] then
					fent.Flayer.Shadow.Rotation = -k[5]
					fent.Flayer.Shadow.Color = Color(1,1,1,k[4])
					fent.Flayer.Shadow:Render(renpos, Vector(k[2],0), Vector(k[3],0))
					fent.Flayer.Shadow.Rotation = 0
				else
					fent.Flayer.Shadow.Color = Color(1,1,1,k[4])
					fent.Flayer.Shadow:Render(renpos, Vector(k[2],0), Vector(k[3],0))
				end
			end
		end
	end

	if fent.InvulnerabilityFrames and player.FrameCount%6 < 3 then
		fent.Flayer.RenderRightHandSprite = nilFunc
		return
	end

	if Isaac_Tower.game:GetFrameCount()%4 <= 2 then
		for i,k in pairs(fent.PosRecord) do
			if Scale ~= 1 then
				local rpos = k[1]/Wtr
				local RenderPos =  Pos + rpos*Scale + ZeroPoint
				--local scaledOffset = ((Scale-1)*rpos)-zeroOffset ---rpos
				RenderPos = RenderPos-zeroOffset --+scaledOffset
				spr.Color = RunSpeedColors[k[2]]
				--spr:Render(RenderPos)
				local preScale = spr.Scale/1
				spr.Scale = spr.Scale*Scale
				spr:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1)))
				spr.Scale = preScale
			else
				local RenderPos =  Pos + k[1]/Wtr + ZeroPoint
				spr.Color = RunSpeedColors[k[2]]
				spr:Render(RenderPos)
			end
		end
	end

	local RenderPos =  (Pos + fent.Position/Wtr*Scale + fent.Velocity/Wtr*Isaac_Tower.GetProcentUpdate() + ZeroPoint) --*Scale
	--local RenderPos =  TSJDNHC_PT:WorldToScreen(fent.Position + fent.Velocity*Isaac_Tower.GetProcentUpdate())  -- + ZeroPoint
	if Scale ~= 1 then
	--	local scaledOffset = ((Scale-1)*(fent.Position/Wtr))-zeroOffset ---(fent.Position/Wtr)
		RenderPos = RenderPos-zeroOffset --+Vector(0,12*(Scale-1))
	end


	--print(RenderPos)
	spr.Color = player:GetColor()

	if fent.ShowSpeedEffect then
		local speedSpr = player:GetData().Isaac_Tower_Data.Flayer.SpeedEffectSprite
		--speedSpr:Update()
		speedSpr.Rotation = fent.ShowSpeedEffect
		if Scale ~= 1 then
			local preScale = spr.Scale/1
			speedSpr.Scale = speedSpr.Scale*Scale
			speedSpr:Render(RenderPos)
			speedSpr.Scale = preScale
		else
			speedSpr:Render(RenderPos)
		end
	end
	
	fent.Flayer.RightHandSprite:SetFrame(spr:GetAnimation(), spr:GetFrame())
	
	if Scale == 1 then
		spr:Render(RenderPos)
		function fent.Flayer.RenderRightHandSprite()
			fent.Flayer.RightHandSprite:Render(RenderPos)
		end
		fent.Flayer.RenderRightHandSprite()
	else
		--local scaledOffset = (Scale*(fent.Position/Wtr)-(fent.Position/Wtr))-zeroOffset

		local preScale = spr.Scale/1
		spr.Scale = spr.Scale*Scale
		spr:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1))) --+scaledOffset+Vector(0,12*(Scale-1)))
		
		function fent.Flayer.RenderRightHandSprite()
			fent.Flayer.RightHandSprite.Scale = fent.Flayer.RightHandSprite.Scale*Scale
			fent.Flayer.RightHandSprite:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1)))
			fent.Flayer.RightHandSprite.Scale = preScale
		end
		fent.Flayer.RenderRightHandSprite()
		spr.Scale = preScale
		
	end
	--spr:Render(TSJDNHC_PT:WorldToScreen(fent.Position) or Vector(0,0))

	if fent.ShowSpeedEffect then
		local speedSpr = player:GetData().Isaac_Tower_Data.Flayer.SpeedEffectSprite
		speedSpr.Color = Color(1,1,1,0.8)
		if Scale ~= 1 then
			local preScale = spr.Scale/1
			speedSpr.Scale = speedSpr.Scale*Scale
			speedSpr:Render(RenderPos)
			speedSpr.Scale = preScale
		else
			speedSpr:Render(RenderPos)
		end
		speedSpr.Color = Color(1,1,1,1)
	end
	Isaac.RunCallback(Isaac_Tower.Callbacks.FLAYER_POST_RENDER, player, RenderPos, Offset, Scale)
end
mod:AddCallback(TSJDNHC_PT.Callbacks.ENTITY_POSTRENDER, Isaac_Tower.FlayerRender, 1)

function Isaac_Tower.GetFlayer(num)
	local player = Isaac.GetPlayer(num)
	return player:GetData().Isaac_Tower_Data
end

function Isaac_Tower.SpecialGridUpdate()
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	if not Isaac_Tower.GridLists.Special then return end
	Isaac_Tower.UpdateSpeedHandler30(function()

		for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
			for index, grid in pairs(tab) do
				if not grid.Parent then
					grid.FrameCount = grid.FrameCount and (grid.FrameCount + 1) or 0
					Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_UPDATE, gtype, grid)
				end
			end
		end

	end)
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, Isaac_Tower.SpecialGridUpdate)

function Isaac_Tower.SpecialGridRender(_, Pos, Offset, Scale)
	if not Isaac_Tower.GridLists.Special then return end
	for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
		for index, grid in pairs(tab) do
			Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_RENDER, gtype, grid, Pos, Offset, Scale)
		end
	end
end
mod:AddPriorityCallback(TSJDNHC_PT.Callbacks.GRID_BACKDROP_RENDER, 100, Isaac_Tower.SpecialGridRender)

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

Isaac_Tower.EnemyHandlers.EnemyState = {
	IDLE = 1,
	STUN = -1,
	GRABBED = -2,
	PUNCHED = -3,
	DEAD = -4,
}

Isaac_Tower.EnemyHandlers.EnemyStateLogic = {
	[Isaac_Tower.EnemyHandlers.EnemyState.STUN] = function(ent)
		local spr = ent:GetSprite()
		local data = ent:GetData().Isaac_Tower_Data
		if spr:GetAnimation() ~= "stun" then
			spr:Play("stun")
		end
		if data.StateFrame > 60 then
			data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			data.StateFrame=0
		end
	end,
	[Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED] = function(ent)
		local data = ent:GetData().Isaac_Tower_Data
		for i, col in pairs(Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent)) do
			local Edata = col:GetData().Isaac_Tower_Data
			Edata.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
			Edata.DeadFlyRot = col.Position.X < ent.Position.X and -1 or 1
			--local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
			--col:ClearEntityFlags(addflag)
		end
		if data.OnGround or data.CollideWall or data.CollideCeiling or data.slopeAngle then
			data.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
			ent:GetData().TSJDNHC_GridColl = 0
			data.DeadFlyRot = data.CollideWall
			if data.StateFrame < 1 then
				ent.Position = data.prePosition or ent.Position
			end
			return
		end
		data.prePosition = ent.Position/1
		data.StateFrame = data.StateFrame + 1
		--for i, col in pairs(Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent)) do
		--	print(col.Position)
		--	local Edata = col:GetData().Isaac_Tower_Data
		--	Edata.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
		--	Edata.DeadFlyRot = col.Position.X < ent.Position.X and -1 or 1
		--end
		local spr = ent:GetSprite()
		local sig = spr.FlipX and -1 or 1
		if ent.FrameCount%2 == 0 then
			spawnSpeedEffect(ent.Position-ent.Velocity+Vector(sig*-15, (ent.FrameCount*4%24)*2-20):Rotated(sig*(ent.Velocity:GetAngleDegrees())),
				ent.Velocity*0.8, (ent.Velocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
	end,
	[Isaac_Tower.EnemyHandlers.EnemyState.DEAD] = function(ent)
		local data = ent:GetData().Isaac_Tower_Data
		if not data.Deaded then
			ent:GetSprite():Play("stun")
			data.Deaded = true
			local rng = RNG()
			rng:SetSeed(ent.DropSeed,35)

			local grid = Isaac.Spawn(1000,EffectVariant.BLOOD_EXPLOSION,0,ent.Position, Vector(0,0) ,nil)
			grid.Color = ent.SplatColor
			for i=1, 8 do
				local vec = Vector.FromAngle(-rng:RandomInt(181) or 0):Resized((rng:RandomInt(105)+11)/10)
				local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,Isaac_Tower.ENT.GibSubType.GIB,ent.Position,vec ,nil)
				grid:GetSprite():Load("gfx/effects/guts.anm2",true)
				grid:GetSprite():Play((rng:RandomInt(12)+1), true)
				grid:ToEffect().Rotation = rng:RandomInt(101)-50
				grid.SpriteRotation = rng:RandomInt(360)+1
				grid.Color = ent.SplatColor
			end
			ent.Variant = IsaacTower_GibVariant
			ent.SubType = Isaac_Tower.ENT.GibSubType.GIB
			local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
			ent:ClearEntityFlags(addflag)
			local ver = data.DeadFlyRot and data.DeadFlyRot*8 or sign0(data.TrueVelocity.X or ent.Velocity.X)*8
			ent.Velocity = Vector(ver, -8)
		end

	end,
}

function Isaac_Tower.EnemyUpdate(_, ent)--IsaacTower_Enemy
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	if not ent:GetData().Isaac_Tower_Data then return end

	ent:GetData().Isaac_Tower_Data.StateFrame = ent:GetData().Isaac_Tower_Data.StateFrame or 0
	if ent.FrameCount > 0 then
		ent.Velocity = ent.Velocity/Isaac_Tower.UpdateSpeed
	end
	Isaac_Tower.UpdateSpeedHandler30(function()
		ent:GetSprite():Update()
		local typ = ent:GetData().Isaac_Tower_Data and ent:GetData().Isaac_Tower_Data.Type
		local data = ent:GetData().Isaac_Tower_Data

		data.slopeAngle = nil

		data.CollideWall = nil
		data.OnGround = false
		data.CollideCeiling = false
		--data.LastPosition = ent.Position/1
		--ent.Velocity = ent.Velocity/Isaac_Tower.UpdateSpeed

		data.Position = ent.Position
		data.Velocity = ent.Velocity

		local collidedGrid = {}

		local indexs = {}

		if ent:GetData().TSJDNHC_GridColl>0 then
			for ia, k in pairs(data.GridPoints) do
				local grid = Isaac_Tower.GridLists.Solid:GetGrid(ent.Position + Vector(0, 10) + ent.Velocity + k[1])

				if grid then
					if Isaac_Tower.ShouldCollide(ent, grid) then
						collidedGrid[grid] = collidedGrid[grid] or {}
					end
				end
				local obs = Isaac_Tower.GridLists.Obs:GetGrid(ent.Position + Vector(0, 10) + ent.Velocity + k[1])
				
				if obs and Isaac_Tower.ShouldCollide(ent, obs) then
					collidedGrid[obs] = collidedGrid[grid] or {}
				end
			end

			for ia, k in pairs(collidedGrid) do

				local hit = EnemyintersectAABB_X(ent, ia)

				if hit and hit.delta.X ~= 0 then
					if not data.slopeRot --hit.Slope
						or ((ent.Position.Y > hit.pos.Y or not data.slopeRot == sign(hit.delta.X))
							and data.slopeRot == sign(hit.delta.X)) then
						
						ent.Position = Vector(ent.Position.X - hit.delta.X + ent.Velocity.X, ent.Position.Y)
					
						if sign(ent.Velocity.X) == sign(hit.delta.X) then
							ent.Velocity = Vector(0, ent.Velocity.Y)
						end
					end
				end
			end

			for ia, k in pairs(collidedGrid) do
				local hitY = EnemyintersectAABB_Y(ent, ia)

				if hitY and hitY.delta.Y ~= 0 then
					if hitY.SmoothUp then
						ent.Position = Vector(ent.Position.X, ent.Position.Y - hitY.delta.Y / math.max(1, (30 / math.abs(ent.Velocity.X)))) --10
					else
						if hitY.delta.Y > 0.0 then
							hitY.delta.Y = math.max(0, hitY.delta.Y - 0.1 - ent.Velocity.Y)
						end
						ent.Position = ent.Position - Vector(0, hitY.delta.Y)
					end
					if hitY.SlopeAngle then
						data.slopeAngle = hitY.SlopeAngle
					end
				end
			end

			local prePosition = ent.Position / 1

			--ent.Position = ent.Position + ent.Velocity -- * Isaac_Tower.UpdateSpeed

			data.TrueVelocity = ent.Position - data.LastPosition
			
			if data.State ~= Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED 
			and data.TrueVelocity.Y >= 0 and data.grounding and data.grounding > 0 then
				local collGrid = {}
				for i = -1, 1 do
					local grid = Isaac_Tower.rayCast((ent.Position - ent.Velocity + Vector(data.Half.X * i, -10)),
						Vector(0, 1), 10, 6)                   -- Vector(fent.Half.X*i,-10)

					if grid and Isaac_Tower.ShouldCollide(ent, grid) then
						collGrid[grid] = collGrid[grid] or true
					end
				end
				local groundMinOffset = -200
				local ignoreGrounding = false
				for ia, k in pairs(collGrid) do
					data.Position = ent.Position
					data.Velocity = ent.Velocity
					local hit = Isaac_Tower.CheckintersectAABB(data, ia)

					if hit.delta.Y > -40 and hit.delta.Y <= 10 and groundMinOffset < hit.delta.Y then
						groundMinOffset = math.min(0, hit.delta.Y) -- 1

						if not ignoreGrounding and not ia.slope then
							ignoreGrounding = true
						elseif ignoreGrounding and ia.slope then
							ignoreGrounding = false
						end
					end
				end
				if not ignoreGrounding and groundMinOffset > -40 and groundMinOffset < 0 then
					ent.Position = Vector(ent.Position.X, ent.Position.Y - groundMinOffset)
					data.OnGround = true
					ent.Velocity = Vector(ent.Velocity.X, math.min(0, ent.Velocity.Y))
				end
			end
			
			if data.OnGround then
				data.grounding = 5
			else
				data.grounding = data.grounding - 1
			end
		end
		data.StateFrame = data.StateFrame + 1

		if data.Flags.EntityCollision == 1 then
			for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
				local fent = Isaac_Tower.GetFlayer(i)
				local dist = fent and fent.Position:Distance(ent.Position)
				if fent and dist < data.FlayerDistanceCheck and data.State ~= Isaac_Tower.EnemyHandlers.EnemyState.GRABBED then
					
					local box1 = {pos = ent.Position, half = data.Half}
					local box2 = {pos = fent.Position, half = fent.Half}
					if Isaac_Tower.NoType_CheckAABB(box1, box2) then
						local result = Isaac.RunCallback(Isaac_Tower.Callbacks.FLAYER_PRE_COLLIDING_ENEMY, fent, ent)
						if result == nil and Isaac_Tower.EnemyHandlers.FlayerCollision[data.Type] then
							result = Isaac_Tower.EnemyHandlers.FlayerCollision[data.Type](fent, ent, data)
						end
						--if result ~= "false"  and fent.OnGround then --and data.State == Isaac_Tower.EnemyHandlers.EnemyState.STUN
						--	if fent.Position.X < ent.Position.X then
						--		ent.Velocity = ent.Velocity*0.8 - (fent.Position-ent.Position):Resized(dist/20)
						--	else
						--		ent.Velocity = ent.Velocity*0.8 + (ent.Position-fent.Position):Resized(dist/20)
						--	end
						--else
							if result == nil then
							Isaac_Tower.FlayerHandlers.EnemyStandeartCollision(fent, ent, dist)
							Isaac_Tower.FlayerHandlers.EnemyGrabCollision(fent, ent)
							Isaac_Tower.FlayerHandlers.EnemyCrashCollision(fent, ent)
						end
					end
				end
			end
		end

		--if data.State == Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED then
		--	if data.OnGround or data.CollideWall or data.CollideCeiling then
		--		data.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
		--	end
		--end
		if Isaac_Tower.EnemyHandlers.EnemyStateLogic[data.State] then
			Isaac_Tower.EnemyHandlers.EnemyStateLogic[data.State](ent)
		end
		

		Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, typ, ent)
		--ent.Velocity = ent.Velocity*Isaac_Tower.UpdateSpeed
		data.LastPosition = ent.Position/1
	end)
	ent.Velocity = ent.Velocity*Isaac_Tower.UpdateSpeed
	
	if not Isaac_Tower.GridLists.Solid:GetGrid(ent.Position) then
		ent:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Isaac_Tower.EnemyUpdate, IsaacTower_Enemy)

function Isaac_Tower.EnemyPostRender(_, ent, Pos, Offset, Scale)
	if ent.Variant ~= IsaacTower_Enemy then return end
	local typ = ent:GetData().Isaac_Tower_Data and ent:GetData().Isaac_Tower_Data.Type
	if typ then
		Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, typ, ent, Pos, Offset, Scale)
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.ENTITY_POSTRENDER, Isaac_Tower.EnemyPostRender, 1000)

---------------------------------------------------------------------------------------------------------------


--0 Обычные детальки
--100 Остаточное изображение
--101 Пот
--110 Звуковой хлопок

local GibsLogic = {
	Update = {
		[0] = function(e)
			e.Velocity = e.Velocity.Y < 15 and Vector(e.Velocity.X,e.Velocity.Y + 0.6) or e.Velocity

			if e.Rotation then
				e.SpriteRotation = e.SpriteRotation + e.Rotation
			end

			if e.Position.Y > Isaac.GetPlayer().Position.Y+1000 then
				e:Remove()
			end

			if e.FrameCount%30==0 then
				if not TSJDNHC_PT.GetGrid(e.Position) then
					e:Remove()
				end
			end
		end,
		[100] = function(e)

		end,
		[101] = function(e)
			if e.State == 0 then
				e.Velocity = e.Velocity.Y < 15 and Vector(e.Velocity.X,e.Velocity.Y + 0.6) or e.Velocity
				local spr = e:GetSprite()
				if not e:GetData().init then
					e:GetData().init = true
					local rng = RNG()
					rng:SetSeed(e.InitSeed,35)
					spr.PlaybackSpeed = (rng:RandomInt(5)+6)/10
					spr.Scale = Vector(0.5,0.5)
					e:GetData().TSJDNHC_GridColl = 1

					e:GetData().Isaac_Tower_Data = {CollisionOffset = Vector(0,0), Half = Vector(0.5,0.5)}
				end

				if e:GetData().Color then
					spr.Color = e:GetData().Color
					e:GetData().Color.A = e:GetData().Color.A - (e:GetData().AlphaLoss or 0.05)
				end

				local grid = Isaac_Tower.GridLists.Solid:GetGrid(e.Position)
				if grid and Isaac_Tower.ShouldCollide(e, grid) then
					e.State = 2
					if spr:GetFrame() > 7 then
						spr:Play("kapsmol")
					else
						spr.Scale = spr.Scale * 5/(15-spr:GetFrame())
						spr:Play("kap")
					end
					e.Velocity = Vector(0,0)
					return
				end
				local grid2 = Isaac_Tower.GridLists.Obs:GetGrid(e.Position)
				if grid and Isaac_Tower.ShouldCollide(e, grid2) then
					e.State = 2
					if spr:GetFrame() > 7 then
						spr:Play("kapsmol")
					else
						spr.Scale = spr.Scale * 5/(15-spr:GetFrame())
						spr:Play("kap")
					end
					e.Velocity = Vector(0,0)
					return
				end

				if e.Position.Y > Isaac.GetPlayer().Position.Y+1000 or spr:IsFinished(spr:GetAnimation()) then
					e:Remove()
				end
			elseif e.State == 2 then
				local spr = e:GetSprite()
				if spr:IsFinished(spr:GetAnimation()) then
					e:Remove()
				end
			end
		end,
		[110] = function (e)
			if e:GetSprite():IsFinished(e:GetSprite():GetAnimation()) then
				e:Remove()
			end
		end
	},
	Render = {
		[100] = function(e)
			if Isaac_Tower.game:IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
			if not TSJDNHC_PT:IsCamRender() and e:GetData().color then
				e:GetData().color.A = e:GetData().color.A-0.05
				e:GetSprite().Color = e:GetData().color
				if e:GetData().color.A <= 0 then
					e:Remove()
				end
			end
		end,
		[101] = function(e)
			e.SpriteRotation = e.Velocity:GetAngleDegrees()
			
		end,
		[Isaac_Tower.ENT.GibSubType.SOUND_BARRIER] = function(e)
			--print(e.SubType, e:GetSprite():GetFrame())
			if Isaac_Tower.game:IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
			if not TSJDNHC_PT:IsCamRender() then
				e:GetSprite():Update()
			end
		end,
	},

}


mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
	--[[if e.SubType == 0 then
		e.Velocity = e.Velocity.Y < 15 and Vector(e.Velocity.X,e.Velocity.Y + 0.6) or e.Velocity

		if e.Rotation then
			e.SpriteRotation = e.SpriteRotation + e.Rotation
		end

		if e.Position.Y > Isaac.GetPlayer().Position.Y+1000 then
			e:Remove()
		end
	elseif e.SubType == 100 then
		--e:GetData().color.A = e:GetData().color.A-0.1
		--e:GetSprite().Color = e:GetData().color
		--if e:GetData().color.A <= 0 then
		--	e:Remove()
		--end
	end]]
	--print(1,e.Velocity)
	if e.FrameCount > 0 then
		e.Velocity = e.Velocity/Isaac_Tower.UpdateSpeed
	end
	Isaac_Tower.UpdateSpeedHandler(function()
		if GibsLogic.Update[e.SubType] then
			GibsLogic.Update[e.SubType](e)
		end
		e.Position = Isaac_Tower.HandleUpdateSpeedPos(e.Position, e.Velocity)
	end)
	e.Velocity = e.Velocity*Isaac_Tower.UpdateSpeed
	--print(2,e.Velocity)
end, IsaacTower_GibVariant)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, e)
	--[[if Game():IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	if not TSJDNHC_PT:IsCamRender() and e:GetData().color then
		e:GetData().color.A = e:GetData().color.A-0.05
		e:GetSprite().Color = e:GetData().color
		if e:GetData().color.A <= 0 then
			e:Remove()
		end
	end]]
	if GibsLogic.Render[e.SubType] then
		GibsLogic.Render[e.SubType](e)
	end
end, IsaacTower_GibVariant)

---------------------------------------------------------------------------------------------------------------

--local function TowerInit(bool)


--mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, TowerInit)

---------------------------------------------------------------------------------------------------------------

Isaac_Tower.sprites.GridCollPoint = Sprite()
Isaac_Tower.sprites.GridCollPoint:Load('gfx/doubleRender/' .. "gridDebug/debug.anm2")
Isaac_Tower.sprites.GridCollPoint.Scale = Vector(2.5,2.5)
Isaac_Tower.sprites.GridCollPoint:Play("point")


--Isaac_Tower.GridLists.Evri

local IsOddRenderFrame = false
Isaac_Tower.Renders = {}
local t = 0
local v26 = Vector(26,26)
local v0 = Vector(0,0)
local v40100 = Vector(-40,100)
function Isaac_Tower.Renders.PreGridRender(_, Pos, Offset, Scale)
	t = Isaac.GetTime()
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end
	IsOddRenderFrame = not IsOddRenderFrame
	if IsOddRenderFrame and Isaac_Tower.GridLists.Evri and Isaac_Tower.GridLists.Evri.List then
		for i,k in pairs(Isaac_Tower.GridLists.Evri.List) do
			k.spr:Update()
		end
	end

	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	end

	local modScale = math.abs(Scale)
	local zer = -Offset - Isaac.WorldToRenderPosition(v40100)
	local modZer = Vector(math.abs(zer.X), math.abs(zer.Y))

	local startPosRender = modZer - v26 + (zeroOffset or v0)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26*modScale)), math.ceil(startPosRender.Y/(26*modScale)))
	local EndPosRender = modZer + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())*(math.max(1,modScale)) -- + (zeroOffset or Vector(0,0)) -- + Vector(26*2,26*2)
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26*modScale)), math.ceil(EndPosRender.Y/(26*modScale)))

	local startPos = -zer

	--GridCollPoint:Render( Isaac.WorldToRenderPosition(Vector(-40,100)) )

	local RenderList = {}
	local list = Isaac_Tower.GridLists.Evri 
	for layer, gridlist in pairs(list) do  --Спрайты с эффектом параллакса не оптимизируются, разница в 1 миллисекунду
		if layer ~= "List" then
			if layer>-2 and layer<2 then
				for y=math.min(EndPosRenderGrid.Y, Isaac_Tower.GridLists.Solid.Y), math.max(1,StartPosRenderGrid.Y),-1 do
					for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.GridLists.Solid.X) do
						local tab = gridlist[y] and gridlist[y][x]
						if tab and tab.Ps then
							RenderList[layer] = RenderList[layer] or {}
							for id in pairs(tab.Ps) do
								RenderList[layer][id] = id
							end
						end
					end
				end
			else
				for y=Isaac_Tower.GridLists.Solid.Y, 1, -1 do
					for x=1, Isaac_Tower.GridLists.Solid.X do
						local tab = gridlist[y] and gridlist[y][x]
						if tab and tab.Ps then
							RenderList[layer] = RenderList[layer] or {}
							for id in pairs(tab.Ps) do
								RenderList[layer][id] = id
							end
						end
					end
				end
			end
		end
	end
	local minindex,maxindex = 0,0
	local tab = {}
	for layer, gridlist in pairs(RenderList) do
		tab[layer] = tab[layer] or {}
		for i,k in pairs(gridlist) do
			tab[layer][#tab[layer]+1] = k
		end
		table.sort(tab[layer])
		minindex = math.min(minindex, layer)
		maxindex = math.max(maxindex, layer)
	end
	--table.sort(tab)
	Isaac_Tower.Renders.EnviRender = tab
	Isaac_Tower.Renders.EnviMaxLayer = maxindex
	Isaac_Tower.Renders.EnviMinLayer = minindex

	if minindex<0 then
		--for layer,gridlist in pairs(tab) do
		for layer=minindex,-1 do
			local gridlist = tab[layer]
			if gridlist then
				for i,k in pairs(gridlist) do
					local obj = Isaac_Tower.GridLists.Evri.List[k]
					if obj then
						local pos = obj.pos*Scale + startPos
						if Scale ~= 1 then
							--local scaledOffset = ((Scale-1)*obj.pos) or Vector(0,0) ---obj.pos
							pos = pos -zeroOffset --+ vec
						end
						if Scale ~= 1 then
							local preScale = obj.spr.Scale/1
							obj.spr.Scale = obj.spr.Scale*Scale
							obj.spr:Render(pos)
							obj.spr.Scale = preScale
						else
							--local off = ((layer+1)/20*Offset) --obj.pos)
							local off = ((layer+1)/20*(Offset+Isaac_Tower.GridLists.Solid.RenderCenterPos))
							obj.spr:Render(pos+off)
						end
						--Isaac.RenderScaledText(tostring(pos), pos.X, pos.Y, 0.5, 0.5, 1,1,1,1)
					end
				end
			end
		end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.FLOOR_BACKDROP_RENDER, Isaac_Tower.Renders.PreGridRender)


function Isaac_Tower.Renders.PostGridRender(_, Pos, Offset, Scale)
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end
	--[[local zer = -Offset - Isaac.WorldToRenderPosition(Vector(-40,100))
	local startPosRender = zer - Vector(26,26)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26)), math.ceil(startPosRender.Y/(26)))
	local EndPosRender = zer + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()) -- + Vector(26*2,26*2)
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26)), math.ceil(EndPosRender.Y/(26)))

	local startPos = -zer

	--GridCollPoint:Render( Isaac.WorldToRenderPosition(Vector(-40,100)) )

	local RenderList = {}
	local list = Isaac_Tower.GridLists.Evri
	for y=math.min(EndPosRenderGrid.Y, Isaac_Tower.GridLists.Solid.Y), math.max(1,StartPosRenderGrid.Y),-1 do
		for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.GridLists.Solid.X) do
			local tab = list[y] and list[y][x]
			if tab and tab.Ps then
				for id in pairs(tab.Ps) do
					RenderList[id] = id
				end
			end
		end
	end
	local tab = {}
	for i,k in pairs(RenderList) do
		tab[#tab+1] = k
	end
	table.sort(tab)]]

	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	end

	local zero = Isaac.WorldToRenderPosition(v40100)
	local startPos = (Offset + zero)
	--for layer,gridlist in pairs(Isaac_Tower.Renders.EnviRender) do
	local gridlist = Isaac_Tower.Renders.EnviRender[0]
	if gridlist then
		--if layer==0 then
			for i,k in pairs(gridlist) do
				local obj = Isaac_Tower.GridLists.Evri.List[k]
				if obj then
					local pos = obj.pos*Scale + startPos
					if Scale ~= 1 then
						--local scaledOffset = (Scale*obj.pos-obj.pos) or Vector(0,0)
						pos = pos -zeroOffset --+ vec + scaledOffset
					end
					if Scale ~= 1 then
						local preScale = obj.spr.Scale/1
						obj.spr.Scale = obj.spr.Scale*Scale
						obj.spr:Render(pos)
						obj.spr.Scale = preScale
					else
						obj.spr:Render(pos)
					end
					--obj.spr:Render(pos)
					--Isaac.RenderScaledText(tostring(pos), pos.X, pos.Y, 0.5, 0.5, 1,1,1,1)
				end
			end
		--end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.GRID_BACKDROP_RENDER, Isaac_Tower.Renders.PostGridRender)

function Isaac_Tower.Renders.PostAllEntityRender(_, Pos, Offset, Scale)
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end
	local zero = Isaac.WorldToRenderPosition(v40100)
	local startPos = (Offset + zero)
	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	end
	--for layer,gridlist in pairs(Isaac_Tower.Renders.EnviRender) do
	if Isaac_Tower.Renders.EnviMaxLayer>0 then
		for layer=1,Isaac_Tower.Renders.EnviMaxLayer do
			local gridlist = Isaac_Tower.Renders.EnviRender[layer]
			if gridlist then
				for i,k in pairs(gridlist) do
					local obj = Isaac_Tower.GridLists.Evri.List[k]
					if obj then
						local pos = obj.pos*Scale + startPos
						if Scale ~= 1 then
							--local scaledOffset = (Scale*obj.pos-obj.pos) or Vector(0,0)
							pos = pos -zeroOffset --+ vec
						end
						if Scale ~= 1 then
							local preScale = obj.spr.Scale/1
							obj.spr.Scale = obj.spr.Scale*Scale
							obj.spr:Render(pos)
							obj.spr.Scale = preScale
						else
							local off = ((layer-1)/20*(Offset+Isaac_Tower.GridLists.Solid.RenderCenterPos))
							obj.spr:Render(pos+off)
						end
						--obj.spr:Render(pos)
						--Isaac.RenderScaledText(tostring(pos), pos.X, pos.Y, 0.5, 0.5, 1,1,1,1)
					end
				end
			end
		end
	end
	--print(Isaac.GetTime()-t)
end
mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, Isaac_Tower.Renders.PostAllEntityRender)

local background = {
	spr = Sprite(),
	size = Vector(100,100),
	visible = true,
}
background.spr:Load("gfx/fakegrid/background.anm2",true)
background.spr:Play(1)

function Isaac_Tower.Renders.SetBGGfx(gfx, size)
	background.spr:ReplaceSpritesheet(0,gfx)
	background.spr:LoadGraphics()
	background.size = size
	background.size.X = background.size.X == 0 and 1 or background.size.X
	background.size.Y = background.size.Y == 0 and 1 or background.size.Y
end
function Isaac_Tower.Renders.SetBGVisible(bol)
	background.visible = bol
end

function Isaac_Tower.Renders.backgroung_render(_, Pos, Offset, Scale)
	local w,h = ScrenX,ScrenY   --Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	
	local x, y = math.ceil(w/background.size.X) + 0, math.ceil(h/background.size.Y) + 0
	local off = Vector(Offset.X%(background.size.X*2), Offset.Y%(background.size.Y*2))/2
	for i=0, x do
		for j=0, y do
			local rpos = Vector(i*background.size.X, j*background.size.Y) + off - background.size --Vector(background.size,background.size)
			background.spr:Render(rpos)
		end
	end
end
--TSJDNHC_PT.Callbacks.PRE_BACKDROP_RENDER
mod:AddCallback(TSJDNHC_PT.Callbacks.PRE_BACKDROP_RENDER, Isaac_Tower.Renders.backgroung_render)




-----------------------------------------------------------------------------------------------------

local Col0Grid = Sprite()
Col0Grid:Load("gfx/doubleRender/gridDebug/debug.anm2")
Col0Grid.Color = Color(0.5,0.5,0.5,0.5)
Col0Grid:Play(0)
--Col1Grid.Offset = Vector()
local Col1Grid = Sprite()
Col1Grid:Load("gfx/doubleRender/gridDebug/debug.anm2")
Col1Grid.Color = Color(0.5,0.5,0.5,0.5)
Col1Grid:Play(1)

local GridCollPoint = Sprite()
GridCollPoint:Load("gfx/doubleRender/gridDebug/debug.anm2")
GridCollPoint.Scale = Vector(0.5,0.5)
GridCollPoint:Play("point")

local GridCollVer = Sprite()
GridCollVer:Load("gfx/doubleRender/gridDebug/debug.anm2")
GridCollVer.Scale = Vector(2.5,2.5)
GridCollVer.Color = Color(0,4,2,1)
GridCollVer:Play("point")

local gridCollayder = Sprite()
gridCollayder:Load("gfx/doubleRender/gridDebug/debug.anm2")
gridCollayder.Color = Color(1,0,5,0.4)
gridCollayder:Play("point")


local PlayerColor = Color(2,0,2,1)

local function debugFridRender(_, Pos, Offset, Scale)
  if TSJDNHC_PT.Isdebug(4) then

	local k = Isaac_Tower.GridLists.Solid
	local playerIndex = k:GetGrid(Isaac.GetPlayer().Position)
	local w,h = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	
	--local startPosRender = -Pos + Vector(23/1,23/1)
	--local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(23/2)), math.ceil(startPosRender.Y/(23/2)))
	--local EndPosRender = -Pos + Vector(23/1,23/1) + Vector(w,h)
	--local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(23/2)), math.ceil(EndPosRender.Y/(23/2)))	

	local start = Isaac.WorldToRenderPosition(k.StartPos)*Scale + Pos*(1-Scale) + Offset
	
	local cent = Pos-Offset
	local startPosRender =  (-Offset-ZeroPoint)*1.54 - k.StartPos  --k:GetRawGrid
	local StartPosRenderGrid = Vector( math.ceil(startPosRender.X/k.Xsize), math.ceil(startPosRender.Y/k.Ysize) )
	local EndPosRender =  (-Offset-ZeroPoint)*1.54 + Vector(w,h)*1.54  - k.StartPos
	local EndPosRenderGrid = Vector( math.ceil(EndPosRender.X/k.Xsize), math.ceil(EndPosRender.Y/k.Ysize) ) --EndPosRender and EndPosRender.XY or Vector(k.X,k.Y)
	

	--for i, colum in pairs(k.Grid) do
	--	local xpos = Vector(0, (i-1) * k.Ysize/1.54)
	--	xpos = xpos * Scale
	--	for j, grid in pairs(colum) do
	for i= math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, k.Y) do   --Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1 do
		local xpos = Vector(0, (i-1) * k.Ysize/1.54)
		xpos = xpos * Scale
		for j=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, k.X) do   --Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1 do
			local grid = k.Grid[i][j]

			local renderPos = start + xpos + Vector((j-1)*k.Xsize/1.54, 0)* Scale

			--if renderPos.X>0 and renderPos.Y>0 and renderPos.X<w and renderPos.Y<h then

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
			--end
		end
	end

	for pl=0,Isaac_Tower.game:GetNumPlayers()-1 do
		local ent = Isaac.GetPlayer(pl)
		local d = ent:GetData()
		if d.DebugGridRen then
			for i,k in pairs(d.DebugGridRen) do
				GridCollVer:Render(Isaac.WorldToRenderPosition(k) + Offset)
			end
		end
		local blockgrid = {}
		if d.LastcollidedGrid then
			for i,k in pairs(d.LastcollidedGrid) do
				if not blockgrid[k.Index] then
					blockgrid[k.Index] = true
					gridCollayder.Scale = k.Half/1.5
					gridCollayder:Render(Isaac.WorldToRenderPosition(k.CenterPos) + Offset)
				end
			end
		end
	end
  end

  if TSJDNHC_PT.Isdebug(3) then
	for pl=0, Isaac_Tower.game:GetNumPlayers()-1 do
		local ent = Isaac.GetPlayer(pl)
		local d = ent:GetData()
		local fent = d.Isaac_Tower_Data
		local fentPos = Isaac.WorldToRenderPosition(fent.Position) + Offset
		for i,k in pairs(d.TSJDNHC_GridPoints) do
			GridCollPoint:Render(fentPos + (Vector(0,12) + k[1])/1.54 ) --+ Offset
		end
		Isaac.RenderText(fent.grounding, fentPos.X, fentPos.Y+30, 1,1,1,0.3)
	end
  end
  --Vector(fent.Half.X*i-i,20)
  if TSJDNHC_PT.Isdebug(5) then
	for i, ent in pairs(Isaac.FindByType(1000, IsaacTower_Enemy,-1)) do
		local d = ent:GetData()
		local fent = d.Isaac_Tower_Data
		local fentPos = Isaac.WorldToRenderPosition(ent.Position) + Offset
		for i,k in pairs(fent.GridPoints) do
			GridCollPoint:Render(fentPos + (Vector(0,12) + k[1])/1.54 ) --+ Offset
		end

		GridCollPoint.Scale = (fent.Half/1.5) --Vector(1,1)*
		GridCollPoint:Render(Isaac.WorldToRenderPosition(ent.Position+fent.CollisionOffset) + Offset)
		GridCollPoint.Scale = Vector(0.5,0.5)
	end
  end

end
mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, debugFridRender) --GRID_BACKDROP_RENDER

local debugShouldRender = {}
function Isaac_Tower.DebugRenderThis(spr, pos, time)
	if spr and pos then
		debugShouldRender[#debugShouldRender+1] = {spr, pos, time}
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, function(_, Pos, Offset, Scale)
	if debugShouldRender then
		for i,k in pairs(debugShouldRender) do
			if k[1] and k[2] then
				k[1]:Render(k[2]+Offset)
			end
			if k[3] and k[3]>0 then
				k[3] = k[3] - 1
			else
				debugShouldRender[i] = nil
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------

local movement = include("flayerMovement")
movement(mod, Isaac_Tower)

local editor = include("room_editor")
editor(mod, Isaac_Tower)

local init = include("IT_init")
init(mod, Isaac_Tower)

local rgon = include("rgon")
if Isaac_Tower.RG then
	rgon(mod, Isaac_Tower)
end

local rooms = {
	"rooms.test",
	"rooms.tutorial",
}

for _, room in pairs(rooms) do
	local module = include(room)
	module(mod, Isaac_Tower)
end


if reloadData then
	if Isaac.GetPlayer() then
		for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
			Isaac.GetPlayer(i):GetData().Isaac_Tower_Data = nil
		end
	end
	TowerInit()
	Isaac_Tower.RoomTransition(reloadData.roomName, true)
	if reloadData.inEditor then
		Isaac_Tower.OpenEditor()
	end
end