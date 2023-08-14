return function(mod)
    
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

    --mod:AddCallback(ModCallbacks.MC_PRE_OPENGL_RENDER, function(_, buffer, elements, shader, ctx)
        --if not Game():IsPaused() then return elements end
        --print(buffer, elements, shader, ctx)
        --[[if elements == 0 then 
            for i=0, #buffer - 1 do
                local vertex = buffer:GetVertex(i)
                --for i,k in pairs(getmetatable(vertex)) do
                --    print(i,k)
                --end
                local position = vertex.Position
                local mod = i % 3
                if mod == 0 then
                    --vertex.Color = Renderer.Vec4(vertex.Color.x, 0, 0, vertex.Color.w)
                elseif mod == 1 then
                    vertex.Color = Renderer.Vec4(0, vertex.Color.y, 0, vertex.Color.w)
                elseif mod == 2 then
                    vertex.Color = Renderer.Vec4(0, 0, vertex.Color.z, vertex.Color.w)
                end
            end
        end]]
    --end)

	local PAUSE_STATES = {
		--"RESUME" = 0
		--"IN_CONSOLE" = 1
		--"UNPAUSING" = 2
		--"IN_OPTIONS" = 3
		--"EXIT" = 4
		--"OPTIONS" = 5
		--"UNPAUSED" = 6

		--"IN_CONSOLE_FROM_RESUME" = 7
		--"IN_CONSOLE_FROM_OPTIONS" = 8
		--"IN_CONSOLE_FROM_EXIT" = 9
		[6] = {
			[ButtonAction.ACTION_PAUSE] = 0,
			[ButtonAction.ACTION_MENUBACK] = 0,
			[Keyboard.KEY_GRAVE_ACCENT] = 1,
		},
		[2] = {
			--[ButtonAction.ACTION_PAUSE] = 0,
		},
		[5] = {
			[ButtonAction.ACTION_PAUSE] = 2,
			[ButtonAction.ACTION_MENUBACK] = 2,
			[ButtonAction.ACTION_MENUCONFIRM] = 3,
			[ButtonAction.ACTION_MENUDOWN] = 0,
			[ButtonAction.ACTION_MENUUP] = 4,
			[Keyboard.KEY_GRAVE_ACCENT] = 8, --2
		},
		[0] = {
			[ButtonAction.ACTION_PAUSE] = 2,
			[ButtonAction.ACTION_MENUBACK] = 2,
			[ButtonAction.ACTION_MENUCONFIRM] = 2,
			[ButtonAction.ACTION_MENUDOWN] = 4,
			[ButtonAction.ACTION_MENUUP] = 5,
			[Keyboard.KEY_GRAVE_ACCENT] = 7, --2
		},
		[4] = {
			[ButtonAction.ACTION_PAUSE] = 2,
			[ButtonAction.ACTION_MENUBACK] = 2,
			[ButtonAction.ACTION_MENUDOWN] = 5,
			[ButtonAction.ACTION_MENUUP] = 0,
			[Keyboard.KEY_GRAVE_ACCENT] = 8, --2
		},
		[3] = {
			Ignore = ButtonAction.ACTION_PAUSE,
			[ButtonAction.ACTION_MENUBACK] = 5,
			[Keyboard.KEY_GRAVE_ACCENT] = 2,
		},
		[1] = {
			[ButtonAction.ACTION_PAUSE] = 1,
			[ButtonAction.ACTION_MENUBACK] = 6,
		},

		[7] = {
			[ButtonAction.ACTION_PAUSE] = 1,
			[ButtonAction.ACTION_MENUBACK] = 0,
		},
		[8] = {
			[ButtonAction.ACTION_PAUSE] = 1,
			[ButtonAction.ACTION_MENUBACK] = 5,
		},
		[9] = {
			[ButtonAction.ACTION_PAUSE] = 1,
			[ButtonAction.ACTION_MENUBACK] = 4,
		},
	}

	local wasPausedLastFrame = false
	local currentPauseState = 6

	local function UpdatePauseTrackingState()
		local isPaused = Isaac_Tower.game:IsPauseMenuOpen()
		local pausedLastFrame = wasPausedLastFrame
		wasPausedLastFrame = isPaused

		if not isPaused then
			currentPauseState = 6
			return
		elseif currentPauseState == 6 and pausedLastFrame then
			return
		end

		local cid = Isaac_Tower.game:GetPlayer(0).ControllerIndex

		if PAUSE_STATES[currentPauseState].Ignore and Input.IsActionTriggered(PAUSE_STATES[currentPauseState].Ignore, cid) then
			return
		end

		for buttonAction, state in pairs(PAUSE_STATES[currentPauseState]) do
			if type(buttonAction) == "number" and (Input.IsActionTriggered(buttonAction, cid) or Input.IsButtonTriggered(buttonAction, cid)) then
				currentPauseState = state
				return
			end
		end
	end

	Isaac_Tower.sprites.pausemenu = { bt = {}, dt = {}}
	Isaac_Tower.sprites.pausemenu.b = GenSprite("gfx/ui/isaac tower pausescreen.anm2", "Idle")
	Isaac_Tower.sprites.pausemenu.b:GetLayer(1):SetVisible(false)
	for i = 1,3 do
		Isaac_Tower.sprites.pausemenu.bt[i] = GenSprite("gfx/ui/isaac tower pausescreen.anm2", "Cursor",i-1)
		Isaac_Tower.sprites.pausemenu.bt[i].Color = Color(1,1,1,0)
		Isaac_Tower.sprites.pausemenu.dt[i] = GenSprite("gfx/ui/isaac tower pausescreen.anm2", "кнопочки",i-1)
	end
	Isaac_Tower.sprites.pausemenu.f = GenSprite("gfx/ui/isaac tower pausescreen.anm2", "fon")

	mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
		UpdatePauseTrackingState()
		--print(Isaac_Tower.game:GetPauseMenuState(), currentPauseState)
	end)

	local background = {
		size = Vector(100,100)
	}
	function Isaac_Tower.Renders.Pause_menu_backgroung1(size, Offset)
		local w,h = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
		local w1,h1 = w/5, h

		local x, y = math.ceil(w1/size.X) + 0, math.ceil(h1/size.Y) + 0
		local off = Vector(Offset.X%(size.X*2), Offset.Y%(size.Y*2))/2
		for i=0, x do
			for j=0, y do
				local rpos = Vector(i*size.X, j*size.Y) + off -size
				local crop = math.max(0, i*size.X+off.X-w1)
				Isaac_Tower.sprites.pausemenu.f:Render(rpos, nil, Vector(crop,0))
			end
		end
	end
	function Isaac_Tower.Renders.Pause_menu_backgroung2(size, Offset)
		local w,h = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
		local w1,h1 = w/5, h
		
		local x, y = math.ceil(w1/size.X) + 0, math.ceil(h1/size.Y) + 0
		local off = Vector(Offset.X%(size.X*2), Offset.Y%(size.Y*2))/2
		for i=0, x do
			for j=0, y do
				local rpos = Vector(i*size.X + w-w1, j*size.Y) + off -size
				local crop = math.max(0, (1-i)*size.X-off.X)
				Isaac_Tower.sprites.pausemenu.f:Render(rpos, Vector(crop,0))
			end
		end
	end


	local stateToCursor = {[0] = 2, [5] = 1, [4] = 3}
	local ColorDis = {
		[0] = Color(1,1,1,0), Color(1,1,1,1/5), Color(1,1,1,2/5), Color(1,1,1,3/5), Color(1,1,1,4/5), Color(1,1,1,1)
	}

	function mod.PauseScreenRender(_, body, doby)
		if not Isaac_Tower.InAction then return end
		local CenPos = Isaac_Tower.GetScreenCenter()+Vector(0,30)
		--UpdatePauseTrackingState()

		--print(body:GetFilename(), body:GetAnimation(),body:GetFrame())
		--print(doby:GetFilename(), doby:GetAnimation(),doby:GetFrame())
		--print(Isaac_Tower.game:GetPauseMenuState(), currentPauseState)
		--Isaac_Tower.RenderBlack(1)
		if Isaac_Tower.game:GetPauseMenuState() == 1 then
			if body:IsPlaying("Appear") then
				Isaac_Tower.sprites.pausemenu.b.Color = ColorDis[body:GetFrame()]
				Isaac_Tower.sprites.pausemenu.f.Color = ColorDis[body:GetFrame()]
			elseif body:IsPlaying("Dissapear") then
				Isaac_Tower.sprites.pausemenu.b.Color = ColorDis[5-body:GetFrame()]
				Isaac_Tower.sprites.pausemenu.f.Color = ColorDis[5-body:GetFrame()]
			end
			local num = Isaac.GetFrameCount()/2
			Isaac_Tower.Renders.Pause_menu_backgroung1(Vector(200,200), Vector(num,num))
			Isaac_Tower.Renders.Pause_menu_backgroung2(Vector(200,200), Vector(num,num)+CenPos)

			Isaac_Tower.sprites.pausemenu.b:Render(CenPos)
			for i=1,3 do
				if body:IsPlaying("Appear") then
					Isaac_Tower.sprites.pausemenu.dt[i].Color = ColorDis[body:GetFrame()]
				elseif body:IsPlaying("Dissapear") then
					Isaac_Tower.sprites.pausemenu.dt[i].Color = ColorDis[5-body:GetFrame()]
				end
				local spr = Isaac_Tower.sprites.pausemenu.bt[i]
				Isaac_Tower.sprites.pausemenu.dt[i]:Render(CenPos+Vector(0,-spr.Color.A*2))
				if stateToCursor[currentPauseState] == i then
					--local spr = Isaac_Tower.sprites.pausemenu.bt[i]
					local col = Color(1,1,1,math.max(0, math.min(1,spr.Color.A+0.1)))
					spr.Color = col
					spr:Render(CenPos+Vector(0,-spr.Color.A*2))
				else
					--local spr = Isaac_Tower.sprites.pausemenu.bt[i]
					local col = Color(1,1,1,math.max(0, math.min(1,spr.Color.A-0.1)))
					spr.Color = col
				end
			end
			return true
		elseif Isaac_Tower.game:GetPauseMenuState() == 2 then
			local num = Isaac.GetFrameCount()/2
			Isaac_Tower.Renders.Pause_menu_backgroung1(Vector(200,200), Vector(num,num))
			Isaac_Tower.Renders.Pause_menu_backgroung2(Vector(200,200), Vector(num,num)+CenPos)
		end
	end

	mod:AddCallback(ModCallbacks.MC_PRE_PAUSE_SCREEN_RENDER, mod.PauseScreenRender)

	function Isaac_Tower.MovementHandlers.GetGrabNullOffset(spr)
		return spr:GetNullFrame("hold"):GetPos()
	end

	function Isaac_Tower.GetClipBroad()
		return Isaac.GetClipboard()
	end

	function Isaac_Tower.editor.GetEnviAutoSpriteFormat(spr)
		if spr then
			local size, pivot, ofset = Vector(10, 10), Vector(0, 0), Vector(0, 0)
			for i = 0, spr:GetLayerCount() - 1 do
				local data = spr:GetLayer(i)
				local cache = spr:GetCurrentAnimationData():GetLayer(i):GetFrame(0)
				if cache then
					local wot = cache:GetPivot()
					local asize = Vector(cache:GetWidth(), cache:GetHeight())
					size = Vector(math.max(size.X, asize.X), math.max(size.Y, asize.Y))
					pivot = Vector(math.max(pivot.X, wot.X), math.max(pivot.Y, wot.Y))
				end
				ofset = data:GetPos()
			end
			return size, pivot, ofset
		end
	end

end