#ifdef CIMGUI_USE_SDL3

typedef struct SDL_Window SDL_Window;
typedef struct SDL_Renderer SDL_Renderer;
typedef struct SDL_Gamepad SDL_Gamepad;
struct SDL_Window;
struct SDL_Renderer;
struct SDL_Gamepad;
typedef union SDL_Event SDL_Event;
typedef enum { ImGui_ImplSDL3_GamepadMode_AutoFirst, ImGui_ImplSDL3_GamepadMode_AutoAll, ImGui_ImplSDL3_GamepadMode_Manual }ImGui_ImplSDL3_GamepadMode;

CIMGUI_API bool ImGui_ImplSDL3_InitForOpenGL(SDL_Window* window,void* sdl_gl_context);
CIMGUI_API bool ImGui_ImplSDL3_InitForVulkan(SDL_Window* window);
CIMGUI_API bool ImGui_ImplSDL3_InitForD3D(SDL_Window* window);
CIMGUI_API bool ImGui_ImplSDL3_InitForMetal(SDL_Window* window);
CIMGUI_API bool ImGui_ImplSDL3_InitForSDLRenderer(SDL_Window* window,SDL_Renderer* renderer);
CIMGUI_API bool ImGui_ImplSDL3_InitForOther(SDL_Window* window);
CIMGUI_API void ImGui_ImplSDL3_Shutdown(void);
CIMGUI_API void ImGui_ImplSDL3_NewFrame(void);
CIMGUI_API bool ImGui_ImplSDL3_ProcessEvent(const SDL_Event* event);
CIMGUI_API void ImGui_ImplSDL3_SetGamepadMode(ImGui_ImplSDL3_GamepadMode mode,SDL_Gamepad** manual_gamepads_array,int manual_gamepads_count);

#endif
