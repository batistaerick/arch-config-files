#include <gdk/wayland/gdkwayland.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "focus-grab.h"

struct panel_grab {
    struct wl_display *display;
    struct wl_registry *registry;
    struct hyprland_focus_grab_manager_v1 *manager;
    struct hyprland_focus_grab_v1 *grab;
    void (*cleared)(void *);
    void *data;
};

static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version) {
    (void)version;
    struct panel_grab *state = data;
    if (!strcmp(interface, "hyprland_focus_grab_manager_v1")) {
        state->manager = wl_registry_bind(registry, name,
            &hyprland_focus_grab_manager_v1_interface, 1);
    }
}

static void global_remove(void *data, struct wl_registry *registry, uint32_t name) {
    (void)data; (void)registry; (void)name;
}

static const struct wl_registry_listener registry_listener = {global, global_remove};

static void cleared(void *data, struct hyprland_focus_grab_v1 *grab) {
    (void)grab;
    struct panel_grab *state = data;
    state->cleared(state->data);
}

static const struct hyprland_focus_grab_v1_listener grab_listener = {cleared};

void panel_grab_destroy(struct panel_grab *state) {
    if (!state) return;
    if (state->grab) hyprland_focus_grab_v1_destroy(state->grab);
    if (state->manager) hyprland_focus_grab_manager_v1_destroy(state->manager);
    if (state->registry) wl_registry_destroy(state->registry);
    wl_display_flush(state->display);
    free(state);
}

void *panel_grab_create(GdkSurface *surface, void (*callback)(void *), void *data) {
    if (!GDK_IS_WAYLAND_SURFACE(surface)) return NULL;
    struct panel_grab *state = calloc(1, sizeof(*state));
    if (!state) return NULL;
    state->display = gdk_wayland_display_get_wl_display(gdk_surface_get_display(surface));
    state->cleared = callback;
    state->data = data;
    state->registry = wl_display_get_registry(state->display);
    wl_registry_add_listener(state->registry, &registry_listener, state);
    if (wl_display_roundtrip(state->display) < 0 || !state->manager) {
        panel_grab_destroy(state);
        return NULL;
    }
    state->grab = hyprland_focus_grab_manager_v1_create_grab(state->manager);
    hyprland_focus_grab_v1_add_listener(state->grab, &grab_listener, state);
    hyprland_focus_grab_v1_add_surface(state->grab, gdk_wayland_surface_get_wl_surface(surface));
    hyprland_focus_grab_v1_commit(state->grab);
    wl_display_flush(state->display);
    return state;
}
