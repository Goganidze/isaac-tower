return function(mod) --, Isaac_Tower)

local Isaac = Isaac
local Vector = Vector
local Isaac_Tower = Isaac_Tower
local Wtr = 20/13

local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')

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

local function sign(num)
	return num < 0 and -1 or 1
end
local function sign0(num)
	if type(num) ~= "number" then error("[1] is not a number",2) end
	return num < 0 and -1 or num == 0 and 0 or 1
end

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

local sizecache = {}
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

local sprites = {}
local function GenSprite(gfx,anim, scale, frame, offset)
  if gfx and anim then
	--if not sprites[anim] then
		local spr --= sprites[anim]
		spr = Sprite()
		spr:Load(gfx, true)
		spr:Play(anim)
		if scale then
			spr.Scale = scale
		end
		if frame then
			spr:SetFrame(frame)
		end
		if offset then
			spr.Offset = offset
		end
		return spr
	--else
	--	return sprites[anim]
	--end
  end
end

local function GetStr(str)
	if Isaac_Tower.editor.strings[str] then
		return Isaac_Tower.editor.strings[str][Options.Language] or Isaac_Tower.editor.strings[str].en
	end
end

local function SetState(data, state)
	data.PreviousState = data.State
	data.State = state
	data.StateFrame = 0
end

local function SpawnAfterImage(spr, pos, col, AlphaLos, isAttack)
	local off = Isaac.Spawn(1000, IsaacTower_GibVariant, Isaac_Tower.ENT.GibSubType.AFTERIMAGE, pos, Vector(0,0), nil)
	local espr, data = off:GetSprite(), off:GetData()
	espr:Load(spr:GetFilename(), true)
	espr:Play(spr:GetAnimation(), true)
	espr:SetFrame(spr:GetFrame())
	data.color = col or Color(1,1,1,1)
	espr.Color = data.color
	espr.FlipX = spr.FlipX
	espr.Rotation = spr.Rotation
	data.AlphaLoss = AlphaLos or 0.05
	data.Increase = isAttack
	return off
end




for i=1,9 do
	Isaac_Tower.editor.AddGrid(tostring(i), tostring(i), GenSprite("gfx/fakegrid/grid2.anm2",tostring(i)), {Collision = 1, SpriteAnim = tostring(i) })
end
--for i=1,9 do
--	local name = "black"..i
--	Isaac_Tower.editor.AddGrid(name, name, GenSprite("gfx/fakegrid/grid2.anm2",name), {Collision = 1, SpriteAnim = name })
--end

Isaac_Tower.editor.AddGrid("infis", "infis", GenSprite("gfx/fakegrid/grid2.anm2","infis",nil,1), {Collision = 1, SpriteAnim = "infis" })

local function GetSlopeAngle(dist, vec)
	local ang = Vector(dist, vec.X-vec.Y):GetAngleDegrees()
	return ang
end

TSJDNHC_PT.AddGridType("45r", function(self, gridList)
	self.SpriteAnim = "45r"
	self.slope = Vector(0,self.Half.Y*2)

	--local vec = Vector(self.Half.X*2, self.slope.X-self.slope.Y)
	self.MovingMulti = GetSlopeAngle(self.Half.X*2, self.slope) --vec:GetAngleDegrees()/90

	self.rot = self.slope.X<self.slope.Y and 1 or 1
end)
Isaac_Tower.editor.AddGrid("45r", "45r", GenSprite("gfx/fakegrid/grid2.anm2","45r"), {Collision = 1, Type = "45r" })

TSJDNHC_PT.AddGridType("45l", function(self, gridList)
	self.SpriteAnim = "45l"
	self.slope = Vector(self.Half.Y*2,0)

	--local vec = Vector(self.Half.X*2, self.slope.X-self.slope.Y)
	self.MovingMulti = GetSlopeAngle(self.Half.X*2, self.slope) --vec:GetAngleDegrees()/90

	self.rot = self.slope.X<self.slope.Y and 1 or 1
end)
Isaac_Tower.editor.AddGrid("45l", "45l", GenSprite("gfx/fakegrid/grid2.anm2","45l"), {Collision = 1, Type = "45l" })

TSJDNHC_PT.AddGridType("30r", function(self, gridList)
	self.SpriteAnim = "30r"
	self.slope = Vector(0,self.Half.Y*2)
	self.rot = self.slope.X<self.slope.Y and 1 or 1
	gridList:MakeMegaGrid(self.Index, 2, 1)

	--local vec = Vector(self.Half.X*2, self.slope.X-self.slope.Y)
	self.MovingMulti = GetSlopeAngle(self.Half.X*2, self.slope) --vec:GetAngleDegrees()/90
end)
Isaac_Tower.editor.AddGrid("30r", "30r", GenSprite("gfx/fakegrid/grid2.anm2","30r", Vector(0.5,0.5)), {Collision = 1, Type = "30r" }, GenSprite("gfx/fakegrid/grid2.anm2","30r"), Vector(2,1))

TSJDNHC_PT.AddGridType("30l", function(self, gridList)
	self.SpriteAnim = "30l"
	self.slope = Vector(self.Half.Y*2,0)
	self.rot = self.slope.X<self.slope.Y and 1 or 1
	gridList:MakeMegaGrid(self.Index, 2, 1)

	--local vec = Vector(self.Half.X*2, self.slope.X-self.slope.Y)
	self.MovingMulti = GetSlopeAngle(self.Half.X*2, self.slope) --vec:GetAngleDegrees()/90
end)
Isaac_Tower.editor.AddGrid("30l", "30l", GenSprite("gfx/fakegrid/grid2.anm2","30l", Vector(0.5,0.5)), {Collision = 1, Type = "30l" }, GenSprite("gfx/fakegrid/grid2.anm2","30l"), Vector(2,1))

TSJDNHC_PT.AddGridType("half_up", function(self, gridList)
	self.SpriteAnim = "half_up"
	self.CenterPos = Vector(self.CenterPos.X,self.CenterPos.Y-self.Half.Y/2)
	self.Half.Y = self.Half.Y/2
end)
Isaac_Tower.editor.AddGrid("half_up", "half_up", GenSprite("gfx/fakegrid/grid2.anm2", "half_up"), {Collision = 1, Type = "half_up" })

TSJDNHC_PT.AddGridType("1_2x2", function(self, gridList)
	self.SpriteAnim = "1_2x2"
	gridList:MakeMegaGrid(self.Index, 2, 2)
end)
Isaac_Tower.editor.AddGrid("1_2x2", "1_2x2", GenSprite("gfx/fakegrid/grid2.anm2","1_2x2", Vector(0.5,0.5)), {Collision = 1, Type = "1_2x2" }, GenSprite("gfx/fakegrid/grid2.anm2","1_2x2"), Vector(2,2))

TSJDNHC_PT.AddGridType("1_3x3", function(self, gridList)
	self.SpriteAnim = "1_3x3"
	gridList:MakeMegaGrid(self.Index, 3, 3)
end)
Isaac_Tower.editor.AddGrid("1_3x3", "1_3x3", GenSprite("gfx/fakegrid/grid2.anm2","1_3x3", Vector(0.33,0.33)), {Collision = 1, Type = "1_3x3" }, GenSprite("gfx/fakegrid/grid2.anm2","1_3x3"), Vector(3,3))

TSJDNHC_PT.AddGridType("3_3x1", function(self, gridList)
	self.SpriteAnim = "3_3x1"
	gridList:MakeMegaGrid(self.Index, 3, 1)
end)
Isaac_Tower.editor.AddGrid("3_3x1", "3_3x1", GenSprite("gfx/fakegrid/grid2.anm2","3_3x1", Vector(0.33,0.33)), {Collision = 1, Type = "3_3x1" }, GenSprite("gfx/fakegrid/grid2.anm2","3_3x1"), Vector(3,1))

TSJDNHC_PT.AddGridType("1_5x5", function(self, gridList)
	self.SpriteAnim = "1_5x5"
	gridList:MakeMegaGrid(self.Index, 5, 5)
end)
Isaac_Tower.editor.AddGrid("1_5x5", "1_5x5", GenSprite("gfx/fakegrid/grid2.anm2","1_5x5", Vector(0.31,0.31),nil,Vector(-7,-7)), {Collision = 1, Type = "1_5x5" }, GenSprite("gfx/fakegrid/grid2.anm2","1_5x5"), Vector(5,5))

TSJDNHC_PT.AddGridType("platform", function(self, gridList)
	--self.SpriteAnim = ""
	self.OnlyUp = true
end)
Isaac_Tower.editor.AddGrid("platform", "platform", GenSprite("gfx/fakegrid/grid2.anm2","platform"), 
	{Collision = 1, Type = "platform", SpriteAnim = "platform" }, GenSprite("gfx/fakegrid/grid2.anm2","platform"))
Isaac_Tower.editor.AddGrid("platform1", "platform1", GenSprite("gfx/fakegrid/grid2.anm2","platform1"), 
	{Collision = 1, Type = "platform", SpriteAnim = "platform1" }, GenSprite("gfx/fakegrid/grid2.anm2","platform1"))
Isaac_Tower.editor.AddGrid("platform2", "platform2", GenSprite("gfx/fakegrid/grid2.anm2","platform2"), 
	{Collision = 1, Type = "platform", SpriteAnim = "platform2" }, GenSprite("gfx/fakegrid/grid2.anm2","platform2"))
Isaac_Tower.editor.AddGrid("platform3", "platform3", GenSprite("gfx/fakegrid/grid2.anm2","platform3"), 
	{Collision = 1, Type = "platform", SpriteAnim = "platform3" }, GenSprite("gfx/fakegrid/grid2.anm2","platform3"))


---------------------------------------------Типы комнат------------------------------------------------------------

do
	Isaac_Tower.editor.RoomTypes = Isaac_Tower.editor.RoomTypes or {}
	Isaac_Tower.editor.RoomTypes.basic = "basic"
	Isaac_Tower.editor.RoomTypes.secretroom = "secretroom"

	Isaac_Tower.sprites.roomtypes["basic"] = GenSprite("gfx/editor/roomtypes.anm2","basic")
	Isaac_Tower.sprites.roomtypes["secretroom"] = GenSprite("gfx/editor/roomtypes.anm2","secretroom")
end

---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================



Isaac_Tower.TileData.AddTileSet("tutorial", {
	Anm2 ='gfx/fakegrid/grid2.anm2',
	Gfx = 'gfx/fakegrid/tutorial.png',
	EditorImage = "gfx/editor/tileset_basement.png",
	EditorAnm2 = "gfx/fakegrid/grid2.anm2",
	EditorGridTypesList = {'8','9','1_3x3','45l','half_up','30l','1_5x5','3_3x1','platform1','1_2x2','30r','platform3','infis','platform2','platform','7','1','2','3','4','5','6','45r',},
})
Isaac_Tower.TileData.AddTileSet("cellar", {
	Anm2 = 'gfx/fakegrid/grid2cellar.anm2',
	Gfx = 'gfx/fakegrid/cellar.png',
	MainMapGridSuffix = "map_",
	Size = Vector(3,3),
	ExtraAnimSuffix = {"1_3x3"},
	EditorImage = "gfx/editor/tileset_cellar.png",
	EditorAnm2 = "gfx/fakegrid/grid2cellar_editor.anm2",
	EditorGridTypesList = {'30l','half_up','45l','1_3x3','3','4','5','6','platform3','1','45r','7','8','9','30r','platform','3_3x1','platform2','platform1','2','infis',},
})
for i,k in pairs({"g2a","g3a","g2b","g1a","1a","1b","5a","6a"}) do
	Isaac_Tower.editor.AddGrid(k, k, GenSprite("gfx/fakegrid/grid2secret.anm2",k), {Collision = 1, SpriteAnim = k })
end
Isaac_Tower.TileData.AddTileSet("secret", {
	Anm2 ='gfx/fakegrid/grid2secret.anm2',
	Gfx = 'gfx/fakegrid/secret.png',
	EditorImage = "gfx/editor/tileset_secret.png",
	EditorAnm2 = "gfx/fakegrid/grid2secret.anm2",
	EditorGridTypesList = {'8','9','1_3x3','45l','half_up','30l','1_5x5','3_3x1','platform1','1_2x2','30r','platform3','infis','platform2','platform','7','1','2','3','4','5','6','45r',"g2b","g3a","g1a"},
	EditorHidedList = {'g2a',"1a","1b","5a","6a"},
	Replaces = {["1"] = {"1a","1b"}, ["g2b"] = {"g2a"},["5"] = {"5a"},["6"] = {"6a"}}
})


---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================

local function poopObsLogic(ent, grid)
	local fent = ent:GetData().Isaac_Tower_Data or ent:GetData().Isaac_Tower_Data
	if fent and fent.CanBreakPoop then
		local gridType = grid.EditorType
		if fent.AttackAngle then
			local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			local GJG = math.floor(((fent.AttackAngle%360-TarAngle%360))-180)%360
			if math.abs(GJG-180) <= 45 then
				grid.HitAngle = TarAngle
				grid.HitPower = math.abs(fent.Velocity:Length())
				if not ent:ToPlayer() then
					grid.HitPower = grid.HitPower / 4
				end

				grid.GridList:DestroyGrid(grid.XY)
				--grid.EditorType = gridType
				return true
			end
		else
			local fentPos = fent.Position
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			grid.HitAngle = TarAngle
			grid.HitPower = math.abs(fent.Velocity:Length())
			if not ent:ToPlayer() then
				grid.HitPower = grid.HitPower / 4
			end
			
			grid.GridList:DestroyGrid(grid.XY)
			--grid.EditorType = gridType
			return true
		end
	end
end

