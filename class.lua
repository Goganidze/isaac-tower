---@class Flayer
---@field GridPoints table
---@field InsideGridPoints table
---@field Position Vector
---@field Velocity Vector
---@field RunSpeed number
---@field Self EntityPlayer
---@field FrameCount integer
---@field TrueVelocity Vector
---@field Half Vector
---@field DefaultHalf Vector
---@field DefaultCroachHalf Vector
---@field CollisionOffset Vector
---@field CroachDefaultCollisionOffset Vector
---@field jumpDelay integer
---@field State any
---@field StateFrame integer
---@field JumpPressed integer
---@field CanJump boolean
---@field grounding integer
---@field Flayer Player_AnimManager
---@field PosRecord table
---@field UnStuck table
---@field CollideWall integer|nil
---@field OnGround boolean
---@field CollideCeiling boolean
---@field slopeAngle integer|nil
---@field LastVelocity Vector
---@field LastPosition Vector
---@field RepeatingNum integer
---@field slopeRot integer
---@field SmoothUp boolean
---@field OnAttack boolean
---@field Shadowposes table
---@field ControllerIndex integer
---@field JumpActive integer
---@field GrabPressed boolean
---@field AttackAngle number
---@field UseApperkot boolean
---@field PreviousState any
---@field InputWait integer
---@field InvulnerabilityFrames integer
---@field CutsceneLogic function|nil
---@field IngoneTransition integer|nil
---@field ForsedVelocity ForsedVelocity?
---@field UnStickWallVel Vector?
---@field UnStickWallTime integer

        
---@class FlayerSprites
---@field Sprite Sprite
---@field Queue integer|string
---@field SpeedEffectSprite Sprite
---@field RightHandSprite Sprite
---@field DefaultOffset Vector

---@class SpecialGrid
---@field Name string|nil
---@field Type any
---@field XY Vector
---@field pos Vector
---@field Size Vector|nil
---@field FrameCount integer
---@field TargetName any|nil
---@field Target any|nil
---@field TargetRoom any

---@class IT_RoomData
---@field rng RNG
---@field deco_rng RNG
---@field GridLists table
---@field EnemiesList table
---@field VisitCount integer
---@field FrameCount integer

---@class Player_AnimManager
---@field Sprs {[string]:Sprite}
---@field Queue string|integer?
---@field QueuePrior integer?
---@field SpeedEffectSprite Sprite
---@field RightHandSprs {[string]:Sprite}
---@field DefaultOffset Vector
---@field Shadow Sprite
---@field CurrentSpr Sprite?
---@field CurrentAnm2 string?
---@field CurrentRHSpr Sprite?
---@field Scale Vector
---@field Color Color
---@field FlipX boolean
---@field FlipY boolean
---@field Offset Vector
---@field Rotation number
---@field ReplaceOnce {["T"]:string, ["R"]:string}

---@class ForsedVelocity
---@field Lerp number,
---@field MaxTime integer,
---@field Time integer,
---@field Velocity Vector,
---@field noGrav boolean,