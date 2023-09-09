return function(mod) --, Isaac_Tower)

local Isaac = Isaac
local string = string
local Vector = Vector

local function utf8_Sub(str, x, y)
	local x2, y2
	x2 = utf8.offset(str, x)
	if y then
		y2 = utf8.offset(str, y + 1)
		if y2 then
			y2 = y2 - 1
		end
	end
	if x2 == nil then error("bad argument #2 to 'sub' (position is not correct)",2) end
	return string.sub(str, x2, y2)
end

local function GenSprite(gfx,anim,frame)
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

local function TabDeepCopy(tbl)
    local t = {}
	if type(tbl) ~= "table" then error("[1] is not a table",2) end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            t[k] = TabDeepCopy(v)
        else
            t[k] = v
        end
    end

    return t
end

local function CopySprite(spr)
	local newSpr = Sprite()
	newSpr:Load(spr:GetFilename(), true)
	newSpr:Play(spr:GetAnimation())
	return newSpr
end

local sizecache = {}

local function GetLinkedGrid(grid, pos, size, fill)
	if size.X then
		if sizecache[size.X .. "," .. size.Y] then
			size = sizecache[size.X .. "," .. size.Y]
		else
			local tab = {}
			for i=1, size.X do
				for j=1, size.Y do
					tab[#tab+1] = {i-1,j-1}
				end
			end
			sizecache[size.X .. "," .. size.Y] = tab
			size = tab
		end
	end
	if size and pos then
		local tab = {}
		local Sx,Sy = pos.X,pos.Y
		for i,k in pairs(size) do
			local Hasgrid = grid[Sy+k[2] ] and grid[Sy+k[2] ][Sx+k[1] ]
			if Hasgrid or fill then
				tab[#tab+1] = {Sy+k[2], Sx+k[1]}
			end
		end
		return tab
	end
end

local function CheckEmpty(grid, pos, size)
	if size.X then
		if sizecache[size.X .. "," .. size.Y] then
			size = sizecache[size.X .. "," .. size.Y]
		else
			local tab = {}
			for i=1, size.X do
				for j=1, size.Y do
					tab[#tab+1] = {i-1,j-1}
				end
			end
			sizecache[size.X .. "," .. size.Y] = tab
			size = tab
		end
	end
	if grid and size and pos then
		local Sx,Sy = pos.X,pos.Y
		for i,k in pairs(size) do
			local Hasgrid = grid[Sy+k[2]] and grid[Sy+k[2]][Sx+k[1]]
			if Hasgrid then
				return false
			end
		end
	end
	return true
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

---made by skykittenpuppy
local function DrawStringScaledBreakline(Font, String, PositionX, PositionY, ScaleX, ScaleY, RenderColor, BoxWidth, Allign)
    BoxWidth = BoxWidth or 0
    Allign = Allign or "Left"
    if BoxWidth ~= 0 then
        local spaceLeft = BoxWidth
        local words = {}
        for word in string.gmatch(String, '([^ ]+)') do --Split string into individual words
            words[#words+1] = word;
        end
        String = ""
        for i=1, #words do
            local wordLength = Font:GetStringWidthUTF8(words[i])*ScaleX
            if (words[i] == "\n") then --Word is purely breakline
                String = String.."\n"
            elseif (utf8_Sub(words[i], 1, 2) == "\n") then --Word starts with breakline
                spaceLeft = BoxWidth - wordLength
                String = String..words[i].." "
            elseif (wordLength > spaceLeft) then --Word breaks text boundary
                spaceLeft = BoxWidth - wordLength
                String = String.."\n"..words[i].." "
            else --Word is fine
                spaceLeft = spaceLeft - wordLength
                String = String..words[i].." "
            end
        end
    end
    local Center = false
    if Allign == "Left" then
        BoxWidth = 0
    elseif Allign == "Center" then
        BoxWidth = 2
        Center = true
    end
    local line = 0
    for word in string.gmatch(String, '([^\n]+)') do
        Font:DrawStringScaledUTF8(word, PositionX-(Allign == "Center" and 1 or 0), PositionY+(line*Font:GetLineHeight()*ScaleY), ScaleX, ScaleY, RenderColor, BoxWidth, Center)
        line = line + 1
    end
end

local function NaitiMezdy(ar1,ar2,ar3,ar4)
	ar1,ar2,ar3,ar4 = Vector(ar1[1],ar1[2]),Vector(ar2[1],ar2[2]),Vector(ar3[1],ar3[2]),Vector(ar4[1],ar4[2])
	local minv,maxv = Vector(100000000,10000000), Vector(0,0)
	--::retu::
	for i,k in pairs({ar1,ar2,ar3,ar4}) do
		if k.X<minv.X then
			minv.X=k.X
		end
		if k.Y<minv.Y then
			minv.Y=k.Y
		end
		if k.X>maxv.X then
			maxv.X=k.X
		end
		if k.Y>maxv.Y then
			maxv.Y=k.Y
		end
	end
	local retu = {}
	for i=minv.X,maxv.X do
		for j=minv.Y,maxv.Y do
			retu[#retu+1] = {i,j}
		end
	end
	return retu
end



Isaac_Tower.editor = {}
Isaac_Tower.editor.InEditor = false
Isaac_Tower.editor.Memory = { CurrentRoom = {}, LastRoom = {}, Changes = {}, Ver = {}, }
Isaac_Tower.editor.GridTypes = {}
Isaac_Tower.editor.GridAnimNames = {}

Isaac_Tower.editor.ObsTypes = {}
Isaac_Tower.editor.ObsAnimNames = {}

Isaac_Tower.editor.SpecialTypes = {}
--Isaac_Tower.editor.SpecialSpriteTab = {}

function Isaac_Tower.editor.ConvertCurrentRoomToEditor()
	Isaac_Tower.editor.Memory.CurrentRoom = nil
	--[[Isaac_Tower.editor.Memory.CurrentRoom = {
		Name = Isaac_Tower.CurrentRoom.Name,
		Size = Vector(Isaac_Tower.GridLists.Solid.X, Isaac_Tower.GridLists.Solid.Y),
		DefSpawnPoint = Vector(Isaac_Tower.CurrentRoom.DefSpawnPoint.X, Isaac_Tower.CurrentRoom.DefSpawnPoint.Y),
		solidGfx = Isaac_Tower.GridLists.Solid.dgfx,
		Solid = {
			--dgfx =  Isaac_Tower.GridLists.Solid.dgfx,
			--animNum = Isaac_Tower.GridLists.Solid.animNum,
			--extraAnim
		},
		Obs = {},
		Special = {},
		SpecialSpriteTab = {},
	}
	for y, ytab in ipairs(Isaac_Tower.GridLists.Solid.Grid) do
		for x, grid in pairs(ytab) do
			if grid.EditorType and Isaac_Tower.editor.GridTypes.Grid[grid.EditorType] then
				Isaac_Tower.editor.Memory.CurrentRoom.Solid[y] = Isaac_Tower.editor.Memory.CurrentRoom.Solid[y] or {}
				Isaac_Tower.editor.Memory.CurrentRoom.Solid[y][x] = {
					sprite = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].trueSpr,
					type = grid.EditorType,
					info = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].info,
					--trueSpr = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].spr,
				}
			end
		end
	end
	for y, ytab in ipairs(Isaac_Tower.GridLists.Obs.Grid) do
		for x, grid in pairs(ytab) do
			if grid.EditorType and Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType] then
				Isaac_Tower.editor.Memory.CurrentRoom.Obs[y+1] = Isaac_Tower.editor.Memory.CurrentRoom.Obs[y+1] or {}
				Isaac_Tower.editor.Memory.CurrentRoom.Obs[y+1][x+1] = {
					sprite = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].trueSpr,
					type = grid.EditorType,
					info = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].info,
					--trueSpr = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].spr,
				}
			end
		end
	end

	local pGrid = Isaac_Tower.editor.GridTypes.Special["spawnpoint_def"]
	local defspawn = Isaac_Tower.CurrentRoom.DefSpawnPoint - Vector(-40,100) --math.ceil
	defspawn = 	Vector(math.ceil(defspawn.X/40),math.ceil(defspawn.Y/40))
	Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"] = Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"] or {}
	Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y] = Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y] or {}
	Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y][defspawn.X] = {info = pGrid.info, type = "spawnpoint_def", pos = Vector(defspawn.X*26/2,defspawn.Y*26/2), XY = Vector(defspawn.X,defspawn.Y)}
	local index = tostring(math.ceil(defspawn.X)) .. "." .. tostring(math.ceil(defspawn.Y)) --(defspawn.Y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + defspawn.X
	local info = function() return Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y][defspawn.X] end
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab["spawnpoint_def"] = {}
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab["spawnpoint_def"][index] = {spr = pGrid.trueSpr, pos = Vector(defspawn.X*26/2, 26*defspawn.Y/2), info = info}
	]]
	
	local roomdata = Isaac_Tower.Rooms[Isaac_Tower.CurrentRoom.Name]

	Isaac_Tower.editor.Memory.CurrentRoom = {
		Name = Isaac_Tower.CurrentRoom.Name,
		Size = roomdata.Size/1,
		DefSpawnPoint = roomdata.DefSpawnPoint/1,
		solidGfx = roomdata.SolidList.gfx,
		Solid = {},
		Obs = {},
		Enemies = {},
		Bonus = {},
		Special = {},
		SpecialSpriteTab = {},
		Envi = {},
		Enemy = {},
		SolidFake = {},
	}
	for y, grid in ipairs(roomdata.SolidList) do
		Isaac_Tower.editor.Memory.CurrentRoom.Solid[grid.pos.Y] = Isaac_Tower.editor.Memory.CurrentRoom.Solid[grid.pos.Y] or {}
		Isaac_Tower.editor.Memory.CurrentRoom.Solid[grid.pos.Y][grid.pos.X] = {
			sprite = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].trueSpr,
			type = grid.EditorType,
			info = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].info,
		}
		local pGrid = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType]
		local list = Isaac_Tower.editor.Memory.CurrentRoom.Solid
		local x,y = grid.pos.X,grid.pos.Y
		if pGrid.size then
			for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
				--if not list[k[1]] then
				--	list[k[1]] = {}
				--end
				--if not list[k[1]][k[2]] then
				--	list[k[1]][k[2]] = {}
				--end
				--list[k[1]][k[2]].Parent = Vector(x,y)
				SafePlacingTable(list,k[1],k[2]).Parent = Vector(x,y)
			end
		end
	end
	if roomdata.SolidFakeList then
		for y, grid in ipairs(roomdata.SolidFakeList) do
			Isaac_Tower.editor.Memory.CurrentRoom.SolidFake[grid.pos.Y] = Isaac_Tower.editor.Memory.CurrentRoom.SolidFake[grid.pos.Y] or {}
			Isaac_Tower.editor.Memory.CurrentRoom.SolidFake[grid.pos.Y][grid.pos.X] = {
				sprite = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].trueSpr,
				type = grid.EditorType,
				info = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType].info,
			}
			local pGrid = Isaac_Tower.editor.GridTypes.Grid[grid.EditorType]
			local list = Isaac_Tower.editor.Memory.CurrentRoom.SolidFake
			local x,y = grid.pos.X,grid.pos.Y
			if pGrid.size then
				for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
					SafePlacingTable(list,k[1],k[2]).Parent = Vector(x,y)
				end
			end
		end
	end
	for y, grid in ipairs(roomdata.ObsList) do
		Isaac_Tower.editor.Memory.CurrentRoom.Obs[grid.pos.Y+1] = Isaac_Tower.editor.Memory.CurrentRoom.Obs[grid.pos.Y+1] or {}
		Isaac_Tower.editor.Memory.CurrentRoom.Obs[grid.pos.Y+1][grid.pos.X+1] = {
			sprite = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].trueSpr,
			type = grid.EditorType,
			info = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].info,
			--trueSpr = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType].spr,
		}
		local pGrid = Isaac_Tower.editor.GridTypes.Obstacle[grid.EditorType]
		local list = Isaac_Tower.editor.Memory.CurrentRoom.Obs
		local x,y = grid.pos.X+1,grid.pos.Y+1
		if pGrid.size then
			for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
				--if not list[k[1]] then
				--	list[k[1]] = {}
				--end
				--if not list[k[1]][k[2]] then
				--	list[k[1]][k[2]] = {}
				--end
				SafePlacingTable(list,k[1],k[2]).Parent = Vector(x,y)
				--list[k[1]][k[2]].Parent = Vector(x,y)
			end
		end
	end

	if roomdata.Enemy then
		for y, grid in ipairs(roomdata.Enemy) do
			Isaac_Tower.editor.Memory.CurrentRoom.Enemies[grid.pos.Y] = Isaac_Tower.editor.Memory.CurrentRoom.Enemies[grid.pos.Y] or {}
			Isaac_Tower.editor.Memory.CurrentRoom.Enemies[grid.pos.Y][grid.pos.X] = {
				sprite = Isaac_Tower.editor.GridTypes.Enemies[grid.EditorType].trueSpr,
				type = grid.EditorType,
				info = Isaac_Tower.editor.GridTypes.Enemies[grid.EditorType].info,
			}
			for i,k in pairs(GetLinkedGrid(Isaac_Tower.editor.Memory.CurrentRoom.Enemies, 
			Vector(grid.pos.X,grid.pos.Y), Isaac_Tower.editor.GridTypes.Enemies[grid.EditorType].size, true)) do
				SafePlacingTable(Isaac_Tower.editor.Memory.CurrentRoom.Enemies,k[1],k[2]).Parent = Vector(grid.pos.X,grid.pos.Y)
			end
		end
	end
	
	if roomdata.EnviList then
		local CustomType = {}
		if roomdata.EnviList.CT and roomdata.EnviList.CF then
			for i, k in pairs(roomdata.EnviList.CT) do
				local size, pivot = Vector(k[3][1],k[3][2]), Vector(k[4][1],k[4][2])
				local anm2, anim = roomdata.EnviList.CF[k[1]], k[2]
				local GType = anm2..anim
				CustomType[i] = GType

				if not Isaac_Tower.editor.GridTypes["Environment"][GType] then
					local ingridSpr = GenSprite(anm2,anim)
					ingridSpr.Scale =  Vector(.5,.5)
					Isaac_Tower.editor.AddEnvironment(GType,
						GenSprite(anm2,anim),
						function() return GenSprite(anm2,anim) end,
						ingridSpr,
						size,
						pivot)
				end
			end
			Isaac_Tower.editor.GetOverlay("Environment").CustomPreGenTileList("Environment")
		end
		for y, grid in ipairs(roomdata.EnviList) do
			Isaac_Tower.editor.Memory.CurrentRoom.EnviList = Isaac_Tower.editor.Memory.CurrentRoom.EnviList or {}
			local newindex = #Isaac_Tower.editor.Memory.CurrentRoom.EnviList+1
			--Isaac_Tower.editor.Memory.CurrentRoom.Envi[grid.pos.Y] = Isaac_Tower.editor.Memory.CurrentRoom.Envi[grid.pos.Y] or {}
			--Isaac_Tower.editor.Memory.CurrentRoom.Envi[grid.pos.Y][grid.pos.X] = { 
			--	Parents = {}
			--} --chl

			local list = Isaac_Tower.editor.Memory.CurrentRoom.Envi --[grid.pos.Y][grid.pos.X]
			local childs = {}
			local chl = grid.chl
			if #chl==4 then
				chl = NaitiMezdy(chl[1],chl[2],chl[3],chl[4])
			end
			for i, k in pairs(chl) do
				local yi, xi = k[1], k[2]
				--list[yi] = list[yi] or {}
				--list[yi][xi] = list[yi][xi] or {Parents = {}}
				local ob = SafePlacingTable(list,yi,xi)
				ob.Parents = ob.Parents or {}
				ob.Parents[newindex] = true
				childs[#childs + 1] = { yi, xi }
			end

			local pGrid = Isaac_Tower.editor.GridTypes.Environment[grid.name or CustomType[grid.ct]]
			Isaac_Tower.editor.Memory.CurrentRoom.EnviList[newindex] =
			{
				info = pGrid,
				spr = pGrid.trueSpr,
				pos = grid.pos/2, --+Vector(13,13)
				childs = childs,
				upleft = grid.pos/2 - pGrid.pivot / 2,
				downright = grid.pos/2 - pGrid.pivot / 2 + pGrid.size / 2,
				layer = grid.l or 0,
			}
		end
	end


	local pGrid = Isaac_Tower.editor.GridTypes.Special["spawnpoint_def"]
	local defspawn = roomdata.DefSpawnPoint/1 - Vector(-40,100) --math.ceil
	defspawn = 	Vector(math.ceil(defspawn.X/40),math.ceil(defspawn.Y/40))
	--Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"] = Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"] or {}
	--Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y] = Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y] or {}
	SafePlacingTable(Isaac_Tower.editor.Memory.CurrentRoom.Special,"spawnpoint_def",defspawn.Y,defspawn.X)
	Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y][defspawn.X] = {info = pGrid.info, type = "spawnpoint_def", pos = Vector((defspawn.X-1)*26/2,(defspawn.Y-1)*26/2), XY = Vector(defspawn.X,defspawn.Y)}
	local index = tostring(math.ceil(defspawn.X)) .. "." .. tostring(math.ceil(defspawn.Y)) --(defspawn.Y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + defspawn.X
	local info = function() return Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"][defspawn.Y][defspawn.X] end
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab["spawnpoint_def"] = {}
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab["spawnpoint_def"][index] = {spr = pGrid.trueSpr, pos = Vector((defspawn.X-1)*26/2, 26*(defspawn.Y-1)/2), info = info}

	Isaac_Tower.editor.MenuData.grid = nil

	Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_CONVERTING_CURRENT_ROOM_TO_EDITOR, Isaac_Tower.editor.Memory, roomdata, Isaac_Tower.CurrentRoom.Name) -- Isaac_Tower.GridLists)
end

local roomGridStartPoses = {}

function Isaac_Tower.editor.ChangeRoom(roomName)
	if Isaac_Tower.editor.Memory.CurrentRoom and Isaac_Tower.editor.Memory.CurrentRoom.Name then
		roomGridStartPoses[Isaac_Tower.editor.Memory.CurrentRoom.Name] = Isaac_Tower.editor.GridStartPos or Vector(50,50)
		Isaac_Tower.editor.Memory.Changes[Isaac_Tower.editor.Memory.CurrentRoom.Name] = TabDeepCopy(Isaac_Tower.editor.Memory.CurrentRoom)
	end
	if Isaac_Tower.Rooms[roomName] then
		if Isaac_Tower.editor.Memory.Changes[roomName] then
			Isaac_Tower.editor.Memory.CurrentRoom = TabDeepCopy(Isaac_Tower.editor.Memory.Changes[roomName])
			Isaac_Tower.editor.GridStartPos = roomGridStartPoses[roomName] or Vector(50,50)
		else
			Isaac_Tower.editor.GridStartPos = Vector(50,50)
			Isaac_Tower.SetRoom(roomName)
			Isaac_Tower.editor.ConvertCurrentRoomToEditor()
		end
		if not Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name] then
			Isaac_Tower.editor.MakeVersion()
		end
		Isaac_Tower.editor.MenuData.grid = nil
	end
	
end


local function GetGridListAnimNamesStr()
	local str = ""
	for name in pairs(Isaac_Tower.editor.GridAnimNames) do
		str = str .. "'" .. name .. "',"
	end
	return str
end
local function GetGridListAnimNames()
	local str = {}
	for name in pairs(Isaac_Tower.editor.GridAnimNames) do
		str[#str+1] = name
	end
	return str
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
function Isaac_Tower.editor.GetConvertedEditorRoomForDebug()
	Isaac.RunCallback(Isaac_Tower.Callbacks.PRE_EDITOR_CONVERTING_EDITOR_ROOM)

	local str = "local roomdata = {"
	str = str .. "Name='" .. Isaac_Tower.editor.Memory.CurrentRoom.Name .. "',"
	str = str .. "Size=Vector(" .. Isaac_Tower.editor.Memory.CurrentRoom.Size.X .. "," .. Isaac_Tower.editor.Memory.CurrentRoom.Size.Y .. "),"
	str = str .. "DefSpawnPoint=Vector(".. Isaac_Tower.editor.Memory.CurrentRoom.DefSpawnPoint.X .. "," .. Isaac_Tower.editor.Memory.CurrentRoom.DefSpawnPoint.Y .. "),"
	
	--[[str = str .. "\nSolidList={\n"
	local solidTab = "  dgfx='gfx/fakegrid/basement.png',\n"
	solidTab = solidTab .. "  extraAnim={" .. GetGridListAnimNamesStr() .. "},\n"
	--solidTab = solidTab .. "  useWorldPos = true,"
	
	local startPos = Vector(-40,100)
	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Solid[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				--local pos = startPos + Vector(20+(x-1)*40, 20+(y-1)*40)
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. pos.X .. "," .. pos.Y .. ")," 
				for param, dat in pairs(grid.info) do
					if type(dat) == "string" then
						solidTab = solidTab..param.."='" .. dat .. "',"
					else
						solidTab = solidTab..param.."=" .. dat .. ","
					end
				end
				--EditorType
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},\n}"]]

	--Isaac_Tower.editor.Overlay.menus[menuName] = {spr = sprite, selectedTile = "", render = renderFunc, convert = converterFunc, saveConvert
	for i, menu in pairs(Isaac_Tower.editor.Overlay.menus) do
		if menu.saveConvert then
			local result = menu.saveConvert(str)
			if type(result) == "string" then
				str = result
			end
		end
	end

	--Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_CONVERTING_EDITOR_ROOM, str)
	for i,k in pairs(Isaac.GetCallbacks(Isaac_Tower.Callbacks.EDITOR_CONVERTING_EDITOR_ROOM)) do
		local result = k.Function(k.Mod, str)
		if type(result) == "string" then
			str = result
		end
	end

	str = str .. "\n}"
	return str
end

Isaac_Tower.editor._EditorTestRoom = {}
function Isaac_Tower.editor.GetConvertedEditorRoom()
	--Isaac.RunCallback(Isaac_Tower.Callbacks.PRE_EDITOR_CONVERTING_EDITOR_ROOM)

	--local tab = {
	--Name = Isaac_Tower.editor.Memory.CurrentRoom.Name,
	--Size = Isaac_Tower.editor.Memory.CurrentRoom.Size,
	--DefSpawnPoint = Isaac_Tower.editor.Memory.CurrentRoom.DefSpawnPoint,
	--SolidList = {},
	--ObsList = {},
	--}

	--[[tab.SolidList = {
		dgfx='gfx/fakegrid/basement.png',
		extraAnim=GetGridListAnimNames(),
	}
	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Solid[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				tab.SolidList[#tab.SolidList+1] = TabDeepCopy(grid.info)
				tab.SolidList[#tab.SolidList].pos = Vector(x,y)
			end
		end
	end]]

	--Isaac_Tower.editor.Overlay.menus[menuName] = {spr = sprite, selectedTile = "", render = renderFunc, convert = converterFunc, saveConvert
	--for i, menu in pairs(Isaac_Tower.editor.Overlay.menus) do
	--	if menu.convert then
	--		menu.convert(tab)
	--	end
	--end
	--Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_CONVERTING_EDITOR_ROOM, tab)

	local tab = load(Isaac_Tower.editor.GetConvertedEditorRoomForDebug() .. " return roomdata")
	tab = tab and tab()
	return tab
end


function Isaac_Tower.editor.PreGenEmptyRoom()
	Isaac_Tower.editor.Memory.CurrentRoom = nil
	Isaac_Tower.editor.Memory.CurrentRoom = {
		Name = "newroom 1",
		Size = Vector(25, 15),
		DefSpawnPoint = Vector(-20, 150),
		solidGfx = "gfx/fakegrid/basement.png",
		Solid = {},
		Obs = {},
		Enemies = {},
		Special = {},
		SpecialSpriteTab = {},
		Envi = {},
		EnviList = {},
		SolidFake = {},
	}
end

function Isaac_Tower.editor.MakeVersion()
	Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name] = Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name] or {}
	local tab = Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name]
	tab.pos = tab.pos and math.min(41,tab.pos+1) or 1
	table.insert(tab,tab.pos,TabDeepCopy(Isaac_Tower.editor.Memory.CurrentRoom))
	if tab[tab.pos+1] then
		for i=tab.pos+1,#tab do
			tab[i] = nil
		end
	end
	if #tab>40 then
		table.remove(tab,1)
	end
end

function Isaac_Tower.editor.BackToVersion(num)
	local tab = Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name]
	Isaac_Tower.editor.SpecialSelectedTile = nil
	if tab and tab.pos and tab[tab.pos + num] then
		tab.pos = tab.pos + num
		local roomname = Isaac_Tower.editor.Memory.CurrentRoom.Name
		Isaac_Tower.editor.Memory.CurrentRoom = TabDeepCopy(tab[tab.pos])
		Isaac_Tower.editor.Memory.CurrentRoom.Name = roomname
	end
end


function Isaac_Tower.editor.AddGrid(name, animName, sprite, data, ingridSpr, sizeTable)
    if name and sprite and data then
		Isaac_Tower.editor.GridTypes["Grid"][name] = {spr = sprite, info = data, trueSpr = ingridSpr or sprite, size = sizeTable}
    end
    Isaac_Tower.editor.GridAnimNames[animName] = true
end
function Isaac_Tower.editor.AddObstacle(name, animName, sprite, data, ingridSpr, sizeTable)
    if name and sprite and data then
		Isaac_Tower.editor.GridTypes["Obstacle"][name] = {spr = sprite, info = data, trueSpr = ingridSpr or sprite, size = sizeTable}
    end
    --Isaac_Tower.editor.ObsAnimNames[animName] = true
end
function Isaac_Tower.editor.AddEnemies(name, sprite, Enemyname, subtype, ingridSpr)
    if name and sprite and Enemyname then
		Isaac_Tower.editor.GridTypes["Enemies"][name] = {spr = sprite, info = {Enemyname, subtype}, 
			trueSpr = ingridSpr or sprite, size = Vector(2,2), group = "Enemies"}
		--Isaac_Tower.editor.Overlay.menus.groups = {}
		--SafePlacingTable(Isaac_Tower.editor.Overlay.menus,"Enemies","groups","Enemies")[name] = true
	end
    --Isaac_Tower.editor.ObsAnimNames[animName] = true
end
function Isaac_Tower.editor.AddSpecial(name, animName, sprite, data, ingridSpr)
	if name and sprite and data then
		Isaac_Tower.editor.GridTypes["Special"][name] = {spr = sprite, info = data, trueSpr = ingridSpr or sprite}
	end
	--Isaac_Tower.editor.SpecialAnimNames[animName] = true
end

Isaac_Tower.editor.SpecialEditingData = {}
--paramType: 1 = textBox {HintText, Text, onlyNumber}; 
--paramType: 2 = selector
function Isaac_Tower.editor.AddSpecialEditData(name, paramName, paramType, tab)
	if not Isaac_Tower.editor.GridTypes["Special"][name] then
		error("This object does not exists",2)
	end
	Isaac_Tower.editor.SpecialEditingData[name] = Isaac_Tower.editor.SpecialEditingData[name] or {}
	--Isaac_Tower.editor.SpecialEditingData[name][paramName] = {Type = paramType, Result = resultCheckFunc}
	local num = #Isaac_Tower.editor.SpecialEditingData[name]+1
	Isaac_Tower.editor.SpecialEditingData[name][num] = {ParamName = paramName, Type = paramType}
	if tab then
		for i,k in pairs(tab) do
			Isaac_Tower.editor.SpecialEditingData[name][num][i] = k
		end
	end
end
---@param name string
---@param sprite Sprite
---@param sprGenFunc function
---@param ingridSpr Sprite
---@param sizeTable Vector
---@param pivot Vector
function Isaac_Tower.editor.AddEnvironment(name, sprite, sprGenFunc, ingridSpr, sizeTable, pivot)
	if name and sprite and sprGenFunc then
		--local index = #Isaac_Tower.editor.GridTypes["Environment"]+1
		Isaac_Tower.editor.GridTypes["Environment"][name] = {name = name, spr = sprite, info = sprGenFunc, trueSpr = ingridSpr or sprite, size = sizeTable, pivot = pivot}
	end
	--Isaac_Tower.editor.SpecialAnimNames[animName] = true
end
---@param name string
---@param sprite Sprite
---@param BonusName string
---@param ingridSpr Sprite
---@param sizeTable Vector
function Isaac_Tower.editor.AddBonusPickup(name, sprite, BonusName, ingridSpr, sizeTable)
	if name and sprite then
		--Isaac_Tower.editor.GridTypes["Bonus"][name] = {name = name, spr = sprite, info = BonusName, trueSpr = ingridSpr or sprite, size = sizeTable}
		SafePlacingTable(Isaac_Tower.editor.GridTypes,"Enemies")[name] = {name = name, spr = sprite, 
			info = BonusName, trueSpr = ingridSpr or sprite, size = sizeTable, group = "Bonus"}
		--SafePlacingTable(Isaac_Tower.editor.Overlay.menus,"Enemies","groups","Bonus")[name] = true
	end
end


local IsaacTower_Type = Isaac.GetPlayerTypeByName("Isaac Tower")
function Isaac_Tower.OpenEditor()
	local IsTower = false
    for pid=0,Isaac_Tower.game:GetNumPlayers()-1 do
		local player = Isaac.GetPlayer(pid)
		if player:GetPlayerType() == IsaacTower_Type then
			IsTower = true
			break
		end
    end
	if not IsTower then error("Func called outside the Isaac Tower mod",2) end
	Isaac_Tower.InAction = false
	Isaac_Tower.Pause = true
	TSJDNHC_PT:EnableCamera(false, true)
	Isaac_Tower.editor.InEditor = true

	Isaac_Tower.editor.PreGenerateGridListMenu()
	Isaac_Tower.editor.GenOverlayMenu()
	Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu, 1)
	--Isaac_Tower.editor.SpecialSpriteTab = {}

	if Isaac_Tower.CurrentRoom and Isaac_Tower.CurrentRoom.Name then
		Isaac_Tower.editor.ConvertCurrentRoomToEditor()
	else
		Isaac_Tower.editor.PreGenEmptyRoom()
		Isaac_Tower.Rooms[Isaac_Tower.editor.Memory.CurrentRoom.Name] = Isaac_Tower.editor.GetConvertedEditorRoom()
	end

	if Isaac_Tower.editor.InEditorTestRoom then
		Isaac_Tower.editor.InEditorTestRoom = nil
		Isaac_Tower.editor.Memory.CurrentRoom = TabDeepCopy(Isaac_Tower.editor.Memory.LastRoom)
		--[[for i,y in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
			for j,x in pairs(y) do
				local pGrid = Isaac_Tower.editor.GridTypes.Special[x.type or ""]
				print(pGrid,pGrid.trueSpr)
				local index = (i-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + j
				Isaac_Tower.editor.SpecialSpriteTab[index] = {spr = pGrid.trueSpr, pos = Vector(j*26/2, 26*i/2), info = x}
			end
		end]]
	end

	for i, ent in pairs(Isaac.FindByType(1000, Isaac_Tower.ENT.Enemy.VAR, -1)) do
		if not ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT) then
			ent:Remove()
		end
	end
	for i, ent in pairs(Isaac.FindByType(1000, Isaac_Tower.ENT.GIB.VAR, -1)) do
		if not ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT) then
			ent:Remove()
		end
	end

	Isaac_Tower.editor.MakeVersion()

	mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, Isaac_Tower.editor.Render)
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, Isaac_Tower.editor.Render)

	mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, Isaac_Tower.editor.MoveControl)
	mod:AddCallback(ModCallbacks.MC_POST_UPDATE, Isaac_Tower.editor.MoveControl)
end
function Isaac_Tower.CloseEditor()
	Isaac_Tower.InAction = true
	Isaac_Tower.Pause = false
	TSJDNHC_PT:EnableCamera(true, true)
	Isaac_Tower.editor.InEditor = false

	Isaac_Tower.editor.MenuData.grid = nil

	mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, Isaac_Tower.editor.Render)
	mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, Isaac_Tower.editor.MoveControl)
end