local function stonePoopObsLogic(ent, grid)
	---@type Flayer
	local fent = ent:GetData().Isaac_Tower_Data or ent:GetData().Isaac_Tower_Data
	if fent and fent.CanBreakMetal then
		local gridType = grid.EditorType
		if grid.IngoreDown and ent.Position.Y>(grid.CenterPos.Y+grid.Half.Y+40) then return false end
		if fent.AttackAngle then
			--[[local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			local GJG = math.floor(((fent.AttackAngle%360-TarAngle%360))-180)%360
			if math.abs(GJG-180) <= 40 then --40
				grid.HitAngle = TarAngle
				grid.HitPower = math.abs(fent.Velocity:Length())
				if not ent:ToPlayer() then
					grid.HitPower = grid.HitPower / 4
				end

				grid.GridList:DestroyGrid(grid.XY)
				---grid.EditorType = gridType
				return true
			end]]
			local ang = math.ceil(fent.AttackAngle/90)*90
			local fentPos = fent.Position + Vector(10 or fent.Velocity:Length(),0):Rotated(fent.AttackAngle)
			local box1,box2 = {fentPos, fent.Half}, {grid.CenterPos, grid.Half}
			local hit = Isaac_Tower.NoType_intersectAABB(box1,box2)

			if hit then

				local result =  ang == 0 and hit.normal.X == 1
					or ang == 180 and hit.normal.X == -1
					or ang == 90 and hit.normal.Y == 1
					or ang == 270 and hit.normal.Y == -1
				
				if result then
					local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
					local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
					grid.HitAngle = TarAngle
					grid.HitPower = math.abs(fent.Velocity:Length())
					if not ent:ToPlayer() then
						grid.HitPower = grid.HitPower / 4
					end

					fent.OnGround = true
					grid.GridList:DestroyGrid(grid.XY)
					---grid.EditorType = gridType
					return true
				else
					fent.Position = hit.pos
				end
			end
		else
			local fentPos = fent.Position
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			grid.HitAngle = TarAngle
			grid.HitPower = math.abs(fent.Velocity:Length())
			if not ent:ToPlayer() then
				grid.HitPower = grid.HitPower / 4
			end
			
			grid.GridList:DestroyGrid(grid.XY)
			--grid.EditorType = gridType
			return true
		end
	end
end

local poopColor = Color(1,1,1,1)
poopColor:SetColorize(0.8,0.5,0.5,1,0.6,0.4,0.4)

----------------------------------------------------------------
TSJDNHC_PT.AddGridType("poop_2x2", function(self, gridList)
	--self.Sprite = GenSprite("gfx/fakegrid/poop.anm2","2x2")
	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","poop2x2")
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.OnCollisionFunc = poopObsLogic
	self.CanBeDestroyedWhenWallClambing = true
	gridList:MakeMegaGrid(self.Index, 2, 2)
end,
nil,
function(self, gridList)
	local poof = Isaac.Spawn(1000,16,4,self.CenterPos,Vector.FromAngle(self.HitAngle or 0),nil)
	poof.Color = poopColor 
	poof:GetSprite().Scale = Vector(0.5,0.5)
	
	local rng = RNG()
	rng:SetSeed(poof.InitSeed,35)

	for i=1,6 do
		--rng:RandomInt()
		local vec = Vector.FromAngle(self.HitAngle+rng:RandomInt(91)-45 or 0):Resized(self.HitPower*(rng:RandomInt(15)+11)/10) --math.random(15,25)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		grid:GetSprite():Load("gfx/fakegrid/grid2.anm2",true)
		grid:GetSprite():Play("poopGib" .. (rng:RandomInt(2)+1), true)
		grid:ToEffect().Rotation = rng:RandomInt(101)-50 --math.random(-50,50)
		grid.SpriteRotation = rng:RandomInt(360)+1 --math.random(1,360)
	end
end)
Isaac_Tower.editor.AddObstacle("poop_2x2", "poop2x2", 
	GenSprite("gfx/fakegrid/grid2.anm2","poop2x2", Vector(1,1)), 
	{Collision = 1, Type = "poop_2x2" }, 
	GenSprite("gfx/fakegrid/grid2.anm2","poop2x2"), Vector(2,2))

----------------------------------------------------------------
TSJDNHC_PT.AddGridType("poop_1x1", function(self, gridList)
	--self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","1x1")
	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","poop1x1")
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.CanBeDestroyedWhenWallClambing = true
	self.OnCollisionFunc = poopObsLogic
end,
nil,
function(self, gridList)
	local poof = Isaac.Spawn(1000,16,4,self.CenterPos,Vector.FromAngle(self.HitAngle or 0),nil)
	poof.Color = poopColor 
	poof:GetSprite().Scale = Vector(0.25,0.25)
	
	local rng = RNG()
	rng:SetSeed(poof.InitSeed,35)

	for i=1,3 do
		--local vec = Vector.FromAngle(self.HitAngle+math.random(-45,45) or 0):Resized(self.HitPower*math.random(15,25)/10)
		--local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		--grid:GetSprite():Load("gfx/fakegrid/poop.anm2",true)
		--grid:GetSprite():Play("деталька" .. math.random(1,2), true)
		--grid:ToEffect().Rotation = math.random(-50,50)
		--grid.SpriteRotation = math.random(1,360)

		local vec = Vector.FromAngle(self.HitAngle+rng:RandomInt(91)-45 or 0):Resized(self.HitPower*(rng:RandomInt(15)+11)/10)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		grid:GetSprite():Load("gfx/fakegrid/grid2.anm2",true)
		grid:GetSprite():Play("poopGib" .. (rng:RandomInt(2)+1), true)
		grid:ToEffect().Rotation = rng:RandomInt(101)-50
		grid.SpriteRotation = rng:RandomInt(360)+1
	end
end)
Isaac_Tower.editor.AddObstacle("poop_1x1", "poop1x1", 
	GenSprite("gfx/fakegrid/grid2.anm2","poop1x1", Vector(1.5,1.5)), 
	{Collision = 1, Type = "poop_1x1" }, 
	GenSprite("gfx/fakegrid/grid2.anm2","poop1x1"))

----------------------------------------------------------------
local stone_poop_2x2Init = function(self, gridList)
	--self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","stone2x2")
	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","stone2x2")
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.OnCollisionFunc = stonePoopObsLogic
	gridList:MakeMegaGrid(self.Index, 2, 2)
end
local stone_poop_2x2Destroy = function(self, gridList)
	local poof = Isaac.Spawn(1000,16,4,self.CenterPos,Vector.FromAngle(self.HitAngle or 0),nil)
	poof.Color = poopColor 
	poof:GetSprite().Scale = Vector(0.5,0.5)
	
	local rng = RNG()
	rng:SetSeed(poof.InitSeed,35)

	for i=1,6 do
		--local vec = Vector.FromAngle(self.HitAngle+math.random(-45,45) or 0):Resized(self.HitPower*math.random(15,25)/10)
		--local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		--grid:GetSprite():Load("gfx/fakegrid/poop_stone.anm2",true)
		--grid:GetSprite():Play("деталька" .. math.random(1,2), true)
		--grid:ToEffect().Rotation = math.random(-50,50)
		--grid.SpriteRotation = math.random(1,360)

		local vec = Vector.FromAngle(self.HitAngle+rng:RandomInt(91)-45 or 0):Resized(self.HitPower*(rng:RandomInt(15)+11)/10)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		grid:GetSprite():Load("gfx/fakegrid/grid2.anm2",true)
		grid:GetSprite():Play("stoneGib" .. (rng:RandomInt(2)+1), true)
		grid:ToEffect().Rotation = rng:RandomInt(101)-50
		grid.SpriteRotation = rng:RandomInt(360)+1
	end
end
TSJDNHC_PT.AddGridType("stone_poop_2x2", stone_poop_2x2Init,nil,stone_poop_2x2Destroy)
Isaac_Tower.editor.AddObstacle("stone_poop_2x2", "2x2", 
	GenSprite("gfx/fakegrid/poop_stone.anm2","2x2", Vector(1,1)), 
	{Collision = 1, Type = "stone_poop_2x2" }, 
	GenSprite("gfx/fakegrid/poop_stone.anm2","2x2"), Vector(2,2))

TSJDNHC_PT.AddGridType("stone_poop_2x2_downW", function(self, gridList)
	stone_poop_2x2Init(self, gridList)
	self.IngoreDown = true
end,nil,stone_poop_2x2Destroy)
Isaac_Tower.editor.AddObstacle("stone_poop_2x2_downW", "2x2", 
	GenSprite("gfx/editor/special_tiles.anm2","stone_poop_низ", Vector(1,1)), 
	{Collision = 1, Type = "stone_poop_2x2_downW" }, 
	GenSprite("gfx/editor/special_tiles.anm2","stone_poop_низ"), Vector(2,2))

----------------------------------------------------------------
TSJDNHC_PT.AddGridType("stone_poop_1x1", function(self, gridList)
	--self.Sprite = GenSprite("gfx/fakegrid/poop_stone.anm2","1x1")
	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","stone1x1")
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.OnCollisionFunc = stonePoopObsLogic
end,
nil,
function(self, gridList)
	local poof = Isaac.Spawn(1000,16,4,self.CenterPos,Vector.FromAngle(self.HitAngle or 0),nil)
	poof.Color = poopColor 
	poof:GetSprite().Scale = Vector(0.25,0.25)
	
	local rng = RNG()
	rng:SetSeed(poof.InitSeed,35)

	for i=1,3 do
		local vec = Vector.FromAngle(self.HitAngle+rng:RandomInt(91)-45 or 0):Resized(self.HitPower*(rng:RandomInt(15)+11)/10)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		grid:GetSprite():Load("gfx/fakegrid/grid2.anm2",true)
		grid:GetSprite():Play("stoneGib" .. (rng:RandomInt(2)+1), true)
		grid:ToEffect().Rotation = rng:RandomInt(101)-50
		grid.SpriteRotation = rng:RandomInt(360)+1
	end
end)
Isaac_Tower.editor.AddObstacle("stone_poop_1x1", "stone1x1", 
	GenSprite("gfx/fakegrid/grid2.anm2","stone1x1", Vector(1.5,1.5)), 
	{Collision = 1, Type = "stone_poop_1x1" }, 
	GenSprite("gfx/fakegrid/grid2.anm2","stone1x1"))

--------------------------------------------------------------------

local function kick_breakable_ObsLogic(ent, grid)
	local fent = ent:GetData().Isaac_Tower_Data
	
	if fent and fent.State and fent.State == Isaac_Tower.EnemyHandlers.EnemyState.PUNCHED then
		local gridType = grid.EditorType
		
		local fentPos = fent.Position
		local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
		grid.HitAngle = TarAngle
		grid.HitPower = math.abs(fent.Velocity:Length())
		if ent:GetData().Isaac_Tower_Data then
			grid.HitPower = grid.HitPower / 7
		end
			
		grid.GridList:DestroyGrid(grid.XY)
		--grid.EditorType = gridType
		return true
	end
end

TSJDNHC_PT.AddGridType("kick_breakable", function(self, gridList)
	local rng = RNG()
	rng:SetSeed(self.Index+self.Position.X+self.Position.Y,35)

	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","kick_breakable" .. (rng:RandomInt(2)+1))
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.OnCollisionFunc = kick_breakable_ObsLogic
	gridList:MakeMegaGrid(self.Index, 2, 2)
end,
nil,
function(self, gridList)
	local poof = Isaac.Spawn(1000,16,4,self.CenterPos,Vector.FromAngle(self.HitAngle or 0),nil)
	poof.Color = poopColor 
	poof:GetSprite().Scale = Vector(0.25,0.25)
	
	local rng = RNG()
	rng:SetSeed(poof.InitSeed,35)

	for i=1,6 do
		local vec = Vector.FromAngle(self.HitAngle+rng:RandomInt(91)-45 or 0):Resized(self.HitPower*(rng:RandomInt(15)+11)/10)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.CenterPos,vec ,nil)
		grid:GetSprite():Load("gfx/fakegrid/grid2.anm2",true)
		grid:GetSprite():Play("kick_breakable_gib" .. (rng:RandomInt(3)+1), true)
		grid:ToEffect().Rotation = rng:RandomInt(101)-50
		grid.SpriteRotation = rng:RandomInt(360)+1
	end
end)
Isaac_Tower.editor.AddObstacle("kick_breakable", "kick_breakable1", 
	GenSprite("gfx/fakegrid/grid2.anm2","kick_breakable1"), 
	{Collision = 1, Type = "kick_breakable" }, 
	GenSprite("gfx/fakegrid/grid2.anm2","kick_breakable1"), Vector(2,2))



TSJDNHC_PT.AddGridType("runaway_switch_block", function(self, gridList)
	local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng
	local suffix = rng:RandomInt(5)==0 and "2" or "1"
	self.Sprite = GenSprite("gfx/fakegrid/switch.anm2","выкл_" .. suffix)
	self.extrasuffix = suffix
	gridList:MakeMegaGrid(self.Index, 2, 2)
end,
function(self, gridList)
	if not self.Updated and Isaac_Tower.LevelHandler.GetLevelData().IsRunAway then
		self.Updated = true
		self.Collision = 1
		self.Sprite:Play("вкл_" .. self.extrasuffix)
	end
end)
Isaac_Tower.editor.AddObstacle("runaway_switch_block", "выкл_1", 
	GenSprite("gfx/fakegrid/switch.anm2","выкл_1"), 
	{Collision = 0, Type = "runaway_switch_block" }, 
	GenSprite("gfx/fakegrid/switch.anm2","выкл_1"), Vector(2,2))

TSJDNHC_PT.AddGridType("runaway_switch_block_rev", function(self, gridList)
		local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng
		local suffix = rng:RandomInt(5)==0 and "2" or "1"
		self.Sprite = GenSprite("gfx/fakegrid/switch.anm2","вкл_" .. suffix)
		self.extrasuffix = suffix
		gridList:MakeMegaGrid(self.Index, 2, 2)
	end,
	function(self, gridList)
		if not self.Updated and Isaac_Tower.LevelHandler.GetLevelData()
		and Isaac_Tower.LevelHandler.GetLevelData().IsRunAway then
			self.Updated = true
			self.Collision = 0
			self.Sprite:Play("выкл_" .. self.extrasuffix)
		end
	end)
Isaac_Tower.editor.AddObstacle("runaway_switch_block_rev", "вкл_1", 
	GenSprite("gfx/fakegrid/switch.anm2","вкл_1"), 
	{Collision = 1, Type = "runaway_switch_block_rev" }, 
	GenSprite("gfx/fakegrid/switch.anm2","вкл_1"), Vector(2,2))

---@param grid Frid
local function SatanStatueCollision(ent, grid)
	local fent = ent:GetData().Isaac_Tower_Data or ent:GetData().Isaac_Tower_Data
	if fent and fent.CanBreakPoop then
		local fentPos = fent.Position
		grid.HitAngle = fentPos.X < grid.CenterPos.X
		grid.HitPower = math.abs(fent.Velocity:Length())
		if not ent:ToPlayer() then
			grid.HitPower = grid.HitPower / 4
		end
			
		grid.GridList:DestroyGrid(grid.XY)
		grid.Collision = 0
		return true
	end
