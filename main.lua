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
	Mod = mod,
	game = Game(),
	sprites = {},
	Renders = {},
	inDebugVer = true
}
local game = Isaac_Tower.game
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

---@return table
local function SafePlacingTable(tab,...)
	tab = tab or {}
	local itab = tab
	for i,k in pairs({...}) do
		if not itab[k] then
			itab[k] = {}
		end
		itab = itab[k]
	end
	return itab
end

if Renderer then
	Isaac_Tower.RG = true
end

function Isaac_Tower.Random(a, b, rng)
    rng = rng or Isaac_Tower.rng
    if a and b then
        return rng:Next() % (b - a + 1) + a
    elseif a then
        return rng:Next() % (a + 1)
    end
    return rng:Next()
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

Isaac_Tower.font = Font()
Isaac_Tower.font:Load("font/upheaval.fnt")

Isaac_Tower.Callbacks = {}
local function addCallbackID(name)
	Isaac_Tower.Callbacks[name] = setmetatable({},{__concat = function(t,b) return "[Isaac Tower] "..name..b end})
end 

--Isaac_Tower.Callbacks = {
local Isaac_TowerCallbacks = {
	FLAYER_GRID_SCANING = {},
	GRID_SHOULD_COLLIDE = {},
	ROOM_LOADING = {},
	POST_NEW_ROOM = {},
	EDITOR_POST_MENUS_RENDER = {},
	EDITOR_CONVERTING_CURRENT_ROOM_TO_EDITOR = {},
	EDITOR_CONVERTING_EDITOR_ROOM = {},
	EDITOR_CONVERTING_EDITOR_ROOM_STRING = {},
	PRE_EDITOR_CONVERTING_EDITOR_ROOM = {},
	EDITOR_SPECIAL_UPDATE = {},
	EDITOR_SPECIAL_TILE_RENDER = {},
	SPECIAL_INIT = {},
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
	ENEMY_PRE_SAVE = {},
	ENEMY_POST_RESTORE = {},
	PROJECTILE_POST_INIT = {},
	PROJECTILE_POST_UPDATE = {},
	PROJECTILE_POST_RENDER = {},
	PROJECTILE_PRE_REMOVE = {},
	BONUSPICKUP_INIT = {},
	BONUSPICKUP_RENDER = {},
	BONUSPICKUP_COLLISION = {},
}

for i,k in pairs(Isaac_TowerCallbacks) do
	addCallbackID(i)
end

Isaac_Tower.DirectCallback = {}
function Isaac_Tower.AddPriorityDirectCallback(mod, callId, priority, func, param)
	priority = priority or 0
	local calltab = SafePlacingTable(Isaac_Tower.DirectCallback,callId)
	if param then
		local tab = SafePlacingTable(calltab,"Params",param)
		--tab[#tab+1] = func
		local pos = #tab+1
		for i=#tab,1,-1 do
			if tab[i].Pr <= priority then
				break
			else
				pos = pos-1
			end
		end
		table.insert(tab, pos, {Mod = mod, Func = func, Pr = priority})
	else
		--calltab[#calltab+1] = func
		local pos = #calltab+1
		for i=#calltab,1,-1 do
			if calltab[i].Pr <= priority then
				break
			else
				pos = pos-1
			end
		end
		table.insert(calltab, pos, {Mod = mod, Func = func, Pr = priority})
	end
end

function Isaac_Tower.AddDirectCallback(mod, callId, func, param)
	Isaac_Tower.AddPriorityDirectCallback(mod, callId, 0, func, param)
end

function Isaac_Tower.RunDirectCallbacks(callId, param, ...)
	local ctab = Isaac_Tower.DirectCallback[callId]
	local result
	if ctab then
		if param and ctab.Params then
			local tab = ctab.Params[param]
			if tab and #tab>0 then
				for i=1,#tab do
					result = tab[i].Func(tab[i].Mod,...) or result
				end
			end
			if #ctab>0 then
				for i=1,#ctab do
					result = ctab[i].Func(ctab[i].Mod,...) or result
				end
			end
		elseif #ctab>0 then
			for i=1,#ctab do
				result = ctab[i].Func(ctab[i].Mod,...) or result
			end
		end
		--if result then print(result) end
		return result
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, function(_, mod)
	for i,k in pairs(Isaac_Tower.DirectCallback) do
		if k.Params then
			for j,f in pairs(k.Params) do
				for h,tab in pairs(f) do
					if tab.Mod == mod then
						table.remove(f, h)
					end
				end
			end
		end
		for j=#k,1,-1 do
			local f = k[j]
			if f.Mod == mod then
				table.remove(k, j)
			end
		end
	end
end)

-----------------------------------------Стырил из fiend folio
local function runUpdates(tab)
	for i = #tab, 1, -1 do
		local f = tab[i]
		f.Delay = f.Delay - 1
		if f.Delay <= 0 then
			f.Func()
			table.remove(tab, i)
		end
	end
end

Isaac_Tower.delayedFuncs = {}
function Isaac_Tower.scheduleForUpdate(foo, delay, callback, noCancelOnNewRoom)
	callback = callback
	if not Isaac_Tower.delayedFuncs[callback] then
		Isaac_Tower.delayedFuncs[callback] = {}
		Isaac_Tower.AddDirectCallback(mod,callback, function()
			runUpdates(Isaac_Tower.delayedFuncs[callback])
		end)
	end

	table.insert(Isaac_Tower.delayedFuncs[callback], { Func = foo, Delay = delay, NoCancel = noCancelOnNewRoom })
end

function Isaac_Tower.cancelScheduledFunctions()
	for callback, tab in pairs(Isaac_Tower.delayedFuncs) do
		for i = #tab, 1, -1 do
			local f = tab[i]
			if not f.NoCancel then
				table.remove(tab, i)
			end
		end
	end
end
----------------------------------------


function Isaac_Tower.SetScale(num, noLerp) TSJDNHC_PT:SetScale(num, noLerp) end

Isaac_Tower.FlayerHandlers = { BonusPickup = {} }

Isaac_Tower.ENT = {}
Isaac_Tower.ENT.GIB = {ID = EntityType.ENTITY_EFFECT, VAR = IsaacTower_GibVariant}
Isaac_Tower.ENT.GibSubType = {
	GIB = 0,
	AFTERIMAGE = 100,
	SWEET = 101,
	BLOOD = 102,
	SOUND_BARRIER = 110,
	BONUS_EFFECT = 200,
	BONUS_EFFECT2 = 201,
	SECRETROOM_ENTER_EFFECT = 202,
}
Isaac_Tower.ENT.Enemy = {ID = EntityType.ENTITY_EFFECT, VAR = IsaacTower_Enemy}
Isaac_Tower.ENT.Proj = {ID = EntityType.ENTITY_EFFECT, VAR = Isaac.GetEntityVariantByName("PIZTOW Projectile")}
Isaac_Tower.ENT.AboveRender = {[Isaac_Tower.ENT.GibSubType.SOUND_BARRIER] = true,
	[Isaac_Tower.ENT.GibSubType.GIB] = true, [Isaac_Tower.ENT.GibSubType.SWEET] = true}

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
function Isaac_Tower.WorldToScreen(pos)
	return pos/Wtr+ZeroPoint
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

local function GetLinkedGrid(grid, pos, size, fill, sizeY)
	if size and pos then
		local tab = {}
		local Sx,Sy = pos.X,pos.Y
		for i=1, size.Y do
			for j=1, size.X do
				if i ~= 1 or j ~= 1 then
					--local index = tostring(math.ceil(Sx+j-1)) .. "." .. tostring(math.ceil(Sy+i-1))
					local index 
					if sizeY then
						index = (Sy+i-1) * sizeY + (Sx+j-1)
					else
						index = Vector(Sx+i-1, Sy+j-1)
					end
					local Hasgrid = grid[index]
					if Hasgrid or fill then
						tab[#tab+1] = index
					end
				end
			end
		end
		return tab
	end
end

do
	Isaac_Tower.LevelHandler = {RoomData = {}, LevelData = {}}

	function Isaac_Tower.LevelHandler.GetLevelData(name)
		if name or Isaac_Tower.CurrentRoom.level then
			return SafePlacingTable(Isaac_Tower.LevelHandler.LevelData, name or Isaac_Tower.CurrentRoom.level)
		end
	end
	function Isaac_Tower.LevelHandler.ClearLevelData(name)
		if Isaac_Tower.LevelHandler.LevelData[name or Isaac_Tower.CurrentRoom.level] then
			Isaac_Tower.LevelHandler.LevelData[name or Isaac_Tower.CurrentRoom.level] = {}
		end
	end
	function Isaac_Tower.LevelHandler.LevelRoomTracker(name, roomName)
		local data = Isaac_Tower.LevelHandler.GetLevelData(name)
		SafePlacingTable(data, "VisitedRoom")[roomName or Isaac_Tower.CurrentRoom.Name] = {}
		--data[roomName or Isaac_Tower.CurrentRoom.Name] = {}
	end



	function Isaac_Tower.LevelHandler.SpawnRoomEnemies(newRoom)
		if newRoom.Enemy then
			--for i, k in pairs(newRoom.Enemy) do
			for i=1, #newRoom.Enemy do
				local k = newRoom.Enemy[i]
				local data = Isaac_Tower.EnemyHandlers.Enemies[k.name]
				if data then
					Isaac_Tower.Spawn(k.name, k.st, k.pos * 20 + Vector(-60, 80 - data.spawnOffset), Vector(0, 0))
				end
			end
		end
	end

	function Isaac_Tower.LevelHandler.PlaceBonusPickup(data, pos, list)
		local spr = GenSprite(data.gfx, data.anim)
		spr.PlaybackSpeed = 0.5
		local x, y = pos.X, pos.Y
		local grid = SafePlacingTable(list.Grid, y) --[x]
		local posi = pos * 20 + data.Size * 10 + Vector(-60, 80)
		grid[x] = {
			Sprite = spr,
			XY = pos,
			Position = posi,
			RenderPos = (pos * 20 + Vector(-20, -20)) / Wtr, --+ Vector(-60,80)
			Exists = true,
			Type = data.Name,
			CH = {},
			Ref = #list.Ref + 1
		}
		for i, k in pairs(GetLinkedGrid(list.Grid, pos, data.Size, true)) do
			SafePlacingTable(list.Grid, k.Y)[k.X] = { XY = k, Parent = grid[x] }
			grid[x].CH[#grid[x].CH + 1] = k
		end
		list.Ref[#list.Ref + 1] = { pos, grid[x] }
		Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.BONUSPICKUP_INIT, data.Name, grid[x])
	end

	function Isaac_Tower.LevelHandler.RemoveInGridBonusPickup(bonus)
		Isaac_Tower.FlayerHandlers.RemoveInGridBonusPickup(bonus)
	end

	function Isaac_Tower.LevelHandler.TrySetSeedForRoom(roomName)
		if not SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, roomName).seed then
			Isaac_Tower.LevelHandler.RoomData[roomName].seed = Isaac_Tower.seeds:GetNextSeed()  --Isaac_Tower.seed
			Isaac_Tower.LevelHandler.RoomData[roomName].rng = RNG()
			Isaac_Tower.LevelHandler.RoomData[roomName].rng:SetSeed(Isaac_Tower.LevelHandler.RoomData[roomName].seed, 35)
			Isaac_Tower.LevelHandler.RoomData[roomName].deco_rng = RNG()
			Isaac_Tower.LevelHandler.RoomData[roomName].deco_rng:SetSeed(Isaac_Tower.LevelHandler.RoomData[roomName].seed, 35)
		end
	end
	---@return IT_RoomData
	function Isaac_Tower.LevelHandler.GetCurrentRoomData()
		return SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, Isaac_Tower.CurrentRoom.Name)
	end
	---@return IT_RoomData
	function Isaac_Tower.LevelHandler.GetRoomData(roomName)
		return SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, roomName)
	end
	local ignoreList = {Special=true, Evri=true, UnSave=true}
	function Isaac_Tower.LevelHandler.SaveCurrentGridList()
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			local curData = Isaac_Tower.LevelHandler.GetCurrentRoomData()
			curData.GridLists = {}
			--curData.GridLists = Isaac_Tower.GridLists
			for i,k in pairs(Isaac_Tower.GridLists) do
				if not ignoreList[i] then
					curData.GridLists[i] = k
				end
			end
		end
	end
	function Isaac_Tower.LevelHandler.TryRestoreSavedGridList(roomName)
		local curData = Isaac_Tower.LevelHandler.GetRoomData(roomName)
		if curData.GridLists then
			--Isaac_Tower.GridLists = {}
			--Isaac_Tower.GridLists = curData.GridLists
			for i,k in pairs(curData.GridLists) do
				Isaac_Tower.GridLists[i] = k
			end
			TSJDNHC_PT.GridsList[#TSJDNHC_PT.GridsList + 1] = Isaac_Tower.GridLists.Solid
			TSJDNHC_PT.GridsList[#TSJDNHC_PT.GridsList + 1] = Isaac_Tower.GridLists.Obs
		end
	end
	function Isaac_Tower.LevelHandler.SaveCurrentEnemies()
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			local curData = Isaac_Tower.LevelHandler.GetCurrentRoomData()
			curData.EnemiesList = {}
			local enemyList = Isaac_Tower.EnemyHandlers.GetAllRoomEnemies()
			if #enemyList>0 then
				for i=1, #enemyList do
					local ent = enemyList[i]
					local entData = ent:GetData().Isaac_Tower_Data
					if not entData.NoPersist and entData.State > Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED then
						local result = Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ENEMY_PRE_SAVE, entData.Type, ent, curData) 
						if result ~= true then
							curData.EnemiesList[#curData.EnemiesList+1] = {
								type = entData.Type,
								st = ent.SubType,
								pos = ent.Position,
								data = entData
							}
						end
					end
				end
			end
		end
	end
	function Isaac_Tower.LevelHandler.TryRestoreSavedtEnemies(roomName)
		local curData = Isaac_Tower.LevelHandler.GetRoomData(roomName)
		if curData.EnemiesList then
			local zero = Vector(0,0)
			for i=1,#curData.EnemiesList do
				local entData = curData.EnemiesList[i]
				local ent = Isaac_Tower.Spawn(entData.type, entData.st,entData.pos,zero,nil)
				ent:GetData().Isaac_Tower_Data = entData.data
				ent:GetData().Isaac_Tower_Data.Velocity = Vector(0,0)
				Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ENEMY_POST_RESTORE, entData.type, ent, curData)
			end
		end
	end
	function Isaac_Tower.LevelHandler.RoomHasSavedData(roomName)
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			return  Isaac_Tower.LevelHandler.RoomData[roomName] and Isaac_Tower.LevelHandler.RoomData[roomName].GridLists
		else
			return false
		end
	end
	function Isaac_Tower.LevelHandler.ClearRoomData()
		Isaac_Tower.LevelHandler.RoomData = {}
	end

	function Isaac_Tower.LevelHandler.IsFirstVisit()
		local d = Isaac_Tower.LevelHandler.GetCurrentRoomData().VisitCount
		return d and d == 1 or false
	end

	function Isaac_Tower.LevelHandler.IsVisited(name)
		local ret = SafePlacingTable(Isaac_Tower.LevelHandler.GetLevelData(), "VisitedRoom")[name]

		if ret then
			return ret
		else
			local count = Isaac_Tower.LevelHandler.GetRoomData(name).VisitCount
			local raz = Isaac_Tower.CurrentRoom.Name == name and 1 or 0
			if count and count > raz then
				return true
			--else
			--	return Isaac_Tower.LevelHandler.GetRoomData(name).VisitCount
			end
		end
	end

	function Isaac_Tower.LevelHandler.CurrentGetRoomType()
		local d = Isaac_Tower.CurrentRoom.roomtype
		return d or "basic"
	end
	function Isaac_Tower.LevelHandler.GetSpawnPosition()
		return Isaac_Tower.SpawnPoint/1
	end

	function Isaac_Tower.LevelHandler.AddEnterSpawn(name, pos)
		Isaac_Tower.GridLists.UnSave.EntersSpawn[name] = {
			Name = name,
			pos = pos
		}
	end
end


local RemoveimmutyEnt = {[Isaac.GetEntityVariantByName('PIZTOW CamEnt')]=true}
--Isaac_Tower.TransitionSpawnOffset
function Isaac_Tower.SetRoom(roomName, preRoomName, TargetSpawnPoint)
	--if not Isaac_Tower.InAction then error("Func called outside the Isaac Tower mod",2) end
	if Isaac_Tower.Rooms[roomName] then
		local oldRoomName = preRoomName or Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name
		local newRoom = Isaac_Tower.Rooms[roomName]

		Isaac_Tower.CurrentRoom = newRoom --{Name = roomName}
		local roomdata = Isaac_Tower.LevelHandler.GetRoomData(roomName)
		roomdata.VisitCount = roomdata.VisitCount and (roomdata.VisitCount+1) or 1
		roomdata.FrameCount = 0
		Isaac_Tower.LevelHandler.LevelRoomTracker(newRoom.level, roomName)
		local leveldata = Isaac_Tower.LevelHandler.GetLevelData(newRoom.level)
		if leveldata then
			leveldata.PreviousRoom = oldRoomName
			leveldata.CurrentRoom = roomName
		end
		TSJDNHC_PT.DeleteAllGridList()
		Isaac_Tower.LevelHandler.TrySetSeedForRoom(roomName)
		
		Isaac_Tower.GridLists = {
			Solid = false,
			Obs = false,
			Special = {},
			Evri = {},
			Bonus = {},
			--Fake = {},
			UnSave = {},
			ObjByName = {},
		}

		local toRemove = Isaac.FindByType(1000, -1, -1)
		for i=1, #toRemove do
			local ent = toRemove[i]
			if not RemoveimmutyEnt[ent.Variant] and not ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT) then
				Isaac_Tower.EnemyHandlers.RemoveEnemyFromArray(ent)
				ent:Remove()
			end
		end
		Isaac_Tower.EnemyHandlers.EnemyArray = {}
		Isaac_Tower.EnemyHandlers.ActiveEnemyArray = {}

		if Isaac_Tower.LevelHandler.RoomHasSavedData(roomName) then
			Isaac_Tower.LevelHandler.TryRestoreSavedGridList(roomName)
			Isaac_Tower.LevelHandler.TryRestoreSavedtEnemies(roomName)

		else
			Isaac_Tower.GridLists.Solid = TSJDNHC_PT:MakeGridList(Vector(-40, 100), newRoom.Size.Y, newRoom.Size.X, 40,
				40)
			Isaac_Tower.GridLists.Obs = TSJDNHC_PT:MakeGridList(Vector(-40, 100), newRoom.Size.Y * 2, newRoom.Size.X * 2,
				20, 20)
			if newRoom.SolidList.anm2 then
				--Isaac_Tower.GridLists.Solid:SetGridAnim(newRoom.SolidList.anm2, 9)
			else
				Isaac_Tower.GridLists.Solid:SetGridAnim("gfx/fakegrid/grid2.anm2", 9)
			end
			--Isaac_Tower.GridLists.Solid:SetTileStyle(1, "map_", Vector(3,3),{"1","2","3","4","5","6","7","8","9"})
			Isaac_Tower.GridLists.Solid:SetGridFromList(newRoom.SolidList)
			Isaac_Tower.GridLists.Obs:SetGridFromList(newRoom.ObsList or {})
			Isaac_Tower.GridLists.Solid:SetRenderMethod(1)
			Isaac_Tower.GridLists.Obs:SetManualRender(true)
			local fakelist = {}
			
			--[[if newRoom.Enemy then
				for i, k in pairs(newRoom.Enemy) do
					local data = Isaac_Tower.EnemyHandlers.Enemies[k.name]
					if data then
						Isaac_Tower.Spawn(k.name, k.st, k.pos * 20 + Vector(-60, 80 - data.spawnOffset), Vector(0, 0))
					end
				end
			end]]
			Isaac_Tower.LevelHandler.SpawnRoomEnemies(newRoom)
			if newRoom.Bonus then
				Isaac_Tower.GridLists.Bonus.Grid = {}
				Isaac_Tower.GridLists.Bonus.Ref = {}
				for i, k in pairs(newRoom.Bonus) do
					local data = Isaac_Tower.FlayerHandlers.BonusPickup[k.name]
					if data then
						Isaac_Tower.LevelHandler.PlaceBonusPickup(data, k.pos, Isaac_Tower.GridLists.Bonus)
					end
				end
			end

			Isaac_Tower.RoomPostCompilator(newRoom)
		end

		local fakelist = {}
		if newRoom.SolidFakeList then
			local Fake = TSJDNHC_PT:MakeGridList(Vector(-40, 100), newRoom.Size.Y, newRoom.Size.X, 40, 40) --TODO: прямое преобразование
			Fake:SetGridAnim("gfx/fakegrid/grid2.anm2", 9)
			Fake:SetGridFromList(newRoom.SolidFakeList)
			Isaac_Tower.GridLists.Fake = {}
			Isaac_Tower.GridLists.Fake.Sorted = {}
			--Isaac_Tower.GridLists.FakeList = {}
			local solid = Isaac_Tower.GridLists.Solid
			local gfx = solid.SpriteSheep
			local anim = solid.Anm2File
			local function makeSprite(gridlist, Gtype, pos)
				local spr = Sprite()
				spr:Load(anim, false)
				if gfx then
					for layer = 0, spr:GetLayerCount() - 1 do
						spr:ReplaceSpritesheet(layer, gfx)
					end
				end
				spr:LoadGraphics()
				spr:Play(tostring(Gtype))
				if solid.MapStyle and (solid.MapStyle.affl[Gtype] or solid.MapStyle.affl[tostring(Gtype)]) then
					local id = (pos.X%solid.MapStyle.size.X)+((pos.Y-1)%solid.MapStyle.size.Y)*solid.MapStyle.size.Y
					--local mapSpr = solid.MapStyle.sprs[id]
					spr:Play(solid.MapStyle.animName .. math.ceil(id), true)
					--spr:SetFrame(id)
					spr:PlayOverlay(tostring(Gtype))
				end
				return spr
			end

			local list = Fake

			for i = list.Y, 1, -1 do
				for j = list.X, 1, -1 do
					local grid = list.Grid[i][j]
					local setGrids
					if grid.SpriteAnim then
						local nextindex = #fakelist + 1
						fakelist[nextindex] = {
							pos = grid.RenderPos,
							spr = makeSprite(nil, grid.SpriteAnim, Vector(j,i)),
							chl = grid.chl,
						}
						setGrids = true
						Isaac_Tower.GridLists.Fake.Sorted[grid.gr] = Isaac_Tower.GridLists.Fake.Sorted[grid.gr] or {}
						Isaac_Tower.GridLists.Fake.Sorted[grid.gr][#Isaac_Tower.GridLists.Fake.Sorted[grid.gr] + 1] =
							fakelist[nextindex].spr
					end
					if grid.Sprite then
						fakelist[#fakelist + 1] = {
							pos = grid.RenderPos,
							spr = grid.Sprite,
							chl = grid.chl,
						}
						setGrids = true
						Isaac_Tower.GridLists.Fake.Sorted[grid.gr] = Isaac_Tower.GridLists.Fake.Sorted[grid.gr] or {}
						Isaac_Tower.GridLists.Fake.Sorted[grid.gr][#Isaac_Tower.GridLists.Fake.Sorted[grid.gr] + 1] =
							fakelist[#fakelist].spr
					end
					if setGrids then
						Isaac_Tower.GridLists.Fake[i] = Isaac_Tower.GridLists.Fake[i] or {}
						Isaac_Tower.GridLists.Fake[i][j] = grid.gr
						if grid.Childs then
							for id = 1, #grid.Childs do
								local chl = grid.Childs[id]
								Isaac_Tower.GridLists.Fake[chl.XY.Y] = Isaac_Tower.GridLists.Fake[chl.XY.Y] or {}
								Isaac_Tower.GridLists.Fake[chl.XY.Y][chl.XY.X] = grid.gr
							end
						end
					end
				end
			end
			Fake:Delete()
		end
		
		if newRoom.EnviList then
			local maxindex, minindex = 0,0
			local list = Isaac_Tower.GridLists.Evri
			list.List = {}
			local CustomType = {}
			if newRoom.EnviList.CT and newRoom.EnviList.CF then
				for i, k in pairs(newRoom.EnviList.CT) do
					local size, pivot = Vector(k[3][1], k[3][2]), Vector(k[4][1], k[4][2])
					local anm2, anim = newRoom.EnviList.CF[k[1] ], k[2]
					local GType = anm2 .. anim
					CustomType[i] = GType

					local ingridSpr = GenSprite(anm2, anim)
					ingridSpr.Scale = Vector(.5, .5)
					Isaac_Tower.editor.AddEnvironment(GType,
						GenSprite(anm2, anim),
						function() return GenSprite(anm2, anim) end,
						ingridSpr,
						size,
						pivot)
				end
				newRoom.EnviList.CT = nil
				newRoom.EnviList.CF = nil
			end
			for i, k in pairs(newRoom.EnviList) do
				if Isaac_Tower.editor.GridTypes["Environment"][k.name or CustomType[k.ct] ] then
					if k.ct and CustomType[k.ct] then
						k.name = CustomType[k.ct]
					end

					local spr = Isaac_Tower.editor.GridTypes["Environment"][k.name or CustomType[k.ct] ].info()
					list.List[i] = { pos = k.pos, spr = spr, l = k.l or 0 }
					local layer = k.l or 0

					maxindex = math.max(maxindex, layer)
					minindex = math.min(minindex, layer)
					list[layer] = list[layer] or {}
					local gridlist = list[layer]
					for _, index in pairs(k.chl) do
						gridlist[index[1] ] = gridlist[index[1] ] or {}
						gridlist[index[1] ][index[2] ] = gridlist[index[1] ][index[2] ] or {}
						gridlist[index[1] ][index[2] ].Ps = gridlist[index[1] ][index[2] ].Ps or {}
						gridlist[index[1] ][index[2] ].Ps[i] = true
					end
				end
			end
			for i, k in pairs(fakelist) do
				local id = #list.List + 1
				list.List[id] = { pos = k.pos, spr = k.spr, l = 0 }
				local layer = "fake"

				list[layer] = list[layer] or {}
				local gridlist = list[layer]
				for _, index in pairs(k.chl) do
					gridlist[index[1] ] = gridlist[index[1] ] or {}
					gridlist[index[1] ][index[2] ] = gridlist[index[1] ][index[2] ] or {}
					gridlist[index[1] ][index[2] ].Ps = gridlist[index[1] ][index[2] ].Ps or {}
					gridlist[index[1] ][index[2] ].Ps[id] = true
				end
			end
			--[[if minindex then
				for i=minindex, maxindex do
					local gridlist = list[i]
					if gridlist then
						for y, yp in pairs(gridlist) do
							for x, xp in pairs(yp) do
								local new = {}
								print("ha")
								for id in pairs(xp.Ps) do
									print(x,y, id)
									new[#new+1] = id
								end
								xp.Ps = new
							end
						end
					end
				end
			end]]
		end

		local toInit = {}
		Isaac_Tower.GridLists.UnSave.EntersSpawn = {}
		Isaac_Tower.GridLists.UnSave.SpawnPoints = {}
		if newRoom.Special then   --Спешлы генерируются в вызове ROOM_LOADING, в файле IT_init
			for gType, tab in pairs(newRoom.Special) do
				if gType == "Room_Transition" or gType == "spawnpoint" then
					Isaac_Tower.GridLists.Special[gType] = {}
					for i, grid in ipairs(tab) do
						--local index = math.ceil(grid.XY.X) .. "." .. math.ceil(grid.XY.Y)
						local index = (grid.XY.Y) * newRoom.Size.X + (grid.XY.X)
						Isaac_Tower.GridLists.Special[gType][index] = TabDeepCopy(grid)
						Isaac_Tower.GridLists.Special[gType][index].pos = grid.XY * 40 + Vector(-60, 80)
						Isaac_Tower.GridLists.Special[gType][index].FrameCount = 0
						Isaac_Tower.GridLists.Special[gType][index].Type = gType
						if Isaac_Tower.GridLists.Special[gType][index].Size then
							for i, k in pairs(GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].Size, true, newRoom.Size.X)) do
								Isaac_Tower.GridLists.Special[gType][k] = { Parent = index }
							end
						end
						toInit[#toInit+1] = {gType,Isaac_Tower.GridLists.Special[gType][index]}

						if gType == "Room_Transition" then
							Isaac_Tower.GridLists.UnSave.EntersSpawn[#Isaac_Tower.GridLists.UnSave.EntersSpawn + 1] = {
								Name = grid.Name,
								pos = Isaac_Tower.GridLists.Special[gType][index].pos,
								HasOffset = true
							}
						elseif gType == "spawnpoint" then
							Isaac_Tower.GridLists.UnSave.SpawnPoints[grid.Name] = {
								Name = grid.Name,
								pos = Isaac_Tower.GridLists.Special[gType][index].pos
							}
							--Isaac_Tower.GridLists.UnSave.EntersSpawn[grid.Name] = {
							--	Name = grid.Name,
							--	pos = Isaac_Tower.GridLists.Special[gType][index].pos
							--}
						end
						if Isaac_Tower.GridLists.Special[gType][index].Name then
							Isaac_Tower.GridLists.ObjByName[Isaac_Tower.GridLists.Special[gType][index].Name] = Isaac_Tower.GridLists.Special[gType][index]
						end
					end
				end
			end
		end
		for i=1,#toInit do
			local k = toInit[i]
			Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_INIT, k[1], k[1], k[2])
		end

		Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ROOM_LOADING, nil, Isaac_Tower.GridLists, newRoom, roomName, oldRoomName)

		Isaac_Tower.SpawnPoint = newRoom.DefSpawnPoint
		local useOffset = false
		local targetName

		for i, k in pairs(Isaac_Tower.GridLists.UnSave.EntersSpawn) do
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

		if newRoom.bg then
			--local bgData = {{}}
			--Isaac_Tower.Renders.SetBGGfx(newRoom.bg.bg[1], newRoom.bg.bg[2])
			Isaac_Tower.Backgroung.SetBG(newRoom.bg)
		else
			--Isaac_Tower.Renders.SetBGGfx("gfx/backgrounds/basement_bg.png", Vector(100,100))
			Isaac_Tower.Backgroung.SetBG("tutorial")
		end
		


		--Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ROOM_LOADING, nil, Isaac_Tower.GridLists, newRoom, roomName, oldRoomName)

		--Isaac_Tower.CurrentRoom = newRoom

		--Isaac_Tower.RoomPostCompilator()

		local offset = useOffset and Isaac_Tower.TransitionSpawnOffset or Vector(0, 0)
		Isaac_Tower.autoRoomClamp(Isaac_Tower.GridLists.Solid)
		for i = 0, Isaac_Tower.game:GetNumPlayers() - 1 do
			Isaac_Tower.SetPlayerPos(Isaac.GetPlayer(i), Isaac_Tower.SpawnPoint + offset)
		end
		TSJDNHC_PT:SetFocusPosition(Isaac.GetPlayer():GetData().Isaac_Tower_Data.Position, 1)
		Isaac_Tower.SmoothPlayerPos = Isaac.GetPlayer():GetData().Isaac_Tower_Data.Position
		Isaac_Tower.TransitionSpawnOffset = nil

		if targetName and Isaac_Tower.GridLists.UnSave.SpawnPoints[targetName] then
			Isaac_Tower.SpawnPoint = Isaac_Tower.GridLists.UnSave.SpawnPoints[targetName].pos - Vector(7, 7)
		end

		Isaac_Tower.cancelScheduledFunctions()
		Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.POST_NEW_ROOM, nil, Isaac_Tower.GridLists, newRoom, roomName, oldRoomName)
	end
