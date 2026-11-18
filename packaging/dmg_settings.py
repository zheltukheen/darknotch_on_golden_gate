# dmgbuild settings for DarkNotch.
# Paths are injected by scripts/make-dmg.sh through -D defines.
import os

app = defines["app"]
readme = defines["readme"]
background = defines["background"]
filename = defines["filename"]
version = defines.get("version", "1.0.0")

volume_name = "DarkNotch " + version
format = "UDZO"

files = [app, readme]
symlinks = {"Applications": "/Applications"}

icon_locations = {
    os.path.basename(app): (180, 210),
    "Applications": (540, 210),
    os.path.basename(readme): (360, 350),
}

background = background
window_rect = ((220, 140), (720, 460))
default_view = "icon-view"
icon_size = 128
text_size = 14

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