end

TSJDNHC_PT.AddGridType("satan_statue", 
	function(self, gridList)
		self.Sprite = GenSprite("gfx/fakegrid/satan statue.anm2","idle")
		gridList:MakeMegaGrid(self.Index, 4, 8)
		self.OnCollisionFunc = SatanStatueCollision
	end,
	function(self, gridList)
		local scared = false
		for i=1, Isaac_Tower.game:GetNumPlayers() do
			local fent = Isaac_Tower.GetFlayer(i)
			if fent.Position:Distance(self.CenterPos) < 400 and fent.OnAttack then
				self.Sprite:Play("scared")
				scared = true
			end
		end
		if not scared then
			self.Sprite:Play("idle")
		end
	end,
	function(self, gridList)
		Isaac_Tower.LevelHandler.GetLevelData().IsRunAway = true
		self.Collision = 0
		local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng
	
		for i=1,6 do
			local vec = Vector.FromAngle(rng:RandomInt(360) or 0):Resized((rng:RandomInt(15)+11)/10)
			if self.HitAngle then
				vec = vec + Vector(-self.HitPower,-3)
			else
				vec = vec + Vector(self.HitPower,-3)
			end
			local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,Isaac_Tower.ENT.GibSubType.SWEET, self.CenterPos+Vector(0,-15), vec ,nil)
		end

		local vec = self.HitAngle and Vector(self.HitPower*2,-4) or Vector(-self.HitPower*2,-4)
		local grid = Isaac.Spawn(1000,IsaacTower_GibVariant,0,self.Position,vec ,nil)
		grid:GetSprite():Load(self.Sprite:GetFilename(),true)
		grid:GetSprite():Play(self.Sprite:GetAnimation(), true)
	end)
Isaac_Tower.editor.AddObstacle("satan_statue", "idle", 
	GenSprite("gfx/fakegrid/satan statue.anm2","idle", Vector(0.5,.5),nil, Vector(0,-13)), 
	{Collision = 1, Type = "satan_statue" }, 
	GenSprite("gfx/fakegrid/satan statue.anm2","idle"), Vector(4,8))


---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================
---==================================================================================================================================

Isaac_Tower.editor.AddSpecial("spawnpoint_def", nil, 
	GenSprite("gfx/editor/special_tiles.anm2","checkpoint_def"),
	{IsDefSpawnPoint = true},
	GenSprite("gfx/editor/special_tiles.anm2","checkpoint_def"))

Isaac_Tower.editor.AddSpecial("spawnpoint", nil, 
	GenSprite("gfx/editor/special_tiles.anm2","checkpoint"),
	{IsSpawnPoint = true, Name = ""},
	GenSprite("gfx/editor/special_tiles.anm2","checkpoint"))

Isaac_Tower.editor.AddSpecialEditData("spawnpoint", "Name", 1, {HintText = GetStr("spawnpoint_name"), ResultCheck = function(info, result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			info.Name = result
			return true
		end
	end})


local nilSpr = GenSprite("gfx/editor/special_tiles.anm2","room_transition")
nilSpr.Color = Color(1,1,1,0)
Isaac_Tower.editor.AddSpecial("Room_Transition", nil, 
	GenSprite("gfx/editor/special_tiles.anm2","room_transition"),
	{TargetRoom = -1, Name = "", Size = Vector(1,1)},
	nilSpr) --GenSprite("gfx/editor/special_tiles.anm2","room_transition")

local function Room_Transition_Collision(_, player, grid)
	--for i,k in pairs(grid) do
	--	print(i,k)
	--end
	if grid.TargetRoom then
		local flayer = player:GetData().Isaac_Tower_Data
		if grid.FrameCount<2 then
			grid.PreFrameCount = grid.FrameCount
			if grid.Size.X>1 then
				if grid.XY.Y<=1 then
					grid.Rot = 0
				end
				if grid.XY.Y>1 then
					grid.Rot = 1
				end
			elseif grid.Size.Y>1 then
				if grid.XY.X<=1 then
					grid.Rot = 2
				end
				if grid.XY.X>1 then
					grid.Rot = 3
				end
			end
			--grid.Rot = flayer.Velocity:GetAngleDegrees()
		end
		
		if grid.PreFrameCount and (grid.PreFrameCount+1) >= grid.FrameCount then
			grid.PreFrameCount = grid.FrameCount

			--[[local ang = grid.Rot%360
			local GJG = math.floor((ang-flayer.Velocity:GetAngleDegrees())%360)-180
			print(GJG, grid.Rot, flayer.Velocity:GetAngleDegrees())
			if GJG>0 then
				local offset = grid.pos - player:GetData().Isaac_Tower_Data.Position
				Isaac_Tower.TransitionSpawnOffset = -offset
				Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
			end]]
		else
			local offset = grid.pos - player:GetData().Isaac_Tower_Data.Position
			Isaac_Tower.TransitionSpawnOffset = -offset
			Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, Room_Transition_Collision, "Room_Transition")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, Room_Transition_Collision, "Room_Transition")

--mod:AddCallback(Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, function(_, ent)
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, function(_, ent)
	local Fpos = ent:GetData().Isaac_Tower_Data.Position
	if Isaac_Tower.GridLists.Special.Room_Transition then
		for index, grid in pairs(Isaac_Tower.GridLists.Special.Room_Transition) do
			if not grid.Parent and grid.Rot then
				if grid.Rot == 0 then
					if Fpos.Y < 100 then
						local bord1, bord2 = grid.pos.X-20, grid.pos.X-20 + grid.Size.X*40
						if Fpos.X>bord1 and Fpos.X<bord2 then
							local offset = grid.pos - Fpos
							Isaac_Tower.TransitionSpawnOffset = -offset
							Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
							return true
						end
					end
				elseif grid.Rot == 1 then
					if Fpos.Y > 100 then
						local bord1, bord2 = grid.pos.X-20, grid.pos.X-20 + grid.Size.X*40
						if Fpos.X>bord1 and Fpos.X<bord2 then
							local offset = grid.pos - Fpos
							Isaac_Tower.TransitionSpawnOffset = -offset
							Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
							return true
						end
					end
				elseif grid.Rot == 2 then
					if Fpos.X < -21 then
						local bord1, bord2 = grid.pos.Y-20, grid.pos.Y-20 + grid.Size.Y*40
						if Fpos.Y>bord1 and Fpos.Y<bord2 then
							local offset = grid.pos - Fpos
							Isaac_Tower.TransitionSpawnOffset = -offset
							Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
							return true
						end
					end
				elseif grid.Rot == 3 then
					if Fpos.X > -21 then
						local bord1, bord2 = grid.pos.Y-20, grid.pos.Y-20 + grid.Size.Y*40
						if Fpos.Y>bord1 and Fpos.Y<bord2 then
							local offset = grid.pos - Fpos
							Isaac_Tower.TransitionSpawnOffset = -offset
							Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
							return true
						end
					end
				end
			end
		end
	end
end)