end

function Isaac_Tower.RoomTransition(roomName, force, preRoomName, TargetSpawnPoint)
	--if not Isaac_Tower.InAction then error("Func called outside the Isaac Tower mod",2) end
    if Isaac_Tower.Rooms[roomName] then
	if force then
		Isaac_Tower.LevelHandler.SaveCurrentGridList()
		Isaac_Tower.LevelHandler.SaveCurrentEnemies()
		Isaac_Tower.SetRoom(roomName, preRoomName, TargetSpawnPoint)
		Isaac_Tower.Pause = false
	else
		Isaac_Tower.Pause = true
		Isaac_Tower.FadeInWithReaction(10, 5, function()
			Isaac_Tower.LevelHandler.SaveCurrentGridList()
			Isaac_Tower.LevelHandler.SaveCurrentEnemies()
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
		Isaac_Tower.seeds = Isaac_Tower.game:GetSeeds()
		Isaac_Tower.rng = RNG()
		Isaac_Tower.rng:SetSeed(Isaac_Tower.seeds:GetStartSeed(), 35)

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
	elseif player:GetPlayerType() == IsaacTower_Type and Isaac_Tower.game:GetFrameCount()<2 then
		player.GridCollisionClass = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Init_Player,0)

------------------------------к

function Isaac_Tower.RoomPostCompilator(roomdata)
	local t = Isaac.GetTime()
	local ignorelist = {}
	local tiledata = Isaac_Tower.TileData.GetTileSetData(roomdata.SolidList.TileSet)
	local chains --= {} --tiledata.Replaces
	if tiledata and tiledata.Replaces then
		chains = {}
		for i,k in pairs(tiledata.Replaces) do
			chains[i] = 3+#k
		end
	end
	---@type RNG
	local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng

	local gridlist = Isaac_Tower.GridLists.Solid:GetGridsAsTable()
	--for i, grid in pairs(Isaac_Tower.GridLists.Solid:GetGridsAsTable()) do
	for i=1,#gridlist do
		local grid = gridlist[i]
		if chains and grid.SpriteAnim and tiledata.Replaces[grid.SpriteAnim] then
			local new = rng:RandomInt(chains[grid.SpriteAnim])-2
			if new>0 then
				grid.SpriteAnim = tiledata.Replaces[grid.SpriteAnim][new]
			end
		end
		if not ignorelist[i] then
			if grid.slope then
				local num = 1
				::retu::
				if grid.Type == "45l" then
					local upgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num - 2] and
					Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num - 2][grid.XY.X - num + 1]
					if num > 1 and upgrid then
						if upgrid.Collision == 0 and not upgrid.Type then
							Isaac_Tower.GridLists.Solid:LinkGrids(grid, upgrid, true)
						end
					end
					local nextgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num] and
					Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num][grid.XY.X - num]
					if nextgrid then
						if nextgrid.Type and nextgrid.Type == grid.Type then
							ignorelist[nextgrid.Index] = true
							Isaac_Tower.GridLists.Solid:LinkGrids(grid, nextgrid, true)
							grid.slope = Vector(grid.Half.Y * 2, 0)
							num = num + 1
							goto retu
						end
					end
				elseif grid.Type == "45r" then
					local upgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num - 2] and
					Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num - 2][grid.XY.X + num - 1]
					if num > 1 and upgrid then
						if upgrid.Collision == 0 and not upgrid.Type then
							Isaac_Tower.GridLists.Solid:LinkGrids(grid, upgrid, true)
						end
					end
					local nextgrid = Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num] and
					Isaac_Tower.GridLists.Solid.Grid[grid.XY.Y + num][grid.XY.X + num]
					if nextgrid then
						if nextgrid.Type and nextgrid.Type == grid.Type then
							ignorelist[nextgrid.Index] = true
							Isaac_Tower.GridLists.Solid:LinkGrids(grid, nextgrid, true)
							grid.slope = Vector(0, grid.Half.Y * 2)
							num = num + 1
							goto retu
						end
					end
				end
			end
		end
	end
	print(Isaac.GetTime() - t)