Isaac_Tower.editor.strings = {
	["Room Name:"] = {en = "Room Name:", ru = "Имя Комнаты:"},
	["Grid:"] = {en = "Grid:", ru = "Клетка:"},
	["ToLog1"] = {en = "To", ru = "В"},
	["ToLog2"] = {en = "Log", ru = "Лог"},
	["TestRun1"] = {en = "Test", ru = "Тест."},
	["TestRun2"] = {en = "run", ru = "прогон"},
	["Cancel"] = {en = "Cancel", ru = "Отмена"},
	["Ok"] = {en = "Ok", ru = "Ок"},
	["emptyField"] = {en = "the field is empty", ru = "поле пустое"},
	["rooms"] = {en = "rooms", ru = "комнаты"},
	["incorrectNumber"] = {en = "number is incorrect", ru = "число некорректно"},
	["ExistRoomName"] = {en = "a room with this name already exists", ru = "комната с таким именем уже существует"},
	["Transition Name"] = {en = "The name of this transition", ru = "Имя данного перехода"},
	["Transition Target"] = {en = "Room name to transition", ru = "Имя комнаты для перехода"},
	["Transition TargetPoint"] = {en = "Name of the linked spawn point", ru = "Имя связанной точки спавна"},
	["Back"] = {en = "Back", ru = "Назад"},
	["newroom"] = {en = "New room", ru = "Новая комната"},
	["anotherFile"] = {en = "another file", ru = "другой файл"},
	["anm2FileFail"] = {en = "file not found", ru = "файл не найден"},
	["AnmFile"] = {en = "animation file", ru = "файл с анимациями"},
	["AnimName"] = {en = "name of the animation", ru = "название анимации"},
	["Auto"] = {en = "Auto", ru = "Авто"},
	["layer"] = {en = "layer", ru = "слой"},

	["DefSpawnPoint"] = {en = "There must be only one DEF spawn point in the room", ru = "В комнате должна быть только одна DEF точка спавна"},
	["addEnvitext1"] = {en = "green square should completely", ru = "зелёный квадрат должен полностью"},
	["addEnvitext2"] = {en = "cover the sprite", ru = "закрывать спрайт"},
	["addEnviVisualBox"] = {en = "visual size of the sprite", ru = "визуальная коробка спрайта"},
	["addEnviSize"] = {en = "size", ru = "размер"},
	["addEnviPivot"] = {en = "offset", ru = "смещение"},
	["addEnviPos"] = {en = "position", ru = "позиция"},
	["spawnpoint_name"] = {en = "The name of this spawn point", ru = "Имя данной точки спавна"},

	["roomlist_hint"] = {en = nil, ru = "открывает список загруженных комнат"},
}
local function GetStr(str)
	if Isaac_Tower.editor.strings[str] then
		return Isaac_Tower.editor.strings[str][Options.Language] or Isaac_Tower.editor.strings[str].en or str
	else
		return str
	end
end



local font = Font()
font:Load("font/upheaval.fnt")

local UIs = {}
UIs.MenuUp = GenSprite("gfx/editor/ui.anm2","фон_вверх")
UIs.MouseGrab = GenSprite("gfx/editor/ui.anm2","mouse_grab")
UIs.Mouse_Tile_edit = GenSprite("gfx/editor/ui.anm2","mouse_tileEdit")
UIs.GridList = GenSprite("gfx/editor/ui.anm2","gridListMenu")
UIs.HintQ = GenSprite("gfx/editor/ui.anm2","hintQ")
UIs.ToLog = GenSprite("gfx/editor/ui.anm2","ВЛог")
UIs.TestRun = GenSprite("gfx/editor/ui.anm2","ТестовыйПрогон")
UIs.OverlayBarL = GenSprite("gfx/editor/ui.anm2","оверлей_лпц",0)
UIs.OverlayBarR = GenSprite("gfx/editor/ui.anm2","оверлей_лпц",1)
UIs.OverlayBarC = GenSprite("gfx/editor/ui.anm2","оверлей_лпц",2)
--UIs.OverlayTab1 = GenSprite("gfx/editor/ui.anm2","оверлей_вкладка",0)
--UIs.OverlayTab2 = GenSprite("gfx/editor/ui.anm2","оверлей_вкладка",1)
--UIs.PositionSbros = GenSprite("gfx/editor/ui.anm2","сброс поз")
UIs.TextBoxPopupBack = GenSprite("gfx/editor/ui.anm2","всплывашка")
UIs.MouseTextEd = GenSprite("gfx/editor/ui.anm2","mouse_textEd")
UIs.TextEdPos = GenSprite("gfx/editor/ui.anm2","TextEd_pos")
UIs.RoomSelectBack = GenSprite("gfx/editor/ui.anm2","фон_вверх")
UIs.RoomSelectBack.Rotation = -90
UIs.RoomSelect = GenSprite("gfx/editor/ui.anm2","room_select")
UIs.RoomSelectWarn = GenSprite("gfx/editor/ui.anm2","room_select_warn")
UIs.SpcEDIT_menu_Up = GenSprite("gfx/editor/ui.anm2","всплывашка_ручная")
UIs.SpcEDIT_menu_Cen = GenSprite("gfx/editor/ui.anm2","всплывашка_ручная",1)
UIs.SpcEDIT_menu_Down = GenSprite("gfx/editor/ui.anm2","всплывашка_ручная",2)
UIs.Flag = GenSprite("gfx/editor/ui.anm2","флажок")
UIs.Hint_MouseMoving = GenSprite("gfx/editor/ui.anm2","hint_mouse_move")
UIs.Hint_MouseMoving_Vert = GenSprite("gfx/editor/ui.anm2","hint_mouse_move",1)
UIs.Hint_tileEdit = GenSprite("gfx/editor/ui.anm2","hint_tile_edit")
UIs.RG_icon = GenSprite("gfx/editor/ui.anm2","рг")
if not Isaac_Tower.RG then
	local gray = Color(1,1,1,1)
	gray:SetColorize(1,1,1,1)
	UIs.RG_icon.Color = gray
end
UIs.HintTextBG1 = GenSprite("gfx/editor/ui.anm2","фон_для_вспом_текста")
UIs.HintTextBG2 = GenSprite("gfx/editor/ui.anm2","фон_для_вспом_текста",1)
UIs.SolidMode1 = GenSprite("gfx/editor/ui.anm2","твёрдаяКлетка")
UIs.SolidMode2 = GenSprite("gfx/editor/ui.anm2","прозрачнаяКлетка")
UIs.EnemiesMode1 = GenSprite("gfx/editor/ui.anm2","враги")
UIs.EnemiesMode2 = GenSprite("gfx/editor/ui.anm2","бонусы")


function UIs.Box48() return GenSprite("gfx/editor/ui.anm2","контейнер") end
function UIs.Counter() return GenSprite("gfx/editor/ui.anm2","счётчик") end
function UIs.CounterSmol() return GenSprite("gfx/editor/ui.anm2","счётчик_smol") end
function UIs.CounterUp() return GenSprite("gfx/editor/ui.anm2","поднять") end
function UIs.CounterDown() return GenSprite("gfx/editor/ui.anm2","опустить") end
function UIs.CounterUpSmol() return GenSprite("gfx/editor/ui.anm2","поднять_smol") end
function UIs.CounterDownSmol() return GenSprite("gfx/editor/ui.anm2","опустить_smol") end
function UIs.PrePage() return GenSprite("gfx/editor/ui.anm2","лево") end
function UIs.NextPage() return GenSprite("gfx/editor/ui.anm2","право") end
function UIs.OverlayTab1() return GenSprite("gfx/editor/ui.anm2","оверлей_вкладка1") end
function UIs.OverlayTab2() return GenSprite("gfx/editor/ui.anm2","оверлей_вкладка2") end
function UIs.PopupTextBox() return GenSprite("gfx/editor/ui.anm2","контейнер_всплывашки") end
function UIs.ButtonWide() return GenSprite("gfx/editor/ui.anm2","кнопка_широкая") end
function UIs.Erase() return GenSprite("gfx/editor/ui.anm2","стереть") end
function UIs.TextBoxSmol() return GenSprite("gfx/editor/ui.anm2","конт_текста_smol") end
function UIs.Var_Sel() return GenSprite("gfx/editor/ui.anm2","sel_var") end
function UIs.Edit_Button() return GenSprite("gfx/editor/ui.anm2","кнопка_редакта") end
function UIs.FlagBtn() return GenSprite("gfx/editor/ui.anm2","кнопка флага") end
function UIs.TextBox() return GenSprite("gfx/editor/ui.anm2","конт_текста") end
function UIs.BigPlus() return GenSprite("gfx/editor/ui.anm2","плюс") end
function UIs.GridModeOn() return GenSprite("gfx/editor/ui.anm2","режим_сетки") end
function UIs.GridModeOff() return GenSprite("gfx/editor/ui.anm2","режим_сетки_выкл") end
function UIs.PositionSbros() return GenSprite("gfx/editor/ui.anm2","сброс поз") end
function UIs.GridOverlayTab1() return GenSprite("gfx/editor/ui.anm2","вкладка1") end
function UIs.GridOverlayTab2() return GenSprite("gfx/editor/ui.anm2","вкладка2") end



local MouseBtnIsPressed = {[0] = 0,0,0}
local function IsMouseBtnTriggered(button)
	if not MouseBtnIsPressed[button] then
		MouseBtnIsPressed[button] = 1
		return true
	else
		return MouseBtnIsPressed[button] == 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function() -- MC_POST_UPDATE MC_POST_RENDER
	for i,k in pairs(MouseBtnIsPressed) do
		if Input.IsMouseBtnPressed(i) then
			MouseBtnIsPressed[i] = MouseBtnIsPressed[i] + 1
		else
			MouseBtnIsPressed[i] = 0
		end
	end
end)


Isaac_Tower.sprites.Col0Grid = Sprite()
Isaac_Tower.sprites.Col0Grid:Load("gfx/doubleRender/gridDebug/debug.anm2")
Isaac_Tower.sprites.Col0Grid.Color = Color(0.5,0.3,1.0,0.5)
Isaac_Tower.sprites.Col0Grid:Play(0)
Isaac_Tower.sprites.Col0Grid.Scale = Vector(0.58, 0.58)

Isaac_Tower.sprites.Col0GridHalf = Sprite()
Isaac_Tower.sprites.Col0GridHalf:Load("gfx/doubleRender/gridDebug/debug.anm2")
Isaac_Tower.sprites.Col0GridHalf.Color = Color(0.5,0.3,1.0,0.5)
Isaac_Tower.sprites.Col0GridHalf:Play(0)
Isaac_Tower.sprites.Col0GridHalf.Scale = Vector(0.29, 0.29)
--Col0GridHalf.Offset = Vector(13/2,13/2) 

Isaac_Tower.sprites.chosenGrid = Sprite()
Isaac_Tower.sprites.chosenGrid:Load("gfx/doubleRender/gridDebug/debug.anm2")
Isaac_Tower.sprites.chosenGrid.Color = Color(2,0,2,0.5)
Isaac_Tower.sprites.chosenGrid:Play(0)
Isaac_Tower.sprites.chosenGrid.Scale = Vector(0.58, 0.58)

Isaac_Tower.sprites.chosenGridHalf = Sprite()
Isaac_Tower.sprites.chosenGridHalf:Load("gfx/doubleRender/gridDebug/debug.anm2")
Isaac_Tower.sprites.chosenGridHalf.Color = Color(2,0,2,0.5)
Isaac_Tower.sprites.chosenGridHalf:Play(0)
Isaac_Tower.sprites.chosenGridHalf.Scale = Vector(0.32, 0.32)

Isaac_Tower.editor.GridStartPos = Vector(50,50)
Isaac_Tower.editor.GridScale = 1
Isaac_Tower.editor.RoomSize = Vector(25,15)
Isaac_Tower.editor.MousePos = Vector(0,0)
Isaac_Tower.editor.SelectedMenu = "grid"
Isaac_Tower.editor.IsStickyMenu = false
Isaac_Tower.editor.MouseSprite = nil
Isaac_Tower.editor.SelectedGridType = ""
Isaac_Tower.editor.GridListMenuPage = 1

Isaac_Tower.editor.MenuData = {}
Isaac_Tower.editor.MenuButtons = {}

Isaac_Tower.editor.Overlay = {menus = {}, selectedMenu = -1, num = 0, order = {}}

---@class EditorButton 
---@field pos Vector
---@field x number
---@field y number
---@field spr Sprite
---@field func function
---@field render function
---@field canPressed boolean
---@field hintText table

---@return nil|EditorButton
function Isaac_Tower.editor.GetButton(menuName, buttonName, NoError)
	if not Isaac_Tower.editor.MenuData[menuName] then
		if NoError then return end
		error("This menu does not exist",2)
	elseif not Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName] then
		if NoError then return end
		error("This button does not exist",2)
	end
	return Isaac_Tower.editor.MenuData[menuName] and Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName]
end

function Isaac_Tower.editor.RemoveButton(menuName, buttonName, NoError)
	if not Isaac_Tower.editor.MenuData[menuName] then
		if NoError then return end
		error("This menu does not exist",2)
	elseif not Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName] then
		return
		--error("This button does not exist",2)
	end
	Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName] = nil
	for i,k in pairs(Isaac_Tower.editor.MenuData[menuName].sortList) do
		if k.btn == buttonName then
			table.remove(Isaac_Tower.editor.MenuData[menuName].sortList, i)
		end
	end
end

function Isaac_Tower.editor.ButtonSetHintText(menuName, buttonName, text, NoError)
	if not Isaac_Tower.editor.MenuData[menuName] then
		if NoError then return end
		error("This menu does not exist",2)
	elseif not Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName] then
		if NoError then return end
		error("This button does not exist",2)
	end
	if Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName] then
		local BoxWidth = 150
		local str = {}
		if BoxWidth ~= 0 then
			local maxWidth = 0
			local spaceLeft = BoxWidth
			local words = {}
			for word in string.gmatch(text, '([^ ]+)') do --Split string into individual words
				words[#words+1] = word;
			end
			text = ""
			for i=1, #words do
				local wordLength = font:GetStringWidthUTF8(words[i])*0.5
				if (words[i] == "\n") then --Word is purely breakline
					--text = text.."\n"
					str[#str+1] = text
					text = ""
				elseif (utf8_Sub(words[i], 1, 2) == "\n") then --Word starts with breakline
					spaceLeft = BoxWidth - wordLength
					text = text..words[i].." "
				elseif (wordLength > spaceLeft) then --Word breaks text boundary
					spaceLeft = BoxWidth - wordLength
					str[#str+1] = text
					text = ""
					text = words[i].." " --text.."\n"..
				else --Word is fine
					maxWidth = math.max(BoxWidth-spaceLeft, maxWidth)
					spaceLeft = spaceLeft - wordLength
					text = text..words[i].." "
				end
				maxWidth = math.max(BoxWidth-spaceLeft+2, maxWidth)
			end
			str[#str+1] = text
			str.Width = maxWidth
		end
		--for i,k in pairs(str) do
		--	Isaac.DebugString(i .. k)
		--end
		Isaac_Tower.editor.MenuData[menuName].Buttons[buttonName].hintText = str
	end
end

---@return EditorButton|nil
function Isaac_Tower.editor.AddButton(menuName, buttonName, pos, sizeX, sizeY, sprite, pressFunc, renderFunc, notpressed, priority)
    if menuName and buttonName then
		Isaac_Tower.editor.MenuData[menuName] = Isaac_Tower.editor.MenuData[menuName] or {sortList = {}, Buttons = {}}
		local menu = Isaac_Tower.editor.MenuData[menuName]
		if menu.Buttons[buttonName] then
			Isaac_Tower.editor.RemoveButton(menuName, buttonName)
		end
		menu.sortList = menu.sortList or {}
		menu.Buttons = menu.Buttons or {}
		menu.Buttons[buttonName] = {pos = pos, x = sizeX, y = sizeY, spr = sprite, func = pressFunc, render = renderFunc, canPressed = not notpressed}
		
		priority = priority or 0
		local Spos = #menu.sortList+1
		for i=#menu.sortList,1,-1 do
			if menu.sortList[i].Priority <= priority then
				break
			else
				Spos = Spos-1
			end
		end
		table.insert(menu.sortList, Spos, {btn = buttonName, Priority = priority})
		return menu.Buttons[buttonName]
    end
end

---@class EditorOverlay
---@field spr Sprite
---@field selectedTile string
---@field render function
---@field saveConvert function
---@field CustomGenTileList function|nil
---@field CustomPreGenTileList function|nil

function Isaac_Tower.editor.AddOverlay(menuName, sprite, renderFunc, converterFunc, saveConverterFunc)
    Isaac_Tower.editor.GridTypes[menuName] = {}
    Isaac_Tower.editor.Overlay.menus[menuName] = {spr = sprite, selectedTile = "", render = renderFunc, convert = converterFunc, saveConvert = saveConverterFunc}
    Isaac_Tower.editor.Overlay.num =  Isaac_Tower.editor.Overlay.num + 1
    Isaac_Tower.editor.Overlay.order[#Isaac_Tower.editor.Overlay.order+1] = menuName
end
---@return EditorOverlay
function Isaac_Tower.editor.GetOverlay(menuName)
	return Isaac_Tower.editor.Overlay.menus[menuName]
end

Isaac_Tower.editor.Keyboard = {}
Isaac_Tower.editor.Keyboard.SelLang = "en"
Isaac_Tower.editor.Keyboard.Languages = {"en","ru"}
Isaac_Tower.editor.Keyboard.Chars = {}

Isaac_Tower.editor.Keyboard.Chars.OnlyNumberBtnList = {[48] = 0,[49] = 1,[50] = 2,[51] = 3,[52] = 4,[53] = 5,[54] = 6,[55] = 7,[56] = 8,[57] = 9,
	[320] = 0,[321] = 1,[322] = 2,[323] = 3,[324] = 4,[325] = 5,[326] = 6,[327] = 7,[328] = 8,[329] = 9,
	[259] = -1, [261] = -1, [45] = "-", [46] = ".", [333] = "-" }
	Isaac_Tower.editor.Keyboard.Chars.ShiftOnlyNumberBtnList = {[48] = ")",[53] = "%",[56] = "*",[57] = "(",
[320] = 0,[321] = 1,[322] = 2,[323] = 3,[324] = 4,[325] = 5,[326] = 6,[327] = 7,[328] = 8,[329] = 9,
[259] = -1, [261] = -1, [333] = "-" }

Isaac_Tower.editor.Keyboard.Chars.CharBtnList = { en = {
		[48] = 0,[49] = 1,[50] = 2,[51] = 3,[52] = 4,[53] = 5,[54] = 6,[55] = 7,[56] = 8,[57] = 9,[61] = "=",
		[65] = "a", [66] = "b",[67] = "c",[68] = "d",[69] = "e",[70] = "f",[71] = "g",[72] = "h",[73] = "i",[74] = "j",[75] = "k",
		[76] = "l",[77] = "m",[78] = "n",[79] = "o",[80] = "p",[81] = "q",[82] = "r",[83] = "s",[84] = "t",[85] = "u",[86] = "v",[87] = "w",
		[88] = "x",[89] = "y",[90] = "z",[47] = "/",[44] = ",",[45] = "-",[46] = ".",[333] = "-" ,
		[32] = " ", [259] = -1, [261] = -1,
	},
	ru = {
		[48] = 0,[49] = 1,[50] = 2,[51] = 3,[52] = 4,[53] = 5,[54] = 6,[55] = 7,[56] = 8,[57] = 9, [61] = "=",
		[65] = "ф", [66] = "и",[67] = "с",[68] = "в",[69] = "у",[70] = "а",[71] = "п",[72] = "р",[73] = "ш",[74] = "о",[75] = "л",
		[76] = "д",[77] = "ь",[78] = "т",[79] = "щ",[80] = "з",[81] = "й",[82] = "к",[83] = "ы",[84] = "е",[85] = "г",[86] = "м",[87] = "ц",
		[88] = "ч",[89] = "н",[90] = "я",[47] = ".",[44] = "б",[45] = "-",[46] = "ю",[333] = "-" , [91] = "х",[93] = "ъ",
		[59] = "ж", [39] = "э",
		[32] = " ", [259] = -1, [261] = -1,
	},
}
Isaac_Tower.editor.Keyboard.Chars.ShiftCharBtnList = { en = {
		[48] = ")",[49] = "!",[50] = "@",[51] = "#",[52] = "$",[53] = "%",[54] = "^",[55] = "&",[56] = "*",[57] = "(",
		[65] = "a", [66] = "b",[67] = "c",[68] = "d",[69] = "e",[70] = "f",[71] = "g",[72] = "h",[73] = "i",[74] = "j",[75] = "k",
		[76] = "l",[77] = "m",[78] = "n",[79] = "o",[80] = "p",[81] = "q",[82] = "r",[83] = "s",[84] = "t",[85] = "u",[86] = "v",[87] = "w",
		[88] = "x",[89] = "y",[90] = "z",[47] = "?",[44] = "<",[45] = "_",[46] = ">",[333] = "-" ,[61] = "+",
		[32] = " ", [259] = -1, [261] = -1,
	},
	ru = {
		[48] = ")",[49] = "!",[50] = "@",[51] = "#",[52] = "$",[53] = "%",[54] = "^",[55] = "&",[56] = "*",[57] = "(", [61] = "+",
		[65] = "ф", [66] = "и",[67] = "с",[68] = "в",[69] = "у",[70] = "а",[71] = "п",[72] = "р",[73] = "ш",[74] = "о",[75] = "л",
		[76] = "д",[77] = "ь",[78] = "т",[79] = "щ",[80] = "з",[81] = "й",[82] = "к",[83] = "ы",[84] = "е",[85] = "г",[86] = "м",[87] = "ц",
		[88] = "ч",[89] = "н",[90] = "я",[47] = ",",[44] = "б",[45] = "-",[46] = "ю",[333] = "-" , [91] = "х",[93] = "ъ", 
		[32] = " ", [259] = -1, [261] = -1,
	},
}

Isaac_Tower.editor.TextboxPopup = {MenuName = "TextboxPopup", OnlyNumber = false, Text = "", InFocus = true, TextPos = 0, lastChar = "",
	TextPosMoveDelay = 0, errorMes = -1}

function Isaac_Tower.editor.OpenTextboxPopup(onlyNumber, resultCheckFunc, startText) --tab, key, 
	local Menuname = Isaac_Tower.editor.TextboxPopup.MenuName
	--Isaac_Tower.editor.MenuData[Menuname] = {sortList = {}, Buttons = {}}
	local mousePosi = Vector(0,0)
	local buttonPos = Vector(0,0)

	Isaac_Tower.editor.TextboxPopup.DontremoveSticky = false
	Isaac_Tower.editor.TextboxPopup.LastMenu = Isaac_Tower.editor.SelectedMenu..""
	Isaac_Tower.editor.SelectedMenu = Menuname
	if not Isaac_Tower.editor.IsStickyMenu then
		Isaac_Tower.editor.IsStickyMenu = true
	else
		Isaac_Tower.editor.TextboxPopup.DontremoveSticky = true
	end
	Isaac_Tower.editor.TextboxPopup.OnlyNumber = onlyNumber and true or false
	Isaac_Tower.editor.TextboxPopup.ResultCheck = resultCheckFunc
	Isaac_Tower.editor.TextboxPopup.Text = startText and tostring(startText) or ""
	Isaac_Tower.editor.TextboxPopup.TextPos = startText and utf8.len(Isaac_Tower.editor.TextboxPopup.Text) or 0
	--Isaac_Tower.editor.TextboxPopup.TabKey = {tab, key}

	local centerPos = Isaac_Tower.editor.ScreenCenter - Vector(94,24) --Vector(Isaac.GetScreenWidth()/2-94, Isaac.GetScreenHeight()/2-24)
	local self
	self = Isaac_Tower.editor.AddButton(Menuname, "TextBox", centerPos, 164, 32, UIs.PopupTextBox(), function(button) 
		if button ~= 0 then return end
		Isaac_Tower.editor.TextboxPopup.InFocus = true
		local mouseClickPos = mousePosi-buttonPos
		
		if Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_textEd" then
			local num = 0
			for i = utf8.len(Isaac_Tower.editor.TextboxPopup.Text),0,-1 do
				local CutPos = font:GetStringWidthUTF8(utf8_Sub(Isaac_Tower.editor.TextboxPopup.Text, 0, i))/2
				if CutPos < mouseClickPos.X then
					Isaac_Tower.editor.TextboxPopup.TextPos = i
					break
				end
			end
			--Isaac_Tower.editor.TextboxPopup.TextPos
		end
	end, function(pos)
		--Isaac_Tower.editor.GetButton(Menuname, "TextBox").pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)
		self.pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)

		buttonPos = pos
		font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.Text,pos.X+3,pos.Y+10,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
		if Isaac_Tower.editor.TextboxPopup.InFocus then
			local poloskaPos = font:GetStringWidthUTF8(utf8_Sub(Isaac_Tower.editor.TextboxPopup.Text, 0, Isaac_Tower.editor.TextboxPopup.TextPos))
			UIs.TextEdPos:Render(pos+Vector(3+poloskaPos/2,9))
			UIs.TextEdPos:Update()
		end

		if type(Isaac_Tower.editor.TextboxPopup.errorMes) == "string" then
			local renderPos = pos + Vector(92,-20)

			font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.errorMes,renderPos.X+0.5,renderPos.Y-0.5,0.5,0.5,KColor(1,1,1,1),1,true)
			font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.errorMes,renderPos.X-0.5,renderPos.Y+0.5,0.5,0.5,KColor(1,1,1,1),1,true)
			font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.errorMes,renderPos.X+0.5,renderPos.Y+0.5,0.5,0.5,KColor(1,1,1,1),1,true)
			font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.errorMes,renderPos.X-0.5,renderPos.Y-0.5,0.5,0.5,KColor(1,1,1,1),1,true)

			font:DrawStringScaledUTF8(Isaac_Tower.editor.TextboxPopup.errorMes,renderPos.X,renderPos.Y,0.5,0.5,KColor(1,0.2,0.2,1),1,true)
		end
	end)

	local self
	self = Isaac_Tower.editor.AddButton(Menuname, "Cancel", centerPos+Vector(12,44), 64, 16, UIs.ButtonWide(), function(button) 
		if button ~= 0 then return end
		Isaac_Tower.editor.CloseTextboxPopup()
	end, function(pos)
		--Isaac_Tower.editor.GetButton(Menuname, "Cancel").pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)+Vector(12,44)
		self.pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)+Vector(12,44)
		font:DrawStringScaledUTF8(GetStr("Cancel"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
	end)
	local self
	self = Isaac_Tower.editor.AddButton(Menuname, "Ok", centerPos+Vector(112,44), 64, 16, UIs.ButtonWide(), function(button) 
		if button ~= 0 then return end
		local result = Isaac_Tower.editor.TextboxPopup.ResultCheck(Isaac_Tower.editor.TextboxPopup.Text)
		if result == true then
			Isaac_Tower.editor.CloseTextboxPopup()
		elseif type(result) == "string" then
			Isaac_Tower.editor.TextboxPopup.errorMes = result
		end
	end, function(pos)
		self.pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)+Vector(112,44)
		--Isaac_Tower.editor.GetButton(Menuname, "Ok").pos = Isaac_Tower.editor.ScreenCenter - Vector(94,24)+Vector(112,44)
		font:DrawStringScaledUTF8(GetStr("Ok"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)

		if not Isaac_Tower.game:IsPaused() and Input.IsButtonTriggered(Keyboard.KEY_ENTER,0) then
			local result = Isaac_Tower.editor.TextboxPopup.ResultCheck(Isaac_Tower.editor.TextboxPopup.Text)
			if result == true then
				Isaac_Tower.editor.CloseTextboxPopup()
			elseif type(result) == "string" then
				Isaac_Tower.editor.TextboxPopup.errorMes = result
			end
		end
	end)

	local ctrlVPressed = false

	Isaac_Tower.editor.MenuLogic[Menuname] = function(MousePos)
		mousePosi = MousePos
		
		if (IsMouseBtnTriggered(0) or IsMouseBtnTriggered(1)) 
		--and Isaac_Tower.editor.MenuButtons[Menuname].TextBox.spr:GetFrame() == 0 then
		and Isaac_Tower.editor.GetButton(Menuname, "TextBox").spr:GetFrame() == 0 then
			Isaac_Tower.editor.TextboxPopup.InFocus = false
		end
		if Isaac_Tower.editor.TextboxPopup.InFocus then

			local mouseClickPos = mousePosi-buttonPos
			local textlong = math.max(font:GetStringWidthUTF8(Isaac_Tower.editor.TextboxPopup.Text)/2, 160)
			
			if mouseClickPos.X > 1 and mouseClickPos.X < textlong+1 and mouseClickPos.Y>4 and mouseClickPos.Y<27 then
				if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_textEd" then
					Isaac_Tower.editor.MouseSprite = UIs.MouseTextEd
				elseif Input.IsMouseBtnPressed(0) then
					Isaac_Tower.editor.MouseSprite:SetFrame(1)
				else
					Isaac_Tower.editor.MouseSprite:SetFrame(0)
				end
			elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_textEd" then
				Isaac_Tower.editor.MouseSprite = nil
			end


			local maxN = utf8.len(Isaac_Tower.editor.TextboxPopup.Text)
			if Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay <= 0 
			or Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay > 15 and Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay%2==0 then
				if Input.IsButtonPressed(Keyboard.KEY_RIGHT,0) then
					Isaac_Tower.editor.TextboxPopup.TextPos = math.min(Isaac_Tower.editor.TextboxPopup.TextPos + 1,maxN)
					--Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay = 5
				elseif Input.IsButtonPressed(Keyboard.KEY_LEFT,0) then
					Isaac_Tower.editor.TextboxPopup.TextPos = math.max(Isaac_Tower.editor.TextboxPopup.TextPos - 1, 0)
					--Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay = 5
				end
			end
			if Input.IsButtonPressed(Keyboard.KEY_RIGHT,0) or Input.IsButtonPressed(Keyboard.KEY_LEFT,0) then
				Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay = Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay + 1
			else
				Isaac_Tower.editor.TextboxPopup.TextPosMoveDelay = 0
			end
			local shift = Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT,0) or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT,0)

			if shift and Input.IsButtonTriggered(Keyboard.KEY_LEFT_ALT,0) then
				--Isaac_Tower.editor.Keyboard.SelLang = "en"
				local fnext = false
				local flast
				for i,k in pairs(Isaac_Tower.editor.Keyboard.Languages) do
					if fnext then
						Isaac_Tower.editor.Keyboard.SelLang = k
						fnext = nil
						break
					end

					if Isaac_Tower.editor.Keyboard.SelLang == k then
						fnext = true
					else
						flast = k
					end
				end
				if fnext then
					Isaac_Tower.editor.Keyboard.SelLang = flast
				end
			end
			
			local newChar
			local remove
			local charTable
			local ignoreKeybord = false

			if Isaac_Tower.editor.TextboxPopup.OnlyNumber then
				if shift then
					charTable = Isaac_Tower.editor.Keyboard.Chars.ShiftOnlyNumberBtnList
				else
					charTable = Isaac_Tower.editor.Keyboard.Chars.OnlyNumberBtnList
				end
			else
				if shift then
					charTable = Isaac_Tower.editor.Keyboard.Chars.ShiftCharBtnList
				else
					charTable = Isaac_Tower.editor.Keyboard.Chars.CharBtnList
				end
				charTable = charTable[Isaac_Tower.editor.Keyboard.SelLang] or charTable["en"]
			end

			--if Isaac_Tower.editor.TextboxPopup.OnlyNumber then
			--	for btn,b in pairs(OnlyNumberBtnList) do
			--		if Input.IsButtonPressed(btn,0) then
			--			if Isaac_Tower.editor.TextboxPopup.lastChar ~= btn then
			--				newChar = b
			--				Isaac_Tower.editor.TextboxPopup.lastChar = btn
			--			end
			--		elseif Isaac_Tower.editor.TextboxPopup.lastChar == btn then
			--			Isaac_Tower.editor.TextboxPopup.lastChar = nil
			--		end
			--	end
			--else
			if not ctrlVPressed and Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) and Input.IsButtonPressed(Keyboard.KEY_V,0) then
				ctrlVPressed = true
				ignoreKeybord = true
				newChar = Isaac_Tower.GetClipBroad and Isaac_Tower.GetClipBroad()
			elseif not (Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) or Input.IsButtonPressed(Keyboard.KEY_V,0)) then
				ctrlVPressed = false
			else
				ignoreKeybord = true
			end
			if not ignoreKeybord then
				for btn,b in pairs(charTable) do
					if Input.IsButtonPressed(btn,0) then
						if Isaac_Tower.editor.TextboxPopup.lastChar ~= btn then
							newChar = b
							Isaac_Tower.editor.TextboxPopup.lastChar = btn
						end
					elseif Isaac_Tower.editor.TextboxPopup.lastChar == btn then
						Isaac_Tower.editor.TextboxPopup.lastChar = nil
					end
				end
			end
			if newChar then
				--local minusPos = utf8.offset(Isaac_Tower.editor.TextboxPopup.Text, Isaac_Tower.editor.TextboxPopup.TextPos-1)
				local curjspos = Isaac_Tower.editor.TextboxPopup.TextPos --utf8.offset(Isaac_Tower.editor.TextboxPopup.Text, Isaac_Tower.editor.TextboxPopup.TextPos)
				local secoPos = Isaac_Tower.editor.TextboxPopup.TextPos+1 -- utf8.offset(Isaac_Tower.editor.TextboxPopup.Text, Isaac_Tower.editor.TextboxPopup.TextPos+1)
				
				local firstPart = utf8_Sub(Isaac_Tower.editor.TextboxPopup.Text, 0, curjspos)
				local secondPart = utf8_Sub(Isaac_Tower.editor.TextboxPopup.Text, secoPos)
				if newChar == -1 then
					if Isaac_Tower.editor.TextboxPopup.TextPos>0 then
						Isaac_Tower.editor.TextboxPopup.Text = utf8_Sub(firstPart, 0, utf8.len(firstPart)-1) .. secondPart
						Isaac_Tower.editor.TextboxPopup.TextPos = Isaac_Tower.editor.TextboxPopup.TextPos - 1
					end
				else
					Isaac_Tower.editor.TextboxPopup.Text = firstPart .. newChar .. secondPart
					Isaac_Tower.editor.TextboxPopup.TextPos = Isaac_Tower.editor.TextboxPopup.TextPos + utf8.len(newChar)
				end
			end
		end
	end

	mod:RemoveCallback(ModCallbacks.MC_INPUT_ACTION, Isaac_Tower.editor.InputFilter)
	mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, Isaac_Tower.editor.InputFilter)