Isaac_Tower.editor.AddSpecialEditData("Room_Transition", "Test", 1, {HintText = GetStr("Transition Name"), ResultCheck = function(info, result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.Name = result
		return true
	end
end})
Isaac_Tower.editor.AddSpecialEditData("Room_Transition", "Test2", 2, {HintText = GetStr("Transition Target"), ResultCheck = function(info,result)
	if not result then
		return false
	else
		info.TargetRoom = result
		return true
	end
end, Generation = function(info)
	local tab = {}
	for rnam, romdat in pairs(Isaac_Tower.Rooms) do
		if rnam ~= Isaac_Tower.editor._EditorTestRoom then
			tab[#tab+1] = rnam
		end
	end
	return tab
end})
Isaac_Tower.editor.AddSpecialEditData("Room_Transition", "Test3", 1, {HintText = GetStr("Transition TargetPoint"), ResultCheck = function(info,result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.TargetName = result
		return true
	end
end})

local nilSpr = GenSprite("gfx/editor/special_tiles.anm2","trigger")
nilSpr.Color = Color(1,1,1,0)
Isaac_Tower.editor.AddSpecial("trigger", nil, 
	GenSprite("gfx/editor/special_tiles.anm2","trigger"),
	{TargetRoom = -1, Name = "", Size = Vector(1,1)},
	nilSpr,
	function(solidTab, grid)
		if grid.TargetName then
			solidTab = solidTab.."TargetName='"..grid.TargetName.."',"
		end
		if grid.Name then
			solidTab = solidTab.."Name='"..grid.Name.."',"
		end
		if grid.Mode then
			solidTab = solidTab.."Mode='"..grid.Mode.."',"
		end
		if grid.FSize then
			solidTab = solidTab.."FSize=Vector(".. math.ceil(grid.FSize.X) .. "," .. math.ceil(grid.FSize.Y) .. ")," 
		end
		return solidTab
	end,
	function(tab)
		for idx, grid in pairs(tab) do
			local Gtype = "trigger"
			local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
			--local size = grid.Size/1
			--grid.Size = nil
			Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
			local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
			list[y][x].EditData = {name = {Text = grid.Name},
				tarname = {Text = grid.TargetName},
				mode = {Text = grid.Mode}, }
			--list[y][x].Size = size
		end
	end)
	
Isaac_Tower.editor.AddSpecialEditData("trigger", "name", 1, {HintText = GetStr("special_obj_name"), ResultCheck = function(info, result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.Name = result
		return true
	end
end})
Isaac_Tower.editor.AddSpecialEditData("trigger", "tarname", 1, {HintText = GetStr("nameTarget"), ResultCheck = function(info, result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.TargetName = result
		return true
	end
end})
Isaac_Tower.editor.AddSpecialEditData("trigger", "mode", 2, {HintText = GetStr("collisionMode"), ResultCheck = function(info,result)
	if not result then
		return false
	else
		info.Mode = result
		return true
	end
end, Generation = function(info)
	local tab = {[GetStr("collisionMode1")]=0,[GetStr("collisionMode2")]=1}
	return tab
end, ParamInit = function(info)
	info.EditData.mode.Text = 0
	info.Mode = 0
end})

Isaac_Tower.editor.TriggerSignalFunc = {
	Room_Transition = function (grid, target)
		Isaac_Tower.RoomTransition(target.TargetRoom, false, nil, target.TargetName)
	end,
	spawnpoint = function (grid, target)
		Isaac_Tower.SpawnPoint = target.pos - Vector(7, 7)
	end,
	script = function (grid, target)
		Isaac_Tower.ScriptHandler.RunScript(target.TargetName)
	end,
}

local function Trigger_Collision(_, player, grid)
	local target = Isaac_Tower.GridLists.ObjByName and Isaac_Tower.GridLists.ObjByName[grid.TargetName]
	if target then
		if Isaac_Tower.editor.TriggerSignalFunc[target.Type] then
			Isaac_Tower.editor.TriggerSignalFunc[target.Type](grid, target)
		end
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, Trigger_Collision, "trigger")

-------------------------------------------------------------------------------------
Isaac_Tower.editor.AddSpecial("script", nil, 
	GenSprite("gfx/editor/special_tiles.anm2","script"),
	{Name = "", Size = Vector(1,1)},
	GenSprite("gfx/editor/special_tiles.anm2","script"),
	function(solidTab, grid)
		if grid.TargetName then
			solidTab = solidTab.."TargetName='"..grid.TargetName.."',"
		end
		if grid.Name then
			solidTab = solidTab.."Name='"..grid.Name.."',"
		end
		return solidTab
	end,
	function(tab)
		for idx, grid in pairs(tab) do
			local Gtype = "script"
			local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
			--local size = grid.Size/1
			--grid.Size = nil
			Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
			local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
			list[y][x].EditData = {name = {Text = grid.Name},
				tarname = {Text = grid.TargetName},}
			--list[y][x].Size = size
		end
	end)
	
Isaac_Tower.editor.AddSpecialEditData("script", "name", 1, {HintText = GetStr("special_obj_name"), ResultCheck = function(info, result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.Name = result
		return true
	end
end})
Isaac_Tower.editor.AddSpecialEditData("script", "tarname", 1, {HintText = GetStr("Scriptname"), ResultCheck = function(info, result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return GetStr("emptyField")
		end
		info.TargetName = result
		return true
	end
end})
-------------------------------------------------------------------------
local holeRotTab = {"0 %","90 %","180 %","270 %"}

local nilSpr = GenSprite("gfx/fakegrid/teleport_hole.anm2","blu",nil,nil,Vector(0,13))
nilSpr.Color = Color(1,1,1,0)
Isaac_Tower.editor.AddSpecial("teleport_hole", nil, 
	GenSprite("gfx/fakegrid/teleport_hole.anm2","blu",Vector(0.5,.5)),
	{TargetRoom = -1, Name = "", Size = Vector(2,2), Rot = 1},
	nilSpr,
	--editor converting to gameplay room. Converts data to a string for later copying by the user
	function(solidTab, grid)
		if grid.TargetName then
			solidTab = solidTab.."TargetName='"..grid.TargetName.."',"
		end
		if grid.TargetRoom ~= -1 then
			solidTab = solidTab.."TargetRoom='"..grid.TargetRoom.."',"
		end
		if grid.Name then
			solidTab = solidTab.."Name='"..grid.Name.."',"
		end
		if grid.Rot then
			solidTab = solidTab.."Rot="..grid.Rot..","
		end
		if grid.AltSkin then
			solidTab = solidTab.."Skin="..(grid.AltSkin and 1 or 0)..","
		end
		solidTab = solidTab.."Size=Vector("..math.ceil(grid.Size.X)..","..math.ceil(grid.Size.Y).."),"
		return solidTab
	end,
	--converting data to editor room
	function(tab)
		for idx, grid in pairs(tab) do
			local Gtype = "teleport_hole"
			local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
			--local size = grid.Size/1
			--grid.Size = nil
			Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
			local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
			list[y][x].EditData = {name = {Text = grid.Name},
				tarname = {Text = grid.TargetName},
				tarroom = {Text = grid.TargetRoom},
				rot = {Text = holeRotTab[grid.Rot]},
				color = {Flag = grid.Skin==1},}
			list[y][x].AltSkin = grid.Skin==1
			--list[y][x].Size = size
		end
	end)
	--textbox
	Isaac_Tower.editor.AddSpecialEditData("teleport_hole", "name", 1, {HintText = GetStr("special_obj_name"), ResultCheck = function(info, result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			info.Name = result
			return true
		end
	end})
	--textbox
	Isaac_Tower.editor.AddSpecialEditData("teleport_hole", "tarname", 1, {HintText = GetStr("nameTarget"), ResultCheck = function(info, result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			info.TargetName = result
			return true
		end
	end})
	--selector
	Isaac_Tower.editor.AddSpecialEditData("teleport_hole", "tarroom", 2, {HintText = GetStr("Transition Target"), ResultCheck = function(info,result)
		if not result then
			return false
		else
			info.TargetRoom = result
			return true
		end
	end, Generation = function(info) --generate list
		local tab = {}
		for rnam, romdat in pairs(Isaac_Tower.Rooms) do
			if rnam ~= Isaac_Tower.editor._EditorTestRoom then
				tab[#tab+1] = rnam
			end
		end
		return tab
	end})
	--selector
	Isaac_Tower.editor.AddSpecialEditData("teleport_hole", "rot", 2, {HintText = GetStr("Rotation"), ResultCheck = function(info,_,result)
		if not result then
			return false
		else
			info.Rot = result
			return true
		end
	end, Generation = function(info)
		local tab = holeRotTab
		return tab
	end, ParamInit = function(info)
		if not info.EditData.rot.Text then
			info.EditData.rot.Text = "0 %"
			info.Rot = 1
		end
	end})
	--flagbox
	Isaac_Tower.editor.AddSpecialEditData("teleport_hole", "color", 3, {HintText = GetStr("use_alt_skin"), ResultCheck = function(info, result)
		info.AltSkin = result
	end})

local function teleport_hole_init(_,_, grid)
	if grid.Name then
		--Isaac_Tower.GridLists.UnSave.EntersSpawn[grid.Name] = {
		--	Name = grid.Name,
		--	pos = grid.pos + Vector(20,20)
		--}
		Isaac_Tower.LevelHandler.AddEnterSpawn(grid.Name, grid.pos + Vector(20,20))
	end
	if Isaac_Tower.LevelHandler.RoomHasSavedData(Isaac_Tower.CurrentRoom.Name) then
		local muv = grid.Rot==1 and Vector(-1,1) or grid.Rot==4 and Vector(1,-1) or Vector(-1,-1)
		grid.Grid = Isaac_Tower.GridLists.Obs:GetGridByXY(grid.XY*2+muv)
	else
		local muv = grid.Rot==1 and Vector(-1,1) or grid.Rot==4 and Vector(1,-1) or Vector(-1,-1)
		grid.Grid = Isaac_Tower.GridLists.Obs:PlaceGrid({Collision=1, Rot = grid.Rot, AltSkin = grid.Skin}, grid.XY*2+muv, "teleport_hole_block")
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_INIT, teleport_hole_init, "teleport_hole")

TSJDNHC_PT.AddGridType("teleport_hole_block", function(self, gridList)
	self.Sprite1 = GenSprite("gfx/fakegrid/teleport_hole.anm2", self.AltSkin and "yellow_down" or "blu_down")
	self.OverSpr = GenSprite("gfx/fakegrid/teleport_hole.anm2", self.AltSkin and "yellow_up" or "blu_up")
	local x,y = 2,2
	--local spawnOfsset = Vector(0,0)
	if self.Rot == 1 or self.Rot == 3 then
		x = 4
	elseif self.Rot == 2 or self.Rot == 4 then
		y = 4
	end
	--if self.Rot == 3 then
	--	spawnOfsset = Vector(0,-1)
	--elseif self.Rot == 4 then
	--	spawnOfsset = Vector(-1,1)
	--end
	self.Sprite1.Rotation = (self.Rot-1) * 90
	--self.Sprite.Offset = self.Rot==1 and Vector(0,0) or self.Rot==2 and Vector(26,0)
	--	or self.Rot==3 and Vector(52,26) or self.Rot==4 and Vector(0,52)
	self.OverSpr.Rotation = self.Sprite1.Rotation
	--self.OverSpr.Offset = self.Sprite.Offset
	self.RenderOffset = self.Rot==1 and Vector(0,0) or self.Rot==2 and Vector(26,0)
		or self.Rot==3 and Vector(52,26) or self.Rot==4 and Vector(0,52)
	gridList:MakeMegaGrid(self.XY, x, y)
end,
nil,nil,
function(self, Pos, Offset, scale)
	local RenderPos = Pos + self.RenderOffset*scale
	local oldScale = self.Sprite1.Scale / 1
	self.Sprite1.Scale = self.Sprite1.Scale*scale
	self.Sprite1:Render(RenderPos)
	self.Sprite1.Scale = oldScale

	if self.Target then
		self.Target.Visible = false
		Isaac_Tower.FlayerRender(nil, self.Target, Offset, Offset, scale)
	end

	local oldScale = self.OverSpr.Scale / 1
	self.OverSpr.Scale = self.OverSpr.Scale*scale
	self.OverSpr:Render(RenderPos)
	self.OverSpr.Scale = oldScale
end)

---@param player EntityPlayer
---@param grid SpecialGrid
local function teleport_hole_collision(_, player, grid)
	---@type Flayer
	local fent = player:GetData().Isaac_Tower_Data
	if grid.TargetName and fent.State ~= "Cutscene" and not Isaac_Tower.Pause then
		local transit = false

		local avec
		local flipX
		if grid.Rot==1 then
			if fent.IngoneTransition and fent.IngoneTransition+5>Isaac.GetFrameCount() 
			and Isaac_Tower.Input.PressDown(player.ControllerIndex) then
				fent.IngoneTransition = Isaac.GetFrameCount()+1
				return
			else
				fent.IngoneTransition = nil
			end

			if Isaac_Tower.Input.PressDown(player.ControllerIndex) or 
			(fent.State == "Стомп_импакт_пол" and fent.OnGround) then
				--player.Visible = false
				transit = true
				avec = Vector(20,25)
			end
		elseif grid.Rot==2 then
			if fent.IngoneTransition and fent.IngoneTransition+45>Isaac.GetFrameCount() then
				fent.IngoneTransition = Isaac.GetFrameCount()+1
				return
			elseif not Isaac_Tower.Input.PressLeft(player.ControllerIndex) then
				fent.IngoneTransition = nil
			end

			if fent.LastVelocity.X<-1 and fent.CollideWall then
				avec = Vector(20,20)
				transit = true
				fent.Flayer.Rotation = 90
				fent.Flayer.Offset = Vector(-12,0)
				fent.Flayer.FlipX = not fent.Flayer.FlipX
			end
		elseif grid.Rot==4 then
			if fent.IngoneTransition and fent.IngoneTransition+5>Isaac.GetFrameCount() 
			and fent.LastVelocity.X>1 then
				fent.IngoneTransition = Isaac.GetFrameCount()+1
				return
			else
				fent.IngoneTransition = nil
			end

			if fent.LastVelocity.X>1 and fent.CollideWall then
				avec = Vector(20,0)
				transit = true
				fent.Flayer.Rotation = 90
				fent.Flayer.Offset = Vector(12,-12)
				fent.Flayer.FlipX = not fent.Flayer.FlipX
			end
		elseif grid.Rot==3 then
			if fent.IngoneTransition and fent.IngoneTransition+45>Isaac.GetFrameCount() then
				fent.IngoneTransition = Isaac.GetFrameCount()+1
				return
			elseif not Isaac_Tower.Input.PressRight(player.ControllerIndex) then
				fent.IngoneTransition = nil
			end

			if fent.LastVelocity.Y<-1 and fent.CollideCeiling then
				if Isaac_Tower.FlayerHandlers.WalkRunState[fent.State] then
					local fenpos = fent.Position+fent.Velocity
					if grid.pos.X < fenpos.X and fenpos.X < grid.pos.X+40  then
						transit = true
						fent.Flayer.Rotation = 180
						fent.Flayer.Offset = -fent.Flayer.DefaultOffset
						fent.Flayer.FlipX = not fent.Flayer.FlipX
					end
				else
					transit = true
					fent.Flayer.Rotation = 180
					fent.Flayer.Offset = -fent.Flayer.DefaultOffset
					fent.Flayer.FlipX = not fent.Flayer.FlipX
				end
					
				avec = Vector(20,10)
			end
		end

		if transit then
			--fent.Flayer.
			fent.Velocity = Vector(0,0)
			grid.Grid.Target = player
			grid.Target = player
			local gridpos = grid.pos+(avec or Vector(20,0))
			fent.PreviousState = fent.State
			fent.State = "Cutscene"
			fent.StateFrame = 0
			fent.InputWait = nil
			--fent.InvulnerabilityFrames = 5
			local entColl = fent.Self.EntityCollisionClass+0
			fent.Self.EntityCollisionClass = 0
			local gridcoll = fent.Self:GetData().TSJDNHC_GridColl+0
			fent.Self:GetData().TSJDNHC_GridColl = 0
			Isaac_Tower.SetScale(1.2,0.1)

			Isaac_Tower.scheduleForUpdate(function()
				player.Visible = true
				fent.Flayer.Offset = fent.Flayer.DefaultOffset
				if flipX then
					fent.Flayer.FlipX = not fent.Flayer.FlipX
				end

				fent.PreviousState = fent.State
				fent.State = "Ходьба"
				fent.StateFrame = 0
				fent.InputWait = nil
				fent.CutsceneLogic = nil
				fent.IngoneTransition = Isaac.GetFrameCount()
				grid.Grid.Target = nil
				Isaac_Tower.SetScale(1.0,0.2)
				fent.Self.EntityCollisionClass = entColl --4
				fent.Flayer.Rotation = 0
				fent.Self:GetData().TSJDNHC_GridColl = gridcoll
			end, 1, Isaac_Tower.Callbacks.ROOM_LOADING)

			fent.CutsceneLogic = function(player, fent, spr, idx)
				player.Visible = false
				fent.Position = fent.Position*0.7 + gridpos*0.3
				--print(spr.Rotation, spr:GetAnimation(), spr:GetFrame(), player.Visible)
				if spr:GetAnimation() ~= "poke" then
					spr:Play("poke")
				elseif spr:IsFinished("poke") then
					Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
					--player.Visible = true

					--fent.PreviousState = fent.State
					--fent.State = "Ходьба"
					--fent.StateFrame = 0
					--fent.InputWait = nil
					--fent.CutsceneLogic = nil
				end
			end
		end
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, teleport_hole_collision, "teleport_hole")

Isaac_Tower.editor.AddSpecial("secretroom_enter", nil, 
	GenSprite("gfx/fakegrid/secretroom_enter.anm2","idle_lightglow"),
	{TargetRoom = -1, Name = ""},
	GenSprite("gfx/fakegrid/secretroom_enter.anm2","idle_lightglow"),
	function(solidTab, grid)
		if grid.TargetName then
			solidTab = solidTab.."TargetName='"..grid.TargetName.."',"
		end
		if grid.TargetRoom ~= -1 then
			solidTab = solidTab.."TargetRoom='"..grid.TargetRoom.."',"
		end
		if grid.Name then
			solidTab = solidTab.."Name='"..grid.Name.."',"
		end
		--solidTab = solidTab.."Size=Vector("..math.ceil(grid.Size.X)..","..math.ceil(grid.Size.Y).."),"
		return solidTab
	end,
	function(tab)
		for idx, grid in pairs(tab) do
			local Gtype = "secretroom_enter"
			local x,y = math.ceil(grid.XY.X), math.ceil(grid.XY.Y)
			--local size = grid.Size/1
			--grid.Size = nil
			Isaac_Tower.editor.PlaceSpecial(Gtype,x,y,grid)
			local list = Isaac_Tower.editor.Memory.CurrentRoom.Special[Gtype]
			list[y][x].EditData = {name = {Text = grid.Name},
				tarname = {Text = grid.TargetName},
				tarroom = {Text = grid.TargetRoom},}
		end
	end)
	Isaac_Tower.editor.AddSpecialEditData("secretroom_enter", "name", 1, {HintText = GetStr("special_obj_name"), ResultCheck = function(info, result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			info.Name = result
			return true
		end
	end})
	Isaac_Tower.editor.AddSpecialEditData("secretroom_enter", "tarname", 1, {HintText = GetStr("nameTarget"), ResultCheck = function(info, result)
		if not result then
			return true
		else
			if #result < 1 or not string.find(result,"%S") then
				return GetStr("emptyField")
			end
			info.TargetName = result
			return true
		end
	end})
	Isaac_Tower.editor.AddSpecialEditData("secretroom_enter", "tarroom", 2, {HintText = GetStr("Transition Target"), ResultCheck = function(info,result)
		if not result then
			return false
		else
			info.TargetRoom = result
			return true
		end
	end, Generation = function(info)
		local tab = {}
		for rnam, romdat in pairs(Isaac_Tower.Rooms) do
			if rnam ~= Isaac_Tower.editor._EditorTestRoom then
				tab[#tab+1] = rnam
			end
		end
		return tab
	end})

local function secretroom_enter_init(_,_, grid)
	if grid.Name then
		Isaac_Tower.LevelHandler.AddEnterSpawn(grid.Name, grid.pos) -- - Vector(20,20))
	end
	if Isaac_Tower.LevelHandler.RoomHasSavedData(Isaac_Tower.CurrentRoom.Name) then
		local muv = Vector(-1,-1)
		grid.Grid = Isaac_Tower.GridLists.Obs:GetGridByXY(grid.XY*2+muv)
		if Isaac_Tower.LevelHandler.IsVisited(grid.TargetRoom) then
			Isaac_Tower.GridLists.Obs:DestroyGrid(grid.Grid.XY)
		end
	elseif Isaac_Tower.LevelHandler.CurrentGetRoomType() == Isaac_Tower.editor.RoomTypes.secretroom 
	or not Isaac_Tower.LevelHandler.IsVisited(grid.TargetRoom) then
		local muv = Vector(-1,-1)
		grid.Grid = Isaac_Tower.GridLists.Obs:PlaceGrid({Collision=0}, grid.XY*2+muv, "secretroom_enter_block")
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_INIT, secretroom_enter_init, "secretroom_enter")

TSJDNHC_PT.AddGridType("secretroom_enter_block", function(self, gridList)
	self.Sprite = GenSprite("gfx/fakegrid/secretroom_enter.anm2", "idle")
	gridList:MakeMegaGrid(self.XY, 2, 2)
end)

Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_COLLISION, function(_, player, grid)
	local fent = player:GetData().Isaac_Tower_Data
	if Isaac_Tower.LevelHandler.CurrentGetRoomType() == Isaac_Tower.editor.RoomTypes.secretroom
		or not Isaac_Tower.LevelHandler.IsVisited(grid.TargetRoom) then
		
		fent.Velocity = Vector(0,0)
		grid.Grid.Target = player
		grid.Target = player
		local gridpos = grid.pos+Vector(0,-20)
		fent.PreviousState = fent.State
		fent.State = "Cutscene"
		fent.StateFrame = 0
		fent.InputWait = 30
		--fent.InvulnerabilityFrames = 5
		local entColl = fent.Self.EntityCollisionClass+0
		fent.Self.EntityCollisionClass = 0
		local gridcoll = fent.Self:GetData().TSJDNHC_GridColl+0
		fent.Self:GetData().TSJDNHC_GridColl = 0
		local returnScale
		local movePlayer = false

		Isaac_Tower.scheduleForUpdate(function()
			if movePlayer then
				for i=0,Isaac_Tower.game:GetNumPlayers()-1 do
					Isaac_Tower.GetFlayer().Position = Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter
				end
				TSJDNHC_PT:SetFocusPosition(Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter, 1)
				Isaac_Tower.SmoothPlayerPos = Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter
			end
			player.Visible = true
			fent.Flayer.Offset = fent.Flayer.DefaultOffset

			grid.Grid.Target = nil
			player.EntityCollisionClass = entColl
			fent.Flayer.Rotation = 0
			player:GetData().TSJDNHC_GridColl = gridcoll

			local ent = Isaac.Spawn(Isaac_Tower.ENT.GIB.ID,Isaac_Tower.ENT.GIB.VAR,
				Isaac_Tower.ENT.GibSubType.SECRETROOM_ENTER_EFFECT,
				player:GetData().Isaac_Tower_Data.Position+Vector(-20,-40),Vector(0,0),player)

			fent.CutsceneLogic = function(player, fent, spr, idx)
				if movePlayer and Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter then
					for i=0,Isaac_Tower.game:GetNumPlayers()-1 do
						Isaac_Tower.GetFlayer().Position = Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter
					end
				else
					fent.Position = fent.Position*0.7 + Isaac_Tower.LevelHandler.GetSpawnPosition()*0.3
				end

				if not ent or ent:GetSprite():WasEventTriggered("break") then
					spr.Scale = spr.Scale * 0.9 + returnScale*0.15
		
					if spr.Scale.X > returnScale.X then
						spr.Scale = returnScale
						fent.CutsceneLogic = nil
						fent.PreviousState = fent.State
						fent.State = "Ходьба"
						fent.StateFrame = 0
						fent.InputWait = nil
					end
				end
			end
		end, 1, Isaac_Tower.Callbacks.POST_NEW_ROOM, true)

		

		fent.CutsceneLogic = function(player, fent, spr, idx)
			returnScale = returnScale or spr.Scale/1
			fent.Position = fent.Position*0.7 + gridpos*0.3
			spr.Scale = spr.Scale * 0.9

			if fent.InputWait <= 0 then
				if Isaac_Tower.LevelHandler.CurrentGetRoomType() == Isaac_Tower.editor.RoomTypes.secretroom then
					local roomName = grid.TargetRoom or Isaac_Tower.LevelHandler.GetLevelData().PreviousRoom
					Isaac_Tower.RoomTransition(roomName, false, nil, grid.TargetName)
					movePlayer = not grid.TargetName
				else
					Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
					Isaac_Tower.LevelHandler.GetLevelData().SecretRoomEnter = gridpos/1
				end
			end
			fent.InputWait = fent.InputWait - 1
		end

	end
end, "secretroom_enter")






do
	local ignoreTypes = {spawnpoint_def=true,[""]=true,Room_Transition=true,spawnpoint=true}
	Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ROOM_LOADING, function(_,gridlist, newRoom, roomName, oldRoomName)
		if newRoom.Special then
			local toInit = {}
			for gType, tab in pairs(newRoom.Special) do
				if not ignoreTypes[gType] then
					Isaac_Tower.GridLists.Special[gType] = {}
					for i, grid in ipairs(tab) do
						--local index = math.ceil(grid.XY.X) .. "." .. math.ceil(grid.XY.Y)
						local index = (grid.XY.Y) * newRoom.Size.X + (grid.XY.X)
						local Parents
						if Isaac_Tower.GridLists.Special[gType][index] and Isaac_Tower.GridLists.Special[gType][index].Parents then
							Parents = Isaac_Tower.GridLists.Special[gType][index].Parents
						end
						Isaac_Tower.GridLists.Special[gType][index] = TabDeepCopy(grid)
						Isaac_Tower.GridLists.Special[gType][index].pos = grid.XY * 40 + Vector(-60, 80)
						Isaac_Tower.GridLists.Special[gType][index].FrameCount = 0
						Isaac_Tower.GridLists.Special[gType][index].Type = gType
						if Parents then
							Isaac_Tower.GridLists.Special[gType][index].Parents = Parents
						end
						if Isaac_Tower.GridLists.Special[gType][index].Size then
							local gridtab = GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].Size, true, newRoom.Size.X)
							for j=1, #gridtab do 
								local k = gridtab[j]
								Isaac_Tower.GridLists.Special[gType][k] = { Parent = index }
							end
							--for i, k in pairs(GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].Size, true, newRoom.Size.X)) do
							--	Isaac_Tower.GridLists.Special[gType][k] = { Parent = index }
							--end
						end
						if Isaac_Tower.GridLists.Special[gType][index].FSize then
							--for i, k in pairs(GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].FSize, true, newRoom.Size.X)) do
							local gridtab = GetLinkedGrid(Isaac_Tower.GridLists.Special[gType], grid.XY, Isaac_Tower.GridLists.Special[gType][index].FSize, true, newRoom.Size.X)
							for j=1, #gridtab do 
								local k = gridtab[j]
								Isaac_Tower.GridLists.Special[gType][k] = { Parent = index }
								if not Isaac_Tower.GridLists.Special[gType][k] then
									Isaac_Tower.GridLists.Special[gType][k] = {Parents = {index}}
								else
									if not Isaac_Tower.GridLists.Special[gType][k].Parents then
										Isaac_Tower.GridLists.Special[gType][k].Parents = {index}
									else
										Isaac_Tower.GridLists.Special[gType][k].Parents[#Isaac_Tower.GridLists.Special[gType][k].Parents+1] = index
									end
								end
							end
						end
						if Isaac_Tower.GridLists.Special[gType][index].Name then
							Isaac_Tower.GridLists.ObjByName[Isaac_Tower.GridLists.Special[gType][index].Name] = Isaac_Tower.GridLists.Special[gType][index]
						end
						toInit[#toInit+1] = {gType,Isaac_Tower.GridLists.Special[gType][index]}
					end
				end
			end

			for i=1,#toInit do
				local k = toInit[i]
				Isaac_Tower.RunDirectCallbacks(Isaac_Tower.Callbacks.SPECIAL_INIT, k[1], k[1], k[2])
			end
		end
	end)
end

------------------------------------------------------------------ОКРУЖЕНИЕ---------------------------------------------

--for i=1,10 do
Isaac_Tower.editor.AddEnvironment("t_slap1", 
	GenSprite("gfx/evrom/tutorial.anm2","1",nil,nil,Vector(13,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","1") end, 
	GenSprite("gfx/evrom/tutorial.anm2","1", Vector(.5,.5)), 
	Vector(14,11),
	Vector(6,7))
--end
Isaac_Tower.editor.AddEnvironment("t_slap2", 
	GenSprite("gfx/evrom/tutorial.anm2","2",nil,nil,Vector(13,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","2") end, 
	GenSprite("gfx/evrom/tutorial.anm2","2", Vector(.5,.5)), 
	Vector(16,13),
	Vector(9,8))


Isaac_Tower.editor.AddEnvironment("t_rock", 
	GenSprite("gfx/evrom/tutorial.anm2","rock",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","rock") end, 
	GenSprite("gfx/evrom/tutorial.anm2","rock", Vector(.5,.5)), 
	Vector(37,32),
	Vector(16,16))

Isaac_Tower.editor.AddEnvironment("t_paper1", 
	GenSprite("gfx/evrom/tutorial.anm2","4",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","4") end, 
	GenSprite("gfx/evrom/tutorial.anm2","4", Vector(.5,.5)), 
	Vector(14,7),
	Vector(7,5))

Isaac_Tower.editor.AddEnvironment("t_hole1", 
	GenSprite("gfx/evrom/tutorial.anm2","7",nil,nil,Vector(11,15)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","7") end, 
	GenSprite("gfx/evrom/tutorial.anm2","7", Vector(.5,.5)), 
	Vector(35,24),
	Vector(16,16))

Isaac_Tower.editor.AddEnvironment("t_rope1", 
	GenSprite("gfx/evrom/tutorial.anm2","11",Vector(0.8,0.8),nil,Vector(9,0)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","11") end, 
	GenSprite("gfx/evrom/tutorial.anm2","11", Vector(.5,.5)), 
	Vector(17,46),
	Vector(11,8))

Isaac_Tower.editor.AddEnvironment("t_grass1", 
	GenSprite("gfx/evrom/tutorial.anm2","3",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","3") end, 
	GenSprite("gfx/evrom/tutorial.anm2","3", Vector(.5,.5)), 
	Vector(10,12),
	Vector(5,8))

Isaac_Tower.editor.AddEnvironment("t_paper2", 
	GenSprite("gfx/evrom/tutorial.anm2","5",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","5") end, 
	GenSprite("gfx/evrom/tutorial.anm2","5", Vector(.5,.5)), 
	Vector(14,10),
	Vector(7,5))

Isaac_Tower.editor.AddEnvironment("t_hole2", 
	GenSprite("gfx/evrom/tutorial.anm2","6",nil,nil,Vector(12,15)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","6") end, 
	GenSprite("gfx/evrom/tutorial.anm2","6", Vector(.5,.5)), 
	Vector(37,29),
	Vector(19,17))

Isaac_Tower.editor.AddEnvironment("t_root1", 
	GenSprite("gfx/evrom/tutorial.anm2","8",nil,nil,Vector(9,5)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","8") end, 
	GenSprite("gfx/evrom/tutorial.anm2","8", Vector(.5,.5)), 
	Vector(14,16),
	Vector(8,2))

Isaac_Tower.editor.AddEnvironment("t_root2", 
	GenSprite("gfx/evrom/tutorial.anm2","9",nil,nil,Vector(9,5)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","9") end, 
	GenSprite("gfx/evrom/tutorial.anm2","9", Vector(.5,.5)), 
	Vector(14,16),
	Vector(6,2))

Isaac_Tower.editor.AddEnvironment("t_root3", 
	GenSprite("gfx/evrom/tutorial.anm2","10",nil,nil,Vector(9,5)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","10") end, 
	GenSprite("gfx/evrom/tutorial.anm2","10", Vector(.5,.5)), 
	Vector(14,16),
	Vector(6,2))

Isaac_Tower.editor.AddEnvironment("t_paper3", 
	GenSprite("gfx/evrom/tutorial.anm2","12",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","12") end, 
	GenSprite("gfx/evrom/tutorial.anm2","12", Vector(.5,.5)), 
	Vector(10,10),
	Vector(5,5))

Isaac_Tower.editor.AddEnvironment("t_paper4", 
	GenSprite("gfx/evrom/tutorial.anm2","13",nil,nil,Vector(9,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","13") end, 
	GenSprite("gfx/evrom/tutorial.anm2","13", Vector(.5,.5)), 
	Vector(10,12),
	Vector(4,5))

for i=1,9 do
	local anm = "back"..i
	Isaac_Tower.editor.AddEnvironment("t_back"..i, 
		GenSprite("gfx/evrom/tutorial.anm2",anm,nil,nil,Vector(13,13)), 
		function() return GenSprite("gfx/evrom/tutorial.anm2",anm) end, 
		GenSprite("gfx/evrom/tutorial.anm2",anm, Vector(.5,.5)), 
		Vector(26,26),
		Vector(13,13))
end

Isaac_Tower.editor.AddEnvironment("t_hint1", 
	GenSprite("gfx/evrom/tutorial.anm2","hint1",nil,nil,Vector(13,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint1") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint1", Vector(.5,.5)), 
	Vector(32,32),
	Vector(16,16))

Isaac_Tower.editor.AddEnvironment("t_hint2", 
	GenSprite("gfx/evrom/tutorial.anm2","hint2",Vector(.6,.7),nil,Vector(11,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint2") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint2", Vector(.5,.5)), 
	Vector(74,42),
	Vector(16+20,16+7))

Isaac_Tower.editor.AddEnvironment("t_hint3", 
	GenSprite("gfx/evrom/tutorial.anm2","hint3",nil,nil,Vector(11,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint3") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint3", Vector(.5,.5)), 
	Vector(41,27),
	Vector(16,16))

Isaac_Tower.editor.AddEnvironment("t_hint4", 
	GenSprite("gfx/evrom/tutorial.anm2","hint4",nil,nil,Vector(11,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint4") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint4", Vector(.5,.5)), 
	Vector(29,32),
	Vector(16,16))

Isaac_Tower.editor.AddEnvironment("t_bigrock", 
	GenSprite("gfx/evrom/tutorial.anm2","bigrock",Vector(.15,.15),nil,Vector(11,13)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","bigrock") end, 
	GenSprite("gfx/evrom/tutorial.anm2","bigrock", Vector(.5,.5)), 
	Vector(208,208),
	Vector(104,104))

Isaac_Tower.editor.AddEnvironment("t_robebig_1", 
	GenSprite("gfx/evrom/tutorial.anm2","robebig_1",Vector(.5,.25),nil,Vector(11,-3)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","robebig_1") end, 
	GenSprite("gfx/evrom/tutorial.anm2","robebig_1", Vector(.5,.5)), 
	Vector(10,144),
	Vector(3,6))

Isaac_Tower.editor.AddEnvironment("t_robebig_2", 
	GenSprite("gfx/evrom/tutorial.anm2","robebig_2",Vector(.3,.15),nil,Vector(11,0)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","robebig_2") end, 
	GenSprite("gfx/evrom/tutorial.anm2","robebig_2", Vector(.5,.5)), 
	Vector(10,284),
	Vector(3,16))
for i=1,5 do
	local anm = "plank_back"..i
	Isaac_Tower.editor.AddEnvironment("t_plank_back"..i, 
		GenSprite("gfx/evrom/tutorial.anm2",anm,nil,nil,Vector(13,13)), 
		function() return GenSprite("gfx/evrom/tutorial.anm2",anm) end, 
		GenSprite("gfx/evrom/tutorial.anm2",anm, Vector(.5,.5)), 
		Vector(28,28),
		Vector(14,14))
end
Isaac_Tower.editor.AddEnvironment("t_hint5", 
	GenSprite("gfx/evrom/tutorial.anm2","hint5",Vector(.4,.5),nil,Vector(11,10)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint5") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint5", Vector(.5,.5)), 
	Vector(96,44),
	Vector(48,22))
Isaac_Tower.editor.AddEnvironment("t_hint6", 
	GenSprite("gfx/evrom/tutorial.anm2","hint6",Vector(1.0,1.0),nil,Vector(11,10)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","hint6") end, 
	GenSprite("gfx/evrom/tutorial.anm2","hint6", Vector(.5,.5)), 
	Vector(42,30),
	Vector(21,15))
--Isaac_Tower.editor.AddEnvironment("t_hint7", 
--	GenSprite("gfx/evrom/tutorial.anm2","hint7",Vector(1.0,1.0),nil,Vector(11,10)), 
--	function() return GenSprite("gfx/evrom/tutorial.anm2","hint7") end, 
--	GenSprite("gfx/evrom/tutorial.anm2","hint7", Vector(.5,.5)), 
--	Vector(21,31),
--	Vector(10,15))
Isaac_Tower.editor.AddEnvironment("t_backs1", 
	GenSprite("gfx/evrom/tutorial.anm2","backs1",Vector(1.0,1.0),nil,Vector(11,10)), 
	function() return GenSprite("gfx/evrom/tutorial.anm2","backs1") end, 
	GenSprite("gfx/evrom/tutorial.anm2","backs1", Vector(.5,.5)), 
	Vector(26,26),
	Vector(13,13))
for i=2,3 do
	local anm = "backs"..i
	Isaac_Tower.editor.AddEnvironment("t_backs"..i, 
		GenSprite("gfx/evrom/tutorial.anm2",anm,nil,nil,Vector(13,13)), 
		function() return GenSprite("gfx/evrom/tutorial.anm2",anm) end, 
		GenSprite("gfx/evrom/tutorial.anm2",anm, Vector(.5,.5)), 
		Vector(26,30),
		Vector(13,17))
end



do
	local EnviList = {
		{"t_","hint7",Vector(21,31),Vector(10,15),Vector(1.0,1.0),Vector(11,10)},
		{"t_","hint8",Vector(12,41),Vector(6,20),Vector(1.0,1.0),Vector(11,10)},
		{"t_","hint9",Vector(16,49),Vector(8,25),Vector(1.0,1.0),Vector(11,10)},
		{"t_","hint10",Vector(27,25),Vector(14,13),Vector(1.0,1.0),Vector(11,10)},
		{"t_","hint11",Vector(21,27),Vector(10,13),Vector(1.0,1.0),Vector(11,10)},
		{"t_","platform_shadow1",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(11,10)},
		{"t_","platform_shadow2",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(11,10)},
		{"t_","platform_shadow3",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(11,10)},
		{"t_","platform_shadow4",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(11,10)},
	}

	for i, tab in ipairs(EnviList) do
		local name = tab[1] .. tab[2]
		local scale = tab[5] or Vector(1,1)
		local off = tab[6] or Vector(10,10)
		Isaac_Tower.editor.AddEnvironment(name, 
			GenSprite("gfx/evrom/tutorial.anm2",tab[2],scale,nil,off), 
			function() return GenSprite("gfx/evrom/tutorial.anm2",tab[2]) end, 
			GenSprite("gfx/evrom/tutorial.anm2",tab[2], Vector(.5,.5)), 
			tab[3],
			tab[4])
	end

	local EnviList = {   ---cellar
		{"cel_","black3_3",Vector(78,78),Vector(39,39),Vector(0.4,0.4),Vector(13,13)},
		{"cel_","black5_5",Vector(130,130),Vector(65,65),Vector(0.3,0.3),Vector(13,13)},
		{"cel_","1_1x3",Vector(86,32),Vector(3,4),Vector(0.5,0.5),Vector(-8,5)},
		{"cel_","web1",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(13,13)},
		{"cel_","web2",Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(13,13)},
		{"cel_","web3",Vector(36,26),Vector(18,13),Vector(1.0,1.0),Vector(10,13)},
		{"cel_","web4",Vector(175,198),Vector(87,99),Vector(.3,.3),Vector(13,13)},
	}

	for i=1,13 do
		local name = "black"..i
		--Isaac_Tower.editor.AddGrid(name, name, GenSprite("gfx/fakegrid/grid2.anm2",name), {Collision = 1, SpriteAnim = name })
		EnviList[#EnviList+1] = {"cel_",name,Vector(26,26),Vector(13,13),Vector(1.0,1.0),Vector(13,13)}
	end

	for i, tab in ipairs(EnviList) do
		local name = tab[1] .. tab[2]
		local scale = tab[5] or Vector(1,1)
		local off = tab[6] or Vector(10,10)
		Isaac_Tower.editor.AddEnvironment(name, 
			GenSprite("gfx/evrom/cellar.anm2",tab[2],scale,nil,off), 
			function() return GenSprite("gfx/evrom/cellar.anm2",tab[2]) end, 
			GenSprite("gfx/evrom/cellar.anm2",tab[2], Vector(.5,.5)), 
			tab[3],
			tab[4])
	end

	local EnviList = {  ---secret room
		{"sr_","1",Vector(16,16),Vector(8,8),Vector(1,1),Vector(13,13)},
		{"sr_","2",Vector(16,16),Vector(8,8),Vector(1,1),Vector(13,13)},
		{"sr_","3",Vector(16,16),Vector(8,8),Vector(1,1),Vector(13,13)},
		{"sr_","4",Vector(16,16),Vector(8,8),Vector(1.0,1.0),Vector(13,13)},
		{"sr_","5",Vector(16,16),Vector(8,8),Vector(1.0,1.0),Vector(13,13)},
		{"sr_","6",Vector(32,48),Vector(16,24),Vector(1.0,1.0),Vector(13,13)},
		{"sr_","7",Vector(32,16),Vector(16,8),Vector(1,1),Vector(13,13)},
	}
	local path = "gfx/evrom/secretroom.anm2"
	for i, tab in ipairs(EnviList) do
		local name = tab[1] .. tab[2]
		local scale = tab[5] or Vector(1,1)
		local off = tab[6] or Vector(10,10)
		Isaac_Tower.editor.AddEnvironment(name, 
			GenSprite(path,tab[2],scale,nil,off), 
			function() return GenSprite(path,tab[2]) end, 
			GenSprite(path,tab[2], Vector(.5,.5)), 
			tab[3],
			tab[4])
	end
end


do

	Isaac_Tower.Backgroung.AddBackgroung("tutorial", {{
		spr = GenSprite("gfx/backgrounds/basement_bg.anm2", "1"),
		size = Vector(100,100),
		visible = true,
		scrollX = true,
		scrollY = true,
		distancing = 2,
	}})
	local spr = GenSprite("gfx/backgrounds/cellar_bg.anm2", "1", Vector(0.5,.5))
	local spr2 = GenSprite("gfx/backgrounds/cellar_bg.anm2", "2", Vector(0.5,.5))
	local spr3 = GenSprite("gfx/backgrounds/cellar_bg.anm2", "4", Vector(1,1))
	--spr:ReplaceSpritesheet(0, "gfx/backgrounds/cellar_bg.png")
	--spr:LoadGraphics()
	Isaac_Tower.Backgroung.AddBackgroung("cellar", {
	{
		spr = spr,
		size = Vector(100,100),
		visible = true,
		scrollX = true,
		scrollY = true,
		distancing = 4,
	},
	--[[{
		spr = spr2,
		size = Vector(100,100),
		visible = true,
		updown = {1,2},
		distancing = 1,
	}]]
	{
		spr = spr3,
		size = Vector(200,200),
		visible = true,
		scrollX = true,
		scrollY = true,
		distancing = 2,
	},
	})

	local spr = GenSprite("gfx/backgrounds/magic_secret.anm2", "bg", Vector(1,1))
	spr.PlaybackSpeed = 0.5
	local spr2 = GenSprite("gfx/backgrounds/magic_secret.anm2", "layer1", Vector(1,1))
	local spr3 = GenSprite("gfx/backgrounds/magic_secret.anm2", "layer2", Vector(1,1))
	local spr4 = GenSprite("gfx/backgrounds/magic_secret.anm2", "down", Vector(1,1))
	local moon = GenSprite("gfx/backgrounds/magic_secret_extra.anm2", "moon", Vector(1,1))
	local star = GenSprite("gfx/backgrounds/magic_secret_extra.anm2", "stars", Vector(.5,.5))
	star.PlaybackSpeed = 0.5
	moon.PlaybackSpeed = 0.5
	spr4.Offset = Vector(0,-64)
	Isaac_Tower.Backgroung.AddBackgroung("secret", {
		{
			spr = spr,
			shines = {},
			size = Vector(300,200),
			visible = true,
			scrollX = true,
			--scrollY = true,
			distancing = 4,
			func = function(background, Offset, Scale)
				local scrX, scrY = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
				local Offset = Vector(0,0) -- -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition 

				local center = Isaac_Tower.GetScreenCenter()
				for i=#background.shines,1,-1 do
					local k=background.shines[i]
					local pp = Offset + k[2]
					local renderPos = Vector(pp.X % scrX, pp.Y % scrY)
					k[1]:Render(renderPos)
					k[1]:Update()
					if k[1]:IsFinished(k[1]:GetAnimation()) then
						table.remove(background.shines,i)
					end
				end

				if not Isaac_Tower.InAction or Isaac_Tower.Pause or Isaac_Tower.game:IsPaused() then return end
				if Isaac.GetFrameCount()%5 == 0 and #background.shines<20 then
					local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng
					local spr = GenSprite("gfx/backgrounds/magic_secret_extra.anm2", rng:RandomInt(2)==0 and "shine" or "shine2") -- .. (rng:RandomInt(2)+1))
					spr.Color = Color(1,1,1,0.5)
					spr.Scale = spr.Scale * rng:RandomFloat()
					spr.PlaybackSpeed = 0.5
					local pos = Offset-- TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition 
						+ Vector(rng:RandomInt(scrX),rng:RandomInt(scrY))
					background.shines[#background.shines+1] = {
						spr, pos
					}
				end
			end,
		},
		{
			spr = star,
			moon = moon,
			size = Vector(200,100),
			visible = true,
			--scrollX = true,
			--scrollY = true,
			distancing = 1000,
			--mov = Vector(0.3,0)
			func = function(background, Offset, Scale)
				local center = Isaac_Tower.GetScreenCenter()
				background.moon:Render(center + center*Vector(0.5,-1.1))
				background.moon:Update()
			end,
		},
		{
			spr = spr2,
			size = Vector(300,200),
			visible = true,
			scrollX = true,
			--scrollY = true,
			distancing = 3,
			mov = Vector(0.2,0)
		},
		{
			spr = spr3,
			size = Vector(300,200),
			visible = true,
			scrollX = true,
			--scrollY = true,
			distancing = 2,
			mov = Vector(0.3,0)
		},
		{
			spr = spr4,
			size = Vector(300,128),
			visible = true,
			updown = {0,14},
			distancing = .8,
			mov = Vector(0.5,0),
			sortlayer = 2,
			shines = {},
			--[[func = function(background, Offset, Scale)
				local scrX, scrY = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
				local Offset = Vector(0,0) -- -TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition 

				local center = Isaac_Tower.GetScreenCenter()
				for i=#background.shines,1,-1 do
					local k=background.shines[i]
					local pp = Offset + k[2]
					local renderPos = Vector(pp.X % scrX, pp.Y % scrY)
					k[1]:Render(renderPos)
					k[1]:Update()
					if k[1]:IsFinished(k[1]:GetAnimation()) then
						table.remove(background.shines,i)
					end
				end

				if not Isaac_Tower.InAction or Isaac_Tower.Pause or Isaac_Tower.game:IsPaused() then return end
				if Isaac.GetFrameCount()%5 == 0 and #background.shines<20 then
					local rng = Isaac_Tower.LevelHandler.GetCurrentRoomData().deco_rng
					local spr = GenSprite("gfx/backgrounds/magic_secret_extra.anm2", rng:RandomInt(2)==0 and "shine" or "shine2") -- .. (rng:RandomInt(2)+1))
					spr.Color = Color(1,1,1,0.5)
					spr.Scale = spr.Scale * rng:RandomFloat()
					spr.PlaybackSpeed = 0.5
					local pos = Offset-- TSJDNHC_PT:GetCameraEnt():GetData().CurrentCameraPosition 
						+ Vector(rng:RandomInt(scrX),rng:RandomInt(scrY))
					background.shines[#background.shines+1] = {
						spr, pos
					}
				end
			end,]]
		},
		{
			spr = GenSprite("gfx/backgrounds/magic_secret.anm2", "cloud1", Vector(1,1)),
			size = Vector(200,100),
			visible = true,
			distancing = 1.2,
			mov = Vector(0.35,0),
			--sortlayer = 2,
		},
		})

end

-------------------------------------------------------------------ВРАГИ------------------------------------------------


Isaac_Tower.ENT.LOGIC = {}

								--ЗНАК
function Isaac_Tower.ENT.LOGIC.EnemySignLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround then
			if data.Velocity.Y>5 then
				data.grounding = -1
				data.OnGround = nil
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(data.Velocity.Y*-0.4,data.Velocity.Y))
				--ent.Position = Vector(ent.Position.X ,ent.Position.Y + ent.Velocity.Y)
				ent:GetSprite().Rotation = -math.abs(data.Velocity.X*data.Velocity.Y/5)
				ent:GetSprite().Offset = Vector(ent:GetSprite().Rotation*.2,0)
			else
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(0,data.Velocity.Y))
			end
		else
			data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+0.8))) or data.Velocity
		end
		if data.CollideCeiling and data.Velocity.Y<0 then
			data.Velocity = Vector(data.Velocity.X, 0)
		end
	end
end

function Isaac_Tower.ENT.LOGIC.EnemySignRender(_,ent)
	if not Isaac_Tower.game:IsPaused() then
		local data = ent:GetData().Isaac_Tower_Data
		if data.State >= 1 then
			if data.OnGround then
				ent:GetSprite().Rotation = -math.abs(data.Velocity.X)
				ent:GetSprite().Offset = Vector(ent:GetSprite().Rotation*.2,0)
			else
				ent:GetSprite().Rotation = ent:GetSprite().Rotation * 0.9 + data.Velocity.X*.1
				ent:GetSprite().Offset = Vector(data.Velocity.X*.2,0)
			end
		end
	end
end

Isaac_Tower.RegisterEnemy("sign", "gfx/it_enemies/sign.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY, NoStun = true})
Isaac_Tower.RegisterEnemy("signp", "gfx/it_enemies/sign.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY, NoStun = true})
Isaac_Tower.editor.AddEnemies("sign", 
	GenSprite("gfx/it_enemies/sign.anm2","TrashCo w",nil,nil,Vector(13,13)), 
	"sign",0,  
	GenSprite("gfx/it_enemies/sign.anm2","TrashCo w",nil,nil,Vector(13/2,13/2)))
Isaac_Tower.editor.AddEnemies("signp", 
	GenSprite("gfx/it_enemies/sign.anm2","pooo",nil,nil,Vector(13,13)), 
	"signp",0,  
	GenSprite("gfx/it_enemies/sign.anm2","pooo",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent:GetSprite():Play("pooo")
end, "signp")

--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "sign")
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "signp")
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "sign")
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "signp")

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, Isaac_Tower.ENT.LOGIC.EnemySignRender, "sign")
mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_RENDER, Isaac_Tower.ENT.LOGIC.EnemySignRender, "signp")

---------------------------------------КЛОТТИГ--------------------------------------------

Isaac_Tower.RegisterEnemy("clottig", "gfx/it_enemies/clottig.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("clottig", 
	GenSprite("gfx/it_enemies/clottig.anm2","idle",nil,nil,Vector(13,13)), 
	"clottig",0,  
	GenSprite("gfx/it_enemies/clottig.anm2","idle",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	--ent.PositionOffset = Vector(0,5)
	ent:GetSprite().Offset = Vector(0,5) / Wtr
end, "clottig")

function Isaac_Tower.ENT.LOGIC.EnemyClottigLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround then
			if data.Velocity.Y>5 then
				data.grounding = -1
				data.OnGround = nil
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(data.Velocity.Y*-0.4,data.Velocity.Y))
				--ent.Position = Vector(ent.Position.X ,ent.Position.Y + ent.Velocity.Y)
			else
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(0,data.Velocity.Y))
			end
		else
			data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+0.8))) or data.Velocity
		end
		if data.CollideCeiling and data.Velocity.Y<0 then
			data.Velocity = Vector(data.Velocity.X, 0)
		end

		if data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE then
			if not spr:IsPlaying("idle") then
				spr:Play("idle")
			end
			data.Delay = data.Delay and (data.Delay-1) or ent:GetDropRNG():RandomInt(60)
			if data.Delay<0 then
				SetState(data,2) --data.State = 2
			end
		elseif data.State == 2 then
			if spr:IsFinished("move") then
				data.Delay = nil
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			elseif not spr:IsPlaying("move") then
				spr:Play("move")
			elseif spr:IsPlaying("move") and spr:GetFrame()>10 and spr:GetFrame()<20 then
				local targetVel = ent.FlipX and Vector(-5,0) or Vector(5,0)
				data.Velocity = data.Velocity * 0.8 + targetVel * 0.2
			end
			if data.CollideWall then
				ent.FlipX = not ent.FlipX
				data.Velocity = Vector(-data.Velocity.X, data.Velocity.Y)
			end
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyClottigLogic, "clottig")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyClottigLogic, "clottig")

---------------------------------------СРЕДНЕРОСТНЫЙ ПОРТАЛ--------------------------------------------

Isaac_Tower.RegisterEnemy("mid portal", "gfx/it_enemies/mid_portal.anm2", Vector(15,15), {EntityCollision = 0})
Isaac_Tower.editor.AddEnemies("mid portal", 
	GenSprite("gfx/it_enemies/mid_portal.anm2","editor",nil,nil,Vector(13,13)), 
	"mid portal",0,  
	GenSprite("gfx/it_enemies/mid_portal.anm2","editor",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	--ent.PositionOffset = Vector(0,25)
	ent:GetSprite().Offset = Vector(0,25) / Wtr
	ent.DepthOffset = -70  -- -13
	local d = ent:GetData().Isaac_Tower_Data
	local x,y = d.SpawnXY.X, d.SpawnXY.Y
	for i,k in pairs(Isaac_Tower.EnemyHandlers.GetRoomEnemies(true)) do
		--if k:GetData().Isaac_Tower_Data then
			--print(i,k.Variant, k:GetData().Isaac_Tower_Data.SpawnXY, ent:GetData().Isaac_Tower_Data.SpawnXY)
		--end
		local xs,ys = k:GetData().Isaac_Tower_Data.SpawnXY.X,k:GetData().Isaac_Tower_Data.SpawnXY.Y
		if x==xs and y-1==ys then
			local off = Isaac_Tower.EnemyHandlers.Enemies[k:GetData().Isaac_Tower_Data.Type]
			d.SpawnTarget = {Name = k:GetData().Isaac_Tower_Data.Type, ST = k.SubType, Off = off.spawnOffset-5}
			ent.Target = k
			k:GetData().Isaac_Tower_Data.NoPersist = true
		end
	end
end, "mid portal")

function Isaac_Tower.ENT.LOGIC.midportalLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	--for i,k in pairs(data.SpawnTarget) do
	--	print(i,k)
	--end
	if data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE and
		(not ent.Target or ent.Target.Variant ~= Isaac_Tower.ENT.Enemy.VAR) then
		if not spr:IsPlaying("spawn") then
			SetState(data,2) --data.State = 2
			spr:Play("spawn")
		end
	elseif data.State == 2 then
		if spr:IsFinished("stopping") then
			SetState(data,Isaac_Tower.EnemyHandlers.EnemyState.IDLE) --data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			spr:Play("idle")
		elseif spr:IsFinished("spawn") then
			spr:Play("spawn_loop")
		elseif spr:IsEventTriggered("spawn") then
			ent.Target = Isaac_Tower.Spawn(data.SpawnTarget.Name,data.SpawnTarget.ST,data.Position+Vector(0,data.SpawnTarget.Off),Vector(0,0),ent)
			ent:Update()
			ent.Target:SetColor(Color(118/255,71/255,173/255,1,117/255,71/255,173/255),20,-1,true,true)
			ent.Target:GetData().Isaac_Tower_Data.NoPersist = true
			data.deley = 60
		elseif data.deley then
			data.deley = data.deley - 1
			if data.deley <= 0 then
				spr:Play("stopping")
				data.deley = nil
			end
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.midportalLogic, "mid portal")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.midportalLogic, "mid portal")
function Isaac_Tower.ENT.LOGIC.midportalSave(_,ent)
	if ent.Target and ent.Target.Variant == Isaac_Tower.ENT.Enemy.VAR then
		local data = ent:GetData().Isaac_Tower_Data
		data.Restore_enemy = ent.Target:GetData().Isaac_Tower_Data.Position/1
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_PRE_SAVE, Isaac_Tower.ENT.LOGIC.midportalSave, "mid portal")
function Isaac_Tower.ENT.LOGIC.midportalRestore(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	if data.Restore_enemy and data.SpawnTarget then
		ent.Target = Isaac_Tower.Spawn(data.SpawnTarget.Name,data.SpawnTarget.ST,data.Restore_enemy,Vector(0,0),ent)
		ent.Target:GetData().Isaac_Tower_Data.NoPersist = true
		ent.Target:Update()
		data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_RESTORE, Isaac_Tower.ENT.LOGIC.midportalRestore, "mid portal")

---------------------------------------ЗЕВАКА--------------------------------------------

Isaac_Tower.RegisterEnemy("gaper", "gfx/it_enemies/it_gaper.anm2", Vector(20,25), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("gaper", 
	GenSprite("gfx/it_enemies/it_gaper.anm2","idle",nil,nil,Vector(13,13)), 
	"gaper",0,  
	GenSprite("gfx/it_enemies/it_gaper.anm2","idle",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	--ent.PositionOffset = Vector(0,3)
	ent:GetSprite().Offset = Vector(0,3) / Wtr
	ent:GetSprite().FlipX = ent:GetDropRNG():RandomInt(2)>0
end, "gaper")

local lvec,rvec = Vector(-7,0), Vector(7,0)
function Isaac_Tower.ENT.LOGIC.EnemyGaperLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround  then
			if data.State ~= 4 then
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(0,data.Velocity.Y))
			else
				data.Velocity = Vector(data.Velocity.X, math.min(0,data.Velocity.Y))
			end
		else
			data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+0.8))) or data.Velocity
		end
		
		if data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE then
			if data.State ~= 4 and data.InRage then
				SetState(data,4) --data.State = 4
				return
			end
			if not spr:IsPlaying("idle") then
				spr:Play("idle")
			end
			data.Delay = data.Delay and (data.Delay-1) or ent:GetDropRNG():RandomInt(60)+50
			if data.Delay<0 then
				SetState(data,2) --data.State = 2
			end

			for i=0, Isaac_Tower.game:GetNumPlayers() do
				local flayer = Isaac_Tower.GetFlayer(i)
				if flayer.Position:Distance(data.Position) < 200 then
					spr:Play("pre_attack")
					SetState(data,4) --data.State = 4
				end
			end
		elseif data.State == 2 then
			if data.State ~= 4 and data.InRage then
				SetState(data,4) --data.State = 4
				return
			end
			if spr:IsFinished(spr:GetAnimation()) then
				data.Delay = nil
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			elseif spr:IsPlaying("idle") then
				local anm = "idle" .. (ent:GetDropRNG():RandomInt(2)+1)
				spr:Play(anm)
			end

			for i=0, Isaac_Tower.game:GetNumPlayers() do
				local flayer = Isaac_Tower.GetFlayer(i)
				if flayer.Position:Distance(data.Position) < 200 then
					spr:Play("pre_attack")
					SetState(data,4) --data.State = 4
				end
			end
		elseif data.State == 4 then
			if spr:IsPlaying("idle") then
				SetState(data, Isaac_Tower.EnemyHandlers.EnemyState.IDLE)
				data.InRage = nil
				return
			end
			data.InRage = true
			--ent.Velocity = ent.Velocity * 0.8
			if spr:IsPlaying("stun") then
				spr:Play("attack")
			end
			if spr:IsFinished("pre_attack") then
				spr:Play("attack", true)
			elseif spr:IsPlaying("attack") then
				spr:Play("attack")
				local targetVel = Isaac_Tower.GerNearestFlayer(data.Position).Position.X<data.Position.X and lvec or rvec
				if ent.FrameCount%2==0 then
					data.Velocity = Vector(data.Velocity.X * 0.8, data.Velocity.Y) + targetVel * 0.2
				end
				local needRotate = math.abs(data.Velocity.X) < 0.001 and spr.FlipX or (data.Velocity.X < 0)
				if spr.FlipX ~= needRotate then
					spr:Play("rotat", true)
				end
				--spr.FlipX = math.abs(ent.Velocity.X) < 0.001 and spr.FlipX or (ent.Velocity.X < 0)
			elseif spr:IsFinished("attack") then
				spr:Play("attack", true)
			elseif spr:IsFinished("rotat") then
				spr.FlipX = not spr.FlipX
				spr:Play("attack", true)
			end
			--ent.Velocity = ent.Velocity * 0.8
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyGaperLogic, "gaper")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyGaperLogic, "gaper")

Isaac_Tower.EnemyHandlers.FlayerCollision["gaper"] = function(fent, ent, EntData)
	local spr = ent:GetSprite()
	local data = ent:GetData().Isaac_Tower_Data
	if spr:IsPlaying("attack") then
		local check
		if spr.FlipX then
			check = (data.Position.X-10) > fent.Position.X
		else
			check = (data.Position.X+10) < fent.Position.X
		end
		if check or ((data.Position.Y-5+6) < fent.Position.Y and (data.Position.Y+5+6) > fent.Position.Y) then
			if Isaac_Tower.FlayerHandlers.TryTakeDamage(fent, 0, 0, ent) then
				return true
			end
		end
	end
end

---------------------------------------ХОРХ--------------------------------------------

Isaac_Tower.RegisterEnemy("horh", "gfx/it_enemies/horh.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("horh",
	GenSprite("gfx/it_enemies/horh.anm2","чего",nil,2,Vector(13,13)),
	"horh",0,
	GenSprite("gfx/it_enemies/horh.anm2","чего",nil,2,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	--ent.PositionOffset = Vector(0,5)
	ent:GetSprite().Offset = Vector(0,5) / Wtr
end, "horh")

function Isaac_Tower.ENT.LOGIC.EnemyHorhLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		local target = Isaac_Tower.GerNearestFlayer(ent.Position)
		if data.State == Isaac_Tower.EnemyHandlers.EnemyState.STUN then
			if data.OnGround then
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(0,data.Velocity.Y))
			else
				data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+1.8))) or data.Velocity
				--if data.StateFrame == 0 then
				--	data.Velocity = data.Velocity * Vector(.1,1)
				--end
			end
		elseif data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE then
			if data.rage then
				SetState(data,3)
				Isaac_Tower.ENT.LOGIC.EnemyHorhLogic(nil,ent)
				return
			end
			if spr:GetAnimation() ~= "idle" and not spr:IsPlaying("ничего") then
				spr:Play("idle", true)
			end
			if target.Position:Distance(data.Position) < 300 and (target.Position:Distance(data.Position) < 200
			or Isaac_Tower.lineOnlyCheck(data.Position, target.Position, 40, 1)) then
				SetState(data,2)
			end
		elseif data.State == 2 then
			if data.rage then
				SetState(data,3)
				Isaac_Tower.ENT.LOGIC.EnemyHorhLogic(nil,ent)
				return
			end
			if spr:GetAnimation() == "idle" then
				spr:Play("а, чего кого", true)
			elseif spr:IsFinished("а, чего кого") then
				spr:Play("чего кого", true)
			end

			local dist = target.Position:Distance(data.Position)
			if (dist > 300 )--or not Isaac_Tower.lineOnlyCheck(ent.Position, target.Position, 40, 1)) 
			and data.StateFrame > 30 then
				SetState(data,1)
				spr:Play("ничего", true)
			elseif dist < 250 
			and Isaac_Tower.lineOnlyCheck(data.Position, target.Position, 40, 1)  then
				SetState(data,3)
			end
		elseif data.State == 3 then
			if not data.rage then
				data.rage = true
				spr:Play("shoot")
				data.delay = ent:GetDropRNG():RandomInt(41)+40
			end
			if spr:IsFinished("shoot") then
				spr:Play("чего")
			end
			local dist = target.Position:Distance(data.Position)
			if data.delay <= 0 and dist < 400 and Isaac_Tower.lineOnlyCheck(data.Position, target.Position, 40, 1) then
				data.delay = ent:GetDropRNG():RandomInt(41)+40
				spr:Play("shoot")
			end
			data.delay = data.delay - 1
		end
		local tarVel = Vector(0,0)
		local grid = Isaac_Tower.rayCast(data.Position,Vector(0,1),20,3)
		if grid then
			tarVel.Y = (((grid.Position+Vector(0,-45))-data.Position)/20).Y
		end
		data.Velocity = data.Velocity * 0.9 + tarVel * 0.1

		if ent.FrameCount%10==0 then
			local sw = Isaac.Spawn(Isaac_Tower.ENT.GIB.ID,Isaac_Tower.ENT.GIB.VAR,Isaac_Tower.ENT.GibSubType.BLOOD,
			data.Position+Vector(0,10),Vector((ent:GetDropRNG():RandomInt(21)-10)/10,0), ent)
			sw:Update()
			sw.DepthOffset = -40
			sw:GetData().ml = true
			sw:GetData().Color = nil
		end
		if spr:IsEventTriggered("shoot") then
			local tarvec = (target.Position-data.Position):Resized(11)
			local e = Isaac_Tower.EnemyHandlers.FireProjectile(0,0, data.Position, tarvec, ent)
			e:GetData().TSJDNHC_GridColl = 1
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyHorhLogic, "horh")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyHorhLogic, "horh")