end

local updateframe = 0
local updateframe30 = 0
local UpdatesInThatFrame = 0
local UpdatesInThatFrame30 = 0

local ScrenX,ScrenY = 0, 0
local ScrenXX,ScrenYY = 0, 0
--local ta,rta = 0,0
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not Isaac_Tower.InAction or (Isaac_Tower.Pause or Isaac_Tower.game:IsPaused()) then return end
	ScrenXX,ScrenYY = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	if Isaac_Tower.GridLists.Solid and ScrenX ~= Isaac.GetScreenWidth() and ScrenY ~= Isaac.GetScreenHeight() then
		ScrenX,ScrenY = ScrenXX,ScrenYY --Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
		Isaac_Tower.autoRoomClamp(Isaac_Tower.GridLists.Solid)
	end

	--[[if not updateframe30 then
		if Isaac.GetFrameCount()%2 == 0 then
			updateframe30 = 0.0
		else
			updateframe30 = 0.5
		end
	end]]

	updateframe = updateframe + Isaac_Tower.UpdateSpeed
	UpdatesInThatFrame = 0
	if updateframe >= 1 then
		for i=1, math.floor(updateframe) do
			updateframe = updateframe - 1
			UpdatesInThatFrame = UpdatesInThatFrame + 1
		end
	end
	updateframe30 = updateframe30 + Isaac_Tower.UpdateSpeed/2
	UpdatesInThatFrame30 = 0
	if updateframe30 >= 1 then
		for i=1, math.floor(updateframe30) do
			updateframe30 = updateframe30 - 1
			UpdatesInThatFrame30 = UpdatesInThatFrame30 + 1
		end
	end
	Isaac_Tower.GameRenderUpdate()

	--Isaac_Tower.font:DrawStringUTF8(rta,130,40,KColor(1,1,1,1),1,true)
	--Isaac_Tower.font:DrawStringUTF8("update",50,40,KColor(1,1,1,1),1,true)
end)

function Isaac_Tower.GetScreenCenter()
	return Vector(ScrenXX/2, ScrenYY/2)
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	UpdateZeroPoint()

	--[[updateframe30 = updateframe30 + Isaac_Tower.UpdateSpeed
	UpdatesInThatFrame30 = 0
	if updateframe30 >= 1 then
		for i=1, math.floor(updateframe30) do
			updateframe30 = updateframe30 - 1
			UpdatesInThatFrame30 = UpdatesInThatFrame30 + 1
		end
	end]]
	--rta = Isaac.GetFrameCount()-ta
	--ta = Isaac.GetFrameCount()
	Isaac_Tower.GameUpdate()
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
function Isaac_Tower.GetProcentUpdate30()
	return updateframe30%1
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

Isaac_Tower.EnemyHandlers = {}
Isaac_Tower.EnemyHandlers.FlayerCollision = {}

Isaac_Tower.EnemyHandlers.Enemies = {}
Isaac_Tower.EnemyHandlers.Projectiles = {}

Isaac_Tower.EnemyHandlers.EnemyArray = {}
Isaac_Tower.EnemyHandlers.ActiveEnemyArray = {}

---@param name string
---@param gfx string
---@param size Vector
---@param flags table
--Flags: EntityCollision, GridCollision, CollisionOffset, NoGrabbing, Invincibility, NoStun
function Isaac_Tower.RegisterEnemy(name, gfx, size, flags)
	if name then
		if size and type(size) ~= "userdata" then error("[3] is not a vector") end
		if flags and type(flags) ~= "table" then error("[4] is not a table",2) end
		Isaac_Tower.EnemyHandlers.Enemies[name] = {Name = name, gfx = gfx, Size = size, Flags = flags or {}, spawnOffset = size.Y-20}
	end
end
---@param name string
---@param gfx string
---@param size integer
---@param flags table
--Flags: EntityCollision, CollisionOffset, Gravity, GridCollision, NoStun, ColType
function Isaac_Tower.RegisterProj(name, gfx, size, flags)
	if name then
		if size and type(size) ~= "number" then error("[3] is not a integer") end
		if flags and type(flags) ~= "table" then error("[4] is not a table",2) end
		Isaac_Tower.EnemyHandlers.Projectiles[name] = {Name = name, gfx = gfx, Size = size, Flags = flags or {}}
	end
end