end

local blockact = {[ButtonAction.ACTION_FULLSCREEN]=true, [ButtonAction.ACTION_RESTART]=true, [ButtonAction.ACTION_MUTE]=true,
	[ButtonAction.ACTION_PAUSE] = true}
function Isaac_Tower.editor.InputFilter(_, ent, InputHook, ButtonAction)
	if Isaac_Tower.editor.TextboxPopup.InFocus and not Isaac_Tower.game:IsPaused() and blockact[ButtonAction] and (InputHook == 0 or InputHook == 1) then
		return false
	end
end
--mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, Isaac_Tower.editor.InputProxy)

function Isaac_Tower.editor.CloseTextboxPopup(accept)
	if not accept then
		Isaac_Tower.editor.SelectedMenu = Isaac_Tower.editor.TextboxPopup.LastMenu
		if not Isaac_Tower.editor.TextboxPopup.DontremoveSticky then
			Isaac_Tower.editor.IsStickyMenu = false
		end

		Isaac_Tower.editor.TextboxPopup = {MenuName = "TextboxPopup", OnlyNumber = false, Text = "", InFocus = false, 
			TextPos = 0, lastChar = "", TextPosMoveDelay = 0, errorMes = -1}
		mod:RemoveCallback(ModCallbacks.MC_INPUT_ACTION, Isaac_Tower.editor.InputFilter)
	end
end

Isaac_Tower.editor.SpecialEditMenu = {Name = "Special_edit_menu", numParam = 0}
--UIs.SpcEDIT_menu_
--Isaac_Tower.editor.SpecialEditingData
function Isaac_Tower.editor.OpenSpecialEditMenu(name, grid)
	if not Isaac_Tower.editor.SpecialEditingData[name] then error(tostring(name) .. " do not Exists",2) end
	local Menuname = Isaac_Tower.editor.SpecialEditMenu.Name

	grid.EditData = grid.EditData or {}
	Isaac_Tower.editor.MenuData[Menuname] = nil

	
	--Isaac_Tower.editor.SpecialEditMenu.LastMenu = Isaac_Tower.editor.SelectedMenu..""
	Isaac_Tower.editor.SelectedMenu = Menuname
	Isaac_Tower.editor.IsStickyMenu = true
	Isaac_Tower.editor.SpecialEditMenu.numParam = 0

	local centerPos = Vector(Isaac.GetScreenWidth()/2-94, Isaac.GetScreenHeight()/2-24)
	local num = 0
	for i,k in pairs(Isaac_Tower.editor.SpecialEditingData[name]) do
		Isaac_Tower.editor.SpecialEditMenu.numParam = Isaac_Tower.editor.SpecialEditMenu.numParam + 1
	end
	for i,k in pairs(Isaac_Tower.editor.SpecialEditingData[name]) do
		grid.EditData[k.ParamName] = grid.EditData[k.ParamName] or {}
		if k.Type == 1 then
			local knum = num+0
			local Rpos = centerPos+Vector(0,32*knum+16-Isaac_Tower.editor.SpecialEditMenu.numParam*16)
			Isaac_Tower.editor.AddButton(Menuname, knum, Rpos, 175, 16, UIs.TextBox(), function(button) 
				if button ~= 0 then return end
				
				local function resultCheck(result)
					local Otvet = k.ResultCheck(grid,result)
					if Otvet == true then
						grid.EditData[k.ParamName].Text = tostring(Isaac_Tower.editor.TextboxPopup.Text)..""
					end
					return Otvet
				end
				Isaac_Tower.editor.OpenTextboxPopup(k.onlyNumber, resultCheck, grid.EditData[k.ParamName].Text or k.Text)
			end, function(pos) 
				if k.HintText then
					font:DrawStringScaledUTF8(k.HintText,pos.X+6,pos.Y-8,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				end
				if grid.EditData[k.ParamName].Text then
					font:DrawStringScaledUTF8(grid.EditData[k.ParamName].Text,pos.X+4,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),0,false)
				end
			end)

		elseif k.Type == 2 then
			local knum = num+0
			local Rpos = centerPos+Vector(0,32*knum+16-Isaac_Tower.editor.SpecialEditMenu.numParam*16)

			local btnD = UIs.CounterDown()

			local function Createlist()
				local Lnum = 0
				local frame = 0

				local MouseOldPos = Vector(0,0)
				local offsetPos = Vector(0,0)
				--local StartPos = Rpos/1
				local OldRenderPos = Vector(0,0)

				local Sadspr = UIs.Var_Sel()
				Sadspr.Scale = Vector(1.5,0.5)
				Sadspr.Color = Color(0,0,0,0.2)
				Sadspr.Offset = Vector(2,2)

				Isaac_Tower.editor.AddButton(Menuname, tostring(knum).."shadow", Rpos+Vector(0,16), 96, 9, Sadspr, function(button) 
					if button ~= 0 then return end
				end, function(pos)
					Sadspr.Scale = Vector(1.5,0.5*Lnum)
					if frame>1 and not Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and (IsMouseBtnTriggered(0) or IsMouseBtnTriggered(1)) then
						Isaac_Tower.editor.RemoveButton(Menuname, tostring(knum).."shadow")
					else
						local poloskaOffset = 0
						if grid.EditData[k.ParamName].Text then
							poloskaOffset = font:GetStringWidthUTF8(grid.EditData[k.ParamName].Text)/2 + 4
						end
						UIs.TextEdPos:Render(Rpos+Vector(18+poloskaOffset,2))
						UIs.TextEdPos:Update()

						Isaac_Tower.editor.GetButton(Menuname, tostring(knum).."shadow").pos = Rpos+Vector(0,16) + offsetPos
						UIs.Hint_MouseMoving_Vert.Color = Color(5,5,5,1)
						local renderPos = Vector(146,Isaac.GetScreenHeight()-15)
						UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(0,1))
						UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(0,1))
						UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(1,0))
						UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(1,0))
						UIs.Hint_MouseMoving_Vert.Color = Color.Default
						UIs.Hint_MouseMoving_Vert:Render(renderPos)
					end
					frame = frame + 1

					local MousePos = Isaac_Tower.editor.MousePos
					if Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then
						--if MousePos.X < 120 and Isaac_Tower.editor.BlockPlaceGrid ~= false then
							--Isaac_Tower.editor.BlockPlaceGrid = true
						--end
						Isaac_Tower.editor.MouseDoNotPressOnButtons = true
						if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_grab" then
							Isaac_Tower.editor.MouseSprite = UIs.MouseGrab
						end
						if Input.IsMouseBtnPressed(0) then
							Isaac_Tower.editor.MouseSprite:SetFrame(1)
							local offset = MousePos - MouseOldPos
							offsetPos.Y = OldRenderPos.Y + offset.Y
						else
							Isaac_Tower.editor.MouseSprite:SetFrame(0)
							MouseOldPos = MousePos/1
							OldRenderPos = offsetPos/1
						end
					elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_grab" then
						Isaac_Tower.editor.MouseSprite = nil
					end
				end,true,-1)

				local maxOff = 0
				for rnam, romdat in pairs(k.Generation(grid)) do
					local qnum = Lnum+0
					local bntName = tostring(knum).."s" .. tostring(qnum)
					local Repos = Rpos + Vector(0, qnum*8 + 16)
					--local frame = 0
					local Sspr = UIs.Var_Sel()
					Sspr.Scale = Vector(1.5,0.5)
				
					local self
					self = Isaac_Tower.editor.AddButton(Menuname, bntName, Repos, 96*1.5, 9, Sspr, function(button) 
						if frame>2 and button ~= 0 then return end
						local Otvet = k.ResultCheck(grid,romdat)
						if Otvet == true then
							grid.EditData[k.ParamName].Text = romdat
						end
					end, function(pos)
						local strW = font:GetStringWidthUTF8(tostring(rnam))/2
						maxOff = maxOff < strW and strW or maxOff
						font:DrawStringScaledUTF8(tostring(rnam),pos.X+1,pos.Y-1,0.5,0.5,KColor(0.2,0.2,0.2,0.8),0,false) 
						font:DrawStringScaledUTF8(tostring(romdat),pos.X+maxOff+5,pos.Y-1,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 
						if frame>2 and not Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and (IsMouseBtnTriggered(0) or IsMouseBtnTriggered(1)) then
							Isaac_Tower.editor.RemoveButton(Menuname, tostring(knum).."s" .. tostring(qnum))
						else
							--Isaac_Tower.editor.GetButton(Menuname, bntName).pos = Repos + offsetPos
							self.pos = Repos + offsetPos
						end
						
					end,nil,-2)
					Lnum = Lnum + 1
				end
			end


			Isaac_Tower.editor.AddButton(Menuname, knum, Rpos, 175, 16, UIs.TextBox(), function(button) 
				if button ~= 0 then return end
				Createlist()
			end, function(pos) 
				if k.HintText then
					font:DrawStringScaledUTF8(k.HintText,pos.X+6,pos.Y-8,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				end
				if grid.EditData[k.ParamName].Text then
					font:DrawStringScaledUTF8(grid.EditData[k.ParamName].Text,pos.X+20,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),0,false)
				end
				--btnD:Render(pos)
			end)

			Isaac_Tower.editor.AddButton(Menuname, tostring(knum).."s", Rpos, 16, 16, UIs.CounterDown(), function(button) 
				if button ~= 0 then return end
				Createlist()
			end, function(pos)
			end,nil,-1)
		end
		num = num + 1
	end

	local preParams = TabDeepCopy(grid.EditData)
	--Isaac_Tower.editor.SpecialEditMenu.numParam = num
	local function hasChanges()
		for i,k in pairs(preParams) do
			if type(k) == "table" then
				local tr = 0
				for j,h in pairs(k) do
					tr = tr + 1
					if h ~= grid.EditData[i][j] then
						return true
					end
				end
				if tr == 0 then
					return true
				end
			end
		end
	end

	Isaac_Tower.editor.AddButton(Menuname, "Cancel", centerPos+Vector(62,15+16*num), 64, 16, UIs.ButtonWide(), function(button) 
		if button ~= 0 then return end
		Isaac_Tower.editor.SelectedMenu = "menuUp" --Isaac_Tower.editor.SpecialEditMenu.LastMenu
		Isaac_Tower.editor.IsStickyMenu = false
		if hasChanges() then
			Isaac_Tower.editor.MakeVersion()
		end
	end, function(pos) 
		font:DrawStringScaledUTF8(GetStr("Back"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
		if Isaac_Tower.editor.SelectedMenu == Isaac_Tower.editor.SpecialEditMenu.Name and Input.IsButtonTriggered(Keyboard.KEY_ENTER,0) then
			Isaac_Tower.editor.SelectedMenu = "menuUp"
			Isaac_Tower.editor.IsStickyMenu = false
		end
	end)
	--[[Isaac_Tower.editor.AddButton(Menuname, "Ok", centerPos+Vector(112,15+16*num), 64, 16, UIs.ButtonWide(), function(button) 
		if button ~= 0 then return end
		
	end, function(pos) 
		font:DrawStringScaledUTF8(GetStr("Ok"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
	end)]]
end

function Isaac_Tower.editor.SpecialEditMenu:onRender(menu)
	if (menu == Isaac_Tower.editor.TextboxPopup.MenuName and Isaac_Tower.editor.TextboxPopup.LastMenu == Isaac_Tower.editor.SpecialEditMenu.Name) or
	menu == Isaac_Tower.editor.SpecialEditMenu.Name then
		Isaac_Tower.RenderBlack(0.4)
		local CenPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2)
		UIs.SpcEDIT_menu_Down:Render(CenPos+Vector(0,Isaac_Tower.editor.SpecialEditMenu.numParam*16))
		UIs.SpcEDIT_menu_Cen.Scale = Vector(1,Isaac_Tower.editor.SpecialEditMenu.numParam*4+2)
		UIs.SpcEDIT_menu_Cen:Render(CenPos+Vector(0,-16-Isaac_Tower.editor.SpecialEditMenu.numParam*16))
		UIs.SpcEDIT_menu_Up:Render(CenPos+Vector(0,-(Isaac_Tower.editor.SpecialEditMenu.numParam)*16-28))

		Isaac_Tower.editor.RenderMenuButtons(Isaac_Tower.editor.SpecialEditMenu.Name)
	end
end
mod:AddPriorityCallback(Isaac_Tower.Callbacks.EDITOR_POST_MENUS_RENDER, 1, Isaac_Tower.editor.SpecialEditMenu.onRender)


local function RenderButtonHintText(text, pos)
	
	--DrawStringScaledBreakline(font, Isaac_Tower.editor.MouseHintText, pos.X, pos.Y, 0.5, 0.5, KColor(0.1,0.1,0.2,1), 60, "Left")
	local Center = false
	local BoxWidth = 0
    local line = 0
	if type(text) == "table" then
		UIs.HintTextBG1.Color = Color(1,1,1,0.5)
		UIs.HintTextBG2.Color = Color(1,1,1,0.5)
		UIs.HintTextBG2.Scale = Vector(text.Width/2+2.5,18*#text/4+2.5)
		UIs.HintTextBG2:Render(pos-Vector(2.5,2.5))
		UIs.HintTextBG1.Scale = Vector(text.Width/2+1,18*#text/4+1)
		UIs.HintTextBG1:Render(pos-Vector(1,1))

		for li, word in ipairs(text) do
			font:DrawStringScaledUTF8(word, pos.X, pos.Y+(line*font:GetLineHeight()*0.5), 0.5, 0.5, KColor(0.1,0.1,0.2,1), BoxWidth, Center)
			line = line + 1
		end
	elseif type(text) == "string" then
		for word in string.gmatch(text, '([^\n]+)') do
			font:DrawStringScaledUTF8(word, pos.X, pos.Y+(line*font:GetLineHeight()*0.5), 0.5, 0.5, KColor(0.1,0.1,0.2,1), BoxWidth, Center)
			line = line + 1
		end
	end
end


function Isaac_Tower.editor.RenderMenuButtons(menuName)
  --if type(Isaac_Tower.editor.MenuButtons[menuName]) == "table" then
--	for i,k in pairs(Isaac_Tower.editor.MenuButtons[menuName]) do
--		local renderPos = k.pos or Vector(50,50)
--		k.spr:Render(renderPos)
--		if k.render then
--			k.render(k.pos)
--		end
--	end
--  end
  	if type(Isaac_Tower.editor.MenuData[menuName]) == "table" and #Isaac_Tower.editor.MenuData[menuName].sortList>0 then
		--for i,k in pairs(Isaac_Tower.editor.MenuData[menuName].sortList) do
		for i=#Isaac_Tower.editor.MenuData[menuName].sortList,1,-1 do
			local dat = Isaac_Tower.editor.MenuData[menuName].sortList[i]
			local btn = Isaac_Tower.editor.MenuData[menuName].Buttons[dat.btn]
			local renderPos = btn.pos or Vector(50,50)
			btn.spr:Render(renderPos)
			if btn.render then
				btn.render(btn.pos)
			end
		end
	end
end

function Isaac_Tower.editor.DetectSelectedButton()
  if type(Isaac_Tower.editor.MenuData[Isaac_Tower.editor.SelectedMenu]) == "table" then
	local mousePos = Isaac_Tower.editor.MousePos
	
	local onceTouch = false
	for i,dt in pairs(Isaac_Tower.editor.MenuData[Isaac_Tower.editor.SelectedMenu].sortList) do
		local k = Isaac_Tower.editor.MenuData[Isaac_Tower.editor.SelectedMenu].Buttons[dt.btn]
		if not k then
			print("Not exist Button ",k, Isaac_Tower.editor.SelectedMenu, dt.btn)
		end
		if k.canPressed then
			if not onceTouch and mousePos.X>=k.pos.X and mousePos.Y>=k.pos.Y 
			and mousePos.X<(k.pos.X+k.x) and mousePos.Y<(k.pos.Y+k.y) then
				onceTouch = true
				if not k.IsSelected then
					k.IsSelected = 0
					k.spr:SetFrame(1)
				else
					k.IsSelected = k.IsSelected + 1
				end
				if IsMouseBtnTriggered(0) and not Isaac_Tower.editor.MouseDoNotPressOnButtons then
					k.func(0)
					break
				elseif IsMouseBtnTriggered(1) and not Isaac_Tower.editor.MouseDoNotPressOnButtons then
					k.func(1)
					break
				end
			else
				if k.IsSelected then
					k.IsSelected = nil
					k.spr:SetFrame(0)
				end
			end
		end
		if k.hintText and k.IsSelected and k.IsSelected > 10 then
			Isaac_Tower.editor.MouseHintText = k.hintText
		end
	end
  end
  --if Isaac_Tower.editor.MouseDoNotPressOnButtons then
	Isaac_Tower.editor.MouseDoNotPressOnButtons = nil
  --end
end


function Isaac_Tower.editor.SetSize(x,y)
	if x and y then
		Isaac_Tower.editor.Memory.CurrentRoom.Size = Vector(x, y)
	end
end


function Isaac_Tower.editor.Render()
	Isaac_Tower.RenderBlack(1)

	Isaac_Tower.editor.ScreenCenter = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2)

	for i,k in pairs(Isaac_Tower.editor.Overlay.menus) do
		if k.render and i ~= Isaac_Tower.editor.Overlay.selectedMenu then
			k.render(false, k)
		end
	end
	if Isaac_Tower.editor.Overlay.menus[Isaac_Tower.editor.Overlay.selectedMenu] 
	and Isaac_Tower.editor.Overlay.menus[Isaac_Tower.editor.Overlay.selectedMenu].render then
		Isaac_Tower.editor.Overlay.menus[Isaac_Tower.editor.Overlay.selectedMenu].render(true, Isaac_Tower.editor.Overlay.menus[Isaac_Tower.editor.Overlay.selectedMenu])
	end
	
	
	Isaac_Tower.editor.MousePos = Isaac.WorldToScreen(Input.GetMousePosition(true))
	--chosenGrid:Render(Isaac_Tower.editor.MousePos)
	--if Isaac_Tower.editor.MouseSprite then
	--	Isaac_Tower.editor.MouseSprite:Render(Isaac_Tower.editor.MousePos)
	--end
	
	--верхнее меню
	local MenuUpPos = Vector(Isaac.GetScreenWidth()/2, -50)
	UIs.MenuUp:Render(MenuUpPos)

	--font:DrawStringScaledUTF8(GetStr("Room Name:"),42,5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 
	--font:DrawStringScaledUTF8(Isaac_Tower.editor.Memory.CurrentRoom.Name,10,15,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 

	Isaac_Tower.editor.RenderMenuButtons("menuUp")

	local RightDownPos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
	local leftPos = 8 + Isaac_Tower.editor.Overlay.num * 16 + 8
	UIs.OverlayBarL:Render(RightDownPos-Vector(leftPos,16))
	UIs.OverlayBarC.Scale = Vector(Isaac_Tower.editor.Overlay.num,1)
	UIs.OverlayBarC:Render(RightDownPos-Vector(leftPos-8,16))
	UIs.OverlayBarR:Render(RightDownPos-Vector(8,16))

	Isaac_Tower.editor.RenderMenuButtons("Overlays")

	Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.EDITOR_POST_MENUS_RENDER, Isaac_Tower.editor.SelectedMenu, Isaac_Tower.editor.SelectedMenu)

	if Isaac_Tower.editor.SelectedMenu == "GridList" then
		Isaac_Tower.RenderBlack(0.4)
		UIs.GridList:Render(Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2))

		Isaac_Tower.editor.RenderMenuButtons("GridList")
	elseif Isaac_Tower.editor.SelectedMenu == Isaac_Tower.editor.TextboxPopup.MenuName then
		Isaac_Tower.RenderBlack(0.4)
		UIs.TextBoxPopupBack:Render(Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2-32))

		Isaac_Tower.editor.RenderMenuButtons(Isaac_Tower.editor.TextboxPopup.MenuName)
	elseif Isaac_Tower.editor.SelectedMenu == "grid" or Isaac_Tower.editor.SelectedMenu == "menuUp" then
		UIs.Hint_MouseMoving.Color = Color(5,5,5,1)
		local renderPos = Vector(6,Isaac.GetScreenHeight()-10)
		UIs.Hint_MouseMoving:Render(renderPos-Vector(0,1))
		UIs.Hint_MouseMoving:Render(renderPos+Vector(0,1))
		UIs.Hint_MouseMoving:Render(renderPos-Vector(1,0))
		UIs.Hint_MouseMoving:Render(renderPos+Vector(1,0))
		UIs.Hint_MouseMoving.Color = Color.Default
		UIs.Hint_MouseMoving:Render(renderPos)

		if Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) then
			
			if Input.IsButtonTriggered(Keyboard.KEY_Z,0) then
				Isaac_Tower.editor.BackToVersion(-1)
			elseif Input.IsButtonTriggered(Keyboard.KEY_Y,0) then
				Isaac_Tower.editor.BackToVersion(1)
			--elseif Input.IsButtonTriggered(Keyboard.KEY_S,0) then
			--	Isaac_Tower.editor.MakeVersion()
			end
		end
	end

	--Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.EDITOR_POST_MENUS_RENDER, Isaac_Tower.editor.SelectedMenu, Isaac_Tower.editor.SelectedMenu)

	if Isaac_Tower.editor.MouseSprite then
		Isaac_Tower.editor.MouseSprite:Render(Isaac_Tower.editor.MousePos)
	end
	if Isaac_Tower.editor.MouseHintText then
		local pos = Isaac_Tower.editor.MousePos
		--DrawStringScaledBreakline(font, Isaac_Tower.editor.MouseHintText, pos.X, pos.Y, 0.5, 0.5, KColor(0.1,0.1,0.2,1), 60, "Left")
		RenderButtonHintText(Isaac_Tower.editor.MouseHintText, pos+Vector(8,8))
	end
end

function Isaac_Tower.editor.MoveControl()
	if Isaac_Tower.game:IsPaused() then return end

	--[[local addPos = Vector(-Input.GetActionValue(ButtonAction.ACTION_LEFT, 0) + Input.GetActionValue(ButtonAction.ACTION_RIGHT, 0),
		-Input.GetActionValue(ButtonAction.ACTION_UP, 0) + Input.GetActionValue(ButtonAction.ACTION_DOWN, 0))
	

	Isaac_Tower.editor.GridStartPos = Isaac_Tower.editor.GridStartPos + addPos]]
	
	--Isaac_Tower.editor.MousePos = Isaac.WorldToScreen(Input.GetMousePosition(true)) --/4
	
	if not Isaac_Tower.editor.IsStickyMenu and not Input.IsMouseBtnPressed(0) then
		local OverlayDetX = Isaac_Tower.editor.Overlay.DetectPosX or 0
		local LastMenu = Isaac_Tower.editor.SelectedMenu and Isaac_Tower.editor.SelectedMenu..""
		
		if Isaac_Tower.editor.MousePos.Y < 50 then
			Isaac_Tower.editor.SelectedMenu = "menuUp"
		elseif Isaac_Tower.editor.MousePos.Y > Isaac.GetScreenHeight()-32 
		and Isaac_Tower.editor.MousePos.X > Isaac.GetScreenWidth()-OverlayDetX then
			Isaac_Tower.editor.SelectedMenu = "Overlays"
		else
			Isaac_Tower.editor.SelectedMenu = "grid"
		end

		--if Input.IsButtonTriggered(Keyboard.KEY_Q, 0) then
		--	Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu, Isaac_Tower.editor.GridListMenuPage)
		--end
		if Input.IsButtonPressed(Keyboard.KEY_Q, 0) then
			if LastMenu ~= "GridList" then
				Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu, Isaac_Tower.editor.GridListMenuPage)
			end
			Isaac_Tower.editor.SelectedMenu = "GridList"
		end
	end

	if Isaac_Tower.editor.MenuLogic[Isaac_Tower.editor.SelectedMenu] then
		Isaac_Tower.editor.MenuLogic[Isaac_Tower.editor.SelectedMenu](Isaac_Tower.editor.MousePos)
	end
	Isaac_Tower.editor.MouseHintText = nil
	Isaac_Tower.editor.DetectSelectedButton()
end


--UIs.Counter
--UIs.CounterUp
--UIs.CounterDown
Isaac_Tower.editor.AddButton("menuUp", "RoomName", Vector(46,27), 80, 16, UIs.TextBoxSmol(), function(button) 
	if button ~= 0 then return end
	Isaac_Tower.editor.OpenTextboxPopup(false, function(result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			if Isaac_Tower.Rooms[result] then
				return GetStr("ExistRoomName")
			end
			Isaac_Tower.Rooms[result] = TabDeepCopy(Isaac_Tower.Rooms[Isaac_Tower.editor.Memory.CurrentRoom.Name])
			if Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name] then
				Isaac_Tower.editor.Memory.Ver[result] = TabDeepCopy(Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name])
				Isaac_Tower.editor.Memory.Ver[Isaac_Tower.editor.Memory.CurrentRoom.Name] = nil
			end
			Isaac_Tower.Rooms[result].Name = result
			Isaac_Tower.Rooms[Isaac_Tower.editor.Memory.CurrentRoom.Name] = nil
			Isaac_Tower.editor.Memory.CurrentRoom.Name = result --Isaac_Tower.editor.Memory.CurrentRoom.Name
			Isaac_Tower.editor.MakeVersion()
			
			return true   
		end
	end, Isaac_Tower.editor.Memory.CurrentRoom.Name)
end, function(pos)
	font:DrawStringScaledUTF8(GetStr("Room Name:"),pos.X+1,pos.Y-10,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)  --42 5
	font:DrawStringScaledUTF8(Isaac_Tower.editor.Memory.CurrentRoom.Name,pos.X+3,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 
end)

Isaac_Tower.editor.AddButton("menuUp", "CounterX", Vector(132,12), 32, 32, UIs.Counter(), function(button)
	if button ~= 0 then return end
	Isaac_Tower.editor.OpenTextboxPopup(true, function(result)
		if not result then
			return true
		else
			if not tonumber(result) or tonumber(result)<1 then
				return GetStr("incorrectNumber")
			end
			Isaac_Tower.editor.Memory.CurrentRoom.Size.X = result
			return true
		end
	end, tostring(Isaac_Tower.editor.Memory.CurrentRoom.Size.X))
end, function(pos)
	font:DrawStringScaledUTF8("X",pos.X+16,pos.Y-15,1,1,KColor(0.1,0.1,0.2,1),1,true) 
	local num = math.floor(Isaac_Tower.editor.Memory.CurrentRoom.Size.X)
	local scale = num<100 and 1 or 0.5
	font:DrawStringScaledUTF8(num,pos.X+16,pos.Y+6+(scale==0.5 and 4 or 0),scale,scale,KColor(0.1,0.1,0.2,1),1,true) 
end)
Isaac_Tower.editor.AddButton("menuUp", "CounterXUp", Vector(164,12), 16, 16, UIs.CounterUp(), function(button) 
	if button ~= 0 then return end
	Isaac_Tower.editor.Memory.CurrentRoom.Size.X = Isaac_Tower.editor.Memory.CurrentRoom.Size.X + 1
end, function(pos) end)
Isaac_Tower.editor.AddButton("menuUp", "CounterXDown", Vector(164,28), 16, 16, UIs.CounterDown(), function(button) 
	if button ~= 0 then return end
	Isaac_Tower.editor.Memory.CurrentRoom.Size.X = Isaac_Tower.editor.Memory.CurrentRoom.Size.X - 1
end, function(pos) end)

Isaac_Tower.editor.AddButton("menuUp", "CounterY", Vector(186,12), 32, 32, UIs.Counter(), function(button)
	if button ~= 0 then return end
	Isaac_Tower.editor.OpenTextboxPopup(true, function(result)
		if not result then
			return true
		else
			if not tonumber(result) or tonumber(result)<1 then
				return GetStr("incorrectNumber")
			end
			Isaac_Tower.editor.Memory.CurrentRoom.Size.Y = result
			return true
		end
	end, tostring(Isaac_Tower.editor.Memory.CurrentRoom.Size.Y))
end, function(pos)
	font:DrawStringScaledUTF8("Y",pos.X+16,pos.Y-15,1,1,KColor(0.1,0.1,0.2,1),1,true) 
	local num = math.floor(Isaac_Tower.editor.Memory.CurrentRoom.Size.Y)
	local scale = num<100 and 1 or 0.5
	font:DrawStringScaledUTF8(num,pos.X+16,pos.Y+6+(scale==0.5 and 4 or 0),scale,scale,KColor(0.1,0.1,0.2,1),1,true) 
end)
Isaac_Tower.editor.AddButton("menuUp", "CounterYUp", Vector(218,12), 16, 16, UIs.CounterUp(), function(button) 
	if button ~= 0 then return end
	Isaac_Tower.editor.Memory.CurrentRoom.Size.Y = Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + 1
end, function(pos) end)
Isaac_Tower.editor.AddButton("menuUp", "CounterYDown", Vector(218,28), 16, 16, UIs.CounterDown(), function(button) 
	if button ~= 0 then return end
	Isaac_Tower.editor.Memory.CurrentRoom.Size.Y = Isaac_Tower.editor.Memory.CurrentRoom.Size.Y - 1
end, function(pos) end)
Isaac_Tower.editor.Overlay.SelectedTileSprite = nil
Isaac_Tower.editor.AddButton("menuUp", "SelectedGrid", Vector(240,0), 48, 48, UIs.Box48(), function() end, function(pos)
	font:DrawStringScaledUTF8(GetStr("Grid:"),pos.X+24,pos.Y,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true) 
	UIs.HintQ:Render(pos+Vector(39,39))
	--local grid = Isaac_Tower.editor.GridTypes.Grid[Isaac_Tower.editor.SelectedGridType or ""]
	--local menu = Isaac_Tower.editor.Overlay.menus[menuName].selectedTile
	--local grid = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu] 
	--	and Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu][Isaac_Tower.editor.SelectedGridType or ""]
	--if grid and grid.spr then
	--	grid.spr:Render(pos+Vector(12,12))
	if Isaac_Tower.editor.Overlay.SelectedTileSprite then
		Isaac_Tower.editor.Overlay.SelectedTileSprite:Render(pos+Vector(12,12))
	end
end, true) --Isaac_Tower.editor.GetConvertedEditorRoomForDebug() UIs.ToLog
Isaac_Tower.editor.AddButton("menuUp", "ToLog", Vector(296,12), 32, 32, UIs.ToLog, function(button) 
	if button ~= 0 then return end
	local str = Isaac_Tower.editor.GetConvertedEditorRoomForDebug() .. " Isaac_Tower.AddRoom(roomdata)"
	Isaac_Tower.editor.Memory.CurrentRoom.HasChanges = nil
	for i=1, math.ceil(string.len(str)/10000) do
		Isaac.DebugString( string.sub(str,(i-1)*10000,i*10000) )
	end
	if Isaac_Tower.RG then
		Isaac_Tower.editor.TryOpenClipBroad(str,Isaac_Tower.editor.Memory.CurrentRoom.Name)
	end
	--Isaac.DebugString( Isaac_Tower.editor.GetConvertedEditorRoomForDebug() )
end, function(pos) 
	font:DrawStringScaledUTF8(GetStr("ToLog1"),pos.X+20,pos.Y+2,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true) 
	font:DrawStringScaledUTF8(GetStr("ToLog2"),pos.X+20,pos.Y+10,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true) 
end)

Isaac_Tower.editor.AddButton("menuUp", "Test", Vector(336,12), 32, 32, UIs.TestRun, function(button) 
	if button ~= 0 then return end
	
	--Isaac_Tower.Rooms[Isaac_Tower.editor._EditorTestRoom] = Isaac_Tower.editor.GetConvertedEditorRoom()
	Isaac_Tower.Rooms[Isaac_Tower.editor.Memory.CurrentRoom.Name] = Isaac_Tower.editor.GetConvertedEditorRoom()
	Isaac_Tower.editor.Memory.LastRoom = TabDeepCopy(Isaac_Tower.editor.Memory.CurrentRoom)

	Isaac_Tower.editor.InEditorTestRoom = true
	Isaac_Tower.CloseEditor()
	Isaac_Tower.SetRoom(Isaac_Tower.editor.Memory.CurrentRoom.Name)
	for i=0,Isaac_Tower.game:GetNumPlayers()-1 do
		local d = Isaac.GetPlayer(i):GetData()
		local fent = d.Isaac_Tower_Data

		fent.State = 0
		fent.StateFrame = 0
		fent.InputWait = nil
	end
	
end, function(pos) 
	font:DrawStringScaledUTF8(GetStr("TestRun1"),pos.X+16,pos.Y+2,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true) 
	font:DrawStringScaledUTF8(GetStr("TestRun2"),pos.X+16,pos.Y+10,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true) 
end)

--UIs.Box48() --UIs.RoomSelect
Isaac_Tower.editor.RoomSelectMenu = {Name = "Room_Select", Frame = 0, StartPos = Vector(0,0), VertOffset = 0, State = 0}