---------------------------------------ПАУК С ЛИЦОМ ИСААКА | ТРИРЕ-------------------------------------------

Isaac_Tower.RegisterEnemy("trire", "gfx/it_enemies/trire.anm2", Vector(15,15), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("trire",
	GenSprite("gfx/it_enemies/trire.anm2","idle",nil,1,Vector(13,13)),
	"trire",0,
	GenSprite("gfx/it_enemies/trire.anm2","idle",nil,1,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent:GetSprite().Offset = Vector(0,-1) / Wtr
	ent:GetData().Isaac_Tower_Data.delay = ent:GetDropRNG():RandomInt(10)+30
end, "trire")
function Isaac_Tower.ENT.LOGIC.EnemyTrireLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		local target = Isaac_Tower.GerNearestFlayer(ent.Position)
		if data.OnGround  then
			if data.State ~= 3 then
				data.Velocity = Vector(data.Velocity.X*0.8, math.min(0,data.Velocity.Y))
			else
				data.Velocity = Vector(data.Velocity.X, math.min(0,data.Velocity.Y))
			end
		else
			data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+0.8))) or data.Velocity
		end
		if data.CollideWall and not data.OnGround and not data.CollideCeiling and data.State ~= 4 then
			data.Velocity.X = -data.TrueVelocity.X/2
			if data.refvelocity then
				data.refvelocity.X = -data.refvelocity.X/2
			end
		end
		if data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE then
			if target.Position.X - ent.Position.X > 0 then
				spr.FlipX = true
			else
				spr.FlipX = false
			end

			if spr:GetAnimation() ~= "idle" then
				spr:Play("idle", true)
			end
			data.delay = data.delay - 1
			if data.delay <= 0 and target.Position:Distance(data.Position)<350 then
				data.State = 2
				data.delay = ent:GetDropRNG():RandomInt(10)+30
			end
		elseif data.State == 2 then
			if target.Position.X - ent.Position.X > 0 then
				spr.FlipX = true
			else
				spr.FlipX = false
			end

			if spr:IsFinished("jump") then
				data.State = 3
				local vel = Vector( (target.Position.X-data.Position.X) / 20 , math.min(-5,target.Position.Y-data.Position.Y) / 6 )
				vel = Vector(math.max(9,math.abs(vel.X))*sign(vel.X), math.min(-1,vel.Y))
				--if not Isaac_Tower.lineOnlyCheck(data.Position, target.Position, 40, 1) then
				--	vel.Y = vel.Y - 3
				--end
				vel = Vector(vel.X, vel.Y-(math.abs(vel.X)+1)/2)
				if not Isaac_Tower.lineOnlyCheck(data.Position, target.Position, 40, 1) then
					vel.Y = vel.Y - 3
				end
				vel:Resize(math.min(15,vel:Length()))
				if not data.OnGround then
					vel = vel * 0.2
				end
				data.Velocity = vel
				data.refvelocity = vel
				spr:Play("up", true)
				data.grounding = 0
			elseif spr:GetAnimation() ~= "jump" then
				spr:Play("jump", true)
			end
		elseif data.State == 3 then
			data.refvelocity = data.refvelocity.Y<12 and (Vector(data.refvelocity.X, math.min(12, data.refvelocity.Y+0.8))) or data.refvelocity
			data.Velocity = data.refvelocity
			if data.Velocity.Y < 0 then
				if spr:GetAnimation() ~= "up" then
					spr:Play("up", true)
				end
			else
				if spr:GetAnimation() == "up" then
					spr:Play("transition", true)
				elseif spr:IsFinished("transition") then
					spr:Play("down", true)
				--elseif spr:GetAnimation() == "down" and data.OnGround then
				--	data.State = 4
				--	data.Velocity.Y = 0
				--	data.Velocity.X = data.refvelocity.X/2
				--	data.refvelocity = nil
				end
				if data.OnGround then
					data.State = 4
					data.Position.Y = data.Position.Y + data.Velocity.Y/3
					local grid = Isaac_Tower.rayCast(data.Position+Vector(0,0),Vector(0,1),5,3)
					if grid and not grid.slope then
						data.Position.Y = grid.CenterPos.Y-grid.Half.Y-data.Half.Y
					end
					data.Velocity.Y = 0
					data.Velocity.X = data.refvelocity.X/2
					data.refvelocity = nil
				end
			end

			SpawnAfterImage(spr, data.Position+data.Velocity, Color(1,0.5,0.5,0.4,0.4), 0.05, true)
			--SpawnAfterImage(spr, data.Position+data.Velocity/2, Color(2,0.5,0.5,0.4,0.2), 0.05, true)
		elseif data.State == 4 then
			if spr:IsFinished("fall") then
				data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			elseif spr:GetAnimation() ~= "fall" then
				spr:Play("fall", true)
			end
		end
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyTrireLogic, "trire")