function Isaac_Tower.Spawn(name, subtype, pos, vec, spawner)
	local data = Isaac_Tower.EnemyHandlers.Enemies[name]
	local ent = Isaac.Spawn(EntityType.ENTITY_EFFECT, IsaacTower_Enemy, subtype or 0, pos, vec, spawner)
	ent:GetSprite():Load(data.gfx, true)
	ent:GetSprite():Play(ent:GetSprite():GetDefaultAnimation())
	ent:GetData().Isaac_Tower_Data = {Type = name, GridPoints = {}, --Position = ent.Position, Velocity = ent.Velocity,
		LastPosition = pos, Half = data.Size, grounding = 0}
	ent:GetData().Isaac_Tower_Data.Position = pos
	ent:GetData().Isaac_Tower_Data.Velocity = vec
	local d = ent:GetData().Isaac_Tower_Data
	d.Self = ent

	local size = d.Half.X > d.Half.Y and d.Half.X*1.2 or d.Half.Y*1.2   --d.Half:Length()*2
	for i=0,360-45,45 do
		local ang = i --90*(i)+45
		local pos = Vector(d.Half:Length()*3.5,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.GridPoints[#d.GridPoints+1] = {pos, vec}
	end
	d.GridPoints[#d.GridPoints+1] = {Vector(0,0), Vector(-1,0)}

	ent:GetData().TSJDNHC_GridColl = data.Flags.GridCollision or 1
	ent.EntityCollisionClass = data.Flags.EntityCollision or 1
	d.CollisionOffset = data.Flags.CollisionOffset or Vector(0,0)
	d.FlayerDistanceCheck = d.Half:Length()*2
	d.State = 1

	if data.Flags then
		if type(data.Flags) == "table" then
			d.Flags = TabDeepCopy(data.Flags)
		end
	end

	local spawnXY = pos - Isaac_Tower.GridLists.Solid.StartPos
	local xs,ys = math.ceil(spawnXY.X/40), math.ceil(spawnXY.Y/40)
	d.SpawnXY = Vector(xs,ys)

	local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE --| EntityFlag.FLAG_INTERPOLATION_UPDATE | EntityFlag.FLAG_NO_INTERPOLATE
	ent:AddEntityFlags(addflag)

	--setmetatable(d, enemyMetatable)

	--d.RNG = RNG()
	--d.RNG:SetSeed(ent.GetDropRNG)
	--Isaac_Tower.EnemyHandlers.EnemyArray[#Isaac_Tower.EnemyHandlers.EnemyArray+1] = ent
	--Isaac_Tower.EnemyHandlers.EnemyArray[#Isaac_Tower.EnemyHandlers.EnemyArray+1] = ent
	Isaac_Tower.EnemyHandlers.AddEnemyToArray(ent)

	Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_INIT, name, ent)
	return ent
end

function Isaac_Tower.EnemyHandlers.FireProjectile(name, subtype, pos, vec, spawner)
	local data = Isaac_Tower.EnemyHandlers.Projectiles[name]
	local ent = Isaac.Spawn(EntityType.ENTITY_EFFECT, Isaac_Tower.ENT.Proj.VAR, subtype or 0, pos, vec, spawner)
	ent:GetSprite():Load(data.gfx, true)
	ent:GetSprite():Play(ent:GetSprite():GetDefaultAnimation())
	local da = ent:GetData()
	ent:GetData().Isaac_Tower_Data = {Type = name, GridPoints = {}, --Position = ent.Position, Velocity = ent.Velocity,
		LastPosition = pos, Half = Vector(data.Size/2,data.Size/2)}
	ent:GetData().Isaac_Tower_Data.Position = pos
	ent:GetData().Isaac_Tower_Data.Velocity = vec
	local d = da.Isaac_Tower_Data
	d.Self = ent

	local Half = da.Isaac_Tower_Data.Half
	local size = Half.X > Half.Y and Half.X*1.2 or Half.Y*1.2   --d.Half:Length()*2
	for i=0,360-45-90,90 do
		local ang = i --90*(i)+45
		local pos = Vector(d.Half:Length()*3.5,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.GridPoints[i] = {pos, vec}
	end
	--d.GridPoints[" "] = {Vector(0,0), Vector(-1,0)}

	da.TSJDNHC_GridColl = data.Flags.GridCollision or 0
	ent.EntityCollisionClass = data.Flags.EntityCollision or 1
	d.CollisionOffset = data.Flags.CollisionOffset or Vector(0,0)
	d.FlayerDistanceCheck = data.Size+20
	d.State = 1
	--da.RA = true

	if data.Flags then
		if type(data.Flags) == "table" then
			d.Flags = TabDeepCopy(data.Flags)
		end
	end

	local spawnXY = pos - Isaac_Tower.GridLists.Solid.StartPos
	local xs,ys = math.ceil(spawnXY.X/40), math.ceil(spawnXY.Y/40)
	d.SpawnXY = Vector(xs,ys)
	local infake = Isaac_Tower.GridLists.Fake[d.SpawnXY.Y] and Isaac_Tower.GridLists.Fake[d.SpawnXY.Y][d.SpawnXY.X]
	if not infake then
		da.RA = true
	end

	local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
	ent:AddEntityFlags(addflag)

	Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.PROJECTILE_POST_INIT, name, ent)
	return ent
end

--Isaac_Tower.EnemyHandlers = {}
--Isaac_Tower.EnemyHandlers.FlayerCollision = {}

function Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent, CollideWithPlayers)
	local data = ent:GetData().Isaac_Tower_Data
	local tab = {}
	if data and data.Half then
		--for i, col in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, IsaacTower_Enemy, -1)) do
		if #Isaac_Tower.EnemyHandlers.ActiveEnemyArray>0 then
			for i=#Isaac_Tower.EnemyHandlers.ActiveEnemyArray,1,-1 do
				local col = Isaac_Tower.EnemyHandlers.ActiveEnemyArray[i]
				if col.Index ~= ent.Index and col.EntityCollisionClass == 1 then
					local colData = col:GetData().Isaac_Tower_Data
					if colData then
						--local box1 = {pos = ent.Position, half = data.Half}
						--local box2 = {pos = col.Position, half = colData.Half}
						local box1 = {pos = data.Position, half = data.Half}
						local box2 = {pos = colData.Position, half = colData.Half}
						if Isaac_Tower.NoType_CheckAABB(box1, box2) then
							tab[#tab+1] = col
						end
					end
				end
			end
		end
		if CollideWithPlayers then
			for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
				local colData = Isaac.GetPlayer(i):GetData().Isaac_Tower_Data
				if colData then
					local box1 = {pos = data.Position, half = data.Half}
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

do
	local CacheFrame = 0
	local cacchetab
	function Isaac_Tower.EnemyHandlers.GetRoomEnemies(cache)
		--if cache then

		--else
			--local tab = {}
			--for i=1,#Isaac_Tower.EnemyHandlers.EnemyArray do
			--	local ent = Isaac_Tower.EnemyHandlers.EnemyArray[i]
			--	if ent:GetData().Isaac_Tower_Data.State ~= Isaac_Tower.EnemyHandlers.EnemyState.DEAD then
			--		tab[#tab+1] = Isaac_Tower.EnemyHandlers.EnemyArray[i]
			--	end
			--end
			return Isaac_Tower.EnemyHandlers.ActiveEnemyArray --EnemyArray
		--end
		--[[for i,k in pairs(Isaac.FindByType(Isaac_Tower.ENT.Enemy.ID,Isaac_Tower.ENT.Enemy.VAR,-1,cache)) do
			if k:GetData().Isaac_Tower_Data then
				tab[#tab+1] = k
			end
		end
		return tab]]
	end
	function Isaac_Tower.EnemyHandlers.GetAllRoomEnemies()
		return Isaac_Tower.EnemyHandlers.EnemyArray --ActiveEnemyArray
	end
end

function Isaac_Tower.EnemyHandlers.Kill(ent, vec)
	ent:GetData().Isaac_Tower_Data.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
	ent:GetData().Isaac_Tower_Data.DeadFlyRot = vec --vec<0 and 1 or vec>0 and -1
	Isaac_Tower.EnemyHandlers.RemoveEnemyFromArray(ent, true)
end

function Isaac_Tower.EnemyHandlers.AddEnemyToArray(ent)
	Isaac_Tower.EnemyHandlers.EnemyArray[#Isaac_Tower.EnemyHandlers.EnemyArray+1] = ent
	Isaac_Tower.EnemyHandlers.ActiveEnemyArray[#Isaac_Tower.EnemyHandlers.ActiveEnemyArray+1] = ent
end

function Isaac_Tower.EnemyHandlers.RemoveEnemyFromArray(ent, fromActive)
	if ent then
		--[[::check::
		local array = Isaac_Tower.EnemyHandlers.EnemyArray
		for i=1,#array do
			if not array[i]:Exists() then
				table.remove(Isaac_Tower.EnemyHandlers.EnemyArray,i)
				goto check
			end
			if array[i].Index == ent.Index then
				table.remove(Isaac_Tower.EnemyHandlers.EnemyArray,i)
				break
			end
		end]]
		if not fromActive then
			local array = Isaac_Tower.EnemyHandlers.EnemyArray
			for i=#array,1,-1 do
				if not array[i]:Exists() then
					table.remove(array,i)
				end
				if array[i] and array[i].Index == ent.Index then
					table.remove(array,i)
					break
				end
			end
		end
		local array = Isaac_Tower.EnemyHandlers.ActiveEnemyArray
		for i=#array,1,-1 do
			if not array[i]:Exists() then
				table.remove(array,i)
			end
			if array[i] and array[i].Index == ent.Index then
				table.remove(array,i)
				break
			end
		end
	end
end

function Isaac_Tower.EnemyHandlers.UngrabEnemy(ent, vel)
	vel = vel or Vector(0,0)
	local data = ent:GetData().Isaac_Tower_Data
	
	data.Velocity = vel
	data.GrabbedBy.GrabTarget = nil
	data.GrabbedBy = nil
	data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
	data.StateFrame = 0
	data.grounding = 0
	--ent:GetData().TSJDNHC_GridColl = 1
	ent.DepthOffset = 0
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

do 
	Isaac_Tower.ScoreHandler = { Current = 0, Active = false, textArray = {}, RenderPos = Vector(40,20) }
	Isaac_Tower.ScoreHandler.Font = Font()
	Isaac_Tower.ScoreHandler.Font:Load("font/upheaval.fnt")

	local num = 1
	function Isaac_Tower.RegisterBonusPickup(name, gfx, anim, size, flags)
		if name then
			if size and type(size) ~= "userdata" then error("[3] is not a integer",2) end
			if flags and type(flags) ~= "table" then error("[4] is not a table",2) end
			Isaac_Tower.FlayerHandlers.BonusPickup[name] = {Name = name, gfx = gfx, anim = anim, Size = size, Flags = flags or {}}
			local sprite = Sprite() sprite:Load(gfx,true) sprite:Play(anim)
			local ingridSpr = GenSprite(gfx, anim)
			ingridSpr.Scale = Vector(0.5,0.5)
			Isaac_Tower.editor.AddBonusPickup("auto_"..name.."_"..num, sprite, name, ingridSpr, size)
			num = num + 1
		end
	end

	function Isaac_Tower.FlayerHandlers.RemoveInGridBonusPickup(bonus)
		if not bonus then error("[1] is not a table",2) end
		local XY = bonus.XY
		local ref = bonus.Ref
		local grid = Isaac_Tower.GridLists.Bonus.Grid[XY.Y] and Isaac_Tower.GridLists.Bonus.Grid[XY.Y][XY.X]
		if grid then
			if bonus.CH then
				for i=1, #bonus.CH do
					local k = bonus.CH[i]
					Isaac_Tower.GridLists.Bonus.Grid[k.Y][k.X] = nil
				end
			end
			Isaac_Tower.GridLists.Bonus.Grid[XY.Y][XY.X] = nil
			table.remove(Isaac_Tower.GridLists.Bonus.Ref, ref)
			for i=1, #Isaac_Tower.GridLists.Bonus.Ref do
				Isaac_Tower.GridLists.Bonus.Ref[i][2].Ref = i
			end
		else
			error("Grid is not in right position!!!",2)
		end
	end

	function Isaac_Tower.ScoreHandler.SpawnRandomMultiEffect(gfx, anim, pos, vel, num, size)
		num = num or 1
		vel = vel or Vector(0,0)
		for i=1, num do
			local addvel = vel + Vector(1,0):Rotated(Isaac_Tower.Random(0,359)):Resized(Isaac_Tower.Random(0,30)/10)
			local rpos = pos
			if size then
				rpos = rpos + Vector(1,0):Rotated(Isaac_Tower.Random(0,359)):Resized(Isaac_Tower.Random(size/4,size))
			end
			local eff = Isaac.Spawn(Isaac_Tower.ENT.GIB.ID,Isaac_Tower.ENT.GIB.VAR,
				Isaac_Tower.ENT.GibSubType.BONUS_EFFECT, rpos, addvel, nil)
			eff.DepthOffset = 250
			local spr = eff:GetSprite()
			spr.PlaybackSpeed = Isaac_Tower.Random(10,25+num)/20
			spr:Load(gfx, true)
			if type(anim) == "table" then
				spr:Play(anim[Isaac_Tower.Random(1,#anim)])
			elseif anim then
				spr:Play(anim, true)
			else
				spr:Play(spr:GetDefaultAnimation())
			end
		end
	end

	function Isaac_Tower.ScoreHandler.AddText(text,data)
		if text then
			data = data or {}
			local color = data.color or KColor(1,1,1,0.8)
			Isaac_Tower.ScoreHandler.textArray[#Isaac_Tower.ScoreHandler.textArray+1] = {text, Vector(0,0), color}
		end
	end

	function Isaac_Tower.ScoreHandler.RenderTextArray(StartPos)
		for i=1, #Isaac_Tower.ScoreHandler.textArray do
			local dat = Isaac_Tower.ScoreHandler.textArray[i]
			local pos = dat[2] + StartPos
			Isaac_Tower.ScoreHandler.Font:DrawStringScaledUTF8(dat[1],pos.X,pos.Y,.5,.5,dat[3],1,true)
		end
	end

	function Isaac_Tower.ScoreHandler.Render(StartPos)
		Isaac_Tower.ScoreHandler.Font:DrawStringScaledUTF8(Isaac_Tower.ScoreHandler.Current,StartPos.X,StartPos.Y,.5,.5,KColor(1,1,1,0.8),1,true)
		Isaac_Tower.ScoreHandler.RenderTextArray(StartPos)
	end

	function Isaac_Tower.ScoreHandler.UpdateTextArray()
		for i=1, #Isaac_Tower.ScoreHandler.textArray do
			local dat = Isaac_Tower.ScoreHandler.textArray[i]
			dat[2].Y = dat[2].Y - 0.5
			if dat[2].Y < -5 then
				dat[3].Alpha = dat[3].Alpha - 0.1
			end
			--if dat[3].Alpha <= 0 then
			--	table.remove(Isaac_Tower.ScoreHandler.textArray, i)
			--end
		end
		for i=1, #Isaac_Tower.ScoreHandler.textArray do
			local dat = Isaac_Tower.ScoreHandler.textArray[i]
			if not dat or dat[3].Alpha <= 0 then
				--Isaac_Tower.ScoreHandler.textArray[i] = nil
				table.remove(Isaac_Tower.ScoreHandler.textArray, 1)
			end
		end
	end

	function Isaac_Tower.ScoreHandler.AddScore(num)
		if num and num ~= 0 then
			Isaac_Tower.ScoreHandler.Current = math.max(0, Isaac_Tower.ScoreHandler.Current + num)
			if num < 0 then
				Isaac_Tower.ScoreHandler.AddText("- " .. math.ceil(math.abs(num)), {color = KColor(1,0.2,0.2,0.6)})
			else
				Isaac_Tower.ScoreHandler.AddText("+ " .. math.ceil(num), {color = KColor(0.2,1,0.2,0.6)})
			end
		end
	end
end
--[[do
	Isaac_Tower.LevelHandler = {RoomData = {}}

	function Isaac_Tower.LevelHandler.TrySetSeedForRoom(roomName)
		if not SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, roomName).seed then
			Isaac_Tower.LevelHandler.RoomData[roomName].seed = Isaac_Tower.seeds:GetNextSeed()  --Isaac_Tower.seed
			Isaac_Tower.LevelHandler.RoomData[roomName].rng = RNG()
			Isaac_Tower.LevelHandler.RoomData[roomName].rng:SetSeed(Isaac_Tower.LevelHandler.RoomData[roomName].seed, 35)
		end
	end
	function Isaac_Tower.LevelHandler.GetCurrentRoomData()
		return SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, Isaac_Tower.CurrentRoom.Name)
	end
	function Isaac_Tower.LevelHandler.GetRoomData(roomName)
		return SafePlacingTable(Isaac_Tower.LevelHandler.RoomData, roomName)
	end
	local ignoreList = {Special=true, Evri=true}
	function Isaac_Tower.LevelHandler.SaveCurrentGridList()
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			local curData = Isaac_Tower.LevelHandler.GetCurrentRoomData()
			curData.GridLists = {}
			--curData.GridLists = Isaac_Tower.GridLists
			for i,k in pairs(Isaac_Tower.GridLists) do
				if not ignoreList[i] then
					curData.GridLists[i] = k
				end
			end
		end
	end
	function Isaac_Tower.LevelHandler.TryRestoreSavedGridList(roomName)
		local curData = Isaac_Tower.LevelHandler.GetRoomData(roomName)
		if curData.GridLists then
			--Isaac_Tower.GridLists = {}
			Isaac_Tower.GridLists = curData.GridLists
			--for i,k in pairs(curData.GridLists) do
			--	Isaac_Tower.GridLists[i] = k
			--end
			TSJDNHC_PT.GridsList[#TSJDNHC_PT.GridsList + 1] = Isaac_Tower.GridLists.Solid
			TSJDNHC_PT.GridsList[#TSJDNHC_PT.GridsList + 1] = Isaac_Tower.GridLists.Obs
		end
	end
	function Isaac_Tower.LevelHandler.SaveCurrentEnemies()
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			local curData = Isaac_Tower.LevelHandler.GetCurrentRoomData()
			curData.EnemiesList = {}
			local enemyList = Isaac_Tower.EnemyHandlers.GetRoomEnemies()
			for i=1, #enemyList do
				local ent = enemyList[i]
				local entData = ent:GetData().Isaac_Tower_Data
				if not entData.NoPersist then
					local result = Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ENEMY_PRE_SAVE, entData.Type, ent, curData) 
					if result ~= true then
						curData.EnemiesList[#curData.EnemiesList+1] = {
							type = entData.Type,
							st = ent.SubType,
							pos = ent.Position,
							data = entData
						}
					end
				end
			end
		end
	end
	function Isaac_Tower.LevelHandler.TryRestoreSavedtEnemies(roomName)
		local curData = Isaac_Tower.LevelHandler.GetRoomData(roomName)
		if curData.EnemiesList then
			local zero = Vector(0,0)
			for i=1,#curData.EnemiesList do
				local entData = curData.EnemiesList[i]
				local ent = Isaac_Tower.Spawn(entData.type, entData.st,entData.pos,zero,nil)
				ent:GetData().Isaac_Tower_Data = entData.data
				Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ENEMY_POST_RESTORE, entData.type, ent, curData)
			end
		end
	end
	function Isaac_Tower.LevelHandler.HasSavedData(roomName)
		if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			return  Isaac_Tower.LevelHandler.RoomData[roomName] and Isaac_Tower.LevelHandler.RoomData[roomName].GridLists
		else
			return false
		end
	end
	function Isaac_Tower.LevelHandler.ClearRoomData()
		Isaac_Tower.LevelHandler.RoomData = {}
	end
end]]

do
	Isaac_Tower.ScriptHandler = {Scripts = {}, RoomLocal = {}}

	function Isaac_Tower.ScriptHandler.AddScript(name, funcAsString)
		if name == nil then error("[1] is a nil",2) end
		if not type(funcAsString) == "string" or not type(funcAsString) == "function" then error("[2] is not a function or a string",2) end
		if type(funcAsString) == "string" then
			funcAsString = load(funcAsString)()
		end
		Isaac_Tower.ScriptHandler.Scripts[name] = funcAsString
	end

	function Isaac_Tower.ScriptHandler.AddLocalScript(roomName, name, funcAsString)
		if roomName == nil then error("[1] is a nil",2) end
		if name == nil then error("[2] is a nil",2) end
		if not type(funcAsString) == "string" or not type(funcAsString) == "function" then error("[3] is not a function or a string",2) end
		if type(funcAsString) == "string" then
			funcAsString = load(funcAsString)()
		end
		Isaac_Tower.ScriptHandler.RoomLocal[roomName] = Isaac_Tower.ScriptHandler.RoomLocal[roomName] or {}
		Isaac_Tower.ScriptHandler.RoomLocal[roomName][name] = funcAsString
	end

	function Isaac_Tower.ScriptHandler.RunScript(name, onlyGlobal)
		if not onlyGlobal and Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
			if Isaac_Tower.ScriptHandler.RoomLocal[Isaac_Tower.CurrentRoom.Name] then
				Isaac_Tower.ScriptHandler.RoomLocal[Isaac_Tower.CurrentRoom.Name][name]()
			end
		end
		if Isaac_Tower.ScriptHandler.Scripts[name] then
			Isaac_Tower.ScriptHandler.Scripts[name]()
		end
	end
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
	local fent = ent:GetData().Isaac_Tower_Data --or ent:GetData().Isaac_Tower_Data
	local pos = fent.Position or ent.Position

	if not check and grid.OnCollisionFunc and grid.OnCollisionFunc(ent, grid) then
		return false
	end
	
	local result = Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.GRID_SHOULD_COLLIDE, ent, grid, check)
	if result then
		return result
	end

	if entCol == 1 and gridColl == 1 then
		if grid.OnlyUp then
			--if not ent:ToPlayer() then

			--	if ent.Position.Y > (grid.CenterPos.Y-grid.Half.Y) then
			--		return
			--	elseif (ent.Position.Y+fent.CollisionOffset.Y+fent.Half.Y) <= (grid.CenterPos.Y-grid.Half.Y+2) then
			--		return true
			--	end
			--else
				if pos.Y > (grid.CenterPos.Y-grid.Half.Y) then
					return
				elseif (pos.Y+fent.CollisionOffset.Y+fent.Half.Y) <= (grid.CenterPos.Y-grid.Half.Y+2) then
					return true
				end
			--end
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

--mode: 0 = standard, 1 = ignore slopes and platforms
---@param startPos Vector
---@param endPos Vector
---@param step integer
---@param mode integer
function Isaac_Tower.lineOnlyCheck(startPos, endPos, step, mode)
	step = step or 40; mode = mode or 0
	local rot = (endPos - startPos):Normalized()
	local stepLimit = startPos:Distance(endPos)/step - 1

	for i = 0, math.ceil(stepLimit) do
		local pos = startPos + rot*(i)*step --/math.ceil(stepLimit))

		Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, Isaac_Tower.WorldToScreen(pos), 1)
		local grid = Isaac_Tower.GridLists.Solid:GetGrid(pos)
		if grid and RayCastShouldCollide(startPos, grid) then
			if mode == 0 
			or (mode == 1 and not grid.OnlyUp and not grid.slope) then
				return false
			end
		end
		local obs = Isaac_Tower.GridLists.Obs:GetGrid(pos)
		if obs and RayCastShouldCollide(startPos, obs) then
			if mode == 0 
			or (mode == 1 and not grid.OnlyUp and not grid.slope) then
				return false
			end
		end
	end
	return true
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
      hit.normal.X = sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.normal.Y = sy;
      hit.pos.X = box.CenterPos.X;
      hit.pos.Y = this.Position.Y + (this.Half.Y * sy);
    end

    return hit
end

---@param box1 table
---@param box2 table
--box = { [1] = Vector position, [2] = Vector half }
function Isaac_Tower.NoType_intersectAABB(box1,box2)
	local dx = box2[1].X - box1[1].X
    local px = (box2[2].X + box1[2].X) - math.abs(dx)
    if px <= 0 then
      return
    end

    local dy = box2[1].Y - box1[1].Y
    local py = (box2[2].Y + box1[2].Y) - math.abs(dy)
    if py <= 0 then
      return
    end

    local hit = hitG()
    if (px < py) then
      local sx = sign(dx)
      hit.delta.X = px * sx
      hit.normal.X = sx
      hit.pos.X = box1[1].X + (box1[2].X * sx)
      hit.pos.Y = box2[1].Y
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.normal.Y = sy;
      hit.pos.X = box2[1].X;
      hit.pos.Y = box1[1].Y + (box1[2].Y * sy);
    end
    return hit
end

---@param box1 table
---@param box2 table
--box = { [1] = Vector position, [2] = Vector half }
function Isaac_Tower.NoType_intersectAABB2(box1,box2)
	local dx = box2[1].X - box1[1].X
    local px = (box2[2].X + box1[2].X) - math.abs(dx)
    if px <= 0 then
      --return
    end

    local dy = box2[1].Y - box1[1].Y
    local py = (box2[2].Y + box1[2].Y) - math.abs(dy)
    if py <= 0 then
      --return
    end

    local hit = hitG()
    if (px < py) then
      local sx = sign(dx)
      hit.delta.X = px * sx
      hit.normal.X = sx
      hit.pos.X = box1[1].X + (box1[2].X * sx)
      hit.pos.Y = box2[1].Y
    else 
      local sy = sign(dy);
      hit.delta.Y = py * sy;
      hit.normal.Y = sy;
      hit.pos.X = box2[1].X;
      hit.pos.Y = box1[1].Y + (box1[2].Y * sy);
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

    local smoothup = this.DontHelpCollisionUpping or this.HelpCollisionHori or
		not (this.Position.Y>=0 and dy>0 and py<5 and (not upbox or upbox.Collision == 0 or upbox.slope) )
		
	local sx = sign(dx)
	local XHelp = this.HelpCollisionHori and ((px - py) < 6) 
		and not Isaac_Tower.rayCast( box.CenterPos+Vector((box.Half.X+1)*-sx,box.Half.Y-5), Vector(-sx,0), 5, 1) 

    if XHelp or (px < py) and smoothup then 
      --local sx = sign(dx)
      hit.delta.X = px * sx
      hit.pos.X = this.Position.X + (this.Half.X * sx)
      hit.pos.Y = boxHalfY
	  local nextgrid = this.HelpCollisionHori and XHelp or
	  	Isaac_Tower.rayCast( box.CenterPos+Vector((box.Half.X+1)*-sx,box.Half.Y-5), Vector(-sx,0), 5, 1)

	  --local renderPos = ( box.CenterPos+Vector((box.Half.X)*-sx,box.Half.Y-5) + Vector(-sx*5,0))/Wtr +ZeroPoint--TSJDNHC_PT.WorldToScreen --+Vector(box.Half.X*-sx,box.Half.Y-5)
	  --Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, renderPos, 5)
	  if not nextgrid then
        this.CollideWall = sx
	  else
		--local renderPos =  nextgrid.RenderPos --+ZeroPoint--TSJDNHC_PT.WorldToScreen --+Vector(box.Half.X*-sx,box.Half.Y-5)
	    --Isaac_Tower.DebugRenderThis(Isaac_Tower.sprites.GridCollPoint, renderPos, 5)
	  end
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
	--this.Position = ent.Position
	--this.Velocity = ent.Velocity

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

    local smoothup = true --this.DontHelpCollisionUpping or not (dy>0 and py<20 and (not upbox or upbox.Collision == 0 or upbox.slope) )
	
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
	--this.Position = ent.Position
	--this.Velocity = ent.Velocity

    local dx = box.CenterPos.X - (this.Position.X+this.CollisionOffset.X) - this.Velocity.X
    local px = (box.Half.X + this.Half.X) - math.abs(dx)

    if px <= 0 then
      return
    end
    
    local hit = hitG()

    local boxHalfY = box.CenterPos.Y --+0

    if box.slope then
      boxHalfY = boxHalfY - (GetDeepSlope(this, box) or 0)
    end

    local dy = boxHalfY - (this.Position.Y+this.CollisionOffset.Y) - this.Velocity.Y
    local py = (box.Half.Y + this.Half.Y) - math.abs(dy)

    if py <= 0 then
      return
    end

    --local upbox = Isaac_Tower.rayCast( box.CenterPos+Vector(0,-box.Half.Y), Vector(0,-1), 15, 2)

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
        --if (px < py) and (dy>0 and py<20) then
        --    hit.SmoothUp = true
        --end
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
	---@type Flayer
	local fent = d.Isaac_Tower_Data

	Isaac_Tower.UpdateSpeedHandler(function()
		Isaac_Tower.HandleMoving(ent)

		--d.TSJDNHC_fallspeed = d.TSJDNHC_fallspeed or 0

		if not Isaac_Tower.GridLists.Solid:GetGrid(fent.Position) then
			local result = Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, nil, ent)
			if type(result) == "userdata" and result.X then
				Isaac_Tower.SetPlayerPos(ent, result)
			elseif result ~= true then
				Isaac_Tower.SetPlayerPos(ent, Isaac_Tower.SpawnPoint or Vector(320, 280))
			end
		end

		-------------------------
		fent.slopeAngle = nil
		local collidedGrid = {}
		local ignoreGrid = {}
		ent:GetData().LastcollidedGrid = {}

		fent.CollideWall = nil
		fent.OnGround = false
		fent.CollideCeiling = false
		fent.jumpDelay = fent.jumpDelay - 1

		fent.LastVelocity = fent.Velocity / 1
		fent.LastPosition = fent.Position / 1

		local repeatNum = math.max(1, math.ceil(fent.Velocity:Length() / 8))
		
		--local origVelocity = fent.Velocity / 1
		fent.Velocity = fent.Velocity / repeatNum
		--local slowedVelocity = fent.Velocity / 1
		fent.RepeatingNum = repeatNum
		local GridListSizeX = Isaac_Tower.GridLists.Solid.X
		
		for ihhh = 1, repeatNum do
			if d.TSJDNHC_GridColl>0 then
				local indexs = {}
				local pointIndex = Isaac_Tower.GridLists.Solid:GetGrid(fent.Position)
				--local pointIndexStr = pointIndex and (math.ceil(pointIndex.XY.X) .. "." .. math.ceil(pointIndex.XY.Y))
				local pointIndexStr = pointIndex and (pointIndex.XY.Y * GridListSizeX + pointIndex.XY.X)
				--for ia, k in pairs(d.TSJDNHC_GridPoints) do
				local orgpos = fent.Position + Vector(0, 12) + fent.Velocity
				for ia=1,#fent.GridPoints do
					local k = fent.GridPoints[ia]
					local grid = Isaac_Tower.GridLists.Solid:GetGrid(orgpos + k[1])

					if grid and not ignoreGrid[grid] then
						if Isaac_Tower.ShouldCollide(ent, grid) then
							--collidedGrid[grid] = collidedGrid[grid] or {}
							collidedGrid[#collidedGrid+1] = grid
							ignoreGrid[grid] = true
							--collidedGrid[grid][i] = k[1] + fent.Position
							ent:GetData().LastcollidedGrid[#ent:GetData().LastcollidedGrid + 1] = grid
						end
						--local index = math.ceil(grid.XY.X) .. "." .. math.ceil(grid.XY.Y)
						local index = grid.XY.Y * GridListSizeX + grid.XY.X
						indexs[index] = true
					end
					--fent.Velocity = origVelocity
					local obs = Isaac_Tower.GridLists.Obs:GetGrid(orgpos + k[1]*Vector(1,1.2))
					if obs and not ignoreGrid[obs] and Isaac_Tower.ShouldCollide(ent, obs) then
						--collidedGrid[obs] = collidedGrid[grid] or {}
						collidedGrid[#collidedGrid+1] = obs
						ignoreGrid[obs] = true
						--collidedGrid[obs][i] = k[1] + fent.Position -- ent.Velocity
						ent:GetData().LastcollidedGrid[#ent:GetData().LastcollidedGrid + 1] = obs
					end
					--fent.Velocity = slowedVelocity

					--[[if obs and Isaac_Tower.GridLists.Bonus.Grid then
						local yr,xr = obs.XY.Y, obs.XY.X
						local bonus = Isaac_Tower.GridLists.Bonus.Grid[yr] and Isaac_Tower.GridLists.Bonus.Grid[yr][xr]
						if bonus then
							if bonus.Parent then
								--if Isaac_Tower.GridLists.Bonus.Ref[bonus.Parent] then
									bonus = bonus.Parent --Isaac_Tower.GridLists.Bonus.Ref[bonus.Parent][2]
								--else
								--	Isaac_Tower.GridLists.Bonus.Grid[bonus.XY.Y][bonus.XY.X] = nil
								--end
							end
							Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.BONUSPICKUP_COLLISION, bonus.Type, ent, bonus)
						end
					end]]
				end
				if Isaac_Tower.GridLists.Bonus.Grid then
					local orgpos = fent.Position + Vector(0, 12) + fent.Velocity - Isaac_Tower.GridLists.Obs.StartPos
					local Xsize, Ysize = Isaac_Tower.GridLists.Obs.Xsize, Isaac_Tower.GridLists.Obs.Ysize
					for ia=1,#fent.InsideGridPoints do
						local k = fent.InsideGridPoints[ia]
						local vec = orgpos + k[1]
						local xs,ys = math.ceil(vec.X/Xsize), math.ceil(vec.Y/Ysize)

						local bonus = Isaac_Tower.GridLists.Bonus.Grid[ys] and Isaac_Tower.GridLists.Bonus.Grid[ys][xs]
						if bonus then
							if bonus.Parent then
								bonus = bonus.Parent
							end
							Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.BONUSPICKUP_COLLISION, bonus.Type, ent, bonus)
						end
					end
				end
				--[[if pointIndex and Isaac_Tower.GridLists.Fake then
					for gtype, tab in pairs(Isaac_Tower.GridLists.Fake) do
						local spec = tab[pointIndexStr]
						print(spec,gtype, tab)
						if spec then
							if spec.Parent then
								spec = tab[spec.Parent]
							end
						end
					end
				end]]

				local calls = Isaac.GetCallbacks(Isaac_Tower.Callbacks.FLAYER_GRID_SCANING)
				for ia=1, #calls do
					local k = calls[ia]
					local result = k.Function(k.Mod, ent, fent)
					if result and not ignoreGrid[result] then
						--collidedGrid[result] = collidedGrid[result] or {}
						collidedGrid[#collidedGrid+1] = result
					end
				end

				ent:GetData().DebugGridRen = ent:GetData().DebugGridRen or {}

				ent:GetData().DebugGridRen = {}
				
				--for ia, k in pairs(collidedGrid) do
				for k=1, #collidedGrid do
					local ia = collidedGrid[k]
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
						fent.UnStuck.CounterForce = fent.UnStuck.CounterForce + math.abs(hit.delta.X)
					end
				end
				
				local hasUpHelp = false
				--for ia, k in pairs(collidedGrid) do
				for k=1, #collidedGrid do
					local ia = collidedGrid[k]
					local hitY = intersectAABB_Y(fent, ia)

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
						fent.UnStuck.CounterForce = fent.UnStuck.CounterForce + math.abs(hitY.delta.Y)
						if hitY.SlopeAngle then
							fent.slopeAngle = hitY.SlopeAngle
						end
					elseif not hasUpHelp then
						fent.SmoothUp = nil
					end
				end

				---- Анти застрязин
				if fent.UnStuck.CounterForce > 50 then
					if fent.UnStuck.LastPoses[fent.UnStuck.Nem+1] then
						fent.Position = fent.UnStuck.LastPoses[fent.UnStuck.Nem+1] --Nem
						fent.UnStuck.Nem = fent.UnStuck.Nem + 1
					else
					--	fent.UnStuck.Nem = 0
					end
				end

				fent.UnStuck.CounterForce = math.min(500, math.max(0, fent.UnStuck.CounterForce - 20))
				if fent.UnStuck.CounterForce <= 10 then
					--fent.UnStuck.LastPoses[#fent.UnStuck.LastPoses+1] = fent.Position
					if fent.FrameCount%2 == 0 then
						table.insert(fent.UnStuck.LastPoses,1,fent.Position)
					end
					fent.UnStuck.Nem = 0
				end
				if #fent.UnStuck.LastPoses>25 then
					fent.UnStuck.LastPoses[26] = nil
				end

				local vel = fent.Velocity/1
				---@type ForsedVelocity
				local ForsedVelocity = fent.ForsedVelocity
				if ForsedVelocity then
					local ler = ForsedVelocity.Lerp
					vel = vel * (1-ler) + ForsedVelocity.Velocity * ler
				end
				local UnStickWallVel = fent.UnStickWallVel
				if UnStickWallVel then
					local UnStickWallTime = fent.UnStickWallTime
					fent.UnStickWallMaxTime = fent.UnStickWallMaxTime or UnStickWallTime
					local lerp = UnStickWallTime / fent.UnStickWallMaxTime
					Isaac_Tower.DebugRenderText(lerp, Vector(80,80),1)
					Isaac_Tower.DebugRenderText(UnStickWallTime, Vector(80,100),1)
					Isaac_Tower.DebugRenderText(UnStickWallTime, Vector(80,120),1)
					vel.X = vel.X * (1-lerp) + UnStickWallVel.X * lerp
					vel.Y = vel.Y * (1-lerp)
					fent.UnStickWallTime = fent.UnStickWallTime - 1
					if fent.UnStickWallTime <= 0 then
						fent.UnStickWallTime = nil
						fent.UnStickWallMaxTime = nil
						fent.UnStickWallVel = nil
					end
				end

				fent.Position = fent.Position + vel -- * Isaac_Tower.UpdateSpeed
				ent.Position = Vector(-200, fent.Position.Y + 50)


				if fent.TrueVelocity.Y >= 0 and fent.grounding and fent.grounding > 0 then
					local collGrid = {}
					for i = -1, 1 do
						local grid = Isaac_Tower.rayCast((fent.Position - fent.Velocity + Vector(fent.Half.X * i, -10)),
							Vector(0, 1), 10, 6)    -- Vector(fent.Half.X*i,-10)

						if grid and Isaac_Tower.ShouldCollide(ent, grid) then  --and grid.slope
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

				for ia, k in pairs(indexs) do
					local indexsignors = {}
					for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
						local spec = tab[ia]
						if spec then
							if spec.Parent then
								spec = tab[spec.Parent]
							end
							if spec.Parents then
								for iq=1,#spec.Parents do
									--local spID = spec.Parents[iq]
									local spid = tab[spec.Parents[iq]]
									if not indexsignors[spid] then
										indexsignors[spid] = true
										--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spid)
										Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spid)
									end
								end
							end
							if not indexsignors[spec] then
								indexsignors[spec] = true
								--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spec)
								Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spec)
							end
						end
					end
				end
				if pointIndexStr then
					for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
						local spec = tab[pointIndexStr]
						if spec then
							if spec.Parent then
								spec = tab[spec.Parent]
							end
							if spec.Parents then
								for iq=1,#spec.Parents do
									--local spID = spec.Parents[iq]
									local spid = tab[spec.Parents[iq]]
									--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_COLLISION, gtype, ent, spid)
									Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, gtype, ent, spid)
								end
							end
							--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, gtype, ent, spec)
							Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, gtype, ent, spec)
						end
					end
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

		Isaac_Tower.SmoothPlayerPos = Vector( math.floor(Isaac_Tower.SmoothPlayerPos.X*20)/20, math.floor(Isaac_Tower.SmoothPlayerPos.Y*20)/20 )

	TSJDNHC_PT:SetFocusPosition(Isaac_Tower.SmoothPlayerPos, 1) --0.98

