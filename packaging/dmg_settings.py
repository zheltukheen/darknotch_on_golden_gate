# dmgbuild settings for DarkNotch.
# Paths are injected by scripts/make-dmg.sh through -D defines.
import os

app = defines["app"]
install = defines["install"]
background = defines["background"]
filename = defines["filename"]
version = defines.get("version", "1.0.0")

volume_name = "DarkNotch " + version
format = "UDZO"

files = [app, install]
symlinks = {"Applications": "/Applications"}

icon_locations = {
    os.path.basename(app): (180, 210),
    "Applications": (540, 210),
    os.path.basename(install): (360, 350),
}

background = background
# The Finder draws the background inside the content area. On macOS 27 the
# chrome above it is 124 pt, so the window is 460 + 124 tall to keep the
# 720x460 background unscaled and the bottom hint visible.
window_rect = ((220, 140), (720, 584))
default_view = "icon-view"
icon_size = 128
text_size = 14

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