Isaac_Tower.EnemyHandlers.FlayerCollision["trire"] = function(fent, ent, EntData)
	--local spr = ent:GetSprite()
	local data = ent:GetData().Isaac_Tower_Data
	if data.State == 3 and fent.State ~= "Захват" and fent.Velocity.Y < 3 then
		if Isaac_Tower.FlayerHandlers.TryTakeDamage(fent, 0, 0, ent) then
			return true
		end
	end
end

--------------------------------------ПИКАПЫ-БОНУСЫ----------------------------------------------

Isaac_Tower.RegisterBonusPickup("ScoreUp1", "gfx/it_picks/scoreUps.anm2", "2", Vector(1,1), {})
--Isaac_Tower.editor.AddBonusPickup("scoreUp1", GenSprite("gfx/it_picks/scoreUps.anm2"), "ScoreUp", ingridSpr, sizeTable)

function Isaac_Tower.ENT.LOGIC.BonusScoreUpSmolCollision(_, ent, bonus)
	Isaac_Tower.FlayerHandlers.RemoveInGridBonusPickup(bonus)
	Isaac_Tower.ScoreHandler.AddScore(10)
	local vel = ent:GetData().Isaac_Tower_Data.Velocity/2
	Isaac_Tower.ScoreHandler.SpawnRandomMultiEffect("gfx/it_picks/scoreUps.anm2", bonus.eff.."ef", bonus.Position, vel, 3, 10)
