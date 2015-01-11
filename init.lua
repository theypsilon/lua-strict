local env, main, mt

local function set_strict(environment, is_in_main)
    env, main = environment, is_in_main

    main = env == _G and main

    if type(env) ~= 'table' then error 'env must be a table' end

    mt = getmetatable(env)
    if mt == nil then
        mt = {}
        setmetatable(env, mt)
    else
        assert(not mt.__newindex)
        assert(not mt.__declared)
        assert(not mt.__index   )
    end

    mt.__declared = {}
    mt.__STRICT   = true

    function mt.__newindex(t, n, v)
        if mt.__STRICT and not mt.__declared[n] then
            local w = debug.getinfo(2, "S").what
            if not main or (w ~= 'main' and w ~= 'C') then
                error("assign to undeclared variable '"..n.."' in ", 2)
            end
            mt.__declared[n] = true
        end
        rawset(t, n, v)
    end
      
    function mt.__index(t, n)
        if mt.__STRICT and not mt.__declared[n] and 
        (not main or debug.getinfo(2, "S").what ~= "C") then
            error("variable '"..n.."' is not declared", 2)
        end
        return rawget(t, n)
    end
end

local function global(...)
    local params = {...}
    if params[1]  and  type(params[1]) == 'table' 
    then for k, v in  pairs(params[1]) do mt.__declared[k] = true; env[k] = v end
    else for _, v in ipairs(params)    do mt.__declared[v] = true end 
    end
end

local function defined (var) return mt.__declared[var] and rawget(env,var) ~= nil end
local function declared(var) return mt.__declared[var] end

return {
    set_strict = set_strict,
    global     = global,
    defined    = defined,
    declared   = declared
}