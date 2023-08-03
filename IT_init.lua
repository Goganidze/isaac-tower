return function(mod) --, Isaac_Tower)

local Isaac = Isaac

local IsaacTower_GibVariant = Isaac.GetEntityVariantByName('PIZTOW Gibs')

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
	local fent = ent:GetData().TSJDNHC_FakePlayer or ent:GetData().Isaac_Tower_Data
	if fent and fent.CanBreakPoop then
		local gridType = grid.EditorType
		if fent.AttackAngle then
			local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			local GJG = math.floor(((fent.AttackAngle%360-TarAngle%360))-180)%360
			if math.abs(GJG-180) <= 45 then
				grid.HitAngle = TarAngle
				grid.HitPower = math.abs(fent.Velocity:Length())
				if ent:GetData().Isaac_Tower_Data then
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
			if ent:GetData().Isaac_Tower_Data then
				grid.HitPower = grid.HitPower / 4
			end
			
			grid.GridList:DestroyGrid(grid.XY)
			--grid.EditorType = gridType
			return true
		end
	end
end

local function stonePoopObsLogic(ent, grid)
	local fent = ent:GetData().TSJDNHC_FakePlayer or ent:GetData().Isaac_Tower_Data
	if fent and fent.CanBreakMetal then
		local gridType = grid.EditorType
		if fent.AttackAngle then
			local fentPos = fent.Position + Vector(10,0):Rotated(fent.AttackAngle)
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			local GJG = math.floor(((fent.AttackAngle%360-TarAngle%360))-180)%360
			if math.abs(GJG-180) <= 40 then
				grid.HitAngle = TarAngle
				grid.HitPower = math.abs(fent.Velocity:Length())
				if ent:GetData().Isaac_Tower_Data then
					grid.HitPower = grid.HitPower / 4
				end

				grid.GridList:DestroyGrid(grid.XY)
				---grid.EditorType = gridType
				return true
			end
		else
			local fentPos = fent.Position
			local TarAngle = math.floor((grid.CenterPos-fentPos):GetAngleDegrees())
			grid.HitAngle = TarAngle
			grid.HitPower = math.abs(fent.Velocity:Length())
			if ent:GetData().Isaac_Tower_Data then
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
TSJDNHC_PT.AddGridType("stone_poop_2x2", function(self, gridList)
	--self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","stone2x2")
	self.Sprite = GenSprite("gfx/fakegrid/grid2.anm2","stone2x2")
	if gridList.SpriteSheep then
		for layer = 0, self.Sprite:GetLayerCount()-1 do
			self.Sprite:ReplaceSpritesheet(layer, gridList.SpriteSheep)
		end
	end
	self.OnCollisionFunc = stonePoopObsLogic
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
end)
Isaac_Tower.editor.AddObstacle("stone_poop_2x2", "2x2", 
	GenSprite("gfx/fakegrid/poop_stone.anm2","2x2", Vector(1,1)), 
	{Collision = 1, Type = "stone_poop_2x2" }, 
	GenSprite("gfx/fakegrid/poop_stone.anm2","2x2"), Vector(2,2))

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
		local flayer = player:GetData().TSJDNHC_FakePlayer
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
				local offset = grid.pos - player:GetData().TSJDNHC_FakePlayer.Position
				Isaac_Tower.TransitionSpawnOffset = -offset
				Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
			end]]
		else
			local offset = grid.pos - player:GetData().TSJDNHC_FakePlayer.Position
			Isaac_Tower.TransitionSpawnOffset = -offset
			Isaac_Tower.RoomTransition(grid.TargetRoom, false, nil, grid.TargetName)
		end
	end
end
mod:AddCallback(Isaac_Tower.Callbacks.SPECIAL_POINT_COLLISION, Room_Transition_Collision, "Room_Transition")

mod:AddCallback(Isaac_Tower.Callbacks.PLAYER_OUT_OF_BOUNDS, function(_, ent)
	local Fpos = ent:GetData().TSJDNHC_FakePlayer.Position
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

for i=1,8 do
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

			--ЗНАК
Isaac_Tower.ENT.LOGIC = {}
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

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "sign")
mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemySignLogic, "signp")

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
				data.State = 2
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
mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.EnemyClottigLogic, "clottig")


---------------------------------------СРЕДНЕРОСТНЫЙ ПОРТАЛ--------------------------------------------

Isaac_Tower.RegisterEnemy("mid portal", "gfx/enemies/mid_portal.anm2", Vector(5,5), {EntityCollision = 0})
Isaac_Tower.editor.AddEnemies("mid portal", 
	GenSprite("gfx/enemies/mid_portal.anm2","editor",nil,nil,Vector(13,13)), 
	"mid portal",0,  
	GenSprite("gfx/enemies/mid_portal.anm2","editor",nil,nil,Vector(13/2,13/2)))

mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_INIT, function(_,ent)
	ent.PositionOffset = Vector(0,25)
	local d = ent:GetData().Isaac_Tower_Data
	local x,y = d.SpawnXY.X, d.SpawnXY.Y
	for i,k in pairs(Isaac_Tower.EnemyHandlers.GetRoomEnemies(true)) do
		--if k:GetData().Isaac_Tower_Data then
			--print(i,k.Variant, k:GetData().Isaac_Tower_Data.SpawnXY, ent:GetData().Isaac_Tower_Data.SpawnXY)
		--end
		local xs,ys = k:GetData().Isaac_Tower_Data.SpawnXY.X,k:GetData().Isaac_Tower_Data.SpawnXY.Y
		if x==xs and y-1==ys then
			d.SpawnTarget = {Name = k:GetData().Isaac_Tower_Data.Type, ST = k.SubType}
			ent.Target = k
		end
	end
end, "mid portal")

function Isaac_Tower.ENT.LOGIC.midportalLogic(_,ent)
	local data = ent:GetData().Isaac_Tower_Data
	local spr = ent:GetSprite()

	if data.State == Isaac_Tower.EnemyHandlers.EnemyState.IDLE and
		(not ent.Target or ent.Target.Variant ~= Isaac_Tower.ENT.Enemy.VAR) then
		if not spr:IsPlaying("spawn") then
			data.State = 2
			spr:Play("spawn")
		end
	elseif data.State == 2 then
		if spr:IsFinished("stopping") then
			data.State = Isaac_Tower.EnemyHandlers.EnemyState.IDLE
			spr:Play("idle")
		elseif spr:IsFinished("spawn") then
			spr:Play("spawn_loop")
		elseif spr:IsEventTriggered("spawn") then
			ent.Target = Isaac_Tower.Spawn(data.SpawnTarget.Name,data.SpawnTarget.ST,ent.Position,Vector(0,0),ent)
			ent:Update()
			ent.Target:SetColor(Color(118/255,71/255,173/255,1,117/255,71/255,173/255),20,-1,true,true)
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
mod:AddCallback(Isaac_Tower.Callbacks.ENEMY_POST_UPDATE, Isaac_Tower.ENT.LOGIC.midportalLogic, "mid portal")

end