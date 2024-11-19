#ifndef IMGUI_DISABLE

struct SDL_Renderer;

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
CIMGUI_API bool     ImGui_ImplSDLRenderer3_Init(SDL_Renderer* renderer);
CIMGUI_API void     ImGui_ImplSDLRenderer3_Shutdown();
CIMGUI_API void     ImGui_ImplSDLRenderer3_NewFrame();
CIMGUI_API void     ImGui_ImplSDLRenderer3_RenderDrawData(ImDrawData* draw_data, SDL_Renderer* renderer);

// Called by Init/NewFrame/Shutdown
CIMGUI_API bool     ImGui_ImplSDLRenderer3_CreateFontsTexture();
CIMGUI_API void     ImGui_ImplSDLRenderer3_DestroyFontsTexture();
CIMGUI_API bool     ImGui_ImplSDLRenderer3_CreateDeviceObjects();
CIMGUI_API void     ImGui_ImplSDLRenderer3_DestroyDeviceObjects();

#endif // #ifndef IMGUI_DISABLE
