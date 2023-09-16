return function(mod) --, Isaac_Tower)

local Isaac = Isaac
local Vector = Vector
local Isaac_Tower = Isaac_Tower

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
	if not sprites[anim] then
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
	else
		return sprites[anim]
	end
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


for i=1,9 do
	Isaac_Tower.editor.AddGrid(tostring(i), tostring(i), GenSprite("gfx/fakegrid/grid2.anm2",tostring(i)), {Collision = 1, SpriteAnim = i })
end

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

TSJDNHC_PT.AddGridType("half", function(self, gridList)
	self.SpriteAnim = "half_up"
	self.CenterPos = Vector(self.CenterPos.X,self.CenterPos.Y-self.Half.Y/2)
	self.Half.Y = self.Half.Y/2
end)
Isaac_Tower.editor.AddGrid("half", "half_up", GenSprite("gfx/fakegrid/grid2.anm2", "half_up"), {Collision = 1, Type = "half" })

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
			local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
			local box1,box2 = {fentPos, fent.Half}, {grid.CenterPos, grid.Half}
			local hit = Isaac_Tower.NoType_intersectAABB(box1,box2)

			if hit then
				local result =  ang == 0 and hit.normal.X == 1
					or ang == 180 and hit.normal.X == -1
					or ang == 90 and hit.normal.Y == 1
					or ang == 270 and hit.normal.Y == -1
				--print(ang, hit.normal)
				if result then
					local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
					local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
					grid.HitAngle = TarAngle
					grid.HitPower = math.abs(fent.Velocity:Length())
					if not ent:ToPlayer() then
						grid.HitPower = grid.HitPower / 4
					end

					grid.GridList:DestroyGrid(grid.XY)
					---grid.EditorType = gridType
					return true
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

mod:AddCallback(Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, function(_, ent)
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
--[[Isaac_Tower.editor.AddSpecialEditData("Room_Transition", "Test4", 1, {HintText = "OnlyNumber Test", ResultCheck = function(info,result)
	if not result then
		return true
	else
		if not tonumber(result) then
			return GetStr("incorrectNumber")
		end
		return true
	end
end, onlyNumber = true})
Isaac_Tower.editor.AddSpecialEditData("Room_Transition", "Test5", 1, {HintText = "Text Test", ResultCheck = function(info,result)
	if not result then
		return true
	else
		if #result < 1 or not string.find(result,"%S") then
			return "emptyField"
		end
		return true
	end
end})]]


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
end})

function Trigger_Collision(_, player, grid)
	for i,k in pairs(grid) do
		print(i,k)
	end
end
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, Trigger_Collision, "trigger")


do
	local ignoreTypes = {spawnpoint_def=true,[""]=true,Room_Transition=true,spawnpoint=true}
	Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ROOM_LOADING, function(_,gridlist, newRoom, roomName, oldRoomName)
		if newRoom.Special then
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
					end
				end
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
end


--Isaac_Tower.editor.AddEnvironment("testpoop1", 
--	GenSprite("gfx/fakegrid/poop.anm2","2x2",Vector(0.8,0.8),nil,Vector(9,0)), 
--	function() return GenSprite("gfx/fakegrid/poop.anm2","2x2") end, 
--	GenSprite("gfx/fakegrid/poop.anm2","2x2", Vector(.5,.5)), 
--	Vector(57,96),
--	Vector(11,8))

--Isaac_Tower.editor.AddEnvironment("fisaac", 
--	GenSprite("gfx/fakePlayer/flayer.anm2","holding_move",Vector(0.8,0.8),nil,Vector(9,24)), 
--	function() return GenSprite("gfx/fakePlayer/flayer.anm2","holding_move") end, 
--	GenSprite("gfx/fakePlayer/flayer.anm2","holding_move", Vector(.5,.5)), 
--	Vector(40,50),
--	Vector(18,40))


-------------------------------------------------------------------ВРАГИ------------------------------------------------


