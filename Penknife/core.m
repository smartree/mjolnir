#import "lua/lauxlib.h"
#import "lua/lualib.h"

lua_State* PKLuaState;

/// === core ===
///
/// Core Penknife functionality.

static int core_exit(lua_State* L) {
    if (lua_toboolean(L, 2))
        lua_close(L);
    
    [[NSApplication sharedApplication] terminate: nil];
    return 0; // lol
}

static AXUIElementRef hydra_system_wide_element() {
    static AXUIElementRef element;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        element = AXUIElementCreateSystemWide();
    });
    return element;
}

/// core.setaccessibilitytimeout(sec)
/// Change the timeout of accessibility operations; may reduce sluggishness.
/// NOTE: this may be a dumb idea and might be removed before 1.0 is released.
static int core_setaccessibilitytimeout(lua_State* L) {
    float sec = luaL_checknumber(L, 1);
    AXUIElementSetMessagingTimeout(hydra_system_wide_element(), sec);
    return 0;
}

static luaL_Reg corelib[] = {
    {"exit", core_exit},
    {"setaccessibilitytimeout", core_setaccessibilitytimeout},
    {}
};

//    hydra_setup_handler_storage(L); // TODO: turn into core.addhandler(), and set it up in setup.lua etc...

void PKSetupLua(void) {
    lua_State* L = PKLuaState = luaL_newstate();
    luaL_openlibs(L);
    
    luaL_newlib(L, corelib);
    lua_setglobal(L, "core");
    
    luaL_dofile(L, [[[NSBundle mainBundle] pathForResource:@"setup" ofType:@"lua"] fileSystemRepresentation]);
}

void PKLoadModule(NSString* fullname) {
    lua_State* L = PKLuaState;
    lua_getglobal(L, "core");
    lua_getfield(L, -1, "_loadmodule");
    lua_remove(L, -2);
    lua_pushstring(L, [fullname UTF8String]);
    lua_call(L, 1, 0);
}
