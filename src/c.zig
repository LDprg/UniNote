const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cDefine("CIMGUI_USE_SDL3", "TRUE");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "TRUE");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
    @cInclude("cimgui_impl_sdlrenderer3.h");
});

pub usingnamespace c;