Isaac_Tower.editor.AddButton("menuUp", "RoomSelect", Vector(8,12), 32, 32, UIs.RoomSelect, function(button)
	if button ~= 0 then return end

	local Menuname = Isaac_Tower.editor.RoomSelectMenu.Name
	Isaac_Tower.editor.SelectedMenu = Menuname
	Isaac_Tower.editor.IsStickyMenu = true
	Isaac_Tower.editor.RoomSelectMenu.Frame = 0
	Isaac_Tower.editor.RoomSelectMenu.State = 1
	Isaac_Tower.editor.RoomSelectMenu.StartPos.X = -120 --Vector(-120,0)

	Isaac_Tower.editor.RoomSelectMenu.GenRoomList()

	local roomNum = 0
	for i,k in pairs(Isaac_Tower.Rooms) do
		roomNum = roomNum + 1
	end

	local OldRenderPos = Vector(0,0)
	local MouseOldPos = Vector(0,0)
	Isaac_Tower.editor.MenuLogic[Isaac_Tower.editor.RoomSelectMenu.Name] = function(MousePos)
		local startPos = Isaac_Tower.editor.RoomSelectMenu.StartPos
		if Isaac_Tower.editor.RoomSelectMenu.State == 0 then
			if Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then
				--if MousePos.X < 120 and Isaac_Tower.editor.BlockPlaceGrid ~= false then
					--Isaac_Tower.editor.BlockPlaceGrid = true
				--end
				if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_grab" then
					Isaac_Tower.editor.MouseSprite = UIs.MouseGrab
				end
				if Input.IsMouseBtnPressed(0) then
					Isaac_Tower.editor.MouseSprite:SetFrame(1)
					local offset = MousePos - MouseOldPos
					Isaac_Tower.editor.RoomSelectMenu.StartPos.Y = math.min( 0, math.max( math.max(-200, -roomNum*16), OldRenderPos.Y + offset.Y) )
				else
					Isaac_Tower.editor.MouseSprite:SetFrame(0)
					MouseOldPos = MousePos/1
					OldRenderPos = Isaac_Tower.editor.RoomSelectMenu.StartPos/1
				end
			elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_grab" then
				Isaac_Tower.editor.MouseSprite = nil
				--Isaac_Tower.editor.BlockPlaceGrid = nil
			end
		elseif Isaac_Tower.editor.RoomSelectMenu.State == 1 then
			if startPos.X < 0 then
				startPos.X = startPos.X<-0.5 and (startPos.X*0.7) or 0
			else
				Isaac_Tower.editor.RoomSelectMenu.State = 0
			end
		elseif Isaac_Tower.editor.RoomSelectMenu.State == 2 then
			if startPos.X > -90 then
				startPos.X = startPos.X>-119.5 and (startPos.X*0.8 + -120*0.2) or -120
			else
				Isaac_Tower.editor.RoomSelectMenu.State = 0
				Isaac_Tower.editor.IsStickyMenu = false
			end
		end
		if Input.IsMouseBtnPressed(0) then
			if MousePos.X < 110 and Isaac_Tower.editor.BlockPlaceGrid ~= true then
				Isaac_Tower.editor.BlockPlaceGrid = true
			end
		else
			Isaac_Tower.editor.BlockPlaceGrid = nil
		end

		if not Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and not Isaac_Tower.editor.BlockPlaceGrid and MousePos.X > 110 and Input.IsMouseBtnPressed(0) then
			Isaac_Tower.editor.RoomSelectMenu.State = 2
		end
		--UIs.RoomSelectBack:Render(Isaac_Tower.editor.RoomSelectMenu.StartPos)
	end
end, function(pos)
	font:DrawStringScaledUTF8(GetStr("rooms"),pos.X+16,pos.Y-10,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
end)
Isaac_Tower.editor.ButtonSetHintText("menuUp", "RoomSelect",GetStr("roomlist_hint"))

--UIs.RoomSelectBack
function Isaac_Tower.editor.RoomSelectMenu.GenRoomList()
	local num = 2
	local rooms = {}
	for i,k in pairs(Isaac_Tower.Rooms) do
		rooms[#rooms+1] = k.Name
	end
	table.sort(rooms)
	for i,k in pairs(rooms) do
		if k ~= Isaac_Tower.editor._EditorTestRoom then
			local qnum = num+0
			local pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16)
			local self
			self = Isaac_Tower.editor.AddButton(Isaac_Tower.editor.RoomSelectMenu.Name, qnum, pos, 96, 16, UIs.Var_Sel(), function(button)
				if button ~= 0 or Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then return end

				Isaac_Tower.editor.ChangeRoom(k) --.Name
				Isaac_Tower.editor.RoomSelectMenu.State = 2
			end, function(pos)
				font:DrawStringScaledUTF8(k,pos.X+12,pos.Y+4,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 
				--Isaac_Tower.editor.GetButton(Isaac_Tower.editor.RoomSelectMenu.Name, qnum).pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16)
				self.pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16)
			end)
			num = num + 1
		end
	end

	local qnum = 1
	local pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16-8)
	local self 
	self = Isaac_Tower.editor.AddButton(Isaac_Tower.editor.RoomSelectMenu.Name, qnum, pos, 96, 16, UIs.Var_Sel(), function(button)
		if button ~= 0 or Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then return end

		local bumun
		::back::
		local newName = bumun and "newroom "..tostring(bumun) or "newroom"
		if Isaac_Tower.Rooms[newName] then
			bumun = bumun and (bumun+1) or 1
			goto back
		end
		Isaac_Tower.editor.PreGenEmptyRoom()
		Isaac_Tower.editor.Memory.CurrentRoom.Name = newName
		Isaac_Tower.Rooms[newName] = Isaac_Tower.editor.GetConvertedEditorRoom()
		Isaac_Tower.editor.MenuData.grid = nil
		Isaac_Tower.editor.RoomSelectMenu.State = 2
	end, function(pos)
		font:DrawStringScaledUTF8(GetStr("newroom"),pos.X+12,pos.Y+4,0.5,0.5,KColor(0.2,0.2,0.4,1),0,false) 
		self.pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16-8)
		--Isaac_Tower.editor.MenuButtons[Isaac_Tower.editor.RoomSelectMenu.Name][qnum].pos = Isaac_Tower.editor.RoomSelectMenu.StartPos + Vector(0, qnum*16)
	end)
	--Isaac_Tower.editor.RoomSelectMenu.Frame = Isaac_Tower.editor.RoomSelectMenu.Frame + 1
end

function Isaac_Tower.editor.RoomSelectMenu:onRender(menu)
	if menu == Isaac_Tower.editor.RoomSelectMenu.Name then
		Isaac_Tower.RenderBlack((Isaac_Tower.editor.RoomSelectMenu.StartPos.X+90)/225)
		UIs.RoomSelectBack:Render(Vector(Isaac_Tower.editor.RoomSelectMenu.StartPos.X, 400))

		Isaac_Tower.editor.RenderMenuButtons(menu)

		if Input.IsButtonTriggered(Keyboard.KEY_ESCAPE, 0) then
			Isaac_Tower.editor.RoomSelectMenu.State = 2
		end
		UIs.Hint_MouseMoving_Vert.Color = Color(5,5,5,1)
		local renderPos = Vector(Isaac_Tower.editor.RoomSelectMenu.StartPos.X + 106,Isaac.GetScreenHeight()-10)
		UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(0,1))
		UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(0,1))
		UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(1,0))
		UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(1,0))
		UIs.Hint_MouseMoving_Vert.Color = Color.Default
		UIs.Hint_MouseMoving_Vert:Render(Vector(Isaac_Tower.editor.RoomSelectMenu.StartPos.X + 106,Isaac.GetScreenHeight()-10))
	end
end
mod:AddCallback(Isaac_Tower.Callbacks.EDITOR_POST_MENUS_RENDER, Isaac_Tower.editor.RoomSelectMenu.onRender)

local PosToZeroPos = Vector(Isaac.GetScreenWidth()-130, Isaac.GetScreenHeight()-22)
local self 
self = Isaac_Tower.editor.AddButton("Overlays", "PosToZero", PosToZeroPos, 16, 32, UIs.PositionSbros(), function(button) 
	if button ~= 0 then return end
	
	Isaac_Tower.editor.GridStartPos = Vector(10,60)
end, function(pos) 
	if Isaac.GetFrameCount()%30 == 0 then
		self.pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-22) - Vector(Isaac_Tower.editor.Overlay.DetectPosX-20, 0)
		--Isaac_Tower.editor.MenuButtons["Overlays"]["PosToZero"].pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-22) - Vector(Isaac_Tower.editor.Overlay.DetectPosX-4, 0)
	end
	--Isaac_Tower.editor.Overlay.DetectPosX
end)

local PosToZeroPos = Vector(Isaac.GetScreenWidth()-130-18, Isaac.GetScreenHeight()-22)

local self 
self = Isaac_Tower.editor.AddButton("Overlays", "GridScaleUp", PosToZeroPos, 16, 8, UIs.CounterUpSmol(), function(button) 
	if button ~= 0 then return end
	local h = Isaac_Tower.editor.GridScale
	Isaac_Tower.editor.GridScale = math.min(3, Isaac_Tower.editor.GridScale+1)
	if h-Isaac_Tower.editor.GridScale ~= 0 then
		local rev = (Isaac_Tower.editor.GridStartPos-Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2+20)) *(3-Isaac_Tower.editor.GridScale/2)
		Isaac_Tower.editor.GridStartPos = Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2+20) + rev
	end
end, function(pos) 
	if Isaac.GetFrameCount()%30 == 0 then
		self.pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-22) - Vector(Isaac_Tower.editor.Overlay.DetectPosX-2, 0)
	end
end)
local self 
self = Isaac_Tower.editor.AddButton("Overlays", "GridScaleDpwn", PosToZeroPos+Vector(0,8), 16, 8, UIs.CounterDownSmol(), function(button) 
	if button ~= 0 then return end
	local h = Isaac_Tower.editor.GridScale
	Isaac_Tower.editor.GridScale = math.max(1, Isaac_Tower.editor.GridScale-1)
	if h-Isaac_Tower.editor.GridScale ~= 0 then
		local rev = (Isaac_Tower.editor.GridStartPos-Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2+20)) /(Isaac_Tower.editor.GridScale+1)
		Isaac_Tower.editor.GridStartPos = Isaac_Tower.editor.GridStartPos - rev
	end
end, function(pos) 
	if Isaac.GetFrameCount()%30 == 0 then
		self.pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-22+8) - Vector(Isaac_Tower.editor.Overlay.DetectPosX-2, 0)
	end
end)

--local self 
--self = Isaac_Tower.editor.AddButton("Overlays", "GridScale", PosToZeroPos, 16, 32, UIs.PositionSbros(), function(button) 
--	if button ~= 0 then return end
--end, function(pos) 
--	if Isaac.GetFrameCount()%30 == 0 then
--		self.pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-22) - Vector(Isaac_Tower.editor.Overlay.DetectPosX-2, 0)
--	end
--	font:DrawStringScaledUTF8(Isaac_Tower.editor.GridScale,pos.X+12,pos.Y+4,0.5,0.5,KColor(0.2,0.2,0.4,1),0,false)
--end)



local greyColor = Color(1,1,1,1)
greyColor:SetColorize(1,1,1,1)
local greyColorObs = Color(0.8,0.8,0.8,0.8)
greyColorObs:SetColorize(1,1,1,0.2)

Isaac_Tower.editor.AddOverlay("Collision", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",0), function(IsSelected)
	if IsSelected then
		local prescale = Isaac_Tower.sprites.Col0Grid.Scale/1

		Isaac_Tower.sprites.Col0Grid.Scale = Vector(Isaac_Tower.editor.Memory.CurrentRoom.Size.X/1.77,2)
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(13,13), nil, Vector(0,22))
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(13,11+Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*13), nil, Vector(0,22))
		Isaac_Tower.sprites.Col0Grid.Scale = Vector(2, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y/1.77-0.16)
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(13,15), nil, Vector(22,0))
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(11+Isaac_Tower.editor.Memory.CurrentRoom.Size.X*13,15), nil, Vector(22,0))

		Isaac_Tower.sprites.Col0Grid.Scale = prescale
	end
end)

local holdMouse
Isaac_Tower.editor.AddOverlay("Grid", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",1), function(IsSelected, self)
	local Gridscale = Isaac_Tower.editor.GridScale
	local overlayData = self --Isaac_Tower.editor.GetOverlay("Grid")
	if not overlayData.lists then
		overlayData.lists = {"Solid","SolidFake"}
	end

	local startPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale - Vector(26*2,26*2)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	local EndPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/Gridscale
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	if IsSelected then
		local mouseOffset = Vector(0,0)
		local pGrid = Isaac_Tower.editor.GridTypes.Grid[Isaac_Tower.editor.SelectedGridType or ""]
		if pGrid and pGrid.size and pGrid.size.X then
			mouseOffset = pGrid.size*13/4
		end

		local algMousePos = Isaac_Tower.editor.MousePos - Isaac_Tower.editor.GridStartPos - mouseOffset
		local xs,ys = math.floor(algMousePos.Y/(26/2)/Gridscale), math.floor(algMousePos.X/(26/2)/Gridscale)
		if xs>=0 and ys>=0 and Isaac_Tower.editor.Memory.CurrentRoom.Size.Y>=(xs+1) and Isaac_Tower.editor.Memory.CurrentRoom.Size.X>=(ys+1) then
			Isaac_Tower.editor.SelectedGrid = {xs+1, ys+1}
		else
			Isaac_Tower.editor.SelectedGrid = nil
		end
	end

	--for y= math.max(2,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y+1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1) do   --Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1 do
	--	local ypos = 26*y/4
	--	for x=math.max(2,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X+1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1) do
	local Col0GridScale
	if Gridscale ~= 1 then
		Col0GridScale = Isaac_Tower.sprites.Col0Grid.Scale/1
		Isaac_Tower.sprites.Col0Grid.Scale = Isaac_Tower.sprites.Col0Grid.Scale*Gridscale
		Isaac_Tower.sprites.chosenGrid.Scale = Isaac_Tower.sprites.Col0Grid.Scale
	end

	local RG = Isaac_Tower.RG
	local lists = Isaac_Tower.editor.Memory.CurrentRoom --.Solid
	local Flist = overlayData.lists
	local main = Flist[self.Layer+1]
	local list = lists[main]
	for y=math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y) do  --for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ypos = 26*y/2
		local yposr = 26*(y-1)/2
		for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X) do  --for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local xr,yr = x-1,y-1
			local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, yposr)*Gridscale --, x*26/2)
			--Col0Grid:Render(renderpos)
			--local list = lists[main]
			local grid = list[y] and list[y][x]
			--local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
			
			for l=1,#Flist do
				if main ~= Flist[l] then
					local list = lists[Flist[l]]
					local grid = list[y] and list[y][x]
					if grid then
						if not IsSelected then
							renderpos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, yposr)*Gridscale
						else
							if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
								list[y][x] = nil
							end
						end
						
						if grid.sprite then
							grid.sprite.Color = Color(.7,.7,1,0.7)
							local scale = grid.sprite.Scale/1
							grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
							grid.sprite:Render(renderpos)
							grid.sprite.Scale = scale
							grid.sprite.Color = Color.Default
						end
					end
				end
			end
			if grid then
				if not IsSelected then
					renderpos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, yposr)*Gridscale
				else
					if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
						list[y][x] = nil
					end
				end
				
				if grid.sprite then
					local scale = grid.sprite.Scale/1
					grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
					grid.sprite:Render(renderpos)
					grid.sprite.Scale = scale
				end
			end

			if IsSelected then
				local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
				if not RG then
					Isaac_Tower.sprites.Col0Grid:Render(renderpos)
				end
				
				if Isaac_Tower.editor.SelectedMenu == "grid" and not Isaac_Tower.editor.BlockPlaceGrid
				and selGrid and not Isaac_Tower.game:IsPaused() then
					Isaac_Tower.sprites.chosenGrid:Render(renderpos)

					local pGrid = Isaac_Tower.editor.GridTypes.Grid[Isaac_Tower.editor.SelectedGridType or ""]
					if pGrid then
						
						if Input.IsMouseBtnPressed(0) then
							if not pGrid.size or CheckEmpty(list, Vector(x,y), pGrid.size) then
								--if not list[y] then
								--	list[y] = {}
								--end
								--if not list[y][x] then
								--	list[y][x] = {}
								--end
								SafePlacingTable(list,y,x)
								list[y][x].sprite = pGrid.trueSpr
								list[y][x].info = pGrid.info
								list[y][x].type = Isaac_Tower.editor.SelectedGridType
								if pGrid.size then
									for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
										if not list[k[1]] then
											list[k[1]] = {}
										end
										if not list[k[1]][k[2]] then
											list[k[1]][k[2]] = {}
										end
										list[k[1]][k[2]].Parent = Vector(x,y)
									end
								end
							end
							holdMouse = 0
						elseif grid and Input.IsMouseBtnPressed(1) then
							if grid.Parent then
								local par = list[grid.Parent.Y][grid.Parent.X]
								if Isaac_Tower.editor.GridTypes.Grid[par.type] and Isaac_Tower.editor.GridTypes.Grid[par.type].size then
									for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Grid[par.type].size)) do
										list[k[1]][k[2]] = nil
									end
								end
							end
							list[y][x] = nil
							holdMouse = 1
						end
					end
				end
			end
		end
	end
	if IsSelected and RG then
		local endPos = (Isaac_Tower.editor.GridStartPos)+Isaac_Tower.editor.Memory.CurrentRoom.Size*(26/2)*Gridscale
		Isaac_Tower.editor.RenderGrid(Isaac_Tower.editor.GridStartPos,26/2*Gridscale,26/2*Gridscale,endPos.X,endPos.Y,Gridscale)
		if Isaac_Tower.editor.SelectedGrid then
			local xr,yr = Isaac_Tower.editor.SelectedGrid[2]-1, Isaac_Tower.editor.SelectedGrid[1]-1
			local RenderPos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, yr*26/2)*Gridscale
			Isaac_Tower.sprites.chosenGrid:Render(RenderPos)
		end
	end
	if Col0GridScale then
		Isaac_Tower.sprites.Col0Grid.Scale = Col0GridScale
		Isaac_Tower.sprites.chosenGrid.Scale = Col0GridScale
	end

	if IsSelected and Isaac_Tower.editor.SelectedGrid then
		local pGrid = Isaac_Tower.editor.GridTypes.Grid[Isaac_Tower.editor.SelectedGridType]
		if pGrid then
			local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
			local yr,xr = y-1,x-1
			local renderpos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, 26*yr/2)*Gridscale
			
			if (list[y] and list[y][x]) or pGrid.size and not CheckEmpty(list, Vector(x,y), pGrid.size) then
				pGrid.trueSpr.Color = Color(2,0.5,0.5,0.5)
			else
				pGrid.trueSpr.Color = greyColorObs
			end
			
			local trueScale = pGrid.trueSpr.Scale/1
			pGrid.trueSpr.Scale = Vector(0.5, 0.5) * Gridscale
			pGrid.trueSpr:Render(renderpos)
			pGrid.trueSpr.Color = Color.Default
			pGrid.trueSpr.Scale = trueScale
		end
	end
	
	if holdMouse and not Input.IsMouseBtnPressed(holdMouse) then
		holdMouse = nil
		Isaac_Tower.editor.MakeVersion()
	end
end, function(tab)
	tab.SolidList = {
		dgfx='gfx/fakegrid/basement.png',
		extraAnim=GetGridListAnimNames(),
	}
	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Solid[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				tab.SolidList[#tab.SolidList+1] = TabDeepCopy(grid.info)
				tab.SolidList[#tab.SolidList].pos = Vector(x,y)
			end
		end
	end
end, function(str)
	str = str .. "\nSolidList={\n"
	local solidTab = "  gfx='gfx/fakegrid/tutorial.png',\n"
	solidTab = solidTab .. "  extraAnim={" .. GetGridListAnimNamesStr() .. "},\n"
	--solidTab = solidTab .. "  useWorldPos = true,"
	
	local startPos = Vector(-40,100)
	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Solid[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				--local pos = startPos + Vector(20+(x-1)*40, 20+(y-1)*40)
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. ")," 
				for param, dat in pairs(grid.info) do
					if type(dat) == "string" then
						solidTab = solidTab..param.."='" .. dat .. "',"
					else
						solidTab = solidTab..param.."=" .. dat .. ","
					end
				end
				--EditorType
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},"

	str = str .. "\nSolidFakeList={\n"
	local solidTab = "  gfx='gfx/fakegrid/tutorial.png',\n"
	solidTab = solidTab .. "  extraAnim={" .. GetGridListAnimNamesStr() .. "},\n"

	local list = Isaac_Tower.editor.Memory.CurrentRoom.SolidFake
	local neigh
	neigh = function(x, y, index)
		local grid = list[y] and list[y][x-1]
		if grid and not grid.group then
			grid.group = index
			neigh(x-1, y, index)
		end
		local grid = list[y] and list[y][x+1]
		if grid and not grid.group then
			grid.group = index
			neigh(x+1, y, index)
		end
		local grid = list[y-1] and list[y-1][x]
		if grid and not grid.group then
			grid.group = index
			neigh(x, y-1, index)
		end
		local grid = list[y+1] and list[y+1][x]
		if grid and not grid.group then
			grid.group = index
			neigh(x, y+1, index)
		end
	end
	
	local group
	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.SolidFake[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]	
			if grid and grid.info and not grid.group then
				if not group then
					group = 1
				else
					group = group + 1
				end
				grid.group = group
				neigh(x,y, group)
			end
		end
	end

	for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.SolidFake[y]
		for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				--local pos = startPos + Vector(20+(x-1)*40, 20+(y-1)*40)
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. ")," 
				for param, dat in pairs(grid.info) do
					if type(dat) == "string" then
						solidTab = solidTab..param.."='" .. dat .. "',"
					else
						solidTab = solidTab..param.."=" .. dat .. ","
					end
				end
				--EditorType
				local pGrid = Isaac_Tower.editor.GridTypes.Grid[grid.type]
				local Addsize = pGrid.size and (pGrid.size-Vector(1,1)) or Vector(0,0)
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"

				solidTab = solidTab .. "gr=" .. grid.group .. ","
				solidTab = solidTab .. "chl={"
				solidTab = solidTab .. "{"..(y+1+Addsize.Y)..","..(x+1+Addsize.X).."},"
				solidTab = solidTab .. "{"..(y+1+Addsize.Y)..","..(x-1).."},"
				solidTab = solidTab .. "{"..(y-1)..","..(x+1+Addsize.Y).."},"
				solidTab = solidTab .. "{"..(y-1)..","..(x-1).."},},"

				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},"

	return str
end)

local holdMouse
Isaac_Tower.editor.AddOverlay("Obstacle", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",2), function(IsSelected)
		local Gridscale = Isaac_Tower.editor.GridScale

	local startPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale - Vector(26*2,26*2)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/4)), math.ceil(startPosRender.Y/(26/4)))
	local EndPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/Gridscale
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/4)), math.ceil(EndPosRender.Y/(26/4)))

	--local startPosRender = -Isaac_Tower.editor.GridStartPos - Vector(26/2,26/2)
	--local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/4)), math.ceil(startPosRender.Y/(26/4)))
	--local EndPosRender = -Isaac_Tower.editor.GridStartPos + Vector(26/2,26/2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
	--local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/4)), math.ceil(EndPosRender.Y/(26/4)))
	
	if IsSelected then
		local algMousePos = Isaac_Tower.editor.MousePos - Isaac_Tower.editor.GridStartPos
		local xs,ys = math.floor(algMousePos.Y/(26/4)/Gridscale), math.floor(algMousePos.X/(26/4)/Gridscale)
		if xs>=0 and ys>=0 
		and Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2-1>=xs and Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2-1>=ys then
			Isaac_Tower.editor.SelectedGrid = {xs+2, ys+2}
		else
			Isaac_Tower.editor.SelectedGrid = nil
		end
		Isaac_Tower.RenderBlack(0.2)
	end

	local Col0GridScale
	if Gridscale ~= 1 then
		Col0GridScale = Isaac_Tower.sprites.Col0GridHalf.Scale/1
		Isaac_Tower.sprites.Col0GridHalf.Scale = Isaac_Tower.sprites.Col0GridHalf.Scale*Gridscale
		Isaac_Tower.sprites.chosenGridHalf.Scale = Isaac_Tower.sprites.Col0GridHalf.Scale
	end

	local RG = Isaac_Tower.RG
	--if IsSelected and RG then
	--	local endPos = (Isaac_Tower.editor.GridStartPos)+Isaac_Tower.editor.Memory.CurrentRoom.Size*(26/2)*Gridscale
	--	Isaac_Tower.editor.RenderGrid(Isaac_Tower.editor.GridStartPos,26/4*Gridscale,26/4*Gridscale,endPos.X,endPos.Y,Gridscale)
	--end
	local list = Isaac_Tower.editor.Memory.CurrentRoom.Obs
	for y= math.max(2,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y+1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1) do   --Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1 do
		local yposr = 26*(y-2)/4
		for x=math.max(2,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X+1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1) do   --Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1 do
			local xr,yr = x-2,y-2
			local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, yposr)*Gridscale
			--Col0Grid:Render(renderpos)	
			local grid = list[y] and list[y][x]
			--local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
			
			if grid then
				if not IsSelected  then
					renderpos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, yposr)*Gridscale 
				end
				
				if grid.sprite then
					--if not IsSelected then
					--	local scale = grid.sprite.Scale/1
					--	grid.sprite.Scale = Vector(0.5, 0.5)
					--	--grid.sprite.Color = greyColor
					--	grid.sprite:Render(renderpos)
					--	grid.sprite.Scale = scale
					--	--grid.sprite.Color = Color(1,1,1,1)
					--else
						local scale = grid.sprite.Scale/1
						grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
						grid.sprite:Render(renderpos)
						grid.sprite.Scale = scale
					--end
				end
			end

			if IsSelected then
				local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
				--if ScreenWidth > renderpos.X and ScreenHeight > renderpos.Y
				--and 0 < renderpos.X and 0 < renderpos.Y then
				if not RG then
					Isaac_Tower.sprites.Col0GridHalf:Render(renderpos)
				end
				
				if Isaac_Tower.editor.SelectedMenu == "grid" and not Isaac_Tower.editor.BlockPlaceGrid
				and selGrid and not Isaac_Tower.game:IsPaused() then
					--if not RG then
						Isaac_Tower.sprites.chosenGridHalf:Render(renderpos)
					--end

					local pGrid = Isaac_Tower.editor.GridTypes.Obstacle[Isaac_Tower.editor.SelectedGridType or ""]
					if pGrid then
						
						if Input.IsMouseBtnPressed(0) then
							holdMouse = 0
							if not pGrid.size or CheckEmpty(list, Vector(x,y), pGrid.size) then
								--if not list[y] then
								--	list[y] = {}
								--end
								--if not list[y][x] then
								--	list[y][x] = {}
								--end
								SafePlacingTable(list,y,x)
								list[y][x].sprite = pGrid.trueSpr
								list[y][x].info = pGrid.info
								list[y][x].type = Isaac_Tower.editor.SelectedGridType
								if pGrid.size then
									for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
										--if not list[k[1]] then
										--	list[k[1]] = {}
										--end
										--if not list[k[1]][k[2]] then
										--	list[k[1]][k[2]] = {}
										--end
										SafePlacingTable(list,k[1],k[2])
										list[k[1]][k[2]].Parent = Vector(x,y)
									end
								end
							end
						elseif grid and Input.IsMouseBtnPressed(1) then
							--list[y][x] = nil
							if grid.Parent then
								local par = list[grid.Parent.Y][grid.Parent.X]
								if Isaac_Tower.editor.GridTypes.Obstacle[par.type] and Isaac_Tower.editor.GridTypes.Obstacle[par.type].size then
									for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Obstacle[par.type].size)) do
										list[k[1]][k[2]] = nil
									end
								end
							end
							list[y][x] = nil
							holdMouse = 1
						end
					end
				end
			end
		end
	end
	if IsSelected and RG then
		local endPos = (Isaac_Tower.editor.GridStartPos)+Isaac_Tower.editor.Memory.CurrentRoom.Size*(26/2)*Gridscale
		Isaac_Tower.editor.RenderGrid(Isaac_Tower.editor.GridStartPos,26/4*Gridscale,26/4*Gridscale,endPos.X,endPos.Y,Gridscale)
		if Isaac_Tower.editor.SelectedGrid then
			local xr,yr = Isaac_Tower.editor.SelectedGrid[2]-2, Isaac_Tower.editor.SelectedGrid[1]-2
			local RenderPos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, yr*26/4)*Gridscale
			Isaac_Tower.sprites.chosenGridHalf:Render(RenderPos)
		end
	end
	if Col0GridScale then
		Isaac_Tower.sprites.Col0GridHalf.Scale = Col0GridScale
		Isaac_Tower.sprites.chosenGridHalf.Scale = Col0GridScale
	end
	if IsSelected and Isaac_Tower.editor.SelectedGrid then
		local pGrid = Isaac_Tower.editor.GridTypes.Obstacle[Isaac_Tower.editor.SelectedGridType]
		if pGrid then
			local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
			local renderpos = Isaac_Tower.editor.GridStartPos + Vector((x-2)*26/4, 26*(y-2)/4)*Gridscale
			
			if (list[y] and list[y][x]) or pGrid.size and not CheckEmpty(list, Vector(x,y), pGrid.size) then
				pGrid.trueSpr.Color = Color(2,0.5,0.5,0.5)
			else
				pGrid.trueSpr.Color = greyColorObs
			end
			
			local trueScale = pGrid.trueSpr.Scale/1
			pGrid.trueSpr.Scale = Vector(0.5, 0.5)*Gridscale
			pGrid.trueSpr:Render(renderpos)
			pGrid.trueSpr.Color = Color.Default
			pGrid.trueSpr.Scale = trueScale
		end
	end
	if holdMouse and not Input.IsMouseBtnPressed(holdMouse) then
		holdMouse = nil
		Isaac_Tower.editor.MakeVersion()
	end
end, function(tab)
	tab.ObsList = {
		--dgfx='gfx/fakegrid/basement.png',
		--extraAnim=GetGridListAnimNames(),
	}
	for y=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1 do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Obs[y]
		for x=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1 do
			
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				tab.ObsList[#tab.ObsList+1] = TabDeepCopy(grid.info)
				tab.ObsList[#tab.ObsList].pos = Vector(x-1,y-1)
			end
		end
	end
end, function(str)
	str = str .. "\nObsList={\n"
	local solidTab = "  gfx='gfx/fakegrid/tutorial.png',\n"
	--solidTab = solidTab .. "  extraAnim={" .. GetGridListAnimNamesStr() .. "},\n"
	--solidTab = solidTab .. "  useWorldPos = true,"
	
	local startPos = Vector(-40,100)
	for y=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2+1 do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Obs[y]
		for x=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2+1 do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				--local pos = startPos + Vector(20+(x-1)*40, 20+(y-1)*40)
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X)-1 .. "," .. math.ceil(pos.Y)-1 .. ")," 
				for param, dat in pairs(grid.info) do
					if type(dat) == "string" then
						solidTab = solidTab..param.."='" .. dat .. "',"
					else
						solidTab = solidTab..param.."=" .. dat .. ","
					end
				end
				--EditorType
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},"
	return str
end)