Isaac_Tower.ENT.LOGIC = {}

								--ЗНАК
function Isaac_Tower.ENT.LOGIC.EnemySignLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround then
			if ent.Velocity.Y>5 then
				data.grounding = -1
				data.OnGround = nil
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(ent.Velocity.Y*-0.4,ent.Velocity.Y))
				--ent.Position = Vector(ent.Position.X ,ent.Position.Y + ent.Velocity.Y)
				ent:GetSprite().Rotation = -math.abs(ent.Velocity.X*ent.Velocity.Y/5)
				ent:GetSprite().Offset = Vector(ent:GetSprite().Rotation*.2,0)
			else
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(0,ent.Velocity.Y))
			end
		else
			ent.Velocity = ent.Velocity.Y<12 and (Vector(ent.Velocity.X, math.min(12, ent.Velocity.Y+0.8))) or ent.Velocity
		end
		if data.CollideCeiling and ent.Velocity.Y<0 then
			ent.Velocity = Vector(ent.Velocity.X, 0)
		end
	end
end

function Isaac_Tower.ENT.LOGIC.EnemySignRender(_,ent)
	if not Isaac_Tower.game:IsPaused() then
		local data = ent:GetData()
		if data.Isaac_Tower_Data.State >= 1 then
			if data.Isaac_Tower_Data.OnGround then
				ent:GetSprite().Rotation = -math.abs(ent.Velocity.X)
				ent:GetSprite().Offset = Vector(ent:GetSprite().Rotation*.2,0)
			else
				ent:GetSprite().Rotation = ent:GetSprite().Rotation * 0.9 + ent.Velocity.X*.1
				ent:GetSprite().Offset = Vector(ent.Velocity.X*.2,0)
			end
		end
	end
end

Isaac_Tower.RegisterEnemy("sign", "gfx/enemies/sign.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY, NoStun = true})
Isaac_Tower.RegisterEnemy("signp", "gfx/enemies/sign.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY, NoStun = true})
Isaac_Tower.editor.AddEnemies("sign", 
	GenSprite("gfx/enemies/sign.anm2","TrashCo w",nil,nil,Vector(13,13)), 
	"sign",0,  
	GenSprite("gfx/enemies/sign.anm2","TrashCo w",nil,nil,Vector(13/2,13/2)))
Isaac_Tower.editor.AddEnemies("signp", 
	GenSprite("gfx/enemies/sign.anm2","pooo",nil,nil,Vector(13,13)), 
	"signp",0,  
	GenSprite("gfx/enemies/sign.anm2","pooo",nil,nil,Vector(13/2,13/2)))

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

Isaac_Tower.RegisterEnemy("clottig", "gfx/enemies/clottig.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("clottig", 
	GenSprite("gfx/enemies/clottig.anm2","idle",nil,nil,Vector(13,13)), 
	"clottig",0,  
	GenSprite("gfx/enemies/clottig.anm2","idle",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent.PositionOffset = Vector(0,5)
end, "clottig")

function Isaac_Tower.ENT.LOGIC.EnemyClottigLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround then
			if ent.Velocity.Y>5 then
				data.grounding = -1
				data.OnGround = nil
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(ent.Velocity.Y*-0.4,ent.Velocity.Y))
				--ent.Position = Vector(ent.Position.X ,ent.Position.Y + ent.Velocity.Y)
			else
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(0,ent.Velocity.Y))
			end
		else
			ent.Velocity = ent.Velocity.Y<12 and (Vector(ent.Velocity.X, math.min(12, ent.Velocity.Y+0.8))) or ent.Velocity
		end
		if data.CollideCeiling and ent.Velocity.Y<0 then
			ent.Velocity = Vector(ent.Velocity.X, 0)
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
				ent.Velocity = ent.Velocity * 0.8 + targetVel * 0.2
			end
			if data.CollideWall then
				ent.FlipX = not ent.FlipX
				ent.Velocity = Vector(-ent.Velocity.X, ent.Velocity.Y)
			end
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyClottigLogic, "clottig")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyClottigLogic, "clottig")