end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Isaac_Tower.PlatformerCollHandler)

function Isaac_Tower.INIT_FLAYER(player)
	
	local d = player:GetData()
	local ent = player
	--TSJDNHC_PT:SetFocusEntity(ent, 2)
	d.TSJDNHC_GridColl = 1
	ent.GridCollisionClass = 0

	--[[d.TSJDNHC_GridPoints = {}
	for i=0,360-30,30 do   

		local ang = i --90*(i)+45
		local size = player.Size*2.1 --Isaac.GetPlayer(pid)
		local pos = Vector(ent.Size*3.2,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.TSJDNHC_GridPoints[i] = {pos, vec}
	end]]

	d.Isaac_Tower_Data = {
		Self = player,
		FrameCount = 0,
		Position = player.Position, --Isaac.GetPlayer(pid)
		Velocity = Vector(0,0),
		TrueVelocity = Vector(0,0),
		Half = Vector(9.5,19),  --Vector(12,19), --15 Vector(ent.Size, ent.Size),
		DefaultHalf = Vector(9.5,19),  --Vector(12,19),
		DefaultCroachHalf = Vector(9.5,10), -- Vector(12,10), --Vector(12,19),
		CollisionOffset = Vector(0,0),
		CroachDefaultCollisionOffset = Vector(0,9),
		jumpDelay = 0,
		State = 1,
		StateFrame = 0,
		JumpPressed = 0,
		CanJump = true,
		grounding = 5,
		--Flayer = manager.GenPlayerMetaSprite(fent),
		PosRecord = {},
		UnStuck = {
			CounterForce = 0,
			Nem = 0,
			LastPoses = {}
		}
	}
	d.Isaac_Tower_Data.Flayer = Isaac_Tower.FlayerHandlers.PlayerAnimManager.GenPlayerMetaSprite(d.Isaac_Tower_Data)
	
	d.Isaac_Tower_Data.GridPoints = {}
	for i=0,360-30,30 do
		local ang = i --90*(i)+45
		local size = player.Size*2.1 --Isaac.GetPlayer(pid)
		local pos = Vector(ent.Size*3.2,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.Isaac_Tower_Data.GridPoints[#d.Isaac_Tower_Data.GridPoints+1] = {pos, vec}
	end
	d.Isaac_Tower_Data.InsideGridPoints = {}
	for i=0,360-45,45 do
		local ang = i --90*(i)+45
		local size = player.Size*1.1 --Isaac.GetPlayer(pid)
		local pos = Vector(ent.Size*3.2,0):Rotated(ang):Clamped(-size,-size,size,size)  + Vector(0,-10)
		local vec = Vector(-1,0):Rotated(ang)
		--vec = Vector(math.floor(vec.X*10)/10, math.floor(vec.Y*10)/10)
		d.Isaac_Tower_Data.InsideGridPoints[#d.Isaac_Tower_Data.InsideGridPoints+1] = {pos, vec}
	end

	--[[d.Isaac_Tower_Data.Flayer.Sprite:Load("gfx/fakePlayer/flayer.anm2", true)
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
	d.Isaac_Tower_Data.Flayer.Shadow.Color = Color(1,1,1,2)]]

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
local font = Font()
font:Load("font/upheaval.fnt")
local nilFunc = function() end

function Isaac_Tower.FlayerRender(_, player, Pos, Offset, Scale)
	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) --BDCenter --+GridListStartPos*(1-Scale)
	end
	local fent = player:GetData().Isaac_Tower_Data
	---@type Player_AnimManager
	local spr = fent.Flayer --.Sprite
	if not spr then return end
	local RightHandSprite = spr.CurrentRHSpr
	spr:UpdateParam()

	
	--print(Isaac.GetFrameCount())

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
	
	if RightHandSprite then
		RightHandSprite:SetFrame(spr:GetAnimation(), spr:GetFrame())
	end
	
	if Scale == 1 then
		spr:Render(RenderPos)
		function fent.Flayer.RenderRightHandSprite()
			if RightHandSprite then
				RightHandSprite:Render(RenderPos)
			end
		end
		fent.Flayer.RenderRightHandSprite()
	else
		--local scaledOffset = (Scale*(fent.Position/Wtr)-(fent.Position/Wtr))-zeroOffset

		local preScale = spr.Scale/1
		spr.Scale = spr.Scale*Scale
		spr:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1))) --+scaledOffset+Vector(0,12*(Scale-1)))
		
		function fent.Flayer.RenderRightHandSprite()
			if RightHandSprite then
				RightHandSprite.Scale = RightHandSprite.Scale*Scale
				RightHandSprite:Render(RenderPos+Vector(0,12*(math.abs(Scale)-1)))
				RightHandSprite.Scale = preScale
			end
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
	--font:DrawStringScaledUTF8(fent.PreviousState or "",RenderPos.X,RenderPos.Y+10,.5,.5,KColor(1,1,1,1),1,true)
	Isaac.RunCallback(Isaac_Tower.Callbacks.FLAYER_POST_RENDER, player, RenderPos, Offset, Scale)
end
mod:AddCallback(TSJDNHC_PT.Callbacks.ENTITY_POSTRENDER, Isaac_Tower.FlayerRender, 1)

local flayerList = {}
function Isaac_Tower.GameUpdate()
	local roomdat = Isaac_Tower.LevelHandler.RoomData[Isaac_Tower.CurrentRoom.Name]
	if roomdat then
		roomdat.FrameCount = roomdat.FrameCount + 1
	end
	Isaac_Tower.GridLists.Obs:CallGridUpdate()

	local fakegroup = {}
	for i=0, Game():GetNumPlayers() do
		flayerList[i] = Isaac_Tower.GetFlayer(i)  --Isaac_Tower.GetFlayer(i)
		local fent = flayerList[i]
		local pointIndex = Isaac_Tower.GridLists.Solid:GetRawGrid(fent.Position)
		--Isaac_Tower.SmoothPlayerPos = Isaac_Tower.SmoothPlayerPos * 0.8 
		--	+ (fent.Position + Vector(fent.Velocity.X, 0) * 5) * 0.2

		--Isaac_Tower.SmoothPlayerPos = Vector( math.floor(Isaac_Tower.SmoothPlayerPos.X*20)/20, math.floor(Isaac_Tower.SmoothPlayerPos.Y*20)/20 )
		--TSJDNHC_PT:SetFocusPosition(Isaac_Tower.SmoothPlayerPos, 1)

		if pointIndex and Isaac_Tower.GridLists.Fake then
			local group = Isaac_Tower.GridLists.Fake[pointIndex.XY.Y] and Isaac_Tower.GridLists.Fake[pointIndex.XY.Y][pointIndex.XY.X]
			if group then
				fakegroup[#fakegroup+1] = group
			end
		end
	end

	if Isaac_Tower.GridLists.Fake then
		local blocked = {}
		for i=1, #fakegroup do
			blocked[fakegroup[i] ] = true
			local tab = Isaac_Tower.GridLists.Fake.Sorted[fakegroup[i]]
			for j,spr in pairs(tab) do
				spr.Color = Color(spr.Color.R, spr.Color.G, spr.Color.B, math.max(0, spr.Color.A-0.1))
			end
		end
		for i,k in pairs(Isaac_Tower.GridLists.Fake.Sorted) do
			if not blocked[i] then
				for j,spr in pairs(k) do
					if spr.Color.A < 1 then
						spr.Color = Color(spr.Color.R, spr.Color.G, spr.Color.B, spr.Color.A+0.1)
					end
				end
			end
		end
	end
end
function Isaac_Tower.GameRenderUpdate()
	if not Isaac_Tower.InAction or Isaac_Tower.Pause or Isaac_Tower.game:IsPaused() then return end
	--[[if flayerList then
		for i=0, #flayerList-1 do
			
			if flayerList[i]:Exists() then
				local fent = flayerList[i]:GetData().Isaac_Tower_Data
				Isaac_Tower.SmoothPlayerPos = Isaac_Tower.SmoothPlayerPos * 0.8 
					+ (fent.Position + Vector(fent.Velocity.X, 0) * 5) * 0.2

				Isaac_Tower.SmoothPlayerPos = Vector( math.floor(Isaac_Tower.SmoothPlayerPos.X*20)/20, math.floor(Isaac_Tower.SmoothPlayerPos.Y*20)/20 )
				TSJDNHC_PT:SetFocusPosition(Isaac_Tower.SmoothPlayerPos, 1)
			end
		end
	end]]

	--if Isaac_Tower.ScoreHandler.Active then
	--	Isaac_Tower.ScoreHandler.Render(Isaac_Tower.ScoreHandler.RenderPos)
		--Isaac_Tower.ScoreHandler.RenderTextArray(Isaac_Tower.ScoreHandler.RenderPos)
	--	Isaac_Tower.ScoreHandler.UpdateTextArray()
	--end


	local array = Isaac_Tower.EnemyHandlers.EnemyArray
	local arrayProj = Isaac.FindByType(1000,Isaac_Tower.ENT.Proj.VAR,-1)
	local updatePos = false
	Isaac_Tower.UpdateSpeedHandler30(function()
		Isaac_Tower.SpecialGridUpdate()
		Isaac_Tower.GridLists.Obs:UpdateGridSprites()

		for i=1,#array do
			local ent = array[i]
			if ent then
				Isaac_Tower.EnemyUpdate(nil,ent)
				if updatePos then
					local data = ent:GetData().Isaac_Tower_Data
					data.Position = data.Position + data.Velocity
				end
			end
		end
		for i=1,#arrayProj do
			local ent = arrayProj[i]
			if ent then
				Isaac_Tower.ProjectileUpdate(nil,ent)
				if updatePos then
					local data = ent:GetData().Isaac_Tower_Data
					data.Position = data.Position + data.Velocity
				end
			end
		end
		updatePos = true


		if Isaac_Tower.Backgroung.Data then
			for i=1, #Isaac_Tower.Backgroung.Data do
				local data = Isaac_Tower.Backgroung.Data[i]
				if data.spr then
					data.spr:Update()
					
				end
				if data.mov then
					data.pos = data.pos or Vector(0,0)
					data.pos.X = (data.pos.X + data.mov.X) % data.size.X
					data.pos.Y = (data.pos.Y + data.mov.Y) % data.size.Y
				end
			end
		end
	end)
	--Isaac_Tower.EnemyUpdate


	if Input.IsButtonTriggered(Keyboard.KEY_1,0) then --TODO
		Isaac_Tower.SetScale()
	elseif Input.IsButtonTriggered(Keyboard.KEY_2,0) then
		Isaac_Tower.SetScale(1.41)
	elseif Input.IsButtonTriggered(Keyboard.KEY_3,0) then
		Isaac_Tower.SetScale(2.05)
	elseif Input.IsButtonTriggered(Keyboard.KEY_4,0) then
		Isaac_Tower.SetScale(.7)
	end
end

---@return Flayer
function Isaac_Tower.GetFlayer(num)
	local player = Isaac.GetPlayer(num)
	return player:GetData().Isaac_Tower_Data
end

function Isaac_Tower.SpecialGridUpdate()
	--if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	--if not Isaac_Tower.GridLists.Special then return end
	--Isaac_Tower.UpdateSpeedHandler30(function()

		for gtype, tab in pairs(Isaac_Tower.GridLists.Special) do
			for index, grid in pairs(tab) do
				if not grid.Parent then
					grid.FrameCount = grid.FrameCount and (grid.FrameCount + 1) or 0
					--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.SPECIAL_UPDATE, gtype, grid)
					Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_UPDATE, gtype, grid)
				end
			end
		end

	--end)