Isaac_Tower.editor.AddOverlay("Enemies", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",4), function(IsSelected, self)
	local Gridscale = Isaac_Tower.editor.GridScale
	local overlayData = self --Isaac_Tower.editor.GetOverlay("Grid")
	--if not overlayData.lists then
	--	overlayData.lists = {"Enemies","Bonus"}
	--end

	local startPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale - Vector(26*2,26*2)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/4)), math.ceil(startPosRender.Y/(26/4)))
	local EndPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/Gridscale
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/4)), math.ceil(EndPosRender.Y/(26/4)))

	--local startPosRender = -Isaac_Tower.editor.GridStartPos - Vector(26*2,26*2)
	--local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	--local EndPosRender = -Isaac_Tower.editor.GridStartPos + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
	--local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	if IsSelected then
		local mouseOffset = Vector(0,0)
		local pGrid = Isaac_Tower.editor.GridTypes.Enemies[Isaac_Tower.editor.SelectedGridType or ""]
		if pGrid and pGrid.size and pGrid.size.X then
			mouseOffset = pGrid.size*13/4*Gridscale
		end

		local algMousePos = Isaac_Tower.editor.MousePos - Isaac_Tower.editor.GridStartPos - mouseOffset
		local xs,ys = math.floor(algMousePos.Y/(26/4)/Gridscale), math.floor(algMousePos.X/(26/4)/Gridscale)
		if xs>=0 and ys>=0 and Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2-1>=xs and Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2-1>=ys then
			Isaac_Tower.editor.SelectedGrid = {xs+1+1, ys+1+1}
		else
			Isaac_Tower.editor.SelectedGrid = nil
		end
	end

	local Col0GridScale
	local enemScaleOffset = Vector(0,0)
	if Gridscale ~= 1 then
		Col0GridScale = Isaac_Tower.sprites.Col0GridHalf.Scale/1
		Isaac_Tower.sprites.Col0GridHalf.Scale = Isaac_Tower.sprites.Col0GridHalf.Scale*Gridscale
		Isaac_Tower.sprites.chosenGridHalf.Scale = Isaac_Tower.sprites.Col0GridHalf.Scale
		enemScaleOffset = Vector(13,13)/2*(Gridscale-1)
	end
	local RG = Isaac_Tower.RG
	if IsSelected and Isaac_Tower.RG then
		local endPos = (Isaac_Tower.editor.GridStartPos)+Isaac_Tower.editor.Memory.CurrentRoom.Size*(26/2)*Gridscale
		Isaac_Tower.editor.RenderGrid(Isaac_Tower.editor.GridStartPos,26/4*Gridscale,26/4*Gridscale,endPos.X,endPos.Y,Gridscale)
		if Isaac_Tower.editor.SelectedGrid then
			local xr,yr = Isaac_Tower.editor.SelectedGrid[2]-2, Isaac_Tower.editor.SelectedGrid[1]-2
			local RenderPos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, yr*26/4)*Gridscale
			Isaac_Tower.sprites.chosenGridHalf:Render(RenderPos)
		end
	end

	--[[local listSecond = Isaac_Tower.editor.Memory.CurrentRoom.Bonus
	for y=math.max(2,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2) do
		local ypos = 26*(y-2)/4
		for x=math.max(2,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2) do
			local xr = x-1-1
			local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, ypos)*Gridscale
			local grid = listSecond[y] and listSecond[y][x]

			if grid then
				if not IsSelected then
					renderpos =Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, ypos)*Gridscale 
				else
					if grid.Parent and not (listSecond[grid.Parent.Y] and listSecond[grid.Parent.Y][grid.Parent.X]) then
						listSecond[y][x] = nil
					end
				end
				
				if grid.sprite then
					local scale = grid.sprite.Scale/1
					grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
					grid.sprite:Render(renderpos+enemScaleOffset)
					grid.sprite.Scale = scale
				end
			end
		end
	end]]

	local lists = Isaac_Tower.editor.Memory.CurrentRoom --.Solid
	local Flist = overlayData.lists
	local main = Flist[self.Layer+1]
	local list = lists[main]
	--local list = Isaac_Tower.editor.Memory.CurrentRoom.Enemies
	--for y=math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y) do  --for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
	--	local ypos = 26*(y-1)/2
	--	for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X) do  --for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
	for y=math.max(2,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2) do
		local ypos = 26*(y-2)/4
		for x=math.max(2,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2) do
			local xr = x-1-1
			local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, ypos)*Gridscale
			local grid = list[y] and list[y][x]

			for l=1,#Flist do
				if main ~= Flist[l] then
					local list = lists[Flist[l]]
					local grid = list[y] and list[y][x]
					if grid then
						if not IsSelected then
							renderpos =Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, ypos)*Gridscale 
						else
							if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
								list[y][x] = nil
							end
						end
						
						if grid.sprite then
							local scale = grid.sprite.Scale/1
							grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
							grid.sprite:Render(renderpos+enemScaleOffset)
							grid.sprite.Scale = scale
						end
					end
				end
			end
			if grid then
				if not IsSelected then
					renderpos =Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, ypos)*Gridscale 
				else
					if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
						list[y][x] = nil
					end
				end
				
				if grid.sprite then
					local scale = grid.sprite.Scale/1
					grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
					grid.sprite:Render(renderpos+enemScaleOffset)
					grid.sprite.Scale = scale
				end
			end

			if IsSelected then
				local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
				if not RG then
					Isaac_Tower.sprites.Col0GridHalf:Render(renderpos)
				end
				
				if Isaac_Tower.editor.SelectedMenu == "grid" and not Isaac_Tower.editor.BlockPlaceGrid
				and selGrid and not Isaac_Tower.game:IsPaused() then
					if not RG then
						Isaac_Tower.sprites.chosenGridHalf:Render(renderpos)
					end

					local pGrid = Isaac_Tower.editor.GridTypes.Enemies[Isaac_Tower.editor.SelectedGridType or ""]
					if pGrid then
						
						if Input.IsMouseBtnPressed(0) then
							if not pGrid.size or CheckEmpty(list, Vector(x,y), pGrid.size) then
								SafePlacingTable(list,y,x)
								list[y][x].sprite = pGrid.trueSpr
								list[y][x].info = pGrid.info
								list[y][x].type = Isaac_Tower.editor.SelectedGridType
								if pGrid.size then
									for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
										SafePlacingTable(list,k[1],k[2])
										list[k[1]][k[2]].Parent = Vector(x,y)
									end
								end
							end
							holdMouse = 0
						elseif grid and Input.IsMouseBtnPressed(1) then
							if grid.Parent then
								local par = list[grid.Parent.Y][grid.Parent.X]
								if Isaac_Tower.editor.GridTypes.Enemies[par.type] and Isaac_Tower.editor.GridTypes.Enemies[par.type].size then
									for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Enemies[par.type].size)) do
										list[k[1]][k[2]] = nil
									end
								end
							end
							list[y][x] = nil
							holdMouse = 1
						end
					end
				end
			end
		end
	end
	--[[if IsSelected and Isaac_Tower.RG then
		local endPos = (Isaac_Tower.editor.GridStartPos)+Isaac_Tower.editor.Memory.CurrentRoom.Size*(26/2)*Gridscale
		Isaac_Tower.editor.RenderGrid(Isaac_Tower.editor.GridStartPos,26/4*Gridscale,26/4*Gridscale,endPos.X,endPos.Y,Gridscale)
		if Isaac_Tower.editor.SelectedGrid then
			local xr,yr = Isaac_Tower.editor.SelectedGrid[2]-2, Isaac_Tower.editor.SelectedGrid[1]-2
			local RenderPos = Isaac_Tower.editor.GridStartPos + Vector(xr*26/4, yr*26/4)*Gridscale
			Isaac_Tower.sprites.chosenGridHalf:Render(RenderPos)
		end
	end]]
	if Col0GridScale then
		Isaac_Tower.sprites.Col0GridHalf.Scale = Col0GridScale
		Isaac_Tower.sprites.chosenGridHalf.Scale = Col0GridScale
	end
	if IsSelected and Isaac_Tower.editor.SelectedGrid then
		local pGrid = Isaac_Tower.editor.GridTypes.Enemies[Isaac_Tower.editor.SelectedGridType]
		if pGrid then
			local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
			local renderpos = Isaac_Tower.editor.GridStartPos + Vector((x-2)*26/4, 26*(y-2)/4)*Gridscale
			
			if (list[y] and list[y][x]) or pGrid.size and not CheckEmpty(list, Vector(x,y), pGrid.size) then
				pGrid.trueSpr.Color = Color(2,0.5,0.5,0.5)
			else
				pGrid.trueSpr.Color = greyColorObs
			end
			
			local trueScale = pGrid.trueSpr.Scale/1
			pGrid.trueSpr.Scale = Vector(0.5, 0.5)*Gridscale
			pGrid.trueSpr:Render(renderpos+enemScaleOffset)
			pGrid.trueSpr.Color = Color.Default
			pGrid.trueSpr.Scale = trueScale
		end
	end
	
	if holdMouse and not Input.IsMouseBtnPressed(holdMouse) then
		holdMouse = nil
		Isaac_Tower.editor.MakeVersion()
	end
end, nil, function(str)
	str = str .. "\nEnemy={\n"
	local solidTab = "" --  gfx='gfx/fakegrid/tutorial.png',\n"
	
	for y=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2 do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Enemies[y]
		for x=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2 do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. ")," 
				solidTab = solidTab.."name='" .. grid.info[1] .. "',"
				solidTab = solidTab.."st=" .. grid.info[2] .. ","
				--EditorType
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},"

	str = str .. "\nBonus={\n"
	local solidTab = "" --  gfx='gfx/fakegrid/tutorial.png',\n"
	
	for y=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*2 do
		local ycol = Isaac_Tower.editor.Memory.CurrentRoom.Bonus[y]
		for x=2, Isaac_Tower.editor.Memory.CurrentRoom.Size.X*2 do
			local grid = ycol and ycol[x]
			
			if grid and grid.info then
				local pos = Vector(x,y)
				solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. ")," 
				solidTab = solidTab.."name='" .. grid.info .. "',"
				--EditorType
				solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
				solidTab = solidTab .. "},\n"
			end

		end
	end
	str = str .. solidTab .. "},"
	return str
end)


local ErrorSignSpr = GenSprite("gfx/editor/special_tiles.anm2","error")
ErrorSignSpr.Scale = Vector(0.5, 0.5)
local ErrorTextPopup = UIs.PopupTextBox()
ErrorTextPopup.Offset = Vector(-94,0)

local ShowErrorMes
local holdMouse

Isaac_Tower.editor.AddOverlay("Special", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",3),function(IsSelected)
	local Gridscale = Isaac_Tower.editor.GridScale

	local startPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale - Vector(26*2,26*2)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	local EndPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/Gridscale
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	--local startPosRender = -Isaac_Tower.editor.GridStartPos - Vector(26*2,26*2)
	--local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	--local EndPosRender = -Isaac_Tower.editor.GridStartPos + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
	--local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	local SelIndex

	if IsSelected then
		local mouseOffset = Vector(0,0)
		local pGrid = Isaac_Tower.editor.GridTypes.Special[Isaac_Tower.editor.SelectedGridType or ""]
		if pGrid and pGrid.size and pGrid.size.X then
			mouseOffset = pGrid.size*13/4
		end

		local algMousePos = Isaac_Tower.editor.MousePos - Isaac_Tower.editor.GridStartPos - mouseOffset
		local xs,ys = math.floor(algMousePos.Y/(26/2)/Gridscale), math.floor(algMousePos.X/(26/2)/Gridscale)
		if xs>=0 and ys>=0 and Isaac_Tower.editor.Memory.CurrentRoom.Size.Y>=xs and Isaac_Tower.editor.Memory.CurrentRoom.Size.X>=ys then
			Isaac_Tower.editor.SelectedGrid = {xs+1, ys+1}
			SelIndex = tostring(ys+1) .. "." .. tostring(xs+1)   --(xs-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + ys
		else
			Isaac_Tower.editor.SelectedGrid = nil
		end
	end

	Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_UPDATE, IsSelected)

	if not Isaac_Tower.game:IsPaused() and Isaac_Tower.editor.SelectedMenu == "grid" and IsSelected then
		if Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, 0) then
			Isaac_Tower.editor.BlockPlaceGrid = true
			if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_tileEdit" then
				Isaac_Tower.editor.MouseSprite = UIs.Mouse_Tile_edit
			end
			--[[if Input.IsMouseBtnPressed(0) then
				Isaac_Tower.editor.MouseSprite:SetFrame(1)
			else
				Isaac_Tower.editor.MouseSprite:SetFrame(0)
			end]]
		elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_tileEdit" then
			Isaac_Tower.editor.BlockPlaceGrid = nil
			Isaac_Tower.editor.MouseSprite = nil
		end
	end

	local Col0GridScale
	if Gridscale ~= 1 then
		Col0GridScale = Isaac_Tower.sprites.Col0Grid.Scale/1
		Isaac_Tower.sprites.Col0Grid.Scale = Isaac_Tower.sprites.Col0Grid.Scale*Gridscale
		Isaac_Tower.sprites.chosenGrid.Scale = Isaac_Tower.sprites.Col0Grid.Scale
	end

	if IsSelected then
		Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType] = Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType] or {}
	end
	local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType]
	if list then
		for y=math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y) do
			local ypos = 26*(y-1)/2
			for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X) do
				local xr = x-1
				local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, ypos)*Gridscale
				local grid = list[y] and list[y][x]
				
				if grid then
					if not IsSelected then
						renderpos =Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, ypos)*Gridscale 
					else
						if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
							list[y][x] = nil
						end
					end
					
					if grid.sprite then
						local scale = grid.sprite.Scale/1
						grid.sprite.Scale = Vector(0.5, 0.5)*Gridscale
						grid.sprite:Render(renderpos)
						grid.sprite.Scale = scale
					end
				end

				if IsSelected then
					local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
					Isaac_Tower.sprites.Col0Grid:Render(renderpos)
					
					if Isaac_Tower.editor.SelectedMenu == "grid" and not Isaac_Tower.editor.BlockPlaceGrid
					and selGrid and not Isaac_Tower.game:IsPaused() then
						Isaac_Tower.sprites.chosenGrid:Render(renderpos)

						local pGrid = Isaac_Tower.editor.GridTypes.Special[Isaac_Tower.editor.SelectedGridType or ""]
						if pGrid then
							
							if Input.IsMouseBtnPressed(0) then
								--if Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) then
									--if grid and grid.Parent then
									--	grid = grid.Parent
									--end
									--Isaac_Tower.editor.SpecialSelectedTile = grid or nil
									
								--else
									if not grid or not grid.Parent then --pGrid.size or (CheckEmpty(list, Vector(x,y), pGrid.size) then
										--if not list[y] then
										--	list[y] = {}
										--end
										--if not list[y][x] then
										--	list[y][x] = {}
										--end
										SafePlacingTable(list,y,x)
										--list[y][x].sprite = pGrid.trueSpr
										local Gtype = Isaac_Tower.editor.SelectedGridType
										list[y][x].info = pGrid.info
										list[y][x].type = Gtype --Isaac_Tower.editor.SelectedGridType
										list[y][x].XY = Vector(x,y)
										list[y][x].pos = Vector(xr*26/2, ypos)

										local index = math.ceil(x) .. "." .. math.ceil(y)   --(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + x
										local info = function() if not pcall(function() return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] end) then error("1",2) end
												return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] 
											end
										Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
										Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = {spr = pGrid.trueSpr, pos = Vector(xr*26/2, ypos), info = info}
										if pGrid.size then
											for i,k in pairs(GetLinkedGrid(list, Vector(x,y), pGrid.size, true)) do
												--if not list[k[1]] then
												--	list[k[1]] = {}
												--end
												--if not list[k[1]][k[2]] then
												--	list[k[1]][k[2]] = {}
												--end
												SafePlacingTable(list,k[1],k[2])
												list[k[1]][k[2]].Parent = Vector(x,y)
											end
										end
										holdMouse = 0
									end
								--end
							elseif grid and Input.IsMouseBtnPressed(1) then
								if grid.Parent then
									local par = list[grid.Parent.Y][grid.Parent.X]
									if Isaac_Tower.editor.GridTypes.Special[par.type] and Isaac_Tower.editor.GridTypes.Special[par.type].size or par.Size then
										for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Special[par.type].size or par.Size)) do
											list[k[1]][k[2]] = nil
										end
									end
									local index = tostring(math.ceil(grid.Parent.X)) .. "." .. tostring(math.ceil(grid.Parent.Y))
									--Isaac.DebugString(index)
									Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Isaac_Tower.editor.SelectedGridType][index] = nil
								end
								list[y][x] = nil

								local index = tostring(math.ceil(x)) .. "." .. tostring(math.ceil(y))   --(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + x
								local Gtype = Isaac_Tower.editor.SelectedGridType
								--Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
								--Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = nil
								SafePlacingTable(Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab,Gtype)[index] = nil
								holdMouse = 1
							end
						end
					end
				end
			end
		end
	end

	for Gtyoe, tab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab) do
		if Gtyoe ~= Isaac_Tower.editor.SelectedGridType then
			for i,k in pairs(tab) do
				local renderPos = Isaac_Tower.editor.GridStartPos + k.pos*Gridscale
				local scale = k.spr.Scale/1
				k.spr.Scale = Vector(0.5, 0.5)*Gridscale
				k.spr:Render(Isaac_Tower.editor.GridStartPos + k.pos*Gridscale)
				k.spr.Scale = scale

				Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_TILE_RENDER, k, renderPos, IsSelected, SelIndex == i, Gridscale)
			end
		end
	end
	if Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Isaac_Tower.editor.SelectedGridType] then
		for i,k in pairs(Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Isaac_Tower.editor.SelectedGridType]) do
			--print(Isaac_Tower.editor.SpecialSelectedTile, k.info(), Isaac_Tower.editor.SpecialSelectedTile ~= k.info())
			if Isaac_Tower.editor.SpecialSelectedTile ~= k.info() then
				local renderPos = Isaac_Tower.editor.GridStartPos + k.pos*Gridscale
				local scale = k.spr.Scale/1
				k.spr.Scale = Vector(0.5, 0.5)*Gridscale
				k.spr:Render(Isaac_Tower.editor.GridStartPos + k.pos*Gridscale)
				k.spr.Scale = scale

				Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_TILE_RENDER, k, renderPos, IsSelected, SelIndex == i, Gridscale)
			end
		end
		if Isaac_Tower.editor.SpecialSelectedTile then
			local index = tostring(math.ceil(Isaac_Tower.editor.SpecialSelectedTile.XY.X)) .. "." .. tostring(math.ceil(Isaac_Tower.editor.SpecialSelectedTile.XY.Y))
			if Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Isaac_Tower.editor.SelectedGridType][index] then
				local k = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Isaac_Tower.editor.SelectedGridType][index]
				local renderPos = Isaac_Tower.editor.GridStartPos + k.pos*Gridscale
				local scale = k.spr.Scale/1
				k.spr.Scale = Vector(0.5, 0.5)*Gridscale
				k.spr:Render(Isaac_Tower.editor.GridStartPos + k.pos*Gridscale)
				k.spr.Scale = scale

				Isaac.RunCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_TILE_RENDER, k, renderPos, IsSelected, SelIndex == index, Gridscale)
			end
		end
	end

	if not Isaac_Tower.game:IsPaused() and Isaac_Tower.editor.SelectedMenu == "grid" and IsSelected and Isaac_Tower.editor.SelectedGrid then
		local pGrid = Isaac_Tower.editor.GridTypes.Special[Isaac_Tower.editor.SelectedGridType]
		local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
		if not Isaac_Tower.editor.BlockPlaceGrid and pGrid then
			--local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
			local renderpos = Isaac_Tower.editor.GridStartPos + Vector((x-1)*26/2, 26*(y-1)/2)*Gridscale
			
			local oldColor = Color(pGrid.trueSpr.Color.R,pGrid.trueSpr.Color.G,pGrid.trueSpr.Color.B,pGrid.trueSpr.Color.A)
			if (list[y] and list[y][x]) or pGrid.size and not CheckEmpty(list, Vector(x,y), pGrid.size) then
				pGrid.trueSpr.Color = Color(2,0.5,0.5,0.5)
			else
				pGrid.trueSpr.Color = greyColorObs
			end
			
			local trueScale = pGrid.trueSpr.Scale/1
			pGrid.trueSpr.Scale = Vector(0.5, 0.5)*Gridscale
			pGrid.trueSpr:Render(renderpos)
			pGrid.trueSpr.Color = oldColor--Color.Default
			pGrid.trueSpr.Scale = trueScale
		end

		if Input.IsMouseBtnPressed(0) and Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL,0) then
			local grid
			for Gtype,tab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
				if Gtype ~= Isaac_Tower.editor.SelectedGridType then
					grid = tab[y] and tab[y][x] or grid
				end
			end
			if Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType] then
				grid = Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType][y] 
					and Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType][y][x] or grid
			end
			if grid and grid.Parent then
				grid = Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType][grid.Parent.Y] 
					and Isaac_Tower.editor.Memory.CurrentRoom.Special[Isaac_Tower.editor.SelectedGridType][grid.Parent.Y][grid.Parent.X] --grid.Parent
			end
			
			Isaac_Tower.editor.SpecialSelectedTile = grid or nil
		end
	end

	if IsSelected and Isaac_Tower.editor.SelectedMenu == "grid" then
		UIs.Hint_tileEdit.Color = Color(5,5,5,1)
		local renderPos = Vector(76,Isaac.GetScreenHeight()-10)
		UIs.Hint_tileEdit:Render(renderPos-Vector(0,1))
		UIs.Hint_tileEdit:Render(renderPos+Vector(0,1))
		UIs.Hint_tileEdit:Render(renderPos-Vector(1,0))
		UIs.Hint_tileEdit:Render(renderPos+Vector(1,0))
		UIs.Hint_tileEdit.Color = Color.Default
		UIs.Hint_tileEdit:Render(renderPos )

		Isaac_Tower.editor.RenderMenuButtons("grid")
	end
	if Col0GridScale then
		Isaac_Tower.sprites.Col0Grid.Scale = Col0GridScale
		Isaac_Tower.sprites.chosenGrid.Scale = Col0GridScale
	end

	if ShowErrorMes then
		local mesPos = Vector(Isaac.GetScreenWidth()/2,Isaac.GetScreenHeight()/2)+Vector(0,60)
		ErrorTextPopup:Render(mesPos-Vector(60,0))
		ErrorTextPopup:Render(mesPos+Vector(90,0),Vector(2,0))
		font:DrawStringScaledUTF8(ShowErrorMes, mesPos.X,mesPos.Y, 0.5,0.5,KColor(1,0.2,0.2,1),1,true)
		ShowErrorMes = nil
	end
	if holdMouse and not Input.IsMouseBtnPressed(holdMouse) then
		holdMouse = nil
		Isaac_Tower.editor.MakeVersion()
	end