---------------------------------------СРЕДНЕРОСТНЫЙ ПОРТАЛ--------------------------------------------

Isaac_Tower.RegisterEnemy("mid portal", "gfx/enemies/mid_portal.anm2", Vector(15,15), {EntityCollision = 0})
Isaac_Tower.editor.AddEnemies("mid portal", 
	GenSprite("gfx/enemies/mid_portal.anm2","editor",nil,nil,Vector(13,13)), 
	"mid portal",0,  
	GenSprite("gfx/enemies/mid_portal.anm2","editor",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent.PositionOffset = Vector(0,25)
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
			ent.Target = Isaac_Tower.Spawn(data.SpawnTarget.Name,data.SpawnTarget.ST,ent.Position+Vector(0,data.SpawnTarget.Off),Vector(0,0),ent)
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
		data.Restore_enemy = ent.Target.Position/1
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

Isaac_Tower.RegisterEnemy("gaper", "gfx/enemies/it_gaper.anm2", Vector(20,25), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("gaper", 
	GenSprite("gfx/enemies/it_gaper.anm2","idle",nil,nil,Vector(13,13)), 
	"gaper",0,  
	GenSprite("gfx/enemies/it_gaper.anm2","idle",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent.PositionOffset = Vector(0,3)
	ent:GetSprite().FlipX = ent:GetDropRNG():RandomInt(2)>0
end, "gaper")

local lvec,rvec = Vector(-7,0), Vector(7,0)
function Isaac_Tower.ENT.LOGIC.EnemyGaperLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		
		if data.OnGround  then
			if data.State ~= 4 then
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(0,ent.Velocity.Y))
			else
				ent.Velocity = Vector(ent.Velocity.X, math.min(0,ent.Velocity.Y))
			end
		else
			ent.Velocity = ent.Velocity.Y<12 and (Vector(ent.Velocity.X, math.min(12, ent.Velocity.Y+0.8))) or ent.Velocity
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
				if flayer.Position:Distance(ent.Position) < 200 then
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
				if flayer.Position:Distance(ent.Position) < 200 then
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
				local targetVel = Isaac_Tower.GerNearestFlayer(ent.Position).Position.X<ent.Position.X and lvec or rvec
				if ent.FrameCount%2==0 then
					ent.Velocity = Vector(ent.Velocity.X * 0.8, ent.Velocity.Y) + targetVel * 0.2
				end
				local needRotate = math.abs(ent.Velocity.X) < 0.001 and spr.FlipX or (ent.Velocity.X < 0)
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
	if spr:IsPlaying("attack") then
		local check
		if spr.FlipX then
			check = (ent.Position.X-10) > fent.Position.X
		else
			check = (ent.Position.X+10) < fent.Position.X
		end
		if check or ((ent.Position.Y-5+6) < fent.Position.Y and (ent.Position.Y+5+6) > fent.Position.Y) then
			if Isaac_Tower.FlayerHandlers.TryTakeDamage(fent, 0, 0, ent) then
				return true
			end
		end
	end
end

---------------------------------------ХОРХ--------------------------------------------

Isaac_Tower.RegisterEnemy("horh", "gfx/enemies/horh.anm2", Vector(20,20), {EntityCollision = EntityCollisionClass.ENTCOLL_PLAYERONLY})
Isaac_Tower.editor.AddEnemies("horh",
	GenSprite("gfx/enemies/horh.anm2","чего",nil,2,Vector(13,13)),
	"horh",0,
	GenSprite("gfx/enemies/horh.anm2","чего",nil,2,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent.PositionOffset = Vector(0,5)
end, "horh")

function Isaac_Tower.ENT.LOGIC.EnemyHorhLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()
	if data.State >= Isaac_Tower.EnemyHandlers.EnemyState.STUN then
		local target = Isaac_Tower.GerNearestFlayer(ent.Position)
		if data.State == Isaac_Tower.EnemyHandlers.EnemyState.STUN then
			if data.OnGround then
				ent.Velocity = Vector(ent.Velocity.X*0.8, math.min(0,ent.Velocity.Y))
			else
				ent.Velocity = ent.Velocity.Y<12 and (Vector(ent.Velocity.X, math.min(12, ent.Velocity.Y+1.8))) or ent.Velocity
				if data.StateFrame == 0 then
					ent.Velocity = ent.Velocity * Vector(.1,1)
				end
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
			if target.Position:Distance(ent.Position) < 300 and (target.Position:Distance(ent.Position) < 200
			or Isaac_Tower.lineOnlyCheck(ent.Position, target.Position, 40, 1)) then
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

			local dist = target.Position:Distance(ent.Position)
			if (dist > 300 )--or not Isaac_Tower.lineOnlyCheck(ent.Position, target.Position, 40, 1)) 
			and data.StateFrame > 30 then
				SetState(data,1)
				spr:Play("ничего", true)
			elseif dist < 250 
			and Isaac_Tower.lineOnlyCheck(ent.Position, target.Position, 40, 1)  then
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
			local dist = target.Position:Distance(ent.Position)
			if data.delay <= 0 and dist < 400 and Isaac_Tower.lineOnlyCheck(ent.Position, target.Position, 40, 1) then
				data.delay = ent:GetDropRNG():RandomInt(41)+40
				spr:Play("shoot")
			end
			data.delay = data.delay - 1
		end
		local tarVel = Vector(0,0)
		local grid = Isaac_Tower.rayCast(ent.Position,Vector(0,1),20,3)
		if grid then
			tarVel.Y = (((grid.Position+Vector(0,-45))-ent.Position)/20).Y
		end
		ent.Velocity = ent.Velocity * 0.9 + tarVel * 0.1

		if ent.FrameCount%10==0 then
			local sw = Isaac.Spawn(Isaac_Tower.ENT.GIB.ID,Isaac_Tower.ENT.GIB.VAR,Isaac_Tower.ENT.GibSubType.BLOOD,
				ent.Position+Vector(0,10),Vector((ent:GetDropRNG():RandomInt(21)-10)/10,0), ent)
			sw:Update()
			sw.DepthOffset = -40
			sw:GetData().ml = true
			sw:GetData().Color = nil
		end
		if spr:IsEventTriggered("shoot") then
			local tarvec = (target.Position-ent.Position):Resized(11)
			local e = Isaac_Tower.EnemyHandlers.FireProjectile(0,0, ent.Position, tarvec, ent)
			e:GetData().TSJDNHC_GridColl = 1
		end
	end
end
--mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyHorhLogic, "horh")
Isaac_Tower.AddDirectCallback(mod, Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyHorhLogic, "horh")

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
		ent.Child = Isaac.Spawn(1000,EffectVariant.SPRITE_TRAIL,0,ent.Position,Vector.Zero,ent)
		ent.Child:ToEffect():FollowParent(ent)
		ent.Child:ToEffect().MinRadius = 0.19

		local Fcolor = Color(1,1,1,2) --Color(0.26*2,0.18*2,0.25*2,1)
		Fcolor:SetColorize(0.56/2,0.18/2,0.25/2,1)
		ent.Child.Color = Fcolor -- Color(0.26,0.18,0.25,1)
	end
	if data.Flags.Gravity then
		local grav = data.Gravity == true and 0.8 or data.Gravity
		ent.Velocity = ent.Velocity.Y<12 and (Vector(ent.Velocity.X, math.min(12, ent.Velocity.Y+grav))) or ent.Velocity
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
	Isaac.Spawn(1000,11,0,ent.Position,Vector.Zero,ent)
	if ent.Child then ent.Child:Die() end
end
mod:AddCallback(Isaac_Tower.Callbacks.PROJECTILE_PRE_REMOVE, Isaac_Tower.ENT.LOGIC.BloodProjRemove, 0)

end