const c = @cImport({
    @cInclude("vulkan/vulkan.h");
    @cInclude("vk_mem_alloc.h");
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_vulkan.h");
    @cDefine("CIMGUI_USE_SDL3", "TRUE");
    @cDefine("CIMGUI_USE_VULKAN", "TRUE");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "TRUE");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl_sdl3.h");
    @cInclude("cimgui_impl_vulkan.h");
});

pub usingnamespace c;