end
--mod:AddCallback(ModCallbacks.MC_POST_UPDATE, Isaac_Tower.SpecialGridUpdate)

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
	[Isaac_Tower.EnemyHandlers.EnemyState.GRABBED] = function(ent)
		local data = ent:GetData().Isaac_Tower_Data
		if data.GrabbedBy and (Isaac_Tower.FlayerHandlers.UnGrabState[data.GrabbedBy.State] or not data.GrabbedBy.GrabTarget ) then
			--[[local rot = sign(data.GrabbedBy.Velocity.X)
			data.Velocity = Vector(rot*-4,-7)
			data.GrabbedBy.GrabTarget = nil
			data.GrabbedBy = nil
			data.State = Isaac_Tower.EnemyHandlers.EnemyState.STUN
			data.StateFrame = 0
			ent:GetData().TSJDNHC_GridColl = 1
			ent.DepthOffset = 0]]
			local rot = sign(data.GrabbedBy.Velocity.X)
			Isaac_Tower.EnemyHandlers.UngrabEnemy(ent, Vector(rot*-4,-7))
		end
		--Isaac_Tower.FlayerHandlers.UnGrabState
	end,
	[Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED] = function(ent)
		local data = ent:GetData().Isaac_Tower_Data
		for i, col in pairs(Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent)) do
			local Edata = col:GetData().Isaac_Tower_Data
			--Edata.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
			--Edata.DeadFlyRot = Edata.Position.X < Edata.Position.X and -1 or 1
			Isaac_Tower.EnemyHandlers.Kill(col, Edata.Position.X < Edata.Position.X and -1 or 1)
			--local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
			--col:ClearEntityFlags(addflag)
		end
		if data.OnGround or data.CollideWall or data.CollideCeiling or data.slopeAngle then
			--data.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
			Isaac_Tower.EnemyHandlers.Kill(ent)
			ent:GetData().TSJDNHC_GridColl = 0
			data.DeadFlyRot = data.CollideWall
			if data.StateFrame < 1 then
				data.Position = data.prePosition or data.Position
			end
			return
		end
		data.prePosition = data.Position/1
		data.StateFrame = data.StateFrame + 1
		--for i, col in pairs(Isaac_Tower.EnemyHandlers.GetCollidedEnemies(ent)) do
		--	local Edata = col:GetData().Isaac_Tower_Data
		--	Edata.State = Isaac_Tower.EnemyHandlers.EnemyState.DEAD
		--	Edata.DeadFlyRot = col.Position.X < ent.Position.X and -1 or 1
		--end
		local spr = ent:GetSprite()
		local sig = spr.FlipX and -1 or 1
		if ent.FrameCount%2 == 0 then
			spawnSpeedEffect(data.Position-data.Velocity+Vector(sig*-15, (ent.FrameCount*4%24)*2-20):Rotated(sig*(data.Velocity:GetAngleDegrees())),
				data.Velocity*0.8, (data.Velocity*Vector(1,-1)):GetAngleDegrees()).Color = Color(1,1,1,.5)
		end
	end,
	[Isaac_Tower.EnemyHandlers.EnemyState.DEAD] = function(ent)
		local data = ent:GetData().Isaac_Tower_Data
		if not data.Deaded then
			Isaac_Tower.EnemyHandlers.RemoveEnemyFromArray(ent)
			ent:GetSprite():Play("stun")
			data.Deaded = true
			local rng = RNG()
			rng:SetSeed(ent.DropSeed,35)

			local grid = Isaac.Spawn(1000,EffectVariant.BLOOD_EXPLOSION,0,data.Position, Vector(0,0) ,nil)
			grid.Color = ent.SplatColor
			for i=1, 8 do
				local vec = Vector.FromAngle(-rng:RandomInt(181) or 0):Resized((rng:RandomInt(105)+11)/10)
				local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,Isaac_Tower.ENT.GibSubType.GIB,data.Position,vec ,nil)
				grid:GetSprite():Load("gfx/effects/it_guts.anm2",true)
				grid:GetSprite():Play((rng:RandomInt(12)+1), true)
				grid:ToEffect().Rotation = rng:RandomInt(101)-50
				grid.SpriteRotation = rng:RandomInt(360)+1
				grid.Color = ent.SplatColor
			end
			ent.Variant = IsaacTower_GibVariant
			ent.SubType = Isaac_Tower.ENT.GibSubType.GIB
			local addflag = EntityFlag.FLAG_NO_SPRITE_UPDATE
			ent:ClearEntityFlags(addflag)
			local ver = data.DeadFlyRot and ((type(data.DeadFlyRot) == "userdata" and data.DeadFlyRot) or
				data.DeadFlyRot*8) or sign0(data.TrueVelocity.X or data.Velocity.X)*8
			ent.Velocity = Vector(ver, -8)
		end

	end,
}

function Isaac_Tower.EnemyUpdate(_, ent)--IsaacTower_Enemy
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	if not ent:GetData().Isaac_Tower_Data then return end

	local typ = ent:GetData().Isaac_Tower_Data and ent:GetData().Isaac_Tower_Data.Type
	local data = ent:GetData().Isaac_Tower_Data
	ent:GetData().Isaac_Tower_Data.StateFrame = ent:GetData().Isaac_Tower_Data.StateFrame or 0
	if ent.FrameCount > 0 then
		--ent.Velocity = ent.Velocity/Isaac_Tower.UpdateSpeed
	end
	--local inpPos = true
	--Isaac_Tower.UpdateSpeedHandler30(function()
	--	inpPos = false
		ent:GetSprite():Update()
		--local typ = ent:GetData().Isaac_Tower_Data and ent:GetData().Isaac_Tower_Data.Type
		--local data = ent:GetData().Isaac_Tower_Data

		data.slopeAngle = nil

		data.CollideWall = nil
		data.OnGround = false
		data.CollideCeiling = false
		--data.LastPosition = ent.Position/1
		--ent.Velocity = ent.Velocity/Isaac_Tower.UpdateSpeed

		--data.Position = ent.Position
		--data.Velocity = ent.Velocity
		data.Position = data.Position + data.Velocity

		local collidedGrid = {}

		local indexs = {}

		if ent:GetData().TSJDNHC_GridColl>0 and not data.GrabbedBy then
			--for ia, k in pairs(data.GridPoints) do
			for ia=1,#data.GridPoints do
				local k = data.GridPoints[ia]
				local grid = Isaac_Tower.GridLists.Solid:GetGrid(data.Position + Vector(0, 10) + data.Velocity + k[1])

				if grid then
					if Isaac_Tower.ShouldCollide(ent, grid) then
						collidedGrid[grid] = collidedGrid[grid] or {}
					end
				end
				local obs = Isaac_Tower.GridLists.Obs:GetGrid(data.Position + Vector(0, 10) + data.Velocity + k[1])
				
				if obs and Isaac_Tower.ShouldCollide(ent, obs) then
					collidedGrid[obs] = collidedGrid[grid] or {}
				end
			end

			for ia, k in pairs(collidedGrid) do
				local hit = EnemyintersectAABB_X(ent, ia)

				if hit and hit.delta.X ~= 0 then
					if not data.slopeRot --hit.Slope
					or ((data.Position.Y > hit.pos.Y or not data.slopeRot == sign(hit.delta.X))
					and data.slopeRot == sign(hit.delta.X)) then
						
						data.Position = Vector(data.Position.X - hit.delta.X + data.Velocity.X, data.Position.Y)
					
						if sign(data.Velocity.X) == sign(hit.delta.X) then
							data.Velocity = Vector(0, data.Velocity.Y)
						end
					end
				end
			end

			for ia, k in pairs(collidedGrid) do
				local hitY = EnemyintersectAABB_Y(ent, ia)

				if hitY and hitY.delta.Y ~= 0 then
					--if hitY.SmoothUp then
					--	data.Position = Vector(data.Position.X, data.Position.Y - hitY.delta.Y / math.max(1, (30 / math.abs(data.Velocity.X)))) --10
					--else
						if hitY.delta.Y > 0.0 then
							hitY.delta.Y = math.max(0, hitY.delta.Y - 0.1 - data.Velocity.Y)
						end
						data.Position = data.Position - Vector(0, hitY.delta.Y)
					--end
					if hitY.SlopeAngle then
						data.slopeAngle = hitY.SlopeAngle
					end
				end
			end

			--local prePosition = data.Position / 1
			--ent:Update()
			ent.Position = data.Position --ent.Position + ent.Velocity -- * Isaac_Tower.UpdateSpeed
			--data.Position = data.Position + data.Velocity

			data.TrueVelocity = data.Position - data.LastPosition
			
			if data.State ~= Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED 
			and data.TrueVelocity.Y >= 0 and data.grounding and data.grounding > 0 then
				local collGrid = {}
				for i = -1, 1 do
					local grid = Isaac_Tower.rayCast((data.Position - data.Velocity + Vector(data.Half.X * i, -10)),
						Vector(0, 1), 10, 6)                   -- Vector(fent.Half.X*i,-10)

					if grid and Isaac_Tower.ShouldCollide(ent, grid) then
						collGrid[grid] = collGrid[grid] or true
					end
				end
				local groundMinOffset = -200
				local ignoreGrounding = false
				for ia, k in pairs(collGrid) do
					--data.Position = ent.Position
					--data.Velocity = ent.Velocity
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
					data.Position = Vector(data.Position.X, data.Position.Y - groundMinOffset)
					data.OnGround = true
					data.Velocity = Vector(data.Velocity.X, math.min(0, data.Velocity.Y))
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
				local player = Isaac.GetPlayer(i)
				local fent = player:GetData().Isaac_Tower_Data --Isaac_Tower.GetFlayer(i)
				local dist = fent and fent.Position:Distance(data.Position)

				if fent and player.EntityCollisionClass > 0 
				and dist < data.FlayerDistanceCheck and data.State ~= Isaac_Tower.EnemyHandlers.EnemyState.GRABBED then
					
					local box1 = {pos = data.Position, half = data.Half}
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
		
		--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, typ, ent)
		Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, typ, ent)
		--data.Position = data.Position + data.Velocity

		data.LastPosition = ent.Position/1
	--end)
	--ent.Velocity = ent.Velocity*Isaac_Tower.UpdateSpeed
	
	if not Isaac_Tower.GridLists.Solid:GetGrid(data.Position) then
		Isaac_Tower.EnemyHandlers.RemoveEnemyFromArray(ent)
		ent:Remove()
	end
end
function Isaac_Tower.EnemyPostUpdate_RealPosUpdate(ent)
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end

	local data = ent:GetData().Isaac_Tower_Data
	if data then
		ent.Position = data.Position+data.Velocity*Isaac_Tower.GetProcentUpdate30()
		ent.Velocity = data.Velocity*Isaac_Tower.UpdateSpeed
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, ent)
	Isaac_Tower.EnemyPostUpdate_RealPosUpdate(ent)
end, IsaacTower_Enemy)

function Isaac_Tower.EnemyPostRender(_, ent, Pos, Offset, Scale)
	if ent.Variant ~= IsaacTower_Enemy then return end
	local data = ent:GetData().Isaac_Tower_Data
	local typ = data and data.Type
	if typ then
		--if data.GrabbedBy then
			Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, typ, ent, Pos, Offset, Scale)
		--end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.ENTITY_POSTRENDER, Isaac_Tower.EnemyPostRender, 1000)

Isaac_Tower.EnemyHandlers.FlayerCollision["_proj"] = function(fent, ent, EntData)
	if EntData.EntityCollision ~= EntityCollisionClass.ENTCOLL_NONE then
		if Isaac_Tower.FlayerHandlers.TryTakeDamage(fent, 0, 0, ent) then
			return true
		end
	end
end

function Isaac_Tower.ProjectileUpdate(_, ent)
	if not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
	if not ent:GetData().Isaac_Tower_Data then return end

	ent:GetData().Isaac_Tower_Data.StateFrame = ent:GetData().Isaac_Tower_Data.StateFrame or 0
	if ent.FrameCount > 0 then
		--ent.Velocity = ent.Velocity/Isaac_Tower.UpdateSpeed
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

		--data.Position = ent.Position
		--data.Velocity = ent.Velocity

		local collidedGrid = {}

		local indexs = {}

		if ent:GetData().TSJDNHC_GridColl>0 then
			for ia, k in pairs(data.GridPoints) do
				local grid = Isaac_Tower.GridLists.Solid:GetGrid(data.Position + Vector(0, 10) + data.Velocity + k[1])

				if grid then
					if Isaac_Tower.ShouldCollide(ent, grid) and not grid.OnlyUp then
						collidedGrid[grid] = collidedGrid[grid] or {}
					end
				end
				local obs = Isaac_Tower.GridLists.Obs:GetGrid(data.Position + Vector(0, 10) + data.Velocity + k[1])
				
				if obs and Isaac_Tower.ShouldCollide(ent, obs) then
					collidedGrid[obs] = collidedGrid[grid] or {}
				end
			end

			for ia, k in pairs(collidedGrid) do

				local hit = EnemyintersectAABB_X(ent, ia)

				if hit and hit.delta.X ~= 0 then
					--if not data.slopeRot --hit.Slope
					--	or ((data.Position.Y > hit.pos.Y or not data.slopeRot == sign(hit.delta.X))
					--		and data.slopeRot == sign(hit.delta.X)) then
						
						--ent.Position = Vector(ent.Position.X - hit.delta.X + ent.Velocity.X, ent.Position.Y)
					
						--if sign(ent.Velocity.X) == sign(hit.delta.X) then
						--	ent.Velocity = Vector(0, ent.Velocity.Y)
						--end
					--end
				end
			end

			for ia, k in pairs(collidedGrid) do
				local hitY = EnemyintersectAABB_Y(ent, ia)

				if hitY and hitY.delta.Y ~= 0 then
					--if hitY.SmoothUp then
					--	ent.Position = Vector(ent.Position.X, ent.Position.Y - hitY.delta.Y / math.max(1, (30 / math.abs(ent.Velocity.X)))) --10
					--else
					--	if hitY.delta.Y > 0.0 then
					--		hitY.delta.Y = math.max(0, hitY.delta.Y - 0.1 - ent.Velocity.Y)
					--	end
					--	ent.Position = ent.Position - Vector(0, hitY.delta.Y)
					--end
					--if hitY.SlopeAngle then
					--	data.slopeAngle = hitY.SlopeAngle
					--end
				end
			end
			--local prePosition = ent.Position / 1
			--ent.Position = ent.Position + ent.Velocity -- * Isaac_Tower.UpdateSpeed
		end
			data.TrueVelocity = data.Position - data.LastPosition
		
		data.StateFrame = data.StateFrame + 1
		
		if ent.EntityCollisionClass == 1 then
			for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
				local fent = Isaac_Tower.GetFlayer(i)
				local dist = fent and fent.Position:Distance(data.Position)
				if fent and dist < data.FlayerDistanceCheck then
					
					local box1 = {pos = data.Position, half = data.Half}
					local box2 = {pos = fent.Position, half = fent.Half}
					if Isaac_Tower.NoType_CheckAABB(box1, box2) then
						local result = Isaac.RunCallback(Isaac_Tower.Callbacks.FLAYER_PRE_COLLIDING_ENEMY, fent, ent)
						if result == nil and Isaac_Tower.EnemyHandlers.FlayerCollision[data.ColType or "_proj"] then
							result = Isaac_Tower.EnemyHandlers.FlayerCollision[data.ColType or "_proj"](fent, ent, data)
						end
						if result == true then
							Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.PROJECTILE_PRE_REMOVE, typ, ent)
							ent:Remove()
							return
						end
					end
				end
			end
		end

		Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.PROJECTILE_POST_UPDATE, typ, ent)
		data.Position = data.Position + data.Velocity
		data.LastPosition = ent.Position/1
	end)
	--ent.Velocity = ent.Velocity*Isaac_Tower.UpdateSpeed
	
	if not Isaac_Tower.GridLists.Solid:GetGrid(ent.Position) then
		ent:Remove()
	end
