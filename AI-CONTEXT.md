# Caelestia Inferno dotfiles - AI & Developer Context

This document provides architectural context, dependency mappings, and design guidelines for developers and AI coding assistants working on the **Caelestia Inferno** repository.

---

## 🏗️ System Architecture

Caelestia Inferno is a highly optimized, premium Wayland-native desktop shell configuration running under **Hyprland** with a custom bottom taskbar powered by **Quickshell**.

```
                           +----------------------------------------+
                           |           Hyprland Compositor          |
                           +--------------------+-------------------+
                                                | (IPC / LayerShell)
                                                v
                           +--------------------+-------------------+
                           |           Quickshell Bar               |
                           +--------------------+-------------------+
                                                |
        +---------------------------------------+---------------------------------------+
        |                                       |                                       |
        v                                       v                                       v
+-------+-------+                       +-------+-------+                       +-------+-------+
|  LEFT WIDGETS |                       | CENTER WIDGET |                       | RIGHT WIDGETS |
| (Start Button |                       | (Active Window|                       | (Sys Tray, Vol|
| & Workspaces) |                       |   Task List)  |                       | Clock & Date) |
+-------+-------+                       +-------+-------+                       +-------+-------+
        | (Middle-Click)                                                                | (Scroll)
        v                                                                               v
+-------+-------+                                                               +-------+-------+
| Caelestia     |                                                               | Pipewire      |
| Settings      |                                                               | defaultAudio  |
| FloatingWindow|                                                               +---------------+
+-------+-------+
        | (Zenity Picker)
        v
+-------+-------+
| Custom Start  |
| Image Icon    |
+---------------+
```

---

## 📦 Dependency Registry

Any changes to core system components must be registered in the **`PKGBUILD`** metadata under the `depends` array. The following packages have been added for specific system-level design features:

1. **`zenity`** (System-level GTK File Selector):
   - **Purpose**: Opens the native GTK file selection dialog window when customizing the start button icon.
   - **Registry**: Declared in `PKGBUILD` dependencies list.
2. **`qt6-5compat`** (Qt 6 Compatibility Module):
   - **Purpose**: Provides `Qt5Compat.GraphicalEffects` (specifically `OpacityMask`) in QML for circular masking of the custom start button and preview icons.
   - **Registry**: Installed on Arch Linux systems as `qt6-5compat`.

---

## ⚙️ Custom Start Icon & Settings Implementation

A custom, glassmorphic settings panel is built into the Quickshell scope in `~/.config/quickshell/shell.qml`.

### Core Flow:
1. **Interactive Trigger**:
   - `startBtn`'s `MouseArea` captures `Qt.LeftButton` and `Qt.MiddleButton`.
   - **Left-Click**: Launches application search menu (`fuzzel`).
   - **Middle-Click**: Toggles visibility of the glassmorphic settings dialog (`settingsWindow` of type `FloatingWindow`).
2. **Zenity File Picking**:
   - Clicking **"Choose Image..."** launches:
     `zenity --file-selection --file-filter="Images | *.png *.jpg *.jpeg *.svg *.gif *.webp"`
   - On exit, `StdioCollector` trims the selected path.
   - A nested `Process` executes `cp <source_path> ~/.config/quickshell/custom_win_icon`.
3. **Real-time Image Cache-Busting**:
   - When the file copy finishes, a timestamp is appended to the file URL (`custom_win_icon?t=Date.now()`). This bypasses QML's internal image caching mechanism and forces the icon to update instantly in the UI.
4. **Circular Clipping (Masking)**:
   - If the custom icon file exists and loads successfully (`Image.Ready`), the default Nerd Font character (``) is hidden, and `OpacityMask` clips the custom image into a circular avatar matching your system design.
5. **Reset & Revert**:
   - Clicking **"Reset to Default"** runs `rm -f ~/.config/quickshell/custom_win_icon`, clears the source path, and restores the standard Windows logo instantly.

---

## 🎨 Theme Tokens & Custom Styling

We maintain a premium, dark-mode glassmorphic theme across all customized widgets:
- **Translucent Dark Panel**: `#a6141414` (Deep dark background with `0.65` opacity).
- **Glass highlight border**: `#1effffff` (Subtle top highlight to define panel edges).
- **Active Accents**: `#3b82f6` (System blue).
- **Secondary Gray / Subtexts**: `#9ca3af` / `#a6adc8`.
- **Workspace glow active / occupied / empty**: `#3b82f6` / `#b2ffffff` / `#4cffffff`.

---

## 🛠️ Testing & Verification Workflow

When making modifications to `shell.qml` or related configurations, run:
```bash
# Gracefully kill active quickshell processes and spawn a daemon in debug mode
qs kill || killall quickshell; sleep 0.2; quickshell -d
```
Alternatively, use the system keybinding:
- **`Ctrl+Super+Alt+R`**: Triggers `qs kill; sleep .1; quickshell -d` to restart the shell environment automatically.
