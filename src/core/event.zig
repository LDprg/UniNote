//! Event enum translates SDL3 events to a custom event

const std = @import("std");

const c = @import("root").c;

/// Translate from SDL3 event to Event
pub fn fromSDL(e: *const c.SDL_Event) Event {
    return @as(Event, @enumFromInt(e.type));
}

pub const Event = enum(u32) {
    quit = c.SDL_EVENT_QUIT,
    terminating = c.SDL_EVENT_TERMINATING,
    low_memory = c.SDL_EVENT_LOW_MEMORY,
    will_enter_background = c.SDL_EVENT_WILL_ENTER_BACKGROUND,
    did_enter_background = c.SDL_EVENT_DID_ENTER_BACKGROUND,
    will_enter_foreground = c.SDL_EVENT_WILL_ENTER_FOREGROUND,
    did_enter_foreground = c.SDL_EVENT_DID_ENTER_FOREGROUND,
    locale_changed = c.SDL_EVENT_LOCALE_CHANGED,
    system_theme_changed = c.SDL_EVENT_SYSTEM_THEME_CHANGED,
    display_orientation = c.SDL_EVENT_DISPLAY_ORIENTATION,
    display_added = c.SDL_EVENT_DISPLAY_ADDED,
    display_removed = c.SDL_EVENT_DISPLAY_REMOVED,
    display_moved = c.SDL_EVENT_DISPLAY_MOVED,
    display_desktop_mode_changed = c.SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED,
    display_current_mode_changed = c.SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED,
    display_content_scale_changed = c.SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED,
    window_shown = c.SDL_EVENT_WINDOW_SHOWN,
    window_hidden = c.SDL_EVENT_WINDOW_HIDDEN,
    window_exposed = c.SDL_EVENT_WINDOW_EXPOSED,
    window_moved = c.SDL_EVENT_WINDOW_MOVED,
    window_resized = c.SDL_EVENT_WINDOW_RESIZED,
    window_pixel_size_changed = c.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
    window_metal_view_resized = c.SDL_EVENT_WINDOW_METAL_VIEW_RESIZED,
    window_minimized = c.SDL_EVENT_WINDOW_MINIMIZED,
    window_maximized = c.SDL_EVENT_WINDOW_MAXIMIZED,
    window_restored = c.SDL_EVENT_WINDOW_RESTORED,
    window_mouse_enter = c.SDL_EVENT_WINDOW_MOUSE_ENTER,
    window_mouse_leave = c.SDL_EVENT_WINDOW_MOUSE_LEAVE,
    window_focus_gained = c.SDL_EVENT_WINDOW_FOCUS_GAINED,
    window_focus_lost = c.SDL_EVENT_WINDOW_FOCUS_LOST,
    window_close_requested = c.SDL_EVENT_WINDOW_CLOSE_REQUESTED,
    window_hit_test = c.SDL_EVENT_WINDOW_HIT_TEST,
    window_iccprof_changed = c.SDL_EVENT_WINDOW_ICCPROF_CHANGED,
    window_display_changed = c.SDL_EVENT_WINDOW_DISPLAY_CHANGED,
    window_display_scale_changed = c.SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED,
    window_safe_area_changed = c.SDL_EVENT_WINDOW_SAFE_AREA_CHANGED,
    window_occluded = c.SDL_EVENT_WINDOW_OCCLUDED,
    window_enter_fullscreen = c.SDL_EVENT_WINDOW_ENTER_FULLSCREEN,
    window_leave_fullscreen = c.SDL_EVENT_WINDOW_LEAVE_FULLSCREEN,
    window_destroyed = c.SDL_EVENT_WINDOW_DESTROYED,
    window_hdr_state_changed = c.SDL_EVENT_WINDOW_HDR_STATE_CHANGED,
    key_down = c.SDL_EVENT_KEY_DOWN,
    key_up = c.SDL_EVENT_KEY_UP,
    text_editing = c.SDL_EVENT_TEXT_EDITING,
    text_input = c.SDL_EVENT_TEXT_INPUT,
    keymap_changed = c.SDL_EVENT_KEYMAP_CHANGED,
    keyboard_added = c.SDL_EVENT_KEYBOARD_ADDED,
    keyboard_removed = c.SDL_EVENT_KEYBOARD_REMOVED,
    text_editing_candidates = c.SDL_EVENT_TEXT_EDITING_CANDIDATES,
    mouse_motion = c.SDL_EVENT_MOUSE_MOTION,
    mouse_button_down = c.SDL_EVENT_MOUSE_BUTTON_DOWN,
    mouse_button_up = c.SDL_EVENT_MOUSE_BUTTON_UP,
    mouse_wheel = c.SDL_EVENT_MOUSE_WHEEL,
    mouse_added = c.SDL_EVENT_MOUSE_ADDED,
    mouse_removed = c.SDL_EVENT_MOUSE_REMOVED,
    joystick_axis_motion = c.SDL_EVENT_JOYSTICK_AXIS_MOTION,
    joystick_ball_motion = c.SDL_EVENT_JOYSTICK_BALL_MOTION,
    joystick_hat_motion = c.SDL_EVENT_JOYSTICK_HAT_MOTION,
    joystick_button_down = c.SDL_EVENT_JOYSTICK_BUTTON_DOWN,
    joystick_button_up = c.SDL_EVENT_JOYSTICK_BUTTON_UP,
    joystick_added = c.SDL_EVENT_JOYSTICK_ADDED,
    joystick_removed = c.SDL_EVENT_JOYSTICK_REMOVED,
    joystick_battery_updated = c.SDL_EVENT_JOYSTICK_BATTERY_UPDATED,
    joystick_update_complete = c.SDL_EVENT_JOYSTICK_UPDATE_COMPLETE,
    gamepad_axis_motion = c.SDL_EVENT_GAMEPAD_AXIS_MOTION,
    gamepad_button_down = c.SDL_EVENT_GAMEPAD_BUTTON_DOWN,
    gamepad_button_up = c.SDL_EVENT_GAMEPAD_BUTTON_UP,
    gamepad_added = c.SDL_EVENT_GAMEPAD_ADDED,
    gamepad_Removed = c.SDL_EVENT_GAMEPAD_REMOVED,
    gamepad_remapped = c.SDL_EVENT_GAMEPAD_REMAPPED,
    gamepad_touchpad_down = c.SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN,
    gamepad_touchpad_motion = c.SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION,
    gamepad_touchpad_up = c.SDL_EVENT_GAMEPAD_TOUCHPAD_UP,
    gamepad_sensor_update = c.SDL_EVENT_GAMEPAD_SENSOR_UPDATE,
    gamepad_updateComplete = c.SDL_EVENT_GAMEPAD_UPDATE_COMPLETE,
    gamepad_steam_handle_updated = c.SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED,
    finger_down = c.SDL_EVENT_FINGER_DOWN,
    finger_up = c.SDL_EVENT_FINGER_UP,
    finger_motion = c.SDL_EVENT_FINGER_MOTION,
    clipboard_update = c.SDL_EVENT_CLIPBOARD_UPDATE,
    drop_file = c.SDL_EVENT_DROP_FILE,
    drop_text = c.SDL_EVENT_DROP_TEXT,
    drop_begin = c.SDL_EVENT_DROP_BEGIN,
    drop_complete = c.SDL_EVENT_DROP_COMPLETE,
    drop_position = c.SDL_EVENT_DROP_POSITION,
    audio_device_added = c.SDL_EVENT_AUDIO_DEVICE_ADDED,
    audio_device_removed = c.SDL_EVENT_AUDIO_DEVICE_REMOVED,
    audio_device_format_changed = c.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED,
    sensor_update = c.SDL_EVENT_SENSOR_UPDATE,
    pen_proximity_in = c.SDL_EVENT_PEN_PROXIMITY_IN,
    pen_proximity_out = c.SDL_EVENT_PEN_PROXIMITY_OUT,
    pen_down = c.SDL_EVENT_PEN_DOWN,
    pen_up = c.SDL_EVENT_PEN_UP,
    pen_button_down = c.SDL_EVENT_PEN_BUTTON_DOWN,
    pen_button_up = c.SDL_EVENT_PEN_BUTTON_UP,
    pen_motion = c.SDL_EVENT_PEN_MOTION,
    pen_axis = c.SDL_EVENT_PEN_AXIS,
    camera_device_added = c.SDL_EVENT_CAMERA_DEVICE_ADDED,
    camera_device_removed = c.SDL_EVENT_CAMERA_DEVICE_REMOVED,
    camera_Device_approved = c.SDL_EVENT_CAMERA_DEVICE_APPROVED,
    camera_Device_denied = c.SDL_EVENT_CAMERA_DEVICE_DENIED,
    // render_targets_reset = c.SDL_EVENT_RENDER_TARGETS_RESET,
    // render_device_reset = c.SDL_EVENT_RENDER_DEVICE_RESET,
    // render_device_lost = c.SDL_EVENT_RENDER_DEVICE_LOST,
    // private0 = c.SDL_EVENT_PRIVATE0,
    // private1 = c.SDL_EVENT_PRIVATE1,
    // private2 = c.SDL_EVENT_PRIVATE2,
    // private3 = c.SDL_EVENT_PRIVATE3,
    poll_sentinel = c.SDL_EVENT_POLL_SENTINEL,
    user = c.SDL_EVENT_USER,
    last = c.SDL_EVENT_LAST,
    enum_padding = c.SDL_EVENT_ENUM_PADDING,
};