end
--mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Isaac_Tower.ProjectileUpdate, Isaac_Tower.ENT.Proj.VAR)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, ent)
	Isaac_Tower.EnemyPostUpdate_RealPosUpdate(ent)
end, Isaac_Tower.ENT.Proj.VAR)

function Isaac_Tower.ProjectilePostRender(_, ent, Pos, Offset, Scale)
	if ent.Variant ~= Isaac_Tower.ENT.Proj.VAR then return end
	local data = ent:GetData().Isaac_Tower_Data
	local typ = data and data.Type
	if typ then
		--if data.GrabbedBy then
			Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.PROJECTILE_POST_RENDER, typ, ent, Pos, Offset, Scale)
		--end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.ENTITY_POSTRENDER, Isaac_Tower.ProjectilePostRender, 1000)
---------------------------------------------------------------------------------------------------------------


--0 Обычные детальки
--100 Остаточное изображение
--101 Пот
--110 Звуковой хлопок
local GibsLogic
GibsLogic = {
	Init = {
		[Isaac_Tower.ENT.GibSubType.SWEET] = function(e)
			e:GetSprite():Load("gfx/effects/it_sweet.anm2",true)
			e:GetSprite():Play("drop", true)
			e.DepthOffset = 310
			e:GetData().Color = Color(1,1,1,1)
			e:Update()
		end,
		[Isaac_Tower.ENT.GibSubType.BLOOD] = function(e)
			GibsLogic.Init[101](e)
			e:GetSprite():Play("blood_drop")
		end,
		[Isaac_Tower.ENT.GibSubType.SECRETROOM_ENTER_EFFECT] = function(e)
			local spr = e:GetSprite()
			spr:Load("gfx/fakegrid/secretroom_enter.anm2",true)
			spr:Play("break", true)
			e:GetData().RA = true
			e.DepthOffset = 50
		end,
	},
	Update = {
		[Isaac_Tower.ENT.GibSubType.GIB] = function(e)
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
		[Isaac_Tower.ENT.GibSubType.AFTERIMAGE] = function(e)

		end,
		[Isaac_Tower.ENT.GibSubType.SWEET] = function(e)
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
				e:GetData().Isaac_Tower_Data.Position = e.Position
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
		[Isaac_Tower.ENT.GibSubType.BLOOD] = function (e)
			GibsLogic.Update[101](e)
			local spr = e:GetSprite()
			if spr:IsPlaying("kapsmol") then
				spr:Play("blood_kapsmol")
			elseif spr:IsPlaying("kap") then
				spr:Play("blood_kap")
			end
		end,
		[Isaac_Tower.ENT.GibSubType.SOUND_BARRIER] = function (e)
			if e:GetSprite():IsFinished(e:GetSprite():GetAnimation()) then
				e:Remove()
			end
		end,
		[Isaac_Tower.ENT.GibSubType.BONUS_EFFECT] = function(e)
			e.Velocity = e.Velocity * 0.95
			if e:GetSprite():IsFinished(e:GetSprite():GetAnimation()) then
				e:Remove()
			end
		end,
		[Isaac_Tower.ENT.GibSubType.SECRETROOM_ENTER_EFFECT] = function(e)
			local spr = e:GetSprite()
			if spr:GetFrame() == 7 then
				for i=1,5 do
					local f = Isaac.Spawn(1000,EffectVariant.HAEMO_TRAIL,0,e.Position+Vector(20+i*3-6,20+i*3-6),Vector(0,5),e)
					f.Color = Color(.5,.5,.6,1,.4,.15,.3)
					f:GetData().RA = true
					f.DepthOffset = 50
				end
			end
			if Isaac_Tower.RG and e.FrameCount % math.ceil((e.FrameCount+5)/3) == 0 then
				local null1 = Isaac_Tower.editor.GetNullLayer(spr,"плю1")
				local pos = null1 and null1:GetPos()
				if pos and null1:IsVisible() then
					local f = Isaac.Spawn(1000,EffectVariant.HAEMO_TRAIL,0,e.Position+pos*Wtr,Vector(0,5),e)
					f:GetSprite().Scale = Vector(.5,.5)
					f.Color = Color(.5,.5,.6,1-(e.FrameCount/50),.4,.15,.3)
					f:GetData().RA = true
					f.DepthOffset = 50
				end
				local null2 = Isaac_Tower.editor.GetNullLayer(spr,"плю2")
				local pos = null2 and null2:GetPos()
				if pos and null2:IsVisible() then
					local f = Isaac.Spawn(1000,EffectVariant.HAEMO_TRAIL,0,e.Position+pos*Wtr,Vector(0,5),e)
					f:GetSprite().Scale = Vector(.5,.5)
					f.Color = Color(.5,.5,.6,1-(e.FrameCount/50),.4,.15,.3)
					f:GetData().RA = true
					f.DepthOffset = 50
				end
			end
			if spr:IsFinished(spr:GetAnimation()) then
				e:Remove()
			end
		end,
	},
	Render = {
		[Isaac_Tower.ENT.GibSubType.AFTERIMAGE] = function(e)
			if Isaac_Tower.game:IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
			local data = e:GetData()
			if data.color then
				data.color.A = data.color.A-data.AlphaLoss*Isaac_Tower.UpdateSpeed
				e:GetSprite().Color = data.color
				if data.color.A <= 0 then
					e:Remove()
				end
			end
			if data.Increase then
				e:GetSprite().Scale = e:GetSprite().Scale + Vector(0.02, 0.02)*Isaac_Tower.UpdateSpeed
			end
		end,
		[Isaac_Tower.ENT.GibSubType.SWEET] = function(e)
			e.SpriteRotation = e.Velocity:GetAngleDegrees()
		end,
		[Isaac_Tower.ENT.GibSubType.BLOOD] = function(e)
			GibsLogic.Render[101](e)
		end,
		[Isaac_Tower.ENT.GibSubType.SOUND_BARRIER] = function(e)
			if Isaac_Tower.game:IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
			e:GetSprite():Update()
		end,
		---@param e EntityEffect
		[Isaac_Tower.ENT.GibSubType.BONUS_EFFECT2] = function(e)
			if Isaac_Tower.game:IsPaused() or not Isaac_Tower.InAction or Isaac_Tower.Pause then return end
			local col = Color(1,1,1, math.abs(e.FrameCount-8)/8 )
			e.Color = col
			local s = math.abs(e.FrameCount-30)/30
			e:GetSprite().Offset = e:GetData().offset/s-e:GetData().offset*2
			e:GetSprite().Scale = Vector(s,s)
			if e.FrameCount>8 then
				e:Remove()
			end
		end
	},

}
Isaac_Tower.ENT.GIBCalls = {}
function Isaac_Tower.ENT.GIBCalls.Init(e)
	if GibsLogic.Init[e.SubType] then
		GibsLogic.Init[e.SubType](e)
	end
end
function Isaac_Tower.ENT.GIBCalls.Update(e)
	if GibsLogic.Update[e.SubType] then
		GibsLogic.Update[e.SubType](e)
	end
	e.Position = Isaac_Tower.HandleUpdateSpeedPos(e.Position, e.Velocity)
end
function Isaac_Tower.ENT.GIBCalls.Render(e)
	if TSJDNHC_PT:IsCamRender() and GibsLogic.Render[e.SubType] then
		GibsLogic.Render[e.SubType](e)
	end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function (_,e)
	Isaac_Tower.ENT.GIBCalls.Init(e)
end)

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
	if e.FrameCount > 0 then
		e.Velocity = e.Velocity/Isaac_Tower.UpdateSpeed
	end
	Isaac_Tower.UpdateSpeedHandler(function()
		--if GibsLogic.Update[e.SubType] then
		--	GibsLogic.Update[e.SubType](e)
		--end
		--e.Position = Isaac_Tower.HandleUpdateSpeedPos(e.Position, e.Velocity)
		Isaac_Tower.ENT.GIBCalls.Update(e)
	end)
	e.Velocity = e.Velocity*Isaac_Tower.UpdateSpeed
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
	--if GibsLogic.Render[e.SubType] then
	--	GibsLogic.Render[e.SubType](e)
	--end
	Isaac_Tower.ENT.GIBCalls.Render(e)
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
--Isaac_Tower.Renders = {}
local tg = 0
local v26 = Vector(26,26)
local v0 = Vector(0,0)
local v40100 = Vector(-40,100)
function Isaac_Tower.Renders.PreGridRender(_, Pos, Offset, Scale)
	tg = Isaac.GetTime()
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

	-- 40x40 зона
	local startPosRender = modZer - v26 + (zeroOffset or v0)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26*modScale)), math.ceil(startPosRender.Y/(26*modScale)))
	local EndPosRender = modZer + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())*(math.max(1,modScale)) -- + (zeroOffset or Vector(0,0)) -- + Vector(26*2,26*2)
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26*modScale)), math.ceil(EndPosRender.Y/(26*modScale)))

	local startPos = -zer

	local RenderList = {}
	local list = Isaac_Tower.GridLists.Evri 
	for layer, gridlist in pairs(list) do  --Спрайты с эффектом параллакса не оптимизируются, мне лень
		if layer ~= "List" then
			RenderList[layer] = RenderList[layer] or {}
			if type(layer) == "string" or layer>-2 and layer<2 then
				for y=math.min(EndPosRenderGrid.Y-1, Isaac_Tower.GridLists.Solid.Y-1), math.max(0,StartPosRenderGrid.Y-1),-1 do
					for x=math.max(0,StartPosRenderGrid.X-1), math.min(EndPosRenderGrid.X-1, Isaac_Tower.GridLists.Solid.X-1) do
						local tab = gridlist[y] and gridlist[y][x]
						if tab and tab.Ps then
							local ps = tab.Ps
							--RenderList[layer] = RenderList[layer] or {}
							for id in pairs(tab.Ps) do
							--for id=1, #ps do
								--local da = ps[id]
								RenderList[layer][id] = id
							end
						end
					end
				end
			else
				for y=Isaac_Tower.GridLists.Solid.Y, 0, -1 do
					for x=-1, Isaac_Tower.GridLists.Solid.X do
						local tab = gridlist[y] and gridlist[y][x]
						if tab and tab.Ps then
							--RenderList[layer] = RenderList[layer] or {}
							local ps = tab.Ps
							for id in pairs(tab.Ps) do
							--for id=1, #ps do
								RenderList[layer][id] = id
							end
						end
					end
				end
			end
		end
	end

	-- 20x20 зона
	local startPosRender = modZer - v26 + (zeroOffset or v0)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(13*modScale)), math.ceil(startPosRender.Y/(13*modScale)))
	local EndPosRender = modZer + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())*(math.max(1,modScale)) -- + (zeroOffset or Vector(0,0)) -- + Vector(26*2,26*2)
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(13*modScale)), math.ceil(EndPosRender.Y/(13*modScale)))

	local Bonuslist = {}
	if Isaac_Tower.GridLists.Bonus.Ref then
		local reftab = Isaac_Tower.GridLists.Bonus.Ref
		local gridlist = Isaac_Tower.GridLists.Bonus.Grid
		--print(Isaac_Tower.GridLists.Bonus.Ref and #Isaac_Tower.GridLists.Bonus.Ref)
		--print(math.min(EndPosRenderGrid.Y, Isaac_Tower.GridLists.Solid.Y*2), math.max(1,StartPosRenderGrid.Y))
		--print(math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.GridLists.Solid.X*2))
		if #Isaac_Tower.GridLists.Bonus.Ref > 100 then
			local layer = Bonuslist
			local max = 0
			local ignore = {}
			for y=math.min(EndPosRenderGrid.Y-1, Isaac_Tower.GridLists.Solid.Y*2-1), math.max(0,StartPosRenderGrid.Y),-1 do
				for x=math.max(0,StartPosRenderGrid.X-1), math.min(EndPosRenderGrid.X-1, Isaac_Tower.GridLists.Solid.X*2+1) do
					local tab = gridlist[y] and gridlist[y][x]
					if tab then
						if tab.Sprite then
							--layer = layer or {}
							if not ignore[tab.Ref] then
								layer[#layer+1] = reftab[tab.Ref] --tab.Ref
								ignore[tab.Ref] = true
							end
						elseif tab.Parent then
							tab = tab.Parent
							if not ignore[tab.Ref] then
								layer[#layer+1] = reftab[tab] --tab.Parent
								ignore[tab.Ref] = true
							end
						end
					end
				end
			end
		else
			Bonuslist = Isaac_Tower.GridLists.Bonus.Ref
		end
	end

	local minindex,maxindex = 0,0
	local tab = {}
	--local num = 0
	for layer, gridlist in pairs(RenderList) do
		tab[layer] = tab[layer] or {}
		for i,k in pairs(gridlist) do
			tab[layer][#tab[layer]+1] = k
			--num = num + 1
		end
		table.sort(tab[layer])
		if type(layer) == "number" then
			minindex = math.min(minindex, layer)
			maxindex = math.max(maxindex, layer)
		end
	end
	--print(num)
	--table.sort(tab)
	tab.Bonus = Bonuslist
	Isaac_Tower.Renders.EnviRender = tab
	Isaac_Tower.Renders.EnviMaxLayer = maxindex
	Isaac_Tower.Renders.EnviMinLayer = minindex

	if minindex<0 then
		--for layer,gridlist in pairs(tab) do
		for layer=minindex,-1 do
			local gridlist = tab[layer]
			if gridlist then
				--for i,k in pairs(gridlist) do
				for i=0,#gridlist do
					local k = gridlist[i]
					local obj = Isaac_Tower.GridLists.Evri.List[k]
					if obj then
						local pos -- = obj.pos*Scale + startPos
						if Scale ~= 1 then
							--local scaledOffset = ((Scale-1)*obj.pos) or Vector(0,0) ---obj.pos
							pos = obj.pos*Scale + startPos -zeroOffset --+ vec

						else
							pos = obj.pos + startPos
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
			for i=0,#gridlist do --,k in pairs(gridlist) do
				local k = gridlist[i]
				local obj = Isaac_Tower.GridLists.Evri.List[k]
				if obj then
					local pos = obj.pos*Scale + startPos
					if Scale ~= 1 then
						--local scaledOffset = (Scale*obj.pos-obj.pos) or Vector(0,0)
						pos = pos -zeroOffset --+ vec + scaledOffset
					--end
					--if Scale ~= 1 then
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

	local bonuslist = Isaac_Tower.Renders.EnviRender.Bonus
	if bonuslist then
		for i=1,#bonuslist do    --,k in pairs(bonuslist) do
			local k = bonuslist[i]
			local grid = k[2]
			if Scale ~= 1 then
				--local scaledOffset = (Scale*obj.pos-obj.pos) or Vector(0,0)
				local pos = grid.RenderPos*Scale + startPos -zeroOffset --+ vec + scaledOffset
			--end
			--if Scale ~= 1 then
				local preScale = grid.Sprite.Scale/1
				grid.Sprite.Scale = grid.Sprite.Scale*Scale
				grid.Sprite:Render(pos)
				grid.Sprite.Scale = preScale
			else
				grid.Sprite:Render(grid.RenderPos*Scale + startPos)
			end
			grid.Sprite:Update()
			Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.BONUSPICKUP_RENDER, grid.Type, grid)
		end
	end

	Isaac_Tower.GridLists.Obs:Render(Offset, Scale)
end
mod:AddCallback(TSJDNHC_PT.Callbacks.GRID_BACKDROP_RENDER, Isaac_Tower.Renders.PostGridRender)

function Isaac_Tower.Renders.FakeLayerRender(_, Pos, Offset, Scale)
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end

	local zero = Isaac.WorldToRenderPosition(v40100)
	local startPos = (Offset + zero)
	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	end
	--if Isaac_Tower.Renders.EnviMaxLayer>0 then
		--for layer=1,Isaac_Tower.Renders.EnviMaxLayer do
			local gridlist = Isaac_Tower.Renders.EnviRender["fake"]
			if gridlist then
				--for i,k in pairs(gridlist) do
				for i=0,#gridlist do
					local k = gridlist[i]
					local obj = Isaac_Tower.GridLists.Evri.List[k]
					if obj and obj.spr.Color.A>0 then
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
							obj.spr:Render(pos)
						end
					end
				end
			end
		--end
	--end
	local gridlist = Isaac_Tower.Renders.EnviRender[1]
	if gridlist then
		--if layer==0 then
			for i=0,#gridlist do --,k in pairs(gridlist) do
				local k = gridlist[i]
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
mod:AddCallback(TSJDNHC_PT.Callbacks.ISAAC_TOWER_POST_ALL_ENEMY_RENDER, Isaac_Tower.Renders.FakeLayerRender)

function Isaac_Tower.Renders.PostAllEntityRender(_, Pos, Offset, Scale)
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end

	local zero = Isaac.WorldToRenderPosition(v40100)
	local startPos = (Offset + zero)
	local zeroOffset
	if Scale ~= 1 then
		zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	end

	local gridlist = Isaac_Tower.Renders.EnviRender[2]
	if gridlist then
		--if layer==0 then
			for i=0,#gridlist do --,k in pairs(gridlist) do
				local k = gridlist[i]
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

	--for layer,gridlist in pairs(Isaac_Tower.Renders.EnviRender) do
	if Isaac_Tower.Renders.EnviMaxLayer>2 then
		for layer=3,Isaac_Tower.Renders.EnviMaxLayer do
			local gridlist = Isaac_Tower.Renders.EnviRender[layer]
			if gridlist then
				--for i,k in pairs(gridlist) do
				for i=0,#gridlist do
					local k = gridlist[i]
					local obj = Isaac_Tower.GridLists.Evri.List[k]
					if obj then
						local pos = obj.pos*Scale + startPos
						if Scale ~= 1 then
							--local scaledOffset = (Scale*obj.pos-obj.pos) or Vector(0,0)
							pos = pos -zeroOffset --+ vec
						end
						if Scale ~= 1 then
							local off = ((layer-2)/20*(Offset/Scale+Isaac_Tower.GridLists.Solid.RenderCenterPos))
							local preScale = obj.spr.Scale/1
							obj.spr.Scale = obj.spr.Scale*Scale
							obj.spr:Render(pos+off)
							obj.spr.Scale = preScale
						else
							local off = ((layer-2)/20*(Offset+Isaac_Tower.GridLists.Solid.RenderCenterPos))
							obj.spr:Render(pos+off)
						end
						--obj.spr:Render(pos)
						--Isaac.RenderScaledText(tostring(pos), pos.X, pos.Y, 0.5, 0.5, 1,1,1,1)
					end
				end
			end
		end
	end
	--print(Isaac.GetTime()-tg)
	--Isaac_Tower.font:DrawStringUTF8(Isaac.GetTime()-tg,130,80,KColor(1,1,1,1),1,true)
end
mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, Isaac_Tower.Renders.PostAllEntityRender)

function Isaac_Tower.Renders.HUDRender()
	if not Isaac_Tower.InAction and not (Isaac_Tower.GridLists and Isaac_Tower.GridLists.Solid) then return end

	if Isaac_Tower.ScoreHandler.Active then
		Isaac_Tower.ScoreHandler.Render(Isaac_Tower.ScoreHandler.RenderPos)
		--Isaac_Tower.ScoreHandler.RenderTextArray(Isaac_Tower.ScoreHandler.RenderPos)
		Isaac_Tower.ScoreHandler.UpdateTextArray()
	end

	Isaac_Tower.DebugMenu()
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, Isaac_Tower.Renders.HUDRender)



