return function(mod)
    local Isaac = Isaac
    local Input = Input
    
    if Isaac.GetPlayer() then
        Isaac.ExecuteCommand("clearcache")
    end

    Isaac_Tower.MainMenu = {}
    local mm = Isaac_Tower.MainMenu
    mm.WGA = include("worst gui api")

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
            spr.PlaybackSpeed = .5
            return spr
        end
    end

    mm.sprs = {
        bg = GenSprite("gfx/ui/isaac tower/main menu.anm2", "bg"),
        tv = GenSprite("gfx/ui/isaac tower/main menu.anm2", "tv_off"),
        tv_light = GenSprite("gfx/ui/isaac tower/main menu.anm2", "tv_light"),
        logo = GenSprite("gfx/ui/isaac tower/main menu.anm2", "logo"),
        btn_start = GenSprite("gfx/ui/isaac tower/main menu.anm2", "menu_btn_start"),
        btn_options = GenSprite("gfx/ui/isaac tower/main menu.anm2", "menu_btn_options"),
        btn_exit = GenSprite("gfx/ui/isaac tower/main menu.anm2", "menu_btn_exit"),
    }
    local tar = GenSprite("gfx/1000.030_dr. fetus target.anm2", "Idle")
    tar.Scale = Vector(.2,.2)
    local sprs = mm.sprs

    sprs.btn_start.PlaybackSpeed = 1
    sprs.btn_start.Offset = Vector(-10,-30)
    sprs.btn_options.PlaybackSpeed = 1
    sprs.btn_options.Offset = Vector(-10,-10)
    sprs.btn_exit.PlaybackSpeed = 1
    sprs.btn_exit.Offset = Vector(-10,-15)


    mm.StateType = {
        PRE = 1,
        TURNON = 2,
        MAIN = 3,
        FADEOUT = 10,
    }

    
    mm.StateFrame = 0
    local z = Vector(0,0)
    mm.globalScale = Vector(1,1)
    mm.globalZero = Vector(0,0)
    local bgSizeZ = 500/300

    local preMousePos = Isaac.WorldToScreen(Input.GetMousePosition(true))-Isaac_Tower.game.ScreenShakeOffset

    function mm.MenuRender()
        if Isaac_Tower.GameState ~= 1 then return end
        local scrX, scrY = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
        local center = Vector(scrX/2, scrY/2)

        local bg = sprs.bg
        local tv = sprs.tv



        local scrsizeRas = scrX/scrY
        if scrsizeRas > bgSizeZ then
            local gs = 1+(scrX-500)/500
            mm.globalScale = Vector(gs,gs)
            local l = (scrY-300*gs - 100 * (scrsizeRas-bgSizeZ))/2
            mm.globalZero = Vector(0,l) 
        else
            local gs = 1+(scrY-300)/300
            mm.globalScale = Vector(gs,gs)
            local l = (scrX-500*gs)/2
            mm.globalZero = Vector(l,0) 
        end
        bg.Scale = mm.globalScale
        bg:Render(mm.globalZero)

        --tv.Scale = mm.globalScale
        --tv:Render(mm.globalZero)


        tar:Render(center)

        -------------------Update
        mm.StateFrame = mm.StateFrame + 1

        if mm.MenuLogic[mm.State] then
            mm.MenuLogic[mm.State](mm.globalZero, mm.globalScale, scrX, scrY)
        end


        ------------------ worst gui api
        local wma = mm.WGA

        if not Isaac_Tower.game:IsPaused() then
            if not wma.IsStickyMenu then
                wma.SelectedMenu = "__mainmenu"
            end
            wma.MouseHintText = nil

            local pos = Isaac.WorldToScreen(Input.GetMousePosition(true))-Isaac_Tower.game.ScreenShakeOffset
            if wma.ControlType == wma.enum.ControlType.CONTROLLER then
                print("gg", pos:Distance(preMousePos))
                if pos:Distance(preMousePos) > 3 then
                    wma.ControlType = wma.enum.ControlType.MOUSE
                end
            else
                local move = wma.input.GetRefMoveVector()
                print("mm", move)
                if move:Length() > .2 then
                    wma.ControlType = wma.enum.ControlType.CONTROLLER
                end
            end
            print("ttt",wma.ControlType)
            preMousePos = pos

            wma.MousePos = pos
            
            wma.DetectMenuButtons(wma.SelectedMenu)
            wma.RenderMenuButtons(wma.SelectedMenu)
            wma.HandleWindowControl()
            wma.RenderWindows()

            wma.DetectSelectedButtonActuale()
        else
            wma.RenderMenuButtons(wma.SelectedMenu)
            wma.RenderWindows()
        end

        if wma.MouseHintText then
            local pos = wma.MousePos
            --DrawStringScaledBreakline(font, Isaac_Tower.editor.MouseHintText, pos.X, pos.Y, 0.5, 0.5, Menu.wma.DefTextColor, 60, "Left")
            wma.RenderButtonHintText(wma.MouseHintText, pos+Vector(8,8))
        end

        wma.LastOrderRender()

    end
    mod:AddCallback(ModCallbacks.MC_HUD_RENDER or ModCallbacks.MC_POST_RENDER, mm.MenuRender)

    mm.Input = {}

    function mm.Input.IsActionPressed(act)
        for i=0, Isaac_Tower.game:GetNumPlayers()-1 do
            if Input.IsActionPressed(act, Isaac.GetPlayer(i).ControllerIndex) then
                return true
            end
        end
    end



    mm.SetState = function(state)
        mm.State = state
        mm.StateFrame = 0
    end

    mm.MenuLogic = {
        [mm.StateType.PRE] = function(zero, scale)
            local tv = sprs.tv
            tv.Scale = scale
            tv:Render(zero)

            local inp = mm.Input.IsActionPressed
            for i,k in pairs(ButtonAction) do
                if inp(k) then
                    mm.SetState(mm.StateType.TURNON)
                end
            end
        end,
        [mm.StateType.TURNON] = function(zero, scale)
            local tv = sprs.tv
            local logo = sprs.logo
            logo.Color = Color(1,1,1, mm.StateFrame / 80)

            if mm.StateFrame < 2 then
                tv:Play("tv_start", true)
            elseif tv:IsFinished() then
                tv:Play("tv_on", true)
                mm.SetState(mm.StateType.MAIN)
                logo.Color = Color(1,1,1,1)
                mm.ButtonOffset = Vector(100,0)

            end
            logo.Scale = scale
            logo:Render(Vector(zero.X,0))

            tv:Update()

            tv.Scale = scale
            tv:Render(zero)
        end,
        [mm.StateType.MAIN] = function(zero, scale, scrX, scrY)
            local logo = sprs.logo
            if mm.StateFrame%6 == 0 then
                logo.Color = Color(1,1,1, (math.sin(mm.StateFrame/2)+5)/7)
            end
            logo.Scale = scale
            logo:Render(Vector(zero.X,0))


            local tv_light = sprs.tv_light
            tv_light:Update()
            tv_light.Scale = scale
            tv_light:Render(zero)

            local tv = sprs.tv
            tv:Update()
            tv.Scale = scale
            tv:Render(zero)

            local btStartPos = Vector(scrX, scrY) + Vector(-170, -20)*scale + mm.ButtonOffset
            local ysi = scale.Y
            for i=1, #mm.menubtns.__mainmenu do
                ---@type EditorButton
                local btn = mm.menubtns.__mainmenu[i]
                btn.pos = btStartPos + Vector(0, i*-73*ysi)
                btn.x = 190 * scale.X
                btn.y = 70 * ysi
            end
            mm.ButtonOffset.X = mm.ButtonOffset.X * 0.8
        end,
    }




    if REPENTOGON then
        sprs.tv:GetLayer("tv"):SetRenderFlags(AnimRenderFlags.STATIC)
        sprs.tv:GetLayer("light"):SetRenderFlags(AnimRenderFlags.STATIC)
        sprs.tv:GetLayer("light"):GetBlendMode():SetMode(2)
        sprs.tv:GetLayer("tv_light"):GetBlendMode():SetMode(1)
        sprs.logo:GetLayer("logo"):GetBlendMode().Flag2 = 4  --:SetMode(2)
    end

    Isaac_Tower.QR = function ()
        for i,k in pairs(sprs) do
            k:Reset()
        end
    end

    mm.menubtns = {__mainmenu = {}}

    local nilspr = Sprite()
    ---@type EditorButton
    local self
    self = mm.WGA.AddButton("__mainmenu", "start", Vector(-200,0), 190, 70, nilspr , function(button) 
        if button ~= 0 then return end
    end, function(pos)
        sprs.btn_start:Update()
        if self.IsSelected then
            sprs.btn_start:Play("menu_btn_start")
        else
            sprs.btn_start:Play("menu_btn_start_r")
        end
        sprs.btn_start.Scale = mm.globalScale/1
        sprs.btn_start:Render(pos)
    end)
    mm.menubtns.__mainmenu[3] = self

    local self
    self = mm.WGA.AddButton("__mainmenu", "options", Vector(-200,0), 190, 70, nilspr , function(button) 
        if button ~= 0 then return end
    end, function(pos)
        sprs.btn_options:Update()
        if self.IsSelected then
            sprs.btn_options:Play("menu_btn_options")
        else
            sprs.btn_options:Play("menu_btn_options_r")
        end
        sprs.btn_options.Scale = mm.globalScale/1
        sprs.btn_options:Render(pos)
    end)
    mm.menubtns.__mainmenu[2] = self

    local self
    self = mm.WGA.AddButton("__mainmenu", "exit", Vector(-200,0), 190, 70, nilspr , function(button) 
        if button ~= 0 then return end
    end, function(pos)
        sprs.btn_exit:Update()
        if self.IsSelected then
            sprs.btn_exit:Play("menu_btn_exit")
        else
            sprs.btn_exit:Play("menu_btn_exit_r")
        end
        sprs.btn_exit.Scale = mm.globalScale/1
        sprs.btn_exit:Render(pos)
    end)
    mm.menubtns.__mainmenu[1] = self

end