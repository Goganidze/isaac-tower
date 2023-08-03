return function(mod)
    
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

    function mod.PauseScreenRender(_, body, doby)
        if not Isaac_Tower.InAction then return end
        --print(body:GetAnimation(),body:GetFrame())
        --Isaac_Tower.RenderBlack(1)
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
            local size, pivot, ofset = Vector(10,10),Vector(0,0),Vector(0,0)
            for i=0, spr:GetLayerCount()-1 do
                local data = spr:GetLayer(i)
                local cache = spr:GetCurrentAnimationData():GetLayer(i):GetFrame(0)
                if cache then
                    local wot = cache:GetPivot()
                    local asize = Vector(cache:GetWidth(), cache:GetHeight())
                    size = Vector(math.max(size.X, asize.X),math.max(size.Y, asize.Y))
                    pivot = Vector(math.max(pivot.X, wot.X),math.max(pivot.Y, wot.Y))
                end
                ofset = data:GetPos()
            end
            return size, pivot, ofset
        end
    end

end