local background = {
	spr = Sprite(),
	size = Vector(100,100),
	visible = true,
	scrollX = true,
	scrollY = true,
	distancing = 2,
}
background.spr:Load("gfx/backgrounds/background.anm2",true)
background.spr:Play(1)

Isaac_Tower.Backgroung = {
	Data = {background}, List = {}, types = {}, sort = {},
}

function Isaac_Tower.Backgroung.SetBG(name)
	local data, sort = Isaac_Tower.Backgroung.GetBackgroung(name)
	Isaac_Tower.Backgroung.Data = data or Isaac_Tower.Backgroung.Data
	Isaac_Tower.Backgroung.List = sort or Isaac_Tower.Backgroung.List
end

function Isaac_Tower.Backgroung.SetBGGfx(gfx, size)
	background.spr:ReplaceSpritesheet(0,gfx)
	background.spr:LoadGraphics()
	background.size = size
	background.size.X = background.size.X == 0 and 1 or background.size.X
	background.size.Y = background.size.Y == 0 and 1 or background.size.Y
end
function Isaac_Tower.Backgroung.SetBGVisible(bol)
	background.visible = bol
end

function Isaac_Tower.Backgroung.AddBackgroung(name, data)
	if name then
		--table.sort(data, function()   end)
		Isaac_Tower.Backgroung.types[name] = data
		Isaac_Tower.Backgroung.sort[name] = {}
		for i=1,#data do
			local sloi = data[i]
			if not sloi.sortlayer then
				local tab = SafePlacingTable(Isaac_Tower.Backgroung.sort[name],-1)
				tab[#tab+1] = sloi
			elseif sloi.sortlayer then
				local tab = SafePlacingTable(Isaac_Tower.Backgroung.sort[name],sloi.sortlayer)
				tab[#tab+1] = sloi
			end
		end
	end
end
function Isaac_Tower.Backgroung.GetBackgroung(name)
	return Isaac_Tower.Backgroung.types[name], Isaac_Tower.Backgroung.sort[name]
end


function Isaac_Tower.Backgroung.standart_render(background, _, Offset, Scale)
	--local zero = Isaac.WorldToRenderPosition(v40100)
	--local startPos = (Offset + zero)
	--local zeroOffset = BDCenter*(Scale-1) +GridListStartPos*(1-Scale) ---BDCenter
	
	--Offset = -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition + Isaac.WorldToRenderPosition(v40100)*(Scale-1)
	local bSe = background.distancing
	--local BScale = Scale
	Scale = 1-1/bSe + Scale/bSe

	local w,h = ScrenX,ScrenY   --Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
	local start = Vector(ScrenX,ScrenY)/2*(Scale-1)
	if background.pos then
		start = start - background.pos
	end
	
	--Offset = -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition -- Vector(ScrenX,ScrenY)*(Scale-1)
	if background.spr then
		local oldScale = background.spr.Scale/1
		background.spr.Scale = background.spr.Scale * Scale

		local x, y = math.ceil(w/background.size.X/Scale) + 1, math.ceil(h/background.size.Y/Scale) + 1
		local off = Vector(Offset.X%(background.size.X*bSe), Offset.Y%(background.size.Y*bSe))/bSe * Scale
		for i=-1, x do
			for j=-1, y do
				local rpos = Vector(i*background.size.X-1, j*background.size.Y-1)*Scale + off - background.size*Scale - start  --Vector(background.size,background.size)
				rpos = rpos - Isaac_Tower.game.ScreenShakeOffset*0.5
				--background.spr.Scale = Vector(Scale, Scale)
				background.spr:Render(rpos)
			end
		end
		background.spr.Scale = oldScale
	end
	if background.func then
		background.func(background, Offset, Scale)
	end
end
function Isaac_Tower.Backgroung.updown_render(background, _, Offset, Scale)
	local bSe = background.distancing
	Scale = 1-1/bSe + Scale/bSe

	local w,h = ScrenX,ScrenY
	local start = Vector(ScrenX,ScrenY)/2*(Scale-1)
	if background.pos then
		start = start - background.pos
	end
	if background.spr then
		local oldScale = background.spr.Scale/1
		background.spr.Scale = background.spr.Scale * Scale

		local x = math.ceil(w/background.size.X/Scale) + 1 --, math.ceil(h/background.size.Y/Scale) + 1
		local off = Vector(Offset.X%(background.size.X*bSe), Offset.Y%(background.size.Y*bSe))/bSe * Scale
		for i=-1, x do

			local rpos = Vector(i*background.size.X-1, background.size.Y)*Scale + off - background.size*Scale - Vector(start.X,0)
			rpos = rpos - Isaac_Tower.game.ScreenShakeOffset*0.5
			--background.spr.Scale = Vector(Scale, Scale)
			background.spr:RenderLayer(background.updown[1], rpos)
			local rpos = Vector(i*background.size.X-1, h/Scale+background.size.Y)*Scale + off - background.size*Scale - Vector(start.X,0)
			rpos = rpos - Isaac_Tower.game.ScreenShakeOffset*0.5
			--background.spr.Scale = Vector(Scale, Scale)
			background.spr:RenderLayer(background.updown[2], rpos)
		end
		background.spr.Scale = oldScale
	end
	if background.func then
		background.func(background, Offset, Scale)
	end
end
function Isaac_Tower.Renders.early_backgroung_render(_, Pos, _, Scale)
	if Isaac_Tower.Backgroung.Data then
		local actPos = -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition
		if Isaac_Tower.Backgroung.List then 
			if Isaac_Tower.Backgroung.List[-1] then
				for i=1, #Isaac_Tower.Backgroung.List[-1] do
					local bg = Isaac_Tower.Backgroung.List[-1][i]
					if bg.updown then
						local Offset = Vector(actPos.X, 0)
						Isaac_Tower.Backgroung.updown_render(bg, Pos, Offset, Scale)
					else
						local Offset = Vector(bg.scrollX and actPos.X or 0, bg.scrollY and actPos.Y or 0)
						Isaac_Tower.Backgroung.standart_render(bg, Pos, Offset, Scale)
					end
				end
			end
		else
			for i=1, #Isaac_Tower.Backgroung.Data do
				local bg = Isaac_Tower.Backgroung.Data[i]
				if bg.updown then
					local Offset = Vector(actPos.X, 0)
					Isaac_Tower.Backgroung.updown_render(bg, Pos, Offset, Scale)
				else
					local Offset = Vector(bg.scrollX and actPos.X or 0, bg.scrollY and actPos.Y or 0)
					Isaac_Tower.Backgroung.standart_render(bg, Pos, Offset, Scale)
				end
			end
		end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.PRE_BACKDROP_RENDER, Isaac_Tower.Renders.early_backgroung_render)

function Isaac_Tower.Renders.Above_backgroung_render(_, Pos, _, Scale)
	if Isaac_Tower.Backgroung.Data then
		local actPos = -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition
		if Isaac_Tower.Backgroung.List then 
			if Isaac_Tower.Backgroung.List[2] then
				for i=1, #Isaac_Tower.Backgroung.List[2] do
					local bg = Isaac_Tower.Backgroung.List[2][i]
					if bg.updown then
						local Offset = Vector(actPos.X, 0)
						Isaac_Tower.Backgroung.updown_render(bg, Pos, Offset, Scale)
					else
						local Offset = Vector(bg.scrollX and actPos.X or 0, bg.scrollY and actPos.Y or 0)
						Isaac_Tower.Backgroung.standart_render(bg, Pos, Offset, Scale)
					end
				end
			end
		end
	end
end
mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, Isaac_Tower.Renders.Above_backgroung_render)


--function Isaac_Tower.Renders.BonusPickupRender(_, Pos, Offset, Scale)

--end


do  --Конец файла, хорошее место для этого
	Isaac_Tower.TileData = { TileSets = {}, EditorData = {}}
	function Isaac_Tower.TileData.AddTileSet(name, data)
		if not name then error("[1] is not a string",2) end
		if type(data) ~= "table" then error("[2] is not a table",2) end
		if not data.Anm2 then error('"Anm2" field is empty',2) end

		local tab = {}
		tab.name_1x1 = data.MainMapGridSuffix
		tab.size = data.Size or Vector(1,1)
		tab.affected = data.AffectedAnimaions or {"1","2","3","4","5","6","7","8","9"}
		tab.extra = data.ExtraAnimSuffix or {}
		tab.anm2 = data.Anm2 --or 'gfx/fakegrid/grid2.anm2'
		tab.gfx = data.Gfx
		tab.Replaces = data.Replaces
		--[[for tile, list in pairs(data.Replaces) do
			tab.Replaces[tile] = {}
			for i,k in pairs(list) do
				tab.Replaces[tile][k] = 0.2
			end
		end]]

		Isaac_Tower.TileData.TileSets[name] = tab

		local tab = {}
		tab.EditorImage = data.EditorImage
		tab.Anm2 = data.EditorAnm2
		--[[tab.Replaces = {} --data.Replaces
		for tile, list in pairs(data.Replaces) do
			tab.Replaces[tile] = {}
			for i,k in pairs(list) do
				tab.Replaces[tile][k] = 0.2
			end
		end]]
		--local GridTypesList = {}
		--for i=1,#data.EditorGridTypesList do
		--	GridTypesList[data.EditorGridTypesList[i]] = true
		--end
		tab.GridTypesList = data.EditorGridTypesList
		tab.ExtraAnims = data.EditorHidedList

		Isaac_Tower.TileData.EditorData[name] = tab
	end

	function Isaac_Tower.TileData.GetTileSetData(name)
		return Isaac_Tower.TileData.TileSets[name]
	end
end

-----------------------------------------------------------------------------------------------------

Isaac_Tower.DebugFlag = 0
function Isaac_Tower.debug(num)
	Isaac_Tower.DebugFlag = Isaac_Tower.DebugFlag ~ 2^(num-1)
end
function Isaac_Tower.isdebug(num)
	return Isaac_Tower.DebugFlag & 2^(num-1) ~= 0
end


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
				Isaac.RenderText(math.ceil(grid.Index), renderPos.X, renderPos.Y, 1,1,1,0.3)
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
		---@type Flayer
		local fent = d.Isaac_Tower_Data
		local fentPos = Isaac.WorldToRenderPosition(fent.Position) + Offset
		for i,k in pairs(fent.GridPoints) do
			GridCollPoint:Render(fentPos + (Vector(0,12) + k[1])/1.54 ) --+ Offset
		end
		for i,k in pairs(fent.InsideGridPoints) do
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
	for i, ent in pairs(Isaac.FindByType(1000, Isaac_Tower.ENT.Proj.VAR,-1)) do
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

local debugtext = {}
function Isaac_Tower.DebugRenderText(text, pos, time)
	if text and pos then
		debugtext[#debugtext+1] = {tostring(text), pos, time or 5}
	end
end


mod:AddCallback(TSJDNHC_PT.Callbacks.OVERLAY_BACKDROP_RENDER, function(_, Pos, Offset, Scale)
	if Isaac_Tower.isdebug(1) then
		for i=0, game:GetNumPlayers()-1 do
			local fent = Isaac_Tower.GetFlayer(i)
			local pos = TSJDNHC_PT:WorldToScreen(fent.Position)

			GridCollPoint:Render(pos)
		end
	end

	if Isaac_Tower.isdebug(2) then
		for i=0, game:GetNumPlayers()-1 do
			local fent = Isaac_Tower.GetFlayer(i)
			local pos = TSJDNHC_PT:WorldToScreen(fent.Position)

			font:DrawStringScaledUTF8(fent.State, pos.X, pos.Y+10, .5, .5, KColor(1,1,1,1))
			font:DrawStringScaledUTF8(fent.Flayer and fent.Flayer.CurrentSpr:GetAnimation() or "", pos.X, pos.Y+20, .5, .5, KColor(1,1,1,1))

			font:DrawStringScaledUTF8(string.format("%.2f",tostring(fent.Velocity.X)), pos.X-15, pos.Y+30, .5, .5, KColor(1,1,1,1))
			font:DrawStringScaledUTF8(string.format("%.2f",tostring(fent.Velocity.Y)), pos.X+15, pos.Y+30, .5, .5, KColor(1,1,1,1))

			font:DrawStringScaledUTF8(fent.RunSpeed, pos.X, pos.Y+40, .5, .5, KColor(1,1,1,1))
		end
	end


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
	if #debugtext > 0 then
		for i = #debugtext, 1, -1 do
			local tab = debugtext[i]
			if tab and tab[1] and tab[2] then
				font:DrawStringUTF8(tab[1], tab[2].X, tab[2].Y, KColor(1,1,1,1))
			else
				debugtext[i] = nil
				goto skip
			end
			if tab[3] and tab[3]>0 then
				tab[3] = tab[3] - 1
			else
				debugtext[i] = nil
			end
			::skip::
		end
	end
end)

do
	local MouseIsMoved = false
	local oldMousePos = 0
	local mousedalay = 0
	local menuOffset = 0

	function Isaac_Tower.DebugMenu()
		
		if not Isaac_Tower.game:IsPaused() and Isaac_Tower.inDebugVer then
			local pos = Isaac.WorldToScreen(Input.GetMousePosition(true))-Isaac_Tower.game.ScreenShakeOffset
			local check = pos.X+pos.Y
			if oldMousePos ~= check then
				oldMousePos = check
				MouseIsMoved = true
				mousedalay = 60
				--menuOffset = 0
			end
			mousedalay = math.max(0,mousedalay-1)
			if mousedalay<=0 then
				MouseIsMoved = false
				menuOffset = menuOffset * 0.9 + 55 * 0.1
			else
				menuOffset = menuOffset * 0.9
			end

			if MouseIsMoved or menuOffset ~= 0 then
				Isaac_Tower.editor.DebugMenu.Render(-menuOffset, pos)
			end
		end

	end

end

-----------------------------------------------------------------------------------------------------

local movement = include("flayerMovement")
movement(mod, Isaac_Tower)

local editor = include("room_editor")
editor(mod, Isaac_Tower)

local init = include("IT_init")
init(mod, Isaac_Tower)

if Isaac_Tower.RG then
	local rgon = include("rgon")
	rgon(mod, Isaac_Tower)
end

local rooms = {
	--"rooms.test",
	"rooms.debugroom",
	"rooms.tutorial",
}

for _, room in pairs(rooms) do
	local module = include(room)
	module(mod, Isaac_Tower)
end

print("Isaac Tower: v.Dev Loaded")

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