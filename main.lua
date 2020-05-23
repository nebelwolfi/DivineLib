local DivineLib;

DivineLib = {
    _NAME        = "DivineLib",
    _TYPE        = "lib",
    _URL         = "https://pixelbot.org/DivineLib/"
}

--[[module
    .load("DivineLib", "net")
    .update(
        DivineLib._NAME,
        DivineLib._TYPE,
        DivineLib._URL,
        function(didUpdate)
            if didUpdate then
                core.reload()
            end
        end
    )]]
    
setmetatable(DivineLib, {
    __index = function(_, b)
        return module.load("DivineLib", b)
    end
})

module.load("DivineLib", "graphics")
local m = menu("DivineLib", "DivineLib")
m:button("orb", "Enable Divine Orbwalker", "Load", function()
    module.load("DivineLib", "orb")
end)
m:boolean("auto", "Automatically load Orbwalker", false)
if (m.auto:get()) then
    module.load("DivineLib", "orb")
end

return DivineLib
