-- Invoked by the optional isolated Windows integration profile, never packaged.
function Initialize()
    local root=SELF:GetOption('ProjectRoot')
    local testRoot=SELF:GetOption('TestRoot')
    local report=assert(io.open(testRoot..'results.txt','w'))
    local originalPrint=print
    print=function(message) report:write(tostring(message)..'\n'); report:flush() end
    local ok,err=pcall(function()
        -- spec.lua uses repository-relative paths.
        local nativeDofile=dofile
        dofile=function(p)
            if p:match('^skin/') then return nativeDofile(root..p) end
            return nativeDofile(p)
        end
        -- Persistence fixtures must also remain inside the workspace.
        local nativeOpen=io.open
        io.open=function(p,mode)
            if p:match('^tests/') or p:match('^missing%-directory/') then p=root..p end
            return nativeOpen(p,mode)
        end
        local nativeRemove=os.remove
        os.remove=function(p) return nativeRemove(root..p) end
        nativeDofile(testRoot..'Fixtures.lua')
        nativeDofile(root..'tests/spec.lua')
        nativeDofile(root..'tests/widget-spec.lua')
    end)
    if not ok then print('FAILED: '..tostring(err)) else print('Native Lua '.._VERSION..' test run completed.') end
    print=originalPrint
    report:close()
end
function Update() return 0 end