end, function(tab)
	tab.Special = {}
	print("specail")
	for typ, gtab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
		if typ ~= "spawnpoint_def" and typ ~= "" then
			tab.Special[typ] = {}
			for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
				local ycol = gtab[y]
				for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
					
					local grid = ycol and ycol[x]
					if grid and grid.info then
						if typ == "Room_Transition" then
							tab.Special[typ][#tab.Special[typ]+1] = {} --TabDeepCopy(grid.info)
							tab.Special[typ][#tab.Special[typ]].TargetRoom = grid.TargetRoom
							tab.Special[typ][#tab.Special[typ]].Name = grid.Name
							tab.Special[typ][#tab.Special[typ]].TargetName = grid.TargetName
							tab.Special[typ][#tab.Special[typ]].Size = grid.Size
							tab.Special[typ][#tab.Special[typ]].XY = Vector(x,y)
						end
					end
				end
			end
		end
	end
	--[[for i,k in pairs(tab.Special) do
		print(i,k)
		for i1,k1 in pairs(k) do
			print(" what ",i1,k1)
			for g,n in pairs(k1) do
				print("   ", g,n)
			end
		end
	end]]
end, function(str)
	str = str .. "\nSpecial={\n"
	local solidTab = ""
	local ignore = {type=true,info=true,EditData=true,XY=true,pos=true,}
	
	for typ, gtab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
		if typ ~= "spawnpoint_def" and typ ~= "" then
			solidTab = solidTab .. " " .. typ .. "={\n"
			for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
				local ycol = gtab[y]
				for x=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.X do
					
					local grid = ycol and ycol[x]
					if grid and grid.info then
						local pos = Vector(x,y)
						solidTab = solidTab .. "    {XY=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. ")," 
						if typ  == "Room_Transition" then
							if grid.TargetRoom then
								solidTab = solidTab.."TargetRoom='"..grid.TargetRoom.."',"
							end
							if grid.Name then
								solidTab = solidTab.."Name='"..grid.Name.."',"
							end
							if grid.TargetName then
								solidTab = solidTab.."TargetName='"..grid.TargetName.."',"
							end
							if grid.Size then
								solidTab = solidTab.."Size=Vector(".. math.ceil(grid.Size.X) .. "," .. math.ceil(grid.Size.Y) .. ")," 
							end
						else
							for param, dat in pairs(grid) do
								if not ignore[param] then
									if type(dat) == "string" then
										solidTab = solidTab..param.."='" .. dat .. "',"
									else
										solidTab = solidTab..param.."=" .. dat .. ","
									end
								end
							end
						end
						--EditorType
						--solidTab = solidTab .. "EditorType='" .. grid.type .. "',"
						solidTab = solidTab .. "},\n"
					end
				end
			end
			solidTab = solidTab .. " },\n"
		end
	end
	str = str .. solidTab .. "},"
	return str
end)

local evroBoxSpr = GenSprite("gfx/doubleRender/gridDebug/debug.anm2", 1)
evroBoxSpr.Scale = Vector(0.5,0.5)
evroBoxSpr.Color = Color(0.5,0.5,0.5,0.5)

local GridCollPoint = Sprite()
GridCollPoint:Load('gfx/doubleRender/' .. "gridDebug/debug.anm2")
GridCollPoint.Scale = Vector(0.5,0.5)
GridCollPoint:Play("point")

local function FindCollidedGrid(list, pos, size, onlyfind, sizer)
	if size and pos then
		local tab = {}
		local ignorelist = {}
		local Sx,Sy = pos.X,pos.Y
		--for i,k in pairs(size) do
		--	local Hasgrid = grid[Sy+k[2]] and grid[Sy+k[2]][Sx+k[1]]
		--	if Hasgrid or fill then
		--		tab[#tab+1] = {Sy+k[2], Sx+k[1]}
		--	end
		--end
		local maxX, maxY = math.ceil(size.X/sizer)+1, math.ceil(size.Y/sizer)+1 --26
		for xi=1, maxX do
			for yi=1, maxY do
				local y,x -- = math.ceil((pos.Y-26)/13)+yi, math.ceil((pos.X-26)/13)+xi
				local pointpos = Vector(0,0)
				if xi == maxX then
					x = math.ceil((pos.X-13+size.X/2)/13) --13
					pointpos.X = pos.X-13+size.X/2
				else
					--x = math.ceil((pos.X-26)/13)+xi
					--pointpos.X = pos.X-26 + xi*13
					x = math.ceil((pos.X-26)/13)+xi
					pointpos.X = pos.X-26 + xi*13
				end
				if yi == maxY then
					y = math.ceil((pos.Y-13+size.Y/2)/13)
					pointpos.Y = pos.Y-13+size.Y/2
				else
					--y = math.ceil((pos.Y-26)/13)+yi
					--pointpos.Y = pos.Y-26 + yi*13
					y = math.ceil((pos.Y-26)/13)+yi
					pointpos.Y = pos.Y-26 + yi*13
				end

				GridCollPoint:Render( pointpos + Isaac_Tower.editor.GridStartPos + Vector(13,13) )

				if not ignorelist[(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.X+x] and
				x~=0 and y~=0 and x<=Isaac_Tower.editor.Memory.CurrentRoom.Size.X and y<=Isaac_Tower.editor.Memory.CurrentRoom.Size.Y then
					if onlyfind then
						tab[#tab+1] = {y,x}
					else
						list[y] = list[y] or {}
						list[y][x] = list[y][x] or {}
						--local grid = list[y] and list[y][x]
						tab[#tab+1] = list[y][x]
					end
					ignorelist[(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.X+x] = true
				end
			end
		end
		return tab
	end
end

local function DetectColEnvi(list, pos, index)
	if list and pos and index then
		pos = pos+Vector(26,26)
		--for y, ycol in pairs(list) do
		--	for x, grid in pairs(ycol) do
				
		--	end
		--end
		local inCache
		local grid = list[index.Y] and list[index.Y][index.X]
		if grid and grid.Parents then
			for i,k in pairs(grid.Parents) do
				local box = Isaac_Tower.editor.Memory.CurrentRoom.EnviList[i]
				
				if pos.X>box.upleft.X and pos.Y>box.upleft.Y and
				pos.X<=box.downright.X and pos.Y<=box.downright.Y then
					if Isaac_Tower.editor.EnvironmentSelectedLayer ~= box.layer then
						inCache = i
					else
						return i
					end
				end

				--GridCollPoint:Render( box.upleft+Isaac_Tower.editor.GridStartPos )
				--GridCollPoint:Render( box.downright+Isaac_Tower.editor.GridStartPos )

				--local off = pGrid.pivot/2 or Vector(0,0)
				--evroBoxSpr.Scale = (box.downright-box.upleft)/23
				--evroBoxSpr:Render(box.upleft+Isaac_Tower.editor.GridStartPos)
			end
			if inCache then
				return inCache
			end
		end
	end

end

local holdMouse
local evriMouseTriger = false
Isaac_Tower.editor.EnvironmentSelectedLayer = 0
Isaac_Tower.editor.EnvironmentGridMode = 0
Isaac_Tower.editor.AddOverlay("Environment", GenSprite("gfx/editor/ui.anm2","оверлей_иконки",5), function(IsSelected)

	Isaac_Tower.editor.Memory.CurrentRoom.EnviList = Isaac_Tower.editor.Memory.CurrentRoom.EnviList or {}

	local Gridscale = Isaac_Tower.editor.GridScale

	local startPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale - Vector(26*2,26*2)
	local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	local EndPosRender = -Isaac_Tower.editor.GridStartPos/Gridscale + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/Gridscale
	local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	--local startPosRender = -Isaac_Tower.editor.GridStartPos - Vector(26*2,26*2)
	--local StartPosRenderGrid = Vector(math.ceil(startPosRender.X/(26/2)), math.ceil(startPosRender.Y/(26/2)))
	--local EndPosRender = -Isaac_Tower.editor.GridStartPos + Vector(26*2,26*2) + Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
	--local EndPosRenderGrid = Vector(math.ceil(EndPosRender.X/(26/2)), math.ceil(EndPosRender.Y/(26/2)))

	local selectedGrid
	if IsSelected then
		local mouseOffset = Vector(0,0)
		local pGrid = Isaac_Tower.editor.GridTypes.Environment[Isaac_Tower.editor.SelectedGridType or ""]

		local algMousePos = Isaac_Tower.editor.MousePos - Isaac_Tower.editor.GridStartPos - mouseOffset
		algMousePos = Vector(math.ceil(algMousePos.X),math.ceil(algMousePos.Y))
		if Isaac_Tower.editor.EnvironmentGridMode == 0 then
			Isaac_Tower.editor.SelectedGrid = algMousePos / Gridscale
		end
		local xs,ys = math.floor(algMousePos.Y/(26/2)/Gridscale), math.floor(algMousePos.X/(26/2)/Gridscale)
		if xs>=0 and ys>=0 and Isaac_Tower.editor.Memory.CurrentRoom.Size.Y-1>=xs and Isaac_Tower.editor.Memory.CurrentRoom.Size.X-1>=ys then
			selectedGrid = {xs, ys}
			if Isaac_Tower.editor.EnvironmentGridMode == 1 then
				Isaac_Tower.editor.SelectedGrid = Vector(ys*13+13/2,xs*13+13/2) --* Gridscale
			end
		else
			selectedGrid = nil
			if Isaac_Tower.editor.EnvironmentGridMode == 1 then
				Isaac_Tower.editor.SelectedGrid = algMousePos / Gridscale
			end
		end
		

		local prescale = Isaac_Tower.sprites.Col0Grid.Scale/1

		Isaac_Tower.sprites.Col0Grid.Scale = Vector(Isaac_Tower.editor.Memory.CurrentRoom.Size.X/1.77,2)*Gridscale
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(0,0), nil, Vector(0,22)) --11
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(0,Isaac_Tower.editor.Memory.CurrentRoom.Size.Y*13*Gridscale-2), nil, Vector(0,22))
		Isaac_Tower.sprites.Col0Grid.Scale = Vector(2*Gridscale, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y/1.765*Gridscale-0.16) --*Gridscale
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(0,2), nil, Vector(22,0)) --+Vector(13,15)
		Isaac_Tower.sprites.Col0Grid:Render(Isaac_Tower.editor.GridStartPos+Vector(Isaac_Tower.editor.Memory.CurrentRoom.Size.X*13*Gridscale-2,2), nil, Vector(22,0))

		Isaac_Tower.sprites.Col0Grid.Scale = prescale
	end

	local Overindex 
	if selectedGrid then
		Overindex = DetectColEnvi(Isaac_Tower.editor.Memory.CurrentRoom.Envi, 
		Isaac_Tower.editor.SelectedGrid-Vector(26,26), 
		Vector(selectedGrid[2], selectedGrid[1]))
	end

	local RenderListSorted = {}
	local minindex,maxindex = 0,0
	for i, data in pairs(Isaac_Tower.editor.Memory.CurrentRoom.EnviList) do
		RenderListSorted[data.layer] = RenderListSorted[data.layer] or {}
		RenderListSorted[data.layer][#RenderListSorted[data.layer]+1] = {data,i} --{data.spr, data.pos, i}
		minindex = math.min(minindex, data.layer)
		maxindex = math.max(maxindex, data.layer)
	end
	for layer = minindex, maxindex do --tab in pairs(RenderListSorted) do
		local tab = RenderListSorted[layer]
		if tab and layer ~= Isaac_Tower.editor.EnvironmentSelectedLayer then
			for i,k in pairs(tab) do
				if k[1].spr and k[1].pos then
					--local oldcolor = k[1].spr.Color
					if selectedGrid then
						k[1].spr.Color = Color(0.5,0.5,0.8,0.5)
					end
					local oldScale = k[1].spr.Scale/1
					k[1].spr.Scale = k[1].spr.Scale * Gridscale
					k[1].spr:Render(k[1].pos*Gridscale+Isaac_Tower.editor.GridStartPos)
					k[1].spr.Color = Color.Default
					k[1].spr.Scale = oldScale
					if Overindex and Overindex == k[2] then
						evroBoxSpr.Color = Color(1.5,0.1,0.1,1)
						evroBoxSpr.Scale = (k[1].downright-k[1].upleft)/23 * Gridscale
						evroBoxSpr:Render(k[1].upleft*Gridscale+Isaac_Tower.editor.GridStartPos)
						evroBoxSpr.Color = Color.Default
					end
				end
			end
		end
	end
	if RenderListSorted[Isaac_Tower.editor.EnvironmentSelectedLayer] then
		for i,k in pairs(RenderListSorted[Isaac_Tower.editor.EnvironmentSelectedLayer]) do
			if k[1].spr and k[1].pos then
				local oldScale = k[1].spr.Scale/1
				k[1].spr.Scale = k[1].spr.Scale * Gridscale
				k[1].spr:Render(k[1].pos*Gridscale+Isaac_Tower.editor.GridStartPos)
				k[1].spr.Scale = oldScale
				if Overindex and Overindex == k[2] then
					evroBoxSpr.Color = Color(1.5,0.1,0.1,1)
					evroBoxSpr.Scale = (k[1].downright-k[1].upleft)/23 * Gridscale
					evroBoxSpr:Render(k[1].upleft*Gridscale+Isaac_Tower.editor.GridStartPos)
					evroBoxSpr.Color = Color.Default
				end
			end
		end
	end
	--for i, data in pairs(Isaac_Tower.editor.Memory.CurrentRoom.EnviList) do
	---	if data.spr and data.pos then
	--		data.spr:Render(data.pos+Isaac_Tower.editor.GridStartPos)
	--		if Overindex and Overindex == i then
	--			evroBoxSpr.Color = Color(1.5,0.1,0.1,1)
	--			evroBoxSpr.Scale = (data.downright-data.upleft)/23
	--			evroBoxSpr:Render(data.upleft+Isaac_Tower.editor.GridStartPos)
	--			evroBoxSpr.Color = Color.Default
	--		end
	--	end
	--end

	local list = Isaac_Tower.editor.Memory.CurrentRoom.Envi
	for y=math.max(1,StartPosRenderGrid.Y), math.min(EndPosRenderGrid.Y, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y) do  --for y=1, Isaac_Tower.editor.Memory.CurrentRoom.Size.Y do
		local ypos = 26*(y-1)/2
		for x=math.max(1,StartPosRenderGrid.X), math.min(EndPosRenderGrid.X, Isaac_Tower.editor.Memory.CurrentRoom.Size.X) do
			local xr = x-1
			local renderpos = IsSelected and Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, ypos) * Gridscale --, x*26/2)
			--Col0Grid:Render(renderpos)
			local grid = list[y] and list[y][x]
			--local selGrid = Isaac_Tower.editor.SelectedGrid and Isaac_Tower.editor.SelectedGrid[1] == y and Isaac_Tower.editor.SelectedGrid[2] == x
			
			if grid then
				if not IsSelected then
					renderpos =Isaac_Tower.editor.GridStartPos + Vector(xr*26/2, ypos) * Gridscale
				else
					if grid.Parent and not (list[grid.Parent.Y] and list[grid.Parent.Y][grid.Parent.X]) then
						list[y][x] = nil
					end
				end
				
				if grid.sprite then
					local scale = grid.sprite.Scale/1
					grid.sprite.Scale = Vector(0.5, 0.5) * Gridscale
					grid.sprite:Render(renderpos)
					grid.sprite.Scale = scale
				end
			end
		end
	end
	if IsSelected and Isaac_Tower.editor.SelectedGrid then

		if selectedGrid then
			local y,x = selectedGrid[1], selectedGrid[2]
			local grid = list[y] and list[y][x]

			local selGrid = selectedGrid and selectedGrid[1] == y and selectedGrid[2] == x
			
			if  Isaac_Tower.editor.SelectedMenu == "grid" and not Isaac_Tower.editor.BlockPlaceGrid
			and selGrid and not Isaac_Tower.game:IsPaused() then
				local pGrid = Isaac_Tower.editor.GridTypes.Environment[Isaac_Tower.editor.SelectedGridType or ""]
				local renderpos = Isaac_Tower.editor.GridStartPos + Vector(x*13, y*13)
				--chosenGrid:Render(renderpos)

				if pGrid and pGrid.size then
					local oldScale = Isaac_Tower.sprites.chosenGrid.Scale
					Isaac_Tower.sprites.chosenGrid.Scale = Isaac_Tower.sprites.chosenGrid.Scale * Gridscale
					for i, k in pairs(FindCollidedGrid(list, Isaac_Tower.editor.SelectedGrid-pGrid.pivot/2, pGrid.size, true, 208)) do
						Isaac_Tower.sprites.chosenGrid:Render(Isaac_Tower.editor.GridStartPos + Vector(k[2]*13, k[1]*13)*Gridscale)
					end
					Isaac_Tower.sprites.chosenGrid.Scale = oldScale
				end
				
				if pGrid then
					if Input.IsMouseBtnPressed(0) and not evriMouseTriger then --Довольно тупо

						local newindex = #Isaac_Tower.editor.Memory.CurrentRoom.EnviList+1
						--Isaac_Tower.editor.Memory.CurrentRoom.EnviList[newindex] = 
						--	{info = pGrid.info, spr = pGrid.trueSpr, pos = Isaac_Tower.editor.SelectedGrid,
						--	upleft = Isaac_Tower.editor.SelectedGrid-pGrid.pivot/2, downright = Isaac_Tower.editor.SelectedGrid+pGrid.pivot/2}
						
						local childs = {}
						for i, k in pairs(FindCollidedGrid(list, Isaac_Tower.editor.SelectedGrid-pGrid.pivot/2, pGrid.size, true, 26)) do
							local yi,xi = k[1], k[2]
							SafePlacingTable(list,yi,xi,"Parents")[newindex] = true
							--list[yi][xi].Parents[newindex] = true
							childs[#childs+1] = {yi,xi}
						end

						Isaac_Tower.editor.Memory.CurrentRoom.EnviList[newindex] = 
							{info = pGrid, spr = pGrid.trueSpr, pos = Isaac_Tower.editor.SelectedGrid, childs = childs,
							upleft = Isaac_Tower.editor.SelectedGrid-pGrid.pivot/2, downright = Isaac_Tower.editor.SelectedGrid-pGrid.pivot/2 + pGrid.size/2,
							layer = Isaac_Tower.editor.EnvironmentSelectedLayer}

						holdMouse = 0
					elseif grid and Input.IsMouseBtnPressed(1) and not evriMouseTriger then
						local index = DetectColEnvi(list, Isaac_Tower.editor.SelectedGrid-Vector(26,26), Vector(x,y))
						if index then
							local envi = Isaac_Tower.editor.Memory.CurrentRoom.EnviList[index]
							if envi then
								for i,k in pairs(envi.childs) do
									local grid = list[k[1] ] and list[k[1] ][k[2] ]
									if grid then
										list[k[1] ][k[2] ].Parents[index] = nil
										--if #list[k[1] ][k[2] ].Parents == 0 then
										--	list[k[1] ][k[2] ] = nil
										--end
									end
								end
							end
							Isaac_Tower.editor.Memory.CurrentRoom.EnviList[index] = nil
							holdMouse = 0
						end
					end
					if Input.IsMouseBtnPressed(0) or Input.IsMouseBtnPressed(1) then
						evriMouseTriger = true
					else
						evriMouseTriger = false
					end
				end
			end
		end


		local pGrid = Isaac_Tower.editor.GridTypes.Environment[Isaac_Tower.editor.SelectedGridType]
		if pGrid then
			--local y,x = Isaac_Tower.editor.SelectedGrid[1], Isaac_Tower.editor.SelectedGrid[2]
			local renderpos = Isaac_Tower.editor.GridStartPos + Isaac_Tower.editor.SelectedGrid*Gridscale --+ Vector(x*26/2, 26*y/2)
			
			if pGrid.size and not Overindex then
				local off = pGrid.pivot/2 or Vector(0,0)
				evroBoxSpr.Scale = pGrid.size/46 * Gridscale
				evroBoxSpr.Color = Color(1,1,1,0.2)
				evroBoxSpr:Render(renderpos-off)
			end
			
			local trueScale = pGrid.trueSpr.Scale/1
			pGrid.trueSpr.Scale = Vector(0.5, 0.5) * Gridscale
			pGrid.trueSpr:Render(renderpos)
			pGrid.trueSpr.Color = Color.Default
			pGrid.trueSpr.Scale = trueScale
		end

		local textPos = Vector(Isaac.GetScreenWidth()/2, 50)
		font:DrawStringScaledUTF8(GetStr("layer") .. " " .. Isaac_Tower.editor.EnvironmentSelectedLayer,
			textPos.X,textPos.Y,0.5,0.5,KColor(0.8,0.8,0.8,0.7),1,true)
	end
	if holdMouse and not Input.IsMouseBtnPressed(holdMouse) then
		holdMouse = nil
		Isaac_Tower.editor.MakeVersion()
	end
end, nil, function(str)
	str = str .. "\nEnviList={\n"
	local solidTab = "" -- "  gfx='gfx/fakegrid/tutorial.png',\n"
	
	--local startPos = Vector(-40,100)

	if Isaac_Tower.editor.Memory.CurrentRoom.EnviList then
		local customFileEnvi = {}
		local customEnvi = {}
		local hasCustom = false
		for i, grid in pairs(Isaac_Tower.editor.Memory.CurrentRoom.EnviList) do
			if grid and grid.info.file then
				if not customFileEnvi[grid.info.file] then
					customFileEnvi[grid.info.file] = true --{grid.info.pivot, grid.info.size} --true
					hasCustom = true
				end
				if not customEnvi[grid.info.file..grid.info.anim] then
					customEnvi[grid.info.file..grid.info.anim] = {grid.info.file, grid.info.pivot, grid.info.size, grid.info.anim}
				end
			end
		end
		if hasCustom then
			local num = 1
			str = str .. "  CF={"
			for file, data in pairs(customFileEnvi) do
				--local vec1,vec2 = "{"..math.ceil(data[2].X)..","..math.ceil(data[2].Y).."}",
				--	"{"..math.ceil(data[1].X)..","..math.ceil(data[1].Y).."},"
				str = str .. "'" .. file .."'," -- "{'"..file.."',"..vec1..","..vec2.."},"
				customFileEnvi[file] = num
				num = num + 1
			end
			local num = 1
			str = str .. "},\n  CT={"
			for file, data in pairs(customEnvi) do
				local vec1,vec2 = "{"..math.ceil(data[3].X)..","..math.ceil(data[3].Y).."}",
					"{"..math.ceil(data[2].X)..","..math.ceil(data[2].Y).."},"
				str = str .."{"..customFileEnvi[data[1]]..",'"..data[4].."',"..vec1..","..vec2.."},"
				customEnvi[data[1]..data[4]] = num
				num = num + 1
			end
			str = str .. "},\n"
		end
		for i, grid in pairs(Isaac_Tower.editor.Memory.CurrentRoom.EnviList) do
				if grid and grid.info then
					--local pos = startPos + Vector(20+(x-1)*40, 20+(y-1)*40)
					if grid.info.file then
						local pos = Vector(math.ceil(grid.pos.X*2)/2, math.ceil(grid.pos.Y*2)/2)*2 --Vector(26,26)
						solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. "),"
						solidTab = solidTab .. "ct=" .. customEnvi[grid.info.name] .. "," --layer
						solidTab = solidTab .. "l=" .. grid.layer .. ","
						--EditorType
						solidTab = solidTab .. "chl={"

						if #grid.childs>4 then
							local min, max = {1000000000,1000000000},{0,0}
							for _, id in pairs(grid.childs) do
								if id[1]<min[1] then
									min[1] = id[1]
								end
								if id[2]<min[2] then
									min[2] = id[2]
								end
								if id[1]>max[1] then
									max[1] = id[1]
								end
								if id[2]>max[2] then
									max[2] = id[2]
								end
							end
							solidTab = solidTab .. "{"..(min[1]+0)..","..(min[2]+0).."},"
							solidTab = solidTab .. "{"..(min[1]+0)..","..(max[2]+0).."},"
							solidTab = solidTab .. "{"..(max[1]+0)..","..(min[2]+0).."},"
							solidTab = solidTab .. "{"..(max[1]+0)..","..(max[2]+0).."},"
						else
							for _, id in pairs(grid.childs) do
								solidTab = solidTab .. "{"..(id[1]+0)..","..(id[2]+0).."},"
							end
						end

						solidTab = solidTab .. "},},\n"
					else
						local pos = Vector(math.ceil(grid.pos.X*2)/2, math.ceil(grid.pos.Y*2)/2)*2 --Vector(26,26)
						solidTab = solidTab .. "  {pos=Vector(" .. math.ceil(pos.X) .. "," .. math.ceil(pos.Y) .. "),"
						solidTab = solidTab .. "name='" .. grid.info.name .. "'," --layer
						solidTab = solidTab .. "l=" .. grid.layer .. ","
						--EditorType
						solidTab = solidTab .. "chl={"

						if #grid.childs>4 then
							local min, max = {1000000000,1000000000},{0,0}
							for _, id in pairs(grid.childs) do
								if id[1]<min[1] then
									min[1] = id[1]
								end
								if id[2]<min[2] then
									min[2] = id[2]
								end
								if id[1]>max[1] then
									max[1] = id[1]
								end
								if id[2]>max[2] then
									max[2] = id[2]
								end
							end
							solidTab = solidTab .. "{"..math.ceil(min[1]+0)..","..math.ceil(min[2]+0).."},"
							solidTab = solidTab .. "{"..math.ceil(min[1]+0)..","..math.ceil(max[2]+0).."},"
							solidTab = solidTab .. "{"..math.ceil(max[1]+0)..","..math.ceil(min[2]+0).."},"
							solidTab = solidTab .. "{"..math.ceil(max[1]+0)..","..math.ceil(max[2]+0).."},"
						else
							for _, id in pairs(grid.childs) do
								solidTab = solidTab .. "{"..math.ceil(id[1]+0)..","..math.ceil(id[2]+0).."},"
							end
						end
						solidTab = solidTab .. "},},\n"
					end
				end

		--	end
		end
		str = str .. solidTab .. "},"
		return str
	end
end)

---@param Menuname string
---@param Pos Vector|function --почему тут функция?
---@param XSize number
---@param params  table
---@param pressFunc function
function Isaac_Tower.editor.FastCreatelist(Menuname, Pos, XSize, params, pressFunc, up)
	--local Menuname = Menuname
	--local centerPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(200, 160) --Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2)
	local Rpos = Pos
	local Lnum = 0
	local frame = 0
	local XScale = XSize/96

	local MouseOldPos = Vector(0,0)
	local offsetPos = Vector(0,0)
	--local StartPos = Rpos/1
	local OldRenderPos = Vector(0,0)

	local Sadspr = UIs.Var_Sel()
	Sadspr.Scale = Vector(XScale,0.5)
	Sadspr.Color = Color(0,0,0,0.2)
	Sadspr.Offset = Vector(2,2)

	Isaac_Tower.editor.AddButton(Menuname, "_Listshadow", Rpos+Vector(0,up and -16 or 16), 96, 9, Sadspr, function(button) 
		if button ~= 0 then return end
	end, function(pos)
		Sadspr.Scale = Vector(XScale,0.5*Lnum)
		if frame>1 and not Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and (IsMouseBtnTriggered(0) or IsMouseBtnTriggered(1)) then
			Isaac_Tower.editor.RemoveButton(Menuname, "_Listshadow")
		else
			--local poloskaOffset = PoloskaPos or 0

			--UIs.TextEdPos:Render(Rpos+Vector(8+poloskaOffset,2))
			--UIs.TextEdPos:Update()

			local butPos
			if up then
				butPos = Rpos-Vector(0,8*(Lnum+1)) + offsetPos
			else
				butPos = Rpos+Vector(0,16) + offsetPos
			end
			Isaac_Tower.editor.GetButton(Menuname, "_Listshadow").pos = butPos --Rpos-Vector(0,8*(Lnum+1)) + offsetPos
			UIs.Hint_MouseMoving_Vert.Color = Color(5,5,5,1)
			local renderPos = Vector(146,Isaac.GetScreenHeight()-15)
			UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(0,1))
			UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(0,1))
			UIs.Hint_MouseMoving_Vert:Render(renderPos-Vector(1,0))
			UIs.Hint_MouseMoving_Vert:Render(renderPos+Vector(1,0))
			UIs.Hint_MouseMoving_Vert.Color = Color.Default
			UIs.Hint_MouseMoving_Vert:Render(renderPos)
		end
		frame = frame + 1

		local MousePos = Isaac_Tower.editor.MousePos
		if Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then
			--if MousePos.X < 120 and Isaac_Tower.editor.BlockPlaceGrid ~= false then
				--Isaac_Tower.editor.BlockPlaceGrid = true
			--end
			Isaac_Tower.editor.MouseDoNotPressOnButtons = true
			if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_grab" then
				Isaac_Tower.editor.MouseSprite = UIs.MouseGrab
			end
			if Input.IsMouseBtnPressed(0) then
				Isaac_Tower.editor.MouseSprite:SetFrame(1)
				local offset = MousePos - MouseOldPos
				offsetPos.Y = OldRenderPos.Y + offset.Y
			else
				Isaac_Tower.editor.MouseSprite:SetFrame(0)
				MouseOldPos = MousePos/1
				OldRenderPos = offsetPos/1
			end
		elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_grab" then
			Isaac_Tower.editor.MouseSprite = nil
		end
	end,true,-1)

	local maxOff = 0
	for rnam, romdat in pairs(params) do
		local qnum = Lnum+0
		local bntName = "_List" .. tostring(qnum)
		local Repos 
		if up then
			Repos = Rpos - Vector(0, qnum*8 + 16)
		else
			Repos = Rpos + Vector(0, qnum*8 + 16)
		end
		--local frame = 0
		local Sspr = UIs.Var_Sel()
		Sspr.Scale = Vector(XScale,0.5)
		
	
		Isaac_Tower.editor.AddButton(Menuname, bntName, Repos, XSize, 9, Sspr, function(button)
			if frame<2 then return end
			pressFunc(button, rnam, romdat)
		end, 
		function(pos)
			local strW = font:GetStringWidthUTF8(tostring(qnum+1))/2
			maxOff = maxOff < strW and strW or maxOff
			font:DrawStringScaledUTF8(tostring(rnam),pos.X+1,pos.Y-1,0.5,0.5,KColor(0.2,0.2,0.2,0.8),0,false) 
			font:DrawStringScaledUTF8(tostring(romdat),pos.X+maxOff+5,pos.Y-1,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false) 
			if frame>2 and not Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and (IsMouseBtnTriggered(0) or IsMouseBtnTriggered(1)) then
				Isaac_Tower.editor.RemoveButton(Menuname, bntName)
			else
				Isaac_Tower.editor.GetButton(Menuname, bntName).pos = Repos + offsetPos
			end
			
		end,nil,-2)
		Lnum = Lnum + 1
	end
end



do
	local Envimenu = Isaac_Tower.editor.GetOverlay("Environment")
	Envimenu.Layer = 0
	Envimenu.CustomPreGenTileList = function(menuName)
		Isaac_Tower.editor.TilesListMenus[menuName] = {}
		local TIlesMenu = Isaac_Tower.editor.TilesListMenus[menuName]
		Envimenu.Anm2Path = Envimenu.Anm2Path or {}
		local num = {} --0
		for i,k in pairs(Isaac_Tower.editor.GridTypes[menuName]) do
			local testSpr = k.info()
			local anm = testSpr:GetFilename()
			Envimenu.Anm2Path[anm] = Envimenu.Anm2Path[anm] or {}

			num[anm] = num[anm] or 0
			num[anm] = num[anm] + 1
			local inum = num[anm]

			local page = math.ceil(inum/15)
			TIlesMenu[anm] = TIlesMenu[anm] or {}
			TIlesMenu[anm][page] = TIlesMenu[anm][page] or {}
			local xpos, ypos = (inum-1)%5+1, math.ceil( ((inum-1)%15+1)/5 )
			TIlesMenu[anm][page][(inum-1)%15+1] = {
				pos = Vector(60*xpos, 60*ypos), --Vector(52*xpos, 49*ypos),
				sprite = k.spr,
				type = i,
			}
		end
		for gfx, tab in pairs(TIlesMenu) do
			for i,k in pairs(tab) do
				if #tab==i then
					if #k+1 >15 then
						tab[i+1] = {}
						local k = tab[i+1]
						local xpos, ypos = (#k+1-1)%5+1, math.ceil( ((#k+1-1)%15+1)/5 )
						k[#k+1] = {
							pos = Vector(60*xpos, 60*ypos),
							sprite = UIs.BigPlus(),
							IsSpecial = true,
						}
						k[#k].sprite.Offset = -Vector(12,12)
						break
					else
						local xpos, ypos = (#k+1-1)%5+1, math.ceil( ((#k+1-1)%15+1)/5 )
						k[#k+1] = {
							pos = Vector(60*xpos, 60*ypos),
							sprite = UIs.BigPlus(),
							IsSpecial = true,
						}
						k[#k].sprite.Offset = -Vector(12,12)
					end
				end
			end
		end

		if not Envimenu.SelectedAnm2Path then
			local anm
			for i,k in pairs(Envimenu.Anm2Path) do
				anm = i
				break
			end
			Envimenu.SelectedAnm2Path = anm
		end
	end


	local AddMenuMenu = {Name = "AddMenuMenu", numParam = 0, sprite = Sprite()}
	local function OpenEvriAddMenu(gfx, id)
		local Menuname = AddMenuMenu.Name
	
		--grid.EditData = grid.EditData or {}
		local NewTileData = {}
		if gfx then
			NewTileData.AnmFile = gfx
			AddMenuMenu.sprite:Load(NewTileData.AnmFile, true)
			AddMenuMenu.sprite:Play(AddMenuMenu.sprite:GetDefaultAnimation())
			NewTileData.AnimName = AddMenuMenu.sprite:GetDefaultAnimation()
		end
		Isaac_Tower.editor.MenuData[Menuname] = nil
		NewTileData.Size = Vector(10,10)
		NewTileData.Pivot = Vector(0,0)
		NewTileData.Pos = Vector(0,0)
		
		--Isaac_Tower.editor.SpecialEditMenu.LastMenu = Isaac_Tower.editor.SelectedMenu..""
		Isaac_Tower.editor.SelectedMenu = Menuname
		Isaac_Tower.editor.IsStickyMenu = true
		AddMenuMenu.numParam = 5
	
		local centerPos = Isaac_Tower.editor.ScreenCenter - Vector(126,24) --Vector(Isaac.GetScreenWidth()/2-94-32, Isaac.GetScreenHeight()/2-24)
		local num = 0
		--for i,k in pairs(Isaac_Tower.editor.SpecialEditingData[name]) do
			--AddMenuMenu.numParam = AddMenuMenu.numParam + 1
		--for i,k in pairs(Isaac_Tower.editor.SpecialEditingData[name]) do

			local knum = num+0
			local Rpos = centerPos+Vector(0,-64)
			Isaac_Tower.editor.AddButton(Menuname, "AnmFile", Rpos, 176, 16, UIs.TextBox(), function(button) 
				if button ~= 0 then return end
				
				local function pressFunc(utton, param1, param2)
					if utton ~= 0 then return end
					if param1 == "" then
						local function resultCheck(result)
							if not result then
								return true
							else
								if #result < 1 or not string.find(result,"%S") then
									return GetStr("emptyField")
								end
								local testspr = Sprite()
								testspr:Load(result, true)
								if testspr:GetDefaultAnimation() == "" then
									return GetStr("anm2FileFail")
								end

								NewTileData.AnmFile = result
								AddMenuMenu.sprite:Load(NewTileData.AnmFile, true)
								if AddMenuMenu.sprite:GetFilename() ~= NewTileData.AnmFile then
									NewTileData.AnmFile = AddMenuMenu.sprite:GetFilename()
									return GetStr("anm2FileFail")
								else
									--Envimenu.Anm2Path[result] = true
									AddMenuMenu.sprite:Play(AddMenuMenu.sprite:GetDefaultAnimation())
									NewTileData.AnimName = AddMenuMenu.sprite:GetDefaultAnimation()
								end
								return true
							end
						end
						Isaac_Tower.editor.OpenTextboxPopup(false, resultCheck, NewTileData.AnmFile)
					else
						local preanm = NewTileData.AnmFile and NewTileData.AnmFile..""
						NewTileData.AnmFile = param2
						if preanm ~= NewTileData.AnmFile then
							AddMenuMenu.sprite:Load(NewTileData.AnmFile, true)
							AddMenuMenu.sprite:Play(AddMenuMenu.sprite:GetDefaultAnimation())
							NewTileData.AnimName = AddMenuMenu.sprite:GetDefaultAnimation()
						end
					end
				end
				local params = {}
				for i,k in pairs(Envimenu.Anm2Path) do
					params[#params+1] = i
				end
				params[""] = GetStr("anotherFile")
				
				Isaac_Tower.editor.FastCreatelist(Menuname, Rpos, 175, params, pressFunc)
			end, function(pos)
				Isaac_Tower.editor.GetButton(Menuname, "AnmFile").pos = Isaac_Tower.editor.ScreenCenter - Vector(126,88)

				font:DrawStringScaledUTF8(GetStr("AnmFile"),pos.X+6,pos.Y-8,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				if Isaac_Tower.editor.GetButton(Menuname,"_Listshadow", true) then
					local poloskaOffset = (font:GetStringWidthUTF8(NewTileData.AnmFile or "")/2 - 2) or 0
					UIs.TextEdPos:Render(Rpos+Vector(8+poloskaOffset,2))
					UIs.TextEdPos:Update()
				end
				
				if NewTileData.AnmFile then
					font:DrawStringScaledUTF8(NewTileData.AnmFile,pos.X+4,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),0,false)
				end
			end,nil,1)
			local Rpos = centerPos+Vector(176-16,-64)
			Isaac_Tower.editor.AddButton(Menuname, "AnmFile_dopbut", Rpos, 16, 16, UIs.CounterDown(), function(button) 
				if button ~= 0 then return end
				Isaac_Tower.editor.GetButton(Menuname, "AnmFile").func(button)
			end)

			local Rpos = centerPos+Vector(0,-40)
			Isaac_Tower.editor.AddButton(Menuname, "AnimName", Rpos, 176, 16, UIs.TextBox(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if #result < 1 or not string.find(result,"%S") then
							return GetStr("emptyField")
						end
						NewTileData.AnimName = result
						AddMenuMenu.sprite:Play(NewTileData.AnimName)
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(false, resultCheck, NewTileData.AnimName)
			end, function(pos)
				font:DrawStringScaledUTF8(GetStr("AnimName"),pos.X+6,pos.Y-8,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				
				if NewTileData.AnimName then
					font:DrawStringScaledUTF8(NewTileData.AnimName,pos.X+4,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),0,false)
				end
			end)
			local Rpos = centerPos+Vector(16,4)
			Isaac_Tower.editor.AddButton(Menuname, "RG_auto", Rpos, 64, 16, UIs.ButtonWide(), function(button) 
				if button ~= 0 then return end
				if Isaac_Tower.RG then
					local anmdata = {Isaac_Tower.editor.GetEnviAutoSpriteFormat(AddMenuMenu.sprite)}
					AddMenuMenu.sprite.Scale = Vector(1,1)*Vector(math.min(1,26/NewTileData.Size.X), math.min(1,26/NewTileData.Size.Y))
					NewTileData.Size = anmdata[1]
					NewTileData.Pivot = anmdata[2]
					NewTileData.Pos = anmdata[3]+Vector(13,13)
				end
			end, function(pos)
				if Isaac_Tower.RG then
					font:DrawStringScaledUTF8(GetStr("Auto"),pos.X+30,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				else
					font:DrawStringScaledUTF8(GetStr("Auto"),pos.X+30,pos.Y+2.5,0.5,0.5,KColor(0.5,0.5,0.6,1),1,true)
				end
				UIs.RG_icon:Render(pos-Vector(8,-6))
			end)

			local polosa = UIs.Var_Sel()
			polosa.Scale = Vector(2,1)
			local Rpos = centerPos+Vector(0,-16) -- +32
			Isaac_Tower.editor.AddButton(Menuname, "Text1", Rpos, 4, 4, Sprite(), function(button) 
				if button ~= 0 then return end
			end, function(pos)
				font:DrawStringScaledUTF8(GetStr("addEnvitext1"),pos.X,pos.Y-6.5,0.5,0.5,KColor(0.3,0.3,0.4,1),0,false)
				font:DrawStringScaledUTF8(GetStr("addEnvitext2"),pos.X,pos.Y+2.5,0.5,0.5,KColor(0.3,0.3,0.4,1),0,false)
				polosa:Render(pos,Vector(0,15))
			end,true)


			local centerPos2 = Vector(Isaac.GetScreenWidth()/2-94-32, Isaac.GetScreenHeight()/2-22)  -- -32
			local Rpos = centerPos2+Vector(40,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextX", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) or tonumber(result)<10 then
							return GetStr("incorrectNumber")
						end
						NewTileData.Size.X = math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  math.ceil(NewTileData.Size.X))
			end, function(pos)
				--font:DrawStringScaledUTF8(GetStr("addEnvitext1"),pos.X-40,pos.Y-52.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				--font:DrawStringScaledUTF8(GetStr("addEnvitext2"),pos.X-40,pos.Y-44.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)

				font:DrawStringScaledUTF8(GetStr("addEnviVisualBox"),pos.X-40,pos.Y-8.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8(GetStr("addEnviSize"),pos.X+108,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("Vector",pos.X-40,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("(",pos.X-4,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local x = math.ceil(NewTileData.Size.X) --, math.ceil(NewTileData.Size.Y)
				if NewTileData.AnimName and x  then
					local str = tostring(x)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)

			local Rpos = centerPos2+Vector(71,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextXUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Size.X = math.max(10, NewTileData.Size.X + 1)
			end)
			local Rpos = centerPos2+Vector(71,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextXDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Size.X = math.max(10, NewTileData.Size.X - 1)
			end)


			local Rpos = centerPos2+Vector(76+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextY", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) or tonumber(result)<10 then
							return GetStr("incorrectNumber")
						end
						NewTileData.Size.Y = math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  math.ceil(NewTileData.Size.Y))
			end, function(pos)
				font:DrawStringScaledUTF8(",",pos.X-3,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8(")",pos.X+48,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local y = math.ceil(NewTileData.Size.Y)
				if NewTileData.AnimName and y then
					local str = tostring(y)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)
			local Rpos = centerPos2+Vector(108+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextYUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Size.Y = math.max(10, NewTileData.Size.Y + 1)
			end)
			local Rpos = centerPos2+Vector(108+16,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimSizeTextYDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Size.Y = math.max(10, NewTileData.Size.Y - 1)
			end)

			------------
			local centerPos2 = Vector(Isaac.GetScreenWidth()/2-94-32, Isaac.GetScreenHeight()/2-22+16)
			local Rpos = centerPos2+Vector(40,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextX", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) then
							return GetStr("incorrectNumber")
						end
						NewTileData.Pivot.X = -math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  -math.ceil(NewTileData.Pivot.X))
			end, function(pos)
				font:DrawStringScaledUTF8(GetStr("addEnviPivot"),pos.X+108,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("Vector",pos.X-40,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("(",pos.X-4,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local x = -math.ceil(NewTileData.Pivot.X) --, math.ceil(NewTileData.Size.Y)
				if NewTileData.AnimName and x  then
					local str = tostring(x)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)

			local Rpos = centerPos2+Vector(71,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextXUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pivot.X = NewTileData.Pivot.X - 1
			end)
			local Rpos = centerPos2+Vector(71,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextXDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pivot.X = NewTileData.Pivot.X + 1
			end)


			local Rpos = centerPos2+Vector(76+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextY", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) then
							return GetStr("incorrectNumber")
						end
						NewTileData.Pivot.Y = -math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  -math.ceil(NewTileData.Pivot.Y))
			end, function(pos)
				font:DrawStringScaledUTF8(",",pos.X-3,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8(")",pos.X+48,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local y = -math.ceil(NewTileData.Pivot.Y)
				if NewTileData.AnimName and y then
					local str = tostring(y)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)
			local Rpos = centerPos2+Vector(108+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextYUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pivot.Y = NewTileData.Pivot.Y - 1
			end)
			local Rpos = centerPos2+Vector(108+16,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPivotTextYDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pivot.Y = NewTileData.Pivot.Y + 1
			end)

			----------
			local centerPos2 =  Vector(Isaac.GetScreenWidth()/2-94-32, Isaac.GetScreenHeight()/2-22+32)
			local Rpos = centerPos2+Vector(40,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextX", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) then
							return GetStr("incorrectNumber")
						end
						NewTileData.Pos.X = math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  math.ceil(NewTileData.Pos.X))
			end, function(pos)
				font:DrawStringScaledUTF8(GetStr("addEnviPos"),pos.X+108,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("Vector",pos.X-40,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8("(",pos.X-4,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local x = math.ceil(NewTileData.Pos.X) --, math.ceil(NewTileData.Size.Y)
				if NewTileData.AnimName and x  then
					local str = tostring(x)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)

			local Rpos = centerPos2+Vector(71,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextXUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pos.X = NewTileData.Pos.X + 1
			end)
			local Rpos = centerPos2+Vector(71,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextXDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pos.X = NewTileData.Pos.X - 1
			end)


			local Rpos = centerPos2+Vector(76+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextY", Rpos, 32, 16, UIs.CounterSmol(), function(button) 
				if button ~= 0 then return end
					
				local function resultCheck(result)
					if not result then
						return true
					else
						if not tonumber(result) then
							return GetStr("incorrectNumber")
						end
						NewTileData.Pos.Y = math.ceil(tonumber(result))
						return true
					end
				end
				Isaac_Tower.editor.OpenTextboxPopup(true, resultCheck,  math.ceil(NewTileData.Pos.Y))
			end, function(pos)
				font:DrawStringScaledUTF8(",",pos.X-3,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,1),0,false)
				font:DrawStringScaledUTF8(")",pos.X+48,pos.Y-2,0.5,1,KColor(0.1,0.1,0.2,1),0,false)

				local y = math.ceil(NewTileData.Pos.Y)
				if NewTileData.AnimName and y then
					local str = tostring(y)
					font:DrawStringScaledUTF8(str,pos.X+16,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
				end
			end)
			local Rpos = centerPos2+Vector(108+16,-6+32)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextYUp", Rpos, 16, 8, UIs.CounterUpSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pos.Y = NewTileData.Pos.Y + 1
			end)
			local Rpos = centerPos2+Vector(108+16,34)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPosTextYDown", Rpos, 16, 8, UIs.CounterDownSmol(), function(button) 
				if button ~= 0 then return end
				NewTileData.Pos.Y = NewTileData.Pos.Y - 1
			end)




			local isVisible = true
			local IsOddRenderFrame = false
			local Rpos = centerPos+Vector(200,-32-40)
			Isaac_Tower.editor.AddButton(Menuname, "AnimPreview", Rpos, 48, 48, UIs.Box48(), function(button) 
				if button ~= 0 then return end
				isVisible = not isVisible
			end, function(pos)
				local renderPos = pos+Vector(12,12)
				if NewTileData.AnimName then
					AddMenuMenu.sprite:Render(renderPos+NewTileData.Pos)
					IsOddRenderFrame = not IsOddRenderFrame
					if IsOddRenderFrame then
						AddMenuMenu.sprite:Update()
					end

					if isVisible and NewTileData.Size then
						local off = NewTileData.Pivot or Vector(0,0)
						evroBoxSpr.Scale = NewTileData.Size/23
						evroBoxSpr.Color = Color(.5,.5,.5,0.7)
						evroBoxSpr:Render(renderPos-off+NewTileData.Pos)
					end
				end
			end)
			

			num = num + 1
		--end
		
	
		Isaac_Tower.editor.AddButton(Menuname, "Cancel", centerPos+Vector(62-48,15+16*5), 64, 16, UIs.ButtonWide(), function(button) 
			if button ~= 0 then return end
			Isaac_Tower.editor.SelectedMenu = "GridList"
			Isaac_Tower.editor.IsStickyMenu = false
		end, function(pos) 
			font:DrawStringScaledUTF8(GetStr("Back"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
			if not Isaac_Tower.game:IsPaused() and Isaac_Tower.editor.SelectedMenu == AddMenuMenu.Name and Input.IsButtonTriggered(Keyboard.KEY_ENTER,0) then
				Isaac_Tower.editor.SelectedMenu = "GridList"
				Isaac_Tower.editor.IsStickyMenu = false
			end
		end)

		Isaac_Tower.editor.AddButton(Menuname, "Next", centerPos+Vector(62+48,15+16*5), 64, 16, UIs.ButtonWide(), function(button) 
			if button ~= 0 then return end
			
			local ingrid = GenSprite(NewTileData.AnmFile,NewTileData.AnimName)
			ingrid.Scale = Vector(.5,.5)
			local sprr = GenSprite(NewTileData.AnmFile,NewTileData.AnimName)
			sprr.Offset = NewTileData.Pos
			sprr.Scale = AddMenuMenu.sprite.Scale
			--Isaac_Tower.editor.AddEnvironment(NewTileData.AnmFile .. NewTileData.AnimName, 
			--	sprr, 
			--	function() return GenSprite(NewTileData.AnmFile,NewTileData.AnimName) end, 
			--	ingrid, 
			--	NewTileData.Size or Vector(10,10),
			--	NewTileData.Pivot or Vector(10,10))
			Isaac_Tower.editor.GridTypes["Environment"][NewTileData.AnmFile .. NewTileData.AnimName] = {
				name = NewTileData.AnmFile .. NewTileData.AnimName, 
				spr = sprr, 
				info = function() return GenSprite(NewTileData.AnmFile,NewTileData.AnimName) end, 
				trueSpr = ingrid, 
				size = NewTileData.Size or Vector(10,10), 
				pivot = NewTileData.Pivot or Vector(10,10),
				file = NewTileData.AnmFile,
				anim = NewTileData.AnimName
			}

			Envimenu.CustomPreGenTileList("Environment")
			Envimenu.CustomGenTileList("Environment",Isaac_Tower.editor.GridListMenuPage)
			Isaac_Tower.editor.SelectedMenu = "GridList"
			Isaac_Tower.editor.IsStickyMenu = false
		end, function(pos) 
			font:DrawStringScaledUTF8(GetStr("Ok"),pos.X+30,pos.Y+3,0.5,0.5,KColor(0.1,0.1,0.2,1),1,true)
		end)
	end

	local function EvrionRender(_,menu)
		if (menu == Isaac_Tower.editor.TextboxPopup.MenuName and Isaac_Tower.editor.TextboxPopup.LastMenu == AddMenuMenu.Name) or
		menu == AddMenuMenu.Name then
			Isaac_Tower.RenderBlack(0.4)
			local CenPos = Vector(Isaac.GetScreenWidth()/2-46, Isaac.GetScreenHeight()/2)
			UIs.SpcEDIT_menu_Down:Render(CenPos+Vector(0,AddMenuMenu.numParam*16))
			UIs.SpcEDIT_menu_Cen.Scale = Vector(1,AddMenuMenu.numParam*4+2)
			UIs.SpcEDIT_menu_Cen:Render(CenPos+Vector(0,-16-AddMenuMenu.numParam*16))
			UIs.SpcEDIT_menu_Up:Render(CenPos+Vector(0,-(AddMenuMenu.numParam)*16-28))

			UIs.SpcEDIT_menu_Down:Render(CenPos+Vector(100,AddMenuMenu.numParam*16),Vector(24,0))
			UIs.SpcEDIT_menu_Cen.Scale = Vector(1,AddMenuMenu.numParam*4+2)
			UIs.SpcEDIT_menu_Cen:Render(CenPos+Vector(100,-16-AddMenuMenu.numParam*16),Vector(24,0))
			UIs.SpcEDIT_menu_Up:Render(CenPos+Vector(100,-(AddMenuMenu.numParam)*16-28),Vector(24,0))
	
			Isaac_Tower.editor.RenderMenuButtons(AddMenuMenu.Name)

			--if AddMenuMenu.sprite then
			--	CenPos:Render()
			--end
		end
	end
	mod:AddPriorityCallback(Isaac_Tower.Callbacks.EDITOR_POST_MENUS_RENDER, 1, EvrionRender)
	


	Envimenu.CustomGenTileList = function(menuName, page)
		local StartPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(200, 160)
		Isaac_Tower.editor.MenuData["GridList"] = {sortList = {}, Buttons = {}}

		local anm = Envimenu.SelectedAnm2Path

		--if Isaac_Tower.editor.GridListMenus[page] then
		if Isaac_Tower.editor.TilesListMenus[menuName][anm][page] then
			for i=1, 15 do
				--local grid = Isaac_Tower.editor.GridListMenus[page][i]
				local grid = Isaac_Tower.editor.TilesListMenus[menuName][anm][page][i]
				
				if grid  then --and grid.type
					local pos = StartPos + grid.pos
					Isaac_Tower.editor.AddButton("GridList", i, pos, 48, 48, UIs.Box48(), function(button) 
						if button ~= 0 then return end

						if grid.IsSpecial then
							OpenEvriAddMenu(anm, i)
						else
							Isaac_Tower.editor.Overlay.menus[menuName].selectedTile = grid.type
							Isaac_Tower.editor.SelectedGridType = grid.type
							
							local menu = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu]
							if menu then
								local grid = menu[Isaac_Tower.editor.Overlay.menus[menuName].selectedTile]
								--Isaac_Tower.editor.Overlay.menus[menuName].selectedTile
							--local grid = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu] 
								--and Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu][Isaac_Tower.editor.Overlay.menus[menuName].selectedTile or ""]
								if grid and grid.spr then
									Isaac_Tower.editor.Overlay.SelectedTileSprite = grid.spr
								end
							end
						end
					end, function(pos) 
						if grid.sprite then
							grid.sprite:Render(pos+Vector(12,12))
						end
					end)
				else
					--Isaac_Tower.editor.MenuButtons["GridList"][i] = nil
					Isaac_Tower.editor.RemoveButton("GridList", i)
				end
			end
		elseif Isaac_Tower.editor.TilesListMenus[menuName][anm][1] then
			Envimenu.CustomGenTileList(menuName, 1)
			return
		end

		if Isaac_Tower.editor.TilesListMenus[menuName][anm][page-1] then
			local pos = StartPos + Vector(25, 240)
			Isaac_Tower.editor.AddButton("GridList", "pre", pos, 32, 32, UIs.PrePage(), function(button) 
				if button ~= 0 then return end
				Isaac_Tower.editor.GridListMenuPage = page-1
				Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu, Isaac_Tower.editor.GridListMenuPage)
			end, nil)
		else
			Isaac_Tower.editor.RemoveButton("GridList", "pre")
		end
		if Isaac_Tower.editor.TilesListMenus[menuName][anm][page+1] then
			local pos = StartPos + Vector(350, 240)
			Isaac_Tower.editor.AddButton("GridList", "next", pos, 32, 32, UIs.NextPage(), function(button) 
				if button ~= 0 then return end
				Isaac_Tower.editor.GridListMenuPage = page+1
				Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu, Isaac_Tower.editor.GridListMenuPage)
			end, nil)
		else
			Isaac_Tower.editor.RemoveButton("GridList", "next")
		end

		local pos = StartPos + Vector(120, 256)
		local PoloskaPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(80, -96)
		Isaac_Tower.editor.AddButton("GridList", "anmsel", pos, 175, 16, UIs.TextBox(), function(button) 
			if button ~= 0 then return end
			local oldAnm = Envimenu.SelectedAnm2Path..""
			--Createlist()

			local Pos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(80, -96)
			local function pressFunc(utton, param1, param2)
				if utton ~= 0 then return end
				local oldAnm = Envimenu.SelectedAnm2Path..""
				Envimenu.SelectedAnm2Path = param2
				if oldAnm ~= Envimenu.SelectedAnm2Path then
					Envimenu.CustomGenTileList("Environment", 1)
				end
			end
			local params = {}
			for i,k in pairs(Envimenu.Anm2Path) do
				params[#params+1] = i
			end
			Isaac_Tower.editor.FastCreatelist( "GridList", Pos, 175, params, pressFunc, true)

		end, function(pos)
			font:DrawStringScaledUTF8(Envimenu.SelectedAnm2Path or "",pos.X+12,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),0,false)
			if Isaac_Tower.editor.GetButton("GridList","_Listshadow", true) then
				local poloskaOffset = (font:GetStringWidthUTF8(Envimenu.SelectedAnm2Path)/2 + 4) or 0
				UIs.TextEdPos:Render(PoloskaPos+Vector(8+poloskaOffset,2))
				UIs.TextEdPos:Update()
			end
		end)

		local pos = StartPos + Vector(80, 256)
		Isaac_Tower.editor.AddButton("GridList", "RenderLayer", pos, 16, 16, UIs.FlagBtn(), function(button) 
			if button ~= 0 then return end
			
		end, function(pos)
			font:DrawStringScaledUTF8(tostring(Isaac_Tower.editor.EnvironmentSelectedLayer) or "",pos.X+7.5,pos.Y+2.5,0.5,0.5,KColor(0.1,0.1,0.2,0.8),1,true)
		end,true)
		Isaac_Tower.editor.AddButton("GridList", "RenderLayerUp", pos+Vector(16,0), 16, 8, UIs.CounterUpSmol(), function(button) 
			if button ~= 0 then return end
			Isaac_Tower.editor.EnvironmentSelectedLayer = Isaac_Tower.editor.EnvironmentSelectedLayer + 1
		end)
		Isaac_Tower.editor.AddButton("GridList", "RenderLayerDown", pos+Vector(16,8), 16, 8, UIs.CounterDownSmol(), function(button) 
			if button ~= 0 then return end
			Isaac_Tower.editor.EnvironmentSelectedLayer = Isaac_Tower.editor.EnvironmentSelectedLayer - 1
		end)

		local spr = Isaac_Tower.editor.EnvironmentGridMode == 1 and UIs.GridModeOn() or UIs.GridModeOff()
		Isaac_Tower.editor.AddButton("GridList", "GridMode", pos+Vector(0,-16), 16, 16, spr, function(button) 
			if button ~= 0 then return end
			Isaac_Tower.editor.EnvironmentGridMode = (Isaac_Tower.editor.EnvironmentGridMode+1)%2
			local spr = Isaac_Tower.editor.EnvironmentGridMode == 1 and UIs.GridModeOn() or UIs.GridModeOff()
			Isaac_Tower.editor.GetButton("GridList", "GridMode").spr = spr
		end)
	end
end

do
	local Solidmenu = Isaac_Tower.editor.GetOverlay("Grid")
	Solidmenu.Layer = 0
	Solidmenu.CustomGenTileList = function(menuName, page)
		local StartPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(200, 160)
		Isaac_Tower.editor.BasicGenGridListMenuBtn(menuName, page)

		local pos = StartPos + Vector(80, 256)
		local SolidMode1
		SolidMode1 = Isaac_Tower.editor.AddButton("GridList", "SolidMode1", pos+Vector(0,-16), 17, 28, UIs.GridOverlayTab1(), function(button) 
			if button ~= 0 then return end
			Solidmenu.Layer = 0
		end, function(pos)
			local off = Vector(0,9)
			if Solidmenu.Layer == 0 then
				off.Y = 7
				if SolidMode1.spr:GetAnimation() ~= "вкладка2" then
					local frame = SolidMode1.spr:GetFrame()
					SolidMode1.spr = UIs.GridOverlayTab2()
					SolidMode1.spr:SetFrame(frame)
				end
				UIs.SolidMode1:SetFrame(SolidMode1.spr:GetFrame())
				UIs.SolidMode1:Render(pos+off)
			else
				UIs.SolidMode1:SetFrame(SolidMode1.spr:GetFrame())
				UIs.SolidMode1:Render(pos+off)
				if SolidMode1.spr:GetAnimation() ~= "вкладка1" then
					local frame = SolidMode1.spr:GetFrame()
					SolidMode1.spr = UIs.GridOverlayTab1()
					SolidMode1.spr:SetFrame(frame)
				end
			end
		end)
		local SolidMode2
		SolidMode2 = Isaac_Tower.editor.AddButton("GridList", "SolidMode2", pos+Vector(17,-16), 17, 28, UIs.GridOverlayTab1(), function(button) 
			if button ~= 0 then return end
			Solidmenu.Layer = 1
		end, function(pos)
			local off = Vector(0,9)
			if Solidmenu.Layer == 1 then
				off.Y = 7
				if SolidMode2.spr:GetAnimation() ~= "вкладка2" then
					local frame = SolidMode2.spr:GetFrame()
					SolidMode2.spr = UIs.GridOverlayTab2()
					SolidMode2.spr:SetFrame(frame)
				end
				UIs.SolidMode2:SetFrame(SolidMode2.spr:GetFrame())
				UIs.SolidMode2:Render(pos+off)
			else
				UIs.SolidMode2:SetFrame(SolidMode2.spr:GetFrame())
				UIs.SolidMode2:Render(pos+off)
				if SolidMode2.spr:GetAnimation() ~= "вкладка1" then
					local frame = SolidMode2.spr:GetFrame()
					SolidMode2.spr = UIs.GridOverlayTab1()
					SolidMode2.spr:SetFrame(frame)
				end
			end
		end)
	end
end
do
	local Enemiesmenu = Isaac_Tower.editor.GetOverlay("Enemies")
	Enemiesmenu.Layer = 0
	Enemiesmenu.lists = {"Enemies","Bonus"}
	local SelectedTiles = {}
	Enemiesmenu.CustomGenTileList = function(menuName, page)
		local StartPos = Vector(Isaac.GetScreenWidth()/2, Isaac.GetScreenHeight()/2) - Vector(200, 160)
		local Flist = Enemiesmenu.lists
		local main = Flist[Enemiesmenu.Layer+1]
		--Isaac_Tower.editor.BasicGenGridListMenuBtn(main, page)

		----------------
			local StartPos = Vector(Isaac.GetScreenWidth() / 2, Isaac.GetScreenHeight() / 2) - Vector(200, 160)
			Isaac_Tower.editor.MenuData["GridList"] = { sortList = {}, Buttons = {} }

			local CurGroup = Flist[Enemiesmenu.Layer+1]
			if Isaac_Tower.editor.TilesListMenus[menuName][CurGroup][page] then
				for i = 1, 15 do
					local grid = Isaac_Tower.editor.TilesListMenus[menuName][CurGroup][page][i]

					if grid and grid.type then
						local pos = StartPos + grid.pos
						Isaac_Tower.editor.AddButton("GridList", i, pos, 48, 48, UIs.Box48(), function(button)
							if button ~= 0 then return end
							Isaac_Tower.editor.Overlay.menus[menuName].selectedTile = grid.type
							Isaac_Tower.editor.SelectedGridType = grid.type

							local menu = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu]
							if menu then
								local grid = menu[Isaac_Tower.editor.Overlay.menus[menuName].selectedTile]
								if grid and grid.spr then
									Isaac_Tower.editor.Overlay.SelectedTileSprite = grid.spr
								end
							end
						end, function(pos)
							if grid.sprite then
								grid.sprite:Render(pos + Vector(12, 12))
							end
						end)
					else
						Isaac_Tower.editor.RemoveButton("GridList", i)
					end
				end
			end
			if Isaac_Tower.editor.TilesListMenus[menuName][CurGroup][page - 1] then
				local pos = StartPos + Vector(25, 240)
				Isaac_Tower.editor.AddButton("GridList", "pre", pos, 32, 32, UIs.PrePage(), function(button)
					if button ~= 0 then return end
					Isaac_Tower.editor.GridListMenuPage = page - 1
					Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu,
						Isaac_Tower.editor.GridListMenuPage)
				end, nil)
			else
				Isaac_Tower.editor.RemoveButton("GridList", "pre")
			end
			if Isaac_Tower.editor.TilesListMenus[menuName][CurGroup][page + 1] then
				local pos = StartPos + Vector(350, 240)
				Isaac_Tower.editor.AddButton("GridList", "next", pos, 32, 32, UIs.NextPage(), function(button)
					if button ~= 0 then return end
					Isaac_Tower.editor.GridListMenuPage = page + 1
					Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu,
						Isaac_Tower.editor.GridListMenuPage)
				end, nil)
			else
				Isaac_Tower.editor.RemoveButton("GridList", "next")
			end
		---------------------

		local function Buttons()

			local pos = StartPos + Vector(80, 256)
			local SolidMode1
			SolidMode1 = Isaac_Tower.editor.AddButton("GridList", "SolidMode1", pos+Vector(0,-16), 17, 28, UIs.GridOverlayTab1(), function(button) 
				if button ~= 0 then return end
				SelectedTiles[Enemiesmenu.Layer] = Isaac_Tower.editor.SelectedGridType
				Enemiesmenu.Layer = 0
				Isaac_Tower.editor.GridListMenuPage = 1
				--Isaac_Tower.editor.BasicGenGridListMenuBtn(Flist[Enemiesmenu.Layer+1], Isaac_Tower.editor.GridListMenuPage)
				Enemiesmenu.CustomGenTileList(menuName, Isaac_Tower.editor.GridListMenuPage)
				Buttons()
				if SelectedTiles[Enemiesmenu.Layer] then
					Isaac_Tower.editor.SelectedGridType = SelectedTiles[Enemiesmenu.Layer]
					Isaac_Tower.editor.Overlay.SelectedTileSprite = 
						Isaac_Tower.editor.GridTypes[menuName][Isaac_Tower.editor.SelectedGridType].spr
				end
			end, function(pos)
				local off = Vector(0,9)
				if Enemiesmenu.Layer == 0 then
					off.Y = 7
					if SolidMode1.spr:GetAnimation() ~= "вкладка2" then
						local frame = SolidMode1.spr:GetFrame()
						SolidMode1.spr = UIs.GridOverlayTab2()
						SolidMode1.spr:SetFrame(frame)
					end
					UIs.EnemiesMode1:SetFrame(SolidMode1.spr:GetFrame())
					UIs.EnemiesMode1:Render(pos+off)
				else
					UIs.EnemiesMode1:SetFrame(SolidMode1.spr:GetFrame())
					UIs.EnemiesMode1:Render(pos+off)
					if SolidMode1.spr:GetAnimation() ~= "вкладка1" then
						local frame = SolidMode1.spr:GetFrame()
						SolidMode1.spr = UIs.GridOverlayTab1()
						SolidMode1.spr:SetFrame(frame)
					end
				end
			end)
			local SolidMode2
			SolidMode2 = Isaac_Tower.editor.AddButton("GridList", "SolidMode2", pos+Vector(17,-16), 17, 28, UIs.GridOverlayTab1(), function(button) 
				if button ~= 0 then return end
				SelectedTiles[Enemiesmenu.Layer] = Isaac_Tower.editor.SelectedGridType
				Enemiesmenu.Layer = 1
				Isaac_Tower.editor.GridListMenuPage = 1
				--Isaac_Tower.editor.BasicGenGridListMenuBtn(Flist[Enemiesmenu.Layer+1], Isaac_Tower.editor.GridListMenuPage)
				Enemiesmenu.CustomGenTileList(menuName, Isaac_Tower.editor.GridListMenuPage)
				Buttons()
				if SelectedTiles[Enemiesmenu.Layer] then
					Isaac_Tower.editor.SelectedGridType = SelectedTiles[Enemiesmenu.Layer]
					Isaac_Tower.editor.Overlay.SelectedTileSprite = Isaac_Tower.editor.GridTypes[menuName][Isaac_Tower.editor.SelectedGridType].spr
				end
			end, function(pos)
				local off = Vector(0,9)
				if Enemiesmenu.Layer == 1 then
					off.Y = 7
					if SolidMode2.spr:GetAnimation() ~= "вкладка2" then
						local frame = SolidMode2.spr:GetFrame()
						SolidMode2.spr = UIs.GridOverlayTab2()
						SolidMode2.spr:SetFrame(frame)
					end
					UIs.EnemiesMode2:SetFrame(SolidMode2.spr:GetFrame())
					UIs.EnemiesMode2:Render(pos+off)
				else
					UIs.EnemiesMode2:SetFrame(SolidMode2.spr:GetFrame())
					UIs.EnemiesMode2:Render(pos+off)
					if SolidMode2.spr:GetAnimation() ~= "вкладка1" then
						local frame = SolidMode2.spr:GetFrame()
						SolidMode2.spr = UIs.GridOverlayTab1()
						SolidMode2.spr:SetFrame(frame)
					end
				end
			end)
		end
		Buttons()
	end

	Enemiesmenu.CustomPreGenTileList = function(menuName)
		Isaac_Tower.editor.TilesListMenus[menuName] = {}
		local num = {} --0
		for i, k in pairs(Isaac_Tower.editor.GridTypes[menuName]) do
		--for name, bol in pairs(Enemiesmenu.groups[Enemiesmenu.lists[Enemiesmenu.Layer+1] ]) do
			--local k = Isaac_Tower.editor.GridTypes[menuName][name]
			num[k.group] = num[k.group] or 0
			num[k.group] = num[k.group] + 1
			local nbum = num[k.group]
			
			local page = math.ceil(nbum / 15)
			local xpos, ypos = (nbum - 1) % 5 + 1, math.ceil(((nbum - 1) % 15 + 1) / 5)
			SafePlacingTable(Isaac_Tower.editor.TilesListMenus,menuName,k.group,page)[(nbum - 1) % 15 + 1] = {
				pos = Vector(60 * xpos, 60 * ypos), --Vector(52*xpos, 49*ypos),
				sprite = k.spr,
				type = i,
			}
		end
	end
end





Isaac_Tower.editor.Overlay.selectedMenu = "Grid"




local OldRenderPos = Vector(0,0)
local MouseOldPos = Vector(0,0)
Isaac_Tower.editor.MenuLogic = {
  grid = function(MousePos)
	--[[local algMousePos = MousePos - Isaac_Tower.editor.GridStartPos
	local xs,ys = math.floor(algMousePos.Y/(26/2)), math.floor(algMousePos.X/(26/2))
	
	local list = Isaac_Tower.editor.Memory.CurrentRoom.Solid
	local grid = list[ys] and list[ys][xs]
	
	if Isaac_Tower.editor.Memory.CurrentRoom.Size.Y>=xs and Isaac_Tower.editor.Memory.CurrentRoom.Size.X>=ys then
		Isaac_Tower.editor.SelectedGrid = {xs, ys}
	else
		Isaac_Tower.editor.SelectedGrid = nil
	end]]
	local addPos = Vector(-Input.GetActionValue(ButtonAction.ACTION_LEFT, 0) + Input.GetActionValue(ButtonAction.ACTION_RIGHT, 0),
		-Input.GetActionValue(ButtonAction.ACTION_UP, 0) + Input.GetActionValue(ButtonAction.ACTION_DOWN, 0))
	

	Isaac_Tower.editor.GridStartPos = Isaac_Tower.editor.GridStartPos - addPos

	if Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) then
		Isaac_Tower.editor.BlockPlaceGrid = true
		if not Isaac_Tower.editor.MouseSprite or Isaac_Tower.editor.MouseSprite:GetAnimation() ~= "mouse_grab" then
			Isaac_Tower.editor.MouseSprite = UIs.MouseGrab
		end
		if Input.IsMouseBtnPressed(0) then
			Isaac_Tower.editor.MouseSprite:SetFrame(1)
			local offset = MousePos - MouseOldPos
			Isaac_Tower.editor.GridStartPos = OldRenderPos + offset
		else
			Isaac_Tower.editor.MouseSprite:SetFrame(0)
			MouseOldPos = MousePos/1
			OldRenderPos = Isaac_Tower.editor.GridStartPos/1
		end
	elseif Isaac_Tower.editor.MouseSprite and Isaac_Tower.editor.MouseSprite:GetAnimation() == "mouse_grab" then
		Isaac_Tower.editor.BlockPlaceGrid = nil
		Isaac_Tower.editor.MouseSprite = nil
	end
  end,
  menuUp = function(MousePos)
	local addPos = Vector(-Input.GetActionValue(ButtonAction.ACTION_LEFT, 0) + Input.GetActionValue(ButtonAction.ACTION_RIGHT, 0),
		-Input.GetActionValue(ButtonAction.ACTION_UP, 0) + Input.GetActionValue(ButtonAction.ACTION_DOWN, 0))
	Isaac_Tower.editor.GridStartPos = Isaac_Tower.editor.GridStartPos + addPos
  end,
  GridList = function()

  end
}

Isaac_Tower.editor.GridListMenus = {}
Isaac_Tower.editor.ObsListMenus = {}
Isaac_Tower.editor.TilesListMenus = {}

function Isaac_Tower.editor.PreGenerateGridListMenu(menuName)
	if menuName then
		if Isaac_Tower.editor.Overlay.menus[menuName].CustomPreGenTileList then
			Isaac_Tower.editor.Overlay.menus[menuName].CustomPreGenTileList(menuName)
		else
			Isaac_Tower.editor.TilesListMenus[menuName] = {}
			local num = 0
			for i,k in pairs(Isaac_Tower.editor.GridTypes[menuName]) do
					
				num = num + 1
				local page = math.ceil(num/15)
				Isaac_Tower.editor.TilesListMenus[menuName][page] = Isaac_Tower.editor.TilesListMenus[menuName][page] or {}
				local xpos, ypos = (num-1)%5+1, math.ceil( ((num-1)%15+1)/5 )
				Isaac_Tower.editor.TilesListMenus[menuName][page][(num-1)%15+1] = {
					pos = Vector(60*xpos, 60*ypos), --Vector(52*xpos, 49*ypos),
					sprite = k.spr,
					type = i,
				}
			end
		end
		
	else
		for name in pairs(Isaac_Tower.editor.Overlay.menus) do
			if Isaac_Tower.editor.Overlay.menus[name].CustomPreGenTileList then
				Isaac_Tower.editor.Overlay.menus[name].CustomPreGenTileList(name)
			else
				Isaac_Tower.editor.TilesListMenus[name] = {}
				local num = 0
				for i,k in pairs(Isaac_Tower.editor.GridTypes[name]) do
					
					num = num + 1
					local page = math.ceil(num/15)
					Isaac_Tower.editor.TilesListMenus[name][page] = Isaac_Tower.editor.TilesListMenus[name][page] or {}
					local xpos, ypos = (num-1)%5+1, math.ceil( ((num-1)%15+1)/5 )
					Isaac_Tower.editor.TilesListMenus[name][page][(num-1)%15+1] = {
						pos = Vector(60*xpos, 60*ypos), --Vector(52*xpos, 49*ypos),
						sprite = k.spr,
						type = i,
					}
				end
			end
		end
	end
end
--Isaac_Tower.editor.ObsTypes = {}
--Isaac_Tower.editor.ObsAnimNames = {}
function Isaac_Tower.editor.BasicGenGridListMenuBtn(menuName, page)
	local StartPos = Vector(Isaac.GetScreenWidth() / 2, Isaac.GetScreenHeight() / 2) - Vector(200, 160)
	Isaac_Tower.editor.MenuData["GridList"] = { sortList = {}, Buttons = {} }

	--if Isaac_Tower.editor.GridListMenus[page] then
	if Isaac_Tower.editor.TilesListMenus[menuName][page] then
		for i = 1, 15 do
			--local grid = Isaac_Tower.editor.GridListMenus[page][i]
			local grid = Isaac_Tower.editor.TilesListMenus[menuName][page][i]

			if grid and grid.type then
				local pos = StartPos + grid.pos
				Isaac_Tower.editor.AddButton("GridList", i, pos, 48, 48, UIs.Box48(), function(button)
					if button ~= 0 then return end
					--Isaac_Tower.editor.SelectedGridType = grid.type
					Isaac_Tower.editor.Overlay.menus[menuName].selectedTile = grid.type
					Isaac_Tower.editor.SelectedGridType = grid.type

					local menu = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu]
					if menu then
						local grid = menu[Isaac_Tower.editor.Overlay.menus[menuName].selectedTile]
						--Isaac_Tower.editor.Overlay.menus[menuName].selectedTile
						--local grid = Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu]
						--and Isaac_Tower.editor.GridTypes[Isaac_Tower.editor.Overlay.selectedMenu][Isaac_Tower.editor.Overlay.menus[menuName].selectedTile or ""]
						if grid and grid.spr then
							Isaac_Tower.editor.Overlay.SelectedTileSprite = grid.spr
						end
					end
				end, function(pos)
					if grid.sprite then
						grid.sprite:Render(pos + Vector(12, 12))
					end
				end)
			else
				--Isaac_Tower.editor.MenuButtons["GridList"][i] = nil
				Isaac_Tower.editor.RemoveButton("GridList", i)
			end
		end
	end
	--if Isaac_Tower.editor.GridListMenus[page-1] then
	if Isaac_Tower.editor.TilesListMenus[menuName][page - 1] then
		local pos = StartPos + Vector(25, 240)
		Isaac_Tower.editor.AddButton("GridList", "pre", pos, 32, 32, UIs.PrePage(), function(button)
			if button ~= 0 then return end
			Isaac_Tower.editor.GridListMenuPage = page - 1
			Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu,
				Isaac_Tower.editor.GridListMenuPage)
		end, nil)
	else
		Isaac_Tower.editor.RemoveButton("GridList", "pre")
		--Isaac_Tower.editor.MenuButtons["GridList"].pre = nil
	end
	--if Isaac_Tower.editor.GridListMenus[page+1] then
	if Isaac_Tower.editor.TilesListMenus[menuName][page + 1] then
		local pos = StartPos + Vector(350, 240)
		Isaac_Tower.editor.AddButton("GridList", "next", pos, 32, 32, UIs.NextPage(), function(button)
			if button ~= 0 then return end
			Isaac_Tower.editor.GridListMenuPage = page + 1
			Isaac_Tower.editor.GenGridListMenuBtn(Isaac_Tower.editor.Overlay.selectedMenu,
				Isaac_Tower.editor.GridListMenuPage)
		end, nil)
	else
		Isaac_Tower.editor.RemoveButton("GridList", "next")
		--Isaac_Tower.editor.MenuButtons["GridList"].next = nil
	end
end

function Isaac_Tower.editor.GenGridListMenuBtn(menuName, page)
	if Isaac_Tower.editor.Overlay.menus[menuName].CustomGenTileList then
		Isaac_Tower.editor.Overlay.menus[menuName].CustomGenTileList(menuName,page)
	else
		Isaac_Tower.editor.BasicGenGridListMenuBtn(menuName, page)
	end
end

local function ChangeOverlayMenu(Name, num)
	--Isaac_Tower.editor.MenuButtons["Overlays"][num].spr = UIs.OverlayTab2()
	Isaac_Tower.editor.GetButton("Overlays",num).spr = UIs.OverlayTab2()
	if Isaac_Tower.editor.Overlay.selectedMenu ~= Name then
		Isaac_Tower.editor.GridListMenuPage = 1
	end
	Isaac_Tower.editor.Overlay.selectedMenu = Name

	Isaac_Tower.editor.SelectedGridType = Isaac_Tower.editor.Overlay.menus[Name].selectedTile
	
	local menu = Isaac_Tower.editor.GridTypes[Name]
	if menu then
		local grid = menu[Isaac_Tower.editor.Overlay.menus[Name].selectedTile]
		if grid and grid.spr then
			Isaac_Tower.editor.Overlay.SelectedTileSprite = grid.spr
		else
			Isaac_Tower.editor.Overlay.SelectedTileSprite = nil
		end
	end
end

function Isaac_Tower.editor.GenOverlayMenu()
	Isaac_Tower.editor.MenuData["Overlays"] = Isaac_Tower.editor.MenuData["Overlays"] or {sortList = {}, Buttons = {}}
	for i,k in ipairs(Isaac_Tower.editor.MenuData["Overlays"]) do
		k = nil
	end
	local pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-32)
	local bum = 1
	local AccMenus = {grid = true, menuUp = true}

	--for i,k in pairs(Isaac_Tower.editor.Overlay.menus) do
	for i = 1, #Isaac_Tower.editor.Overlay.order do
		local k = Isaac_Tower.editor.Overlay.menus[Isaac_Tower.editor.Overlay.order[i]]
		local OverlayName = Isaac_Tower.editor.Overlay.order[i]

		local inum = bum + 0
		local rnum = #Isaac_Tower.editor.Overlay.order - bum
		Isaac_Tower.editor.AddButton("Overlays", bum, pos - Vector(rnum*16+24, 0), 16, 32, UIs.OverlayTab2(), function(button) 
			if button ~= 0 then return end
			--Isaac_Tower.editor.MenuButtons["Overlays"][inum].spr = UIs.OverlayTab2()
			--if Isaac_Tower.editor.Overlay.selectedMenu ~= OverlayName then
			--	Isaac_Tower.editor.GridListMenuPage = 1
			--end
			--Isaac_Tower.editor.Overlay.selectedMenu = OverlayName

			ChangeOverlayMenu(OverlayName, inum)
		end, function(pos) 
			if Isaac_Tower.editor.Overlay.selectedMenu == OverlayName then
				k.spr:Render(pos+Vector(0,-3))
			else
				k.spr:Render(pos)
			end
			if AccMenus[Isaac_Tower.editor.SelectedMenu] and
			Input.IsButtonPressed(Keyboard["KEY_" .. tostring(inum)], 0) then
				--Isaac_Tower.editor.Overlay.selectedMenu = OverlayName
				--Isaac_Tower.editor.MenuButtons["Overlays"][inum].spr = UIs.OverlayTab2()
				ChangeOverlayMenu(OverlayName, inum)
			end
			
			if Isaac_Tower.editor.Overlay.selectedMenu ~= OverlayName and Isaac_Tower.editor.GetButton("Overlays",inum).spr:GetAnimation() ~= "оверлей_вкладка1" then
				Isaac_Tower.editor.GetButton("Overlays",inum).spr = UIs.OverlayTab1()
			end
			if Isaac.GetFrameCount()%30 == 0 then
				Isaac_Tower.editor.GetButton("Overlays",inum).pos = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight()-32) - Vector(rnum*16+24, 0)
			end
		end)
		bum = bum + 1
	end
	Isaac_Tower.editor.Overlay.DetectPosX = Isaac_Tower.editor.Overlay.num*16 + 16 + 22+16
end


local SpecialConstMem = {}
SpecialConstMem.ArrowLeft = GenSprite("gfx/editor/special_tiles.anm2","arrow_smol",0)
SpecialConstMem.ArrowRight = GenSprite("gfx/editor/special_tiles.anm2","arrow_smol",1)
SpecialConstMem.ArrowUp = GenSprite("gfx/editor/special_tiles.anm2","arrow_smol",2)
SpecialConstMem.ArrowDown = GenSprite("gfx/editor/special_tiles.anm2","arrow_smol",3)
--SpecialConstMem.ArrowLeft.Scale = Vector(0.5,0.5)
--SpecialConstMem.ArrowRight.Scale = Vector(0.5,0.5)
--SpecialConstMem.ArrowUp.Scale = Vector(0.5,0.5)
--SpecialConstMem.ArrowDown.Scale = Vector(0.5,0.5)
SpecialConstMem.ArrowLeft.Offset = Vector(0,-1.0)
SpecialConstMem.ArrowRight.Offset = Vector(0,-1.0)
SpecialConstMem.ArrowUp.Offset = Vector(-1,0)
SpecialConstMem.ArrowDown.Offset = Vector(-1,0)

mod:AddCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_UPDATE, function(_,IsSelected)
	if IsSelected and Isaac.GetFrameCount()%60 == 0 and not Isaac_Tower.game:IsPaused() then
		local NeedRepeat = false
		local DefPointNum = 0

		for Gtype,tab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
			for i,y in pairs(tab) do
				for j, x in pairs(y) do
					if x.info and x.info.IsDefSpawnPoint then
						DefPointNum = DefPointNum + 1
						if DefPointNum > 1 then
							NeedRepeat = true
							SpecialConstMem.MultiDesPoint = true
						end
					end
				end
			end
		end

		
		if SpecialConstMem.MultiDesPoint and DefPointNum <= 1 then
			SpecialConstMem.MultiDesPoint = false
			for i,y in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special["spawnpoint_def"]) do
				for j, x in pairs(y) do
					if x.info and x.info.IsDefSpawnPoint then
						x.ErrorMes = nil
					end
				end
			end
		end

		if NeedRepeat then
			for Gtype,tab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
				for i,y in pairs(tab) do
					for j, x in pairs(y) do
						if x.info and x.info.IsDefSpawnPoint then
							x.ErrorMes = GetStr("DefSpawnPoint")
						end
					end
				end
			end
		end

	end
end)

local function SameVector(v1,v2)
	return v1.X == v2.X and v1.Y == v2.Y
end

local Room_Transition_Spr =  GenSprite("gfx/editor/special_tiles.anm2","room_transition")
Room_Transition_Spr.Scale = Vector(0.5,0.5)
mod:AddCallback(Isaac_Tower.Callbacks.EDITOR_SPECIAL_TILE_RENDER, function(_,info, renderPos, OverleySelected, IsSel, Gridscale)
	local Linfo = info.info()
	if Linfo and Linfo.ErrorMes then
		ErrorSignSpr:Render(renderPos)
		if not Isaac_Tower.game:IsPaused() and IsSel then
			ShowErrorMes = Linfo.ErrorMes
		end
	end
	if OverleySelected and Linfo then
		if Isaac_Tower.editor.SpecialSelectedTile == Linfo and Linfo.type == "Room_Transition" then --стена коооооооооооооооооооооооооооооооооооооооооооооооооооооооооооооооооооода
			local size = info.info().Size
			local Cenpos = renderPos + Vector(13/2.0*size.X,13/2.0*size.Y)*Gridscale
			local addOffset = Linfo.ThitRenderOffset or Vector(0,0)
			if size.Y<2 then
				SpecialConstMem.ArrowLeft:Render(Cenpos-Vector(13/2*size.X,0)*Gridscale+addOffset)
				SpecialConstMem.ArrowRight:Render(Cenpos+Vector(13/2*size.X,0)*Gridscale+addOffset)
			end
			if size.X<2 then
				SpecialConstMem.ArrowUp:Render(Cenpos+Vector(0,-13/2*size.Y)*Gridscale+addOffset)
				SpecialConstMem.ArrowDown:Render(Cenpos+Vector(0,13/2*size.Y)*Gridscale+addOffset)
			end

			if not Isaac_Tower.game:IsPaused() and Isaac_Tower.editor.SelectedMenu == "grid" then
				if Isaac_Tower.editor.NeedRemoveBlockPlaceGrid and not SpecialConstMem.OldMousePos then
					Isaac_Tower.editor.NeedRemoveBlockPlaceGrid = nil
					Isaac_Tower.editor.BlockPlaceGrid = nil
				end
				local MousePos = Isaac_Tower.editor.MousePos

				local CanDrag = false
				if size.Y < 2 then
					--SpecialConstMem.ArrowLeft:Render(Rpos-Vector(13/2*size.X,0))
					--SpecialConstMem.ArrowRight:Render(Rpos+Vector(13/2*size.X,0))
					if (Cenpos - Vector(13 / 2 * size.X*Gridscale + 4, 0)):Distance(MousePos) < 5 then
						if not Isaac_Tower.editor.BlockPlaceGrid then
							Isaac_Tower.editor.NeedRemoveBlockPlaceGrid = true
						end
						Isaac_Tower.editor.BlockPlaceGrid = true
						SpecialConstMem.ArrowLeft.Color = Color(0.5, 0.5, 0.5, 1)
						SpecialConstMem.ArrowLeft:Render(Cenpos - Vector(13 / 2 * size.X, 0)*Gridscale)
						SpecialConstMem.ArrowLeft.Color = Color.Default
						CanDrag = 0
						SpecialConstMem.GragDir = 0
					elseif (Cenpos+Vector(13/2*size.X*Gridscale + 4,0)):Distance(MousePos) < 5 then
						if not Isaac_Tower.editor.BlockPlaceGrid then
							Isaac_Tower.editor.NeedRemoveBlockPlaceGrid = true
						end
						Isaac_Tower.editor.BlockPlaceGrid = true
						SpecialConstMem.ArrowRight.Color = Color(0.5, 0.5, 0.5, 1)
						SpecialConstMem.ArrowRight:Render(Cenpos+Vector(13/2*size.X,0)*Gridscale)
						SpecialConstMem.ArrowRight.Color = Color.Default
						CanDrag = 2
						SpecialConstMem.GragDir = 2
					end
				end
				if size.X < 2 then
					if (Cenpos+Vector(0,-13/2*size.Y*Gridscale-4)):Distance(MousePos) < 5 then
						if not Isaac_Tower.editor.BlockPlaceGrid then
							Isaac_Tower.editor.NeedRemoveBlockPlaceGrid = true
						end
						Isaac_Tower.editor.BlockPlaceGrid = true
						SpecialConstMem.ArrowUp.Color = Color(0.5, 0.5, 0.5, 1)
						SpecialConstMem.ArrowUp:Render(Cenpos+Vector(0,-13/2*size.Y)*Gridscale)
						SpecialConstMem.ArrowUp.Color = Color.Default
						CanDrag = 1
						SpecialConstMem.GragDir = 1
					elseif (Cenpos+Vector(0,13/2*size.Y*Gridscale+4)):Distance(MousePos) < 5 then
						if not Isaac_Tower.editor.BlockPlaceGrid then
							Isaac_Tower.editor.NeedRemoveBlockPlaceGrid = true
						end
						Isaac_Tower.editor.BlockPlaceGrid = true
						SpecialConstMem.ArrowDown.Color = Color(0.5, 0.5, 0.5, 1)
						SpecialConstMem.ArrowDown:Render(Cenpos+Vector(0,13/2*size.Y)*Gridscale)
						SpecialConstMem.ArrowDown.Color = Color.Default
						CanDrag = 3
						SpecialConstMem.GragDir = 3
					end
				end
				if size.X < 2 then
					--SpecialConstMem.ArrowUp:Render(Rpos+Vector(0,-13/2*size.Y))
					--SpecialConstMem.ArrowDown:Render(Rpos+Vector(0,13/2*size.Y))
				end	

				if CanDrag or SpecialConstMem.OldMousePos then
					if Input.IsMouseBtnPressed(0) then
						if not SpecialConstMem.OldMousePos then
							SpecialConstMem.OldMousePos = MousePos
							SpecialConstMem.OldSize = size*1
						end
						local Offset = MousePos - SpecialConstMem.OldMousePos
						if SpecialConstMem.GragDir == 0 then
							--print(math.ceil(Offset.X/-13*0.90))
							SpecialConstMem.NewSize = SpecialConstMem.NewSize or size/1

							--size.X = math.min( math.max(SpecialConstMem.OldSize.X, Linfo.XY.X) ,math.max(1-SpecialConstMem.OldSize.X+1,math.ceil(Offset.X/-13*1.1)+SpecialConstMem.OldSize.X))
							size.X = math.min( math.max(SpecialConstMem.NewSize.X+1, Linfo.XY.X) ,math.max(1,math.ceil(Offset.X/-13*1.1)+SpecialConstMem.OldSize.X))
							--print(size.X, Linfo.XY.X, 1-SpecialConstMem.OldSize.X+1, math.max(0,size.X-SpecialConstMem.NewSize.X))
							--local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							--local grid = list[Linfo.XY.Y][Linfo.XY.X - size.X-SpecialConstMem.NewSize.X]
							--print(Linfo.XY.X - size.X-SpecialConstMem.NewSize.X, grid)
							--if SpecialConstMem.NewSize.X<size.X and CheckEmpty(Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type],
							--Linfo.XY-Vector(size.X-SpecialConstMem.OldSize.X,0), Vector(math.max(0,size.X-SpecialConstMem.OldSize.X),1)) then

							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local nextInx = Linfo.XY.X - SpecialConstMem.NewSize.X + SpecialConstMem.OldSize.X-1
							local grid = list[Linfo.XY.Y][nextInx]
							--print(grid, nextInx, SpecialConstMem.OldSize.Y)
							--if SpecialConstMem.NewSize.Y<size.Y and CheckEmpty(Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type],
							--Linfo.XY-Vector(0,size.Y-SpecialConstMem.OldSize.Y), Vector(1,math.max(0,size.Y-SpecialConstMem.OldSize.Y))) then
							local isSameGrid = grid and (not grid.Parent and SameVector(Linfo.XY,grid.XY) or grid.Parent and SameVector(Linfo.XY,grid.Parent) )
							--print( not grid , grid and not grid.Parent , grid and grid.Parent and (grid.Parent.X == Linfo.XY.X and grid.Parent.Y == Linfo.XY.Y),
							--	not grid or isSameGrid)
							if SpecialConstMem.NewSize.X<size.X and (not grid or isSameGrid) and (nextInx)>0 then
								SpecialConstMem.NewSize.X = SpecialConstMem.NewSize.X + 1
							elseif SpecialConstMem.NewSize.X>size.X then
								SpecialConstMem.NewSize.X = SpecialConstMem.NewSize.X - 1
							end
							info.info().Size = SpecialConstMem.NewSize/1
							Linfo.ThitRenderOffset = Vector(-13*0.99*(info.info().Size.X-SpecialConstMem.OldSize.X),0)  ---Нужно смещать позицию при отпускание
							--info.info().Size = SpecialConstMem.NewSize/1

						elseif SpecialConstMem.GragDir == 1  then
							SpecialConstMem.NewSize = SpecialConstMem.NewSize or size/1
							size.Y = math.min( math.max(SpecialConstMem.NewSize.Y+1, Linfo.XY.Y) ,math.max(1,math.ceil(Offset.Y/-13*1.1)+SpecialConstMem.OldSize.Y))

							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local nextInx = Linfo.XY.Y - SpecialConstMem.NewSize.Y + SpecialConstMem.OldSize.Y-1
							local grid = list[nextInx] 
								and list[nextInx][Linfo.XY.X]
							--print(grid, nextInx, SpecialConstMem.OldSize.Y)
							--if SpecialConstMem.NewSize.Y<size.Y and CheckEmpty(Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type],
							--Linfo.XY-Vector(0,size.Y-SpecialConstMem.OldSize.Y), Vector(1,math.max(0,size.Y-SpecialConstMem.OldSize.Y))) then
							local isSameGrid = grid and (not grid.Parent and SameVector(Linfo.XY,grid.XY) or grid.Parent and SameVector(Linfo.XY,grid.Parent) )
							--print( not grid , grid and not grid.Parent , grid and grid.Parent and (grid.Parent.X == Linfo.XY.X and grid.Parent.Y == Linfo.XY.Y),
							--	not grid or isSameGrid)
							if SpecialConstMem.NewSize.Y<size.Y and (not grid or isSameGrid) and (nextInx)>0 then
								SpecialConstMem.NewSize.Y = SpecialConstMem.NewSize.Y + 1
							elseif SpecialConstMem.NewSize.Y>size.Y then
								SpecialConstMem.NewSize.Y = SpecialConstMem.NewSize.Y - 1
							end
							info.info().Size = SpecialConstMem.NewSize/1
							Linfo.ThitRenderOffset = Vector(0,-13*0.99*(info.info().Size.Y-SpecialConstMem.OldSize.Y))

						elseif SpecialConstMem.GragDir == 2  then
							SpecialConstMem.NewSize = SpecialConstMem.NewSize or size/1

							size.X = math.min( math.max(SpecialConstMem.NewSize.X+1, Linfo.XY.X) ,math.max(1,math.ceil(Offset.X/13*1.1)+SpecialConstMem.OldSize.X))
							
							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local nextInx = Linfo.XY.X + SpecialConstMem.NewSize.X
							local grid = list[Linfo.XY.Y][nextInx]
							local isSameGrid = grid and (not grid.Parent and SameVector(Linfo.XY,grid.XY) or grid.Parent and SameVector(Linfo.XY,grid.Parent) )
							
							if SpecialConstMem.NewSize.X<size.X and (not grid or isSameGrid) and (nextInx)<Isaac_Tower.editor.Memory.CurrentRoom.Size.X+1 then
								SpecialConstMem.NewSize.X = SpecialConstMem.NewSize.X + 1
							elseif SpecialConstMem.NewSize.X>size.X then
								SpecialConstMem.NewSize.X = SpecialConstMem.NewSize.X - 1
							end
							info.info().Size = SpecialConstMem.NewSize/1
							Linfo.ThitRenderOffset = Vector(0,0) 
						elseif SpecialConstMem.GragDir == 3  then
							SpecialConstMem.NewSize = SpecialConstMem.NewSize or size/1

							size.Y = math.min( math.max(SpecialConstMem.NewSize.Y+1, Linfo.XY.Y) ,math.max(1,math.ceil(Offset.Y/13*1.1)+SpecialConstMem.OldSize.Y))
						
							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local nextInx = Linfo.XY.Y + SpecialConstMem.NewSize.Y

							local grid = list[nextInx] 
								and list[nextInx][Linfo.XY.X]
							local isSameGrid = grid and (not grid.Parent and SameVector(Linfo.XY,grid.XY) or grid.Parent and SameVector(Linfo.XY,grid.Parent) )
							
							if SpecialConstMem.NewSize.Y<size.Y and (not grid or isSameGrid) and (nextInx)<Isaac_Tower.editor.Memory.CurrentRoom.Size.Y+1 then
								SpecialConstMem.NewSize.Y = SpecialConstMem.NewSize.Y + 1
							elseif SpecialConstMem.NewSize.Y>size.Y then
								SpecialConstMem.NewSize.Y = SpecialConstMem.NewSize.Y - 1
							end
							info.info().Size = SpecialConstMem.NewSize/1
							Linfo.ThitRenderOffset = Vector(0,0) 
						end
					else
						size = SpecialConstMem.NewSize and (SpecialConstMem.NewSize/1) or size
						SpecialConstMem.NewSize = nil
						SpecialConstMem.OldMousePos = nil
						--SpecialConstMem.GragDir = nil
						local hernya = {[0] = true,[1] = true}
						if hernya[SpecialConstMem.GragDir] and Linfo.ThitRenderOffset and (Linfo.ThitRenderOffset.X<0 or Linfo.ThitRenderOffset.Y<0) then
							local pGrid = Isaac_Tower.editor.GridTypes.Special[Linfo.type]
							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local x,y = math.ceil(Linfo.XY.X-(size.X-SpecialConstMem.OldSize.X)), math.ceil(Linfo.XY.Y-(size.Y-SpecialConstMem.OldSize.Y))
							--if not list[y] then
							--	list[y] = {}
							--end
							--if not list[y][x] then
							--	list[y][x] = {}
							--end
							--list[y][x].sprite = pGrid.trueSpr
							local Gtype = Linfo.type
							SafePlacingTable(list,y,x)
							list[y][x] = TabDeepCopy(Linfo)
							list[y][x].info = pGrid.info
							list[y][x].type = Gtype --Isaac_Tower.editor.SelectedGridType
							list[y][x].XY = Vector(x,y)
							list[y][x].pos = Vector(x*26/2, y*26/2)
							list[y][x].Size = size*1
							list[y][x].ThitRenderOffset = nil

							local index = tostring(x) .. "." .. tostring(y)   --(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + x
							local info = function() return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] end
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = {spr = pGrid.trueSpr, pos = Vector(x*26/2, y*26/2), info = info}
							
							--------------------
							local xs,ys = math.ceil(x+(size.X-SpecialConstMem.OldSize.X)), math.ceil(y+(size.Y-SpecialConstMem.OldSize.Y))
							local grid = list[ys][xs]
							if grid.Parent then
								local par = list[grid.Parent.Y][grid.Parent.X]
								if Isaac_Tower.editor.GridTypes.Special[par.type] and Isaac_Tower.editor.GridTypes.Special[par.type].size then
									for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Special[par.type].size)) do
										list[k[1]][k[2]] = nil
									end
								end
							end
							list[ys][xs] = nil
							local index = tostring(xs) .. "." .. tostring(ys)   --(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + x
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = nil

							------------------
							for i,k in pairs(GetLinkedGrid(list, Vector(x,y), size, true)) do
								if k[1] ~= y or k[2] ~= x then
									--if not list[k[1]] then
									--	list[k[1]] = {}
									--end
									--if not list[k[1]][k[2]] then
									--	list[k[1]][k[2]] = {}
									--end
									SafePlacingTable(list,k[1],k[2])
									list[k[1]][k[2]].Parent = Vector(x,y)
								end
							end
							Isaac_Tower.editor.MakeVersion()
						elseif hernya[SpecialConstMem.GragDir] and SpecialConstMem.OldSize and (SpecialConstMem.OldSize.X>size.X or SpecialConstMem.OldSize.Y>size.Y) then
							local pGrid = Isaac_Tower.editor.GridTypes.Special[Linfo.type]
							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local Gtype = Linfo.type

							--------------------
							local xs,ys = math.ceil(Linfo.XY.X), math.ceil(Linfo.XY.Y)
							local grid = list[ys][xs]
							if grid.Parent then
								local par = list[grid.Parent.Y][grid.Parent.X]
								if Isaac_Tower.editor.GridTypes.Special[par.type] and Isaac_Tower.editor.GridTypes.Special[par.type].size then
									for i,k in pairs(GetLinkedGrid(list, grid.Parent, Isaac_Tower.editor.GridTypes.Special[par.type].size)) do
										list[k[1] ][k[2] ] = nil
									end
								end
							end
							list[ys][xs] = nil
							local index = tostring(xs) .. "." .. tostring(ys)   --(y-1)*Isaac_Tower.editor.Memory.CurrentRoom.Size.Y + x
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = nil

							------------------
							
							local x,y = math.ceil(Linfo.XY.X-(size.X-SpecialConstMem.OldSize.X)), math.ceil(Linfo.XY.Y-(size.Y-SpecialConstMem.OldSize.Y))
							if not list[y] then
								list[y] = {}
							end
							--if not list[y][x] then
								list[y][x] = {}
							--end
							--list[y][x].sprite = pGrid.trueSpr
							
							list[y][x] = TabDeepCopy(Linfo)
							list[y][x].info = pGrid.info
							list[y][x].type = Gtype --Isaac_Tower.editor.SelectedGridType
							list[y][x].XY = Vector(x,y)
							list[y][x].pos = Vector(x*26/2, y*26/2)
							list[y][x].Size = size*1
							list[y][x].ThitRenderOffset = nil

							local index = tostring(x) .. "." .. tostring(y)
							local info = function() return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] end
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
							Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = {spr = pGrid.trueSpr, pos = Vector(x*26/2, y*26/2), info = info}
							for i,k in pairs(GetLinkedGrid(list, Vector(x,y), size, true)) do
								if k[1] ~= y or k[2] ~= x then
									if not list[k[1] ] then
										list[k[1] ] = {}
									end
									--if not list[k[1] ][k[2] ] then
										list[k[1] ][k[2] ] = {}
									--end
									list[k[1] ][k[2] ].Parent = Vector(x,y)
								end
							end
							Isaac_Tower.editor.MakeVersion()
						elseif SpecialConstMem.OldSize and Linfo.ThitRenderOffset and (SpecialConstMem.GragDir==2 or SpecialConstMem.GragDir==3) then ------------------
							local pGrid = Isaac_Tower.editor.GridTypes.Special[Linfo.type]
							local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Linfo.type]
							local Gtype = Linfo.type

							local xs,ys = math.ceil(Linfo.XY.X), math.ceil(Linfo.XY.Y)
							for i,k in pairs(GetLinkedGrid(list, Linfo.XY, SpecialConstMem.OldSize)) do
								if k[1] ~= ys or k[2] ~= xs then
									list[k[1] ][k[2] ] = nil
								end
							end

							for i,k in pairs(GetLinkedGrid(list, Linfo.XY, Linfo.Size, true)) do
								if k[1] ~= ys or k[2] ~= xs then
									--if not list[k[1] ] then
									--	list[k[1] ] = {}
									--end
									SafePlacingTable(list,k[1],k[2])
									list[k[1] ][k[2] ] = {Parent = Vector(xs,ys)}
								end
							end
							Isaac_Tower.editor.MakeVersion()
						end
						SpecialConstMem.OldSize = nil
						SpecialConstMem.GragDir = nil
						
					end
				end
			end
		end
		if Isaac_Tower.editor.SpecialSelectedTile == Linfo 
		and not Isaac_Tower.game:IsPaused() and Isaac_Tower.editor.SelectedMenu == "grid" then
			if not Isaac_Tower.editor.GetButton("grid", "_special_edit_button", true) then
				local spr = UIs.Edit_Button()
				spr.Scale = Vector(0.5,0.5) --*Gridscale
				local repos = Linfo.pos*Gridscale + Isaac_Tower.editor.GridStartPos + Vector(-10,-10)
				local hasBlocked = false
				local self
				self = Isaac_Tower.editor.AddButton("grid", "_special_edit_button", repos, 8,8, spr, function(button)
					if button ~= 0 then return end
					Isaac_Tower.editor.OpenSpecialEditMenu(Linfo.type, Linfo)
				end, function(pos)
					if not Isaac_Tower.editor.SpecialSelectedTile or not info or not info.info() or Isaac_Tower.editor.SpecialSelectedTile ~= info.info() or info.info().Parent then
						Isaac_Tower.editor.RemoveButton("grid", "_special_edit_button")
					else
						self.pos = (info.info().pos or Vector(0,0))*Gridscale + Isaac_Tower.editor.GridStartPos + Vector(-10,-10)
					end
					if spr:GetFrame() == 1 and not hasBlocked then
						hasBlocked = not Isaac_Tower.editor.BlockPlaceGrid
						Isaac_Tower.editor.BlockPlaceGrid = true
					elseif spr:GetFrame() == 0 and  hasBlocked then 
						Isaac_Tower.editor.BlockPlaceGrid = nil
						hasBlocked = nil
					end
				end, nil, 10)
			end
		end
	end
	if Linfo and Linfo.type == "Room_Transition" then
		Linfo.Size = Linfo.Size or Vector(1,1)
		local oldScale = Room_Transition_Spr.Scale*1
		Room_Transition_Spr.Scale = Vector(0.5,0.5) * Gridscale * Vector(math.max(1,Linfo.Size.X*(1-2/28)), math.max(1,Linfo.Size.Y*(1-2/28)))
		Room_Transition_Spr:Render(renderPos+(Linfo.ThitRenderOffset or Vector(0,0))+Room_Transition_Spr.Scale)
		Room_Transition_Spr.Scale = oldScale
	end