end
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.BONUSPICKUP_COLLISION,Isaac_Tower.ENT.LOGIC.BonusScoreUpSmolCollision,"ScoreUp1")
function Isaac_Tower.ENT.LOGIC.BonusScoreUpSmolInit(_, bonus)
	local rng = Isaac_Tower.LevelHandler:GetCurrentRoomData().rng
	local int = rng:RandomInt(4)+1
	bonus.Sprite:Play(int)
	bonus.eff = int
end
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.BONUSPICKUP_INIT,Isaac_Tower.ENT.LOGIC.BonusScoreUpSmolInit,"ScoreUp1")

Isaac_Tower.RegisterBonusPickup("ScoreUp2", "gfx/it_picks/scoreUps.anm2", "1big", Vector(2,2), {})

function Isaac_Tower.ENT.LOGIC.BonusScoreUpBigCollision(_, ent, bonus)
	Isaac_Tower.FlayerHandlers.RemoveInGridBonusPickup(bonus)
	Isaac_Tower.ScoreHandler.AddScore(50)
	local vel = ent:GetData().Isaac_Tower_Data.Velocity/2
	Isaac_Tower.ScoreHandler.SpawnRandomMultiEffect("gfx/it_picks/scoreUps.anm2", bonus.eff.."ef", bonus.Position, vel, 8, 20)
	local eff = Isaac.Spawn(1000,Isaac_Tower.ENT.GIB.VAR,Isaac_Tower.ENT.GibSubType.BONUS_EFFECT2, bonus.Position,Vector.Zero, nil)
	eff.DepthOffset = -250
	local spr = eff:GetSprite()
	spr.Offset = Vector(-13,-13)
	eff:GetData().offset = -spr.Offset
	spr:Load("gfx/it_picks/scoreUps.anm2", true)
	spr:Play(bonus.Sprite:GetAnimation()) --Таблицы нельзя удалить, поэтому это работает
	spr:SetFrame(bonus.Sprite:GetFrame())
end
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.BONUSPICKUP_COLLISION,Isaac_Tower.ENT.LOGIC.BonusScoreUpBigCollision,"ScoreUp2")
function Isaac_Tower.ENT.LOGIC.BonusScoreUpBigInit(_, bonus)
	local rng = Isaac_Tower.LevelHandler:GetCurrentRoomData().rng
	local int = rng:RandomInt(4)+1
	bonus.Sprite:Play(int.."big")
	bonus.eff = int
end
Isaac_Tower.AddDirectCallback(mod,Isaac_Tower.Callbacks.BONUSPICKUP_INIT,Isaac_Tower.ENT.LOGIC.BonusScoreUpBigInit,"ScoreUp2")

---------------------------------------ПУЛЬКИ------------------------------------

--blood
Isaac_Tower.RegisterProj(0, "gfx/009.000_projectile.anm2", 10, {HasTrailEffect = true})
function Isaac_Tower.ENT.LOGIC.BloodProjUpdate(_, ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if not ent.Child and data.Flags.HasTrailEffect then
		ent.Child = Isaac.Spawn(1000,EffectVariant.SPRITE_TRAIL,0,data.Position,Vector.Zero,ent)
		ent.Child:ToEffect():FollowParent(ent)
		ent.Child:ToEffect().MinRadius = 0.19

		local Fcolor = Color(1,1,1,2) --Color(0.26*2,0.18*2,0.25*2,1)
		Fcolor:SetColorize(0.56/2,0.18/2,0.25/2,1)
		ent.Child.Color = Fcolor -- Color(0.26,0.18,0.25,1)
	end
	if data.Flags.Gravity then
		local grav = data.Gravity == true and 0.8 or data.Gravity
		data.Velocity = data.Velocity.Y<12 and (Vector(data.Velocity.X, math.min(12, data.Velocity.Y+grav))) or data.Velocity
	end
	if ent:GetData().TSJDNHC_GridColl == 1 then
		if data.OnGround or data.CollideWall or data.CollideCeiling then
			Isaac.RunCallbackWithParam(Isaac_Tower.Callbacks.PROJECTILE_PRE_REMOVE, data.Type, ent)
			ent:Remove()
		end
	end
end
mod:AddCallback(Isaac_Tower.Callbacks.PROJECTILE_POST_UPDATE, Isaac_Tower.ENT.LOGIC.BloodProjUpdate, 0)
function Isaac_Tower.ENT.LOGIC.BloodProjInit(_, ent) --Зачем?
	local spr = ent:GetSprite()
	spr:Play("RegularTear6")
end
function Isaac_Tower.ENT.LOGIC.BloodProjRemove(_, ent)
	local data = ent:GetData().Isaac_Tower_Data
	Isaac.Spawn(1000,11,0,data.Position,Vector.Zero,ent)
	if ent.Child then ent.Child:Die() end
end
mod:AddCallback(Isaac_Tower.Callbacks.PROJECTILE_PRE_REMOVE, Isaac_Tower.ENT.LOGIC.BloodProjRemove, 0)






do	--player animations

	Isaac_Tower.FlayerHandlers.PlayerAnimManager.AddFile("main", "gfx/fakePlayer/player_main.anm2", 
	{
		"idle", "walk", "pre_run", "run", "run_change_dir", "walk_jump_up", "walk_jump_down",
		"duck_idle", "duck_move", "duck_roll", "grab", "stopping_run", "wall_climbing",
		"slide", "grab_down_appear", "grab_down_idle", "lunge_down", "grab_down_landing", 
		"pre_super_jump_appear", "pre_super_jump", "pre_super_jump_left", "pre_super_jump_right",
		"super_jump", "super_jump_collide", "super_jump_fall", "super_jump_landing", "attack_up",
		"attack_up_loop", "attack_up_end", "wall_climbing_land", "lunge_down_wall", "hit",
		"hitb", "poke", "superrun", "grab_air_start", "grab_air_loop", "grab_stop",
	})

	Isaac_Tower.FlayerHandlers.PlayerAnimManager.AddFile("grab", "gfx/fakePlayer/player_grab.anm2", 
	{
		"holding_idle", "holding_move", "holding_jump_up", "holding_jump_down", "holding_appear",
		"kick_hori", 
	}, "gfx/fakePlayer/player_sheet_grab_righthand.png")

end

end