end)

mod:AddCallback(Isaac_Tower.Callbacks.PRE_EDITOR_CONVERTING_EDITOR_ROOM, function()
	Isaac_Tower.editor.Memory.CurrentRoom.DefSpawnPoint = Vector(-20, 150)
	for Gtype,tab in pairs(Isaac_Tower.editor.Memory.CurrentRoom.Special) do
		for i,y in pairs(tab) do
			for j,x in pairs(y) do
				local info = x and x.info
				if info and info.IsDefSpawnPoint then
					local pos = Vector(-40,100) + Vector(j*40-20,i*40-20)
					Isaac_Tower.editor.Memory.CurrentRoom.DefSpawnPoint = pos
				end
			end
		end
	end
end)

function Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,data)
	local pGrid = Isaac_Tower.editor.GridTypes.Special[Gtype]
	Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] or {}
	local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]

	SafePlacingTable(list,y,x)
	
	local size = data.Size

	list[y][x] = TabDeepCopy(data)
	local grid = list[y][x]
	grid.info = pGrid.info
	grid.type = Gtype --Isaac_Tower.editor.SelectedGridType
	grid.XY = Vector(x,y)
	grid.pos = Vector((x-1)*26/2, (y-1)*26/2)
	--grid.Size = size*1
	grid.ThitRenderOffset = nil
	
	local index = tostring(x) .. "." .. tostring(y)
	local info = function() --if not Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] then error("",2)  end
		--if not Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y] then return end -- error(Gtype.." "..x.." "..y,2)  end
		return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] end
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
	Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = {spr = pGrid.trueSpr, pos = Vector((x-1)*26/2, (y-1)*26/2), info = info}
	
	if size then
		grid.Size = size*1
		for i,k in pairs(GetLinkedGrid(list, Vector(x,y), size, true)) do
			if k[1] ~= y or k[2] ~= x then
				SafePlacingTable(list,k[1],k[2])
				list[k[1] ][k[2] ].Parent = Vector(x,y)
			end
		end
	end
end

--Isaac_Tower.Callbacks.EDITOR_CONVERTING_CURRENT_ROOM_TO_EDITOR, Isaac_Tower.editor.Memory, Isaac_Tower.GridLists
mod:AddCallback(Isaac_Tower.Callbacks.EDITOR_CONVERTING_CURRENT_ROOM_TO_EDITOR, function(_,Memory, roomdata) --GridLists)

	--if GridLists.Special then
	--	if GridLists.Special["Room_Transition"] then
	if roomdata.Special then
		if roomdata.Special["Room_Transition"] then
			--for idx, grid in pairs(GridLists.Special["Room_Transition"]) do
			for idx, grid in ipairs(roomdata.Special["Room_Transition"]) do
				--if not grid.Parent then
					--[[local Gtype = "Room_Transition"
					local pGrid = Isaac_Tower.editor.GridTypes.Special[Gtype]
					Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] or {}
					local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
					

					------------------
					local size = grid.Size
					local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
					--if not list[y] then
					--	list[y] = {}
					--end
					--list[y][x] = {}
					SafePlacingTable(list,y,x)
					
					list[y][x] = TabDeepCopy(grid)
					list[y][x].info = pGrid.info
					list[y][x].type = Gtype --Isaac_Tower.editor.SelectedGridType
					list[y][x].XY = Vector(x,y)
					list[y][x].pos = Vector((x-1)*26/2, (y-1)*26/2)
					list[y][x].Size = size*1
					list[y][x].ThitRenderOffset = nil
					list[y][x].EditData = {Test = {Text = grid.Name},
						Test2 = {Text = grid.TargetRoom},
						Test3 = {Text = grid.TargetName}, }
						
					local index = tostring(x) .. "." .. tostring(y)
					local info = function() --if not Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype] then error("",2)  end
						--if not Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y] then return end -- error(Gtype.." "..x.." "..y,2)  end
						return Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype][y][x] end
					Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] = Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype] or {}
					Isaac_Tower.editor.Memory.CurrentRoom.SpecialSpriteTab[Gtype][index] = {spr = pGrid.trueSpr, pos = Vector((x-1)*26/2, (y-1)*26/2), info = info}
					for i,k in pairs(GetLinkedGrid(list, Vector(x,y), size, true)) do
						if k[1] ~= y or k[2] ~= x then
							--if not list[k[1] ] then
							--	list[k[1] ] = {}
							--end
							--if not list[k[1] ][k[2] ] then
							--	list[k[1] ][k[2] ] = {}
							--end
							SafePlacingTable(list,k[1],k[2])
							list[k[1] ][k[2] ].Parent = Vector(x,y)
						end
					end]]

					local Gtype = "Room_Transition"
					local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
					Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
					local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
					list[y][x].EditData = {Test = {Text = grid.Name},
						Test2 = {Text = grid.TargetRoom},
						Test3 = {Text = grid.TargetName}, }

				--end
			end
		end
		if roomdata.Special["spawnpoint"] then
			for idx, grid in pairs(roomdata.Special["spawnpoint"]) do
				local Gtype = "spawnpoint"
				local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
				Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
				local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
				list[y][x].EditData = {
						Name = {Text = grid.Name}
					}
			end

		end
	end
end)

--[[local toRender = nil
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	toRender = nil
	for i,k in pairs(Keyboard) do
		if Input.IsButtonPressed(k,0) then
			toRender = i
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if toRender and type(toRender) == "string" then
		font:DrawStringUTF8(toRender, 150,150, KColor(1,1,1,1), 0, false)
	end
end)]]

end