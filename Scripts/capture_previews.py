#!/usr/bin/env python3
"""Capture light and dark screenshots of every registry item from the Showcase.

The Showcase's `-item <name>` launch renders one demo alone and writes the
demo's on-screen frame to the path given by `-capture-info`, so each capture
is cropped to the content instead of a whole phone screen. Images land in
`docs/images/items/<name>-<appearance>.png` at half resolution, ready for the
item metadata (`preview.screenshots`), the catalog, and the website.

Runs against the pinned simulator (`docs/visual-testing.md`) and drives it
through `xcrun simctl`, the batch-friendly path for forty-plus launches.

Usage (from the repository root):

    python3 Scripts/capture_previews.py            # every item, light and dark
    python3 Scripts/capture_previews.py badge card # a subset
    python3 Scripts/capture_previews.py --themes   # the theme presets page (or --themes Mango for one preset)
    python3 Scripts/capture_previews.py --scene mango-demo   # a Showcase scene that is not an item, into docs/images/themes
    python3 Scripts/capture_previews.py --ipad     # every item on the iPad, into docs/images/ipad
    python3 Scripts/capture_previews.py --blocks   # the blocks only, on the iPad, same folder
    python3 Scripts/capture_previews.py --preset a13GkaOXWwIa --output /tmp/presets  # one preset code, both appearances

`--app` points at a built SweetUIShowcase.app; without it the script
builds one with xcodebuild into a scratch derived-data directory. `--tool`
points at a built `sweetui` binary, which lists and validates the
items and checks a preset code; without it the script builds the tool in
release from this clone.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
import zlib
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent

REPOSITORY_ROOT = _SCRIPTS.parent
PINNED_UDID = "1807166B-C557-4F6B-B177-D5F3F701CBD7"
BUNDLE_ID = "com.example.sweetui.showcase"
WORKSPACE = REPOSITORY_ROOT / "Examples" / "Showcase" / "SweetUIShowcase.xcworkspace"
SCHEME = "SweetUIShowcase"
OUTPUT = REPOSITORY_ROOT / "docs" / "images" / "items"
THEME_OUTPUT = REPOSITORY_ROOT / "docs" / "images" / "themes"
IPAD_OUTPUT = REPOSITORY_ROOT / "docs" / "images" / "ipad"
# The iOS 27 iPad Pro 13-inch (M5) used for the iPad captures on this machine.
IPAD_UDID = "FF62F68C-7D96-4073-B0CC-865A9D3B0A41"
APPEARANCES = ("light", "dark")
THEME_PRESETS = ("System", "Graphite", "Indigo", "Rose", "Emerald", "Amber", "Mango")
# No top margin: the demo starts at the safe-area edge, right under the Dynamic Island.
TOP_MARGIN_POINTS = 0
BOTTOM_MARGIN_POINTS = 12


def run(command: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(command, check=True, capture_output=True, text=True, **kwargs)


def registry_tool(explicit: Path | None) -> Path:
    """The `sweetui` tool, built in release from this clone unless given."""
    if explicit:
        return explicit
    print("building sweetui...", flush=True)
    package = ["swift", "build", "--package-path", str(REPOSITORY_ROOT), "-c", "release"]
    run(package + ["--product", "sweetui"])
    return Path(run(package + ["--show-bin-path"]).stdout.strip()) / "sweetui"


def catalog(tool: Path) -> dict[str, str]:
    """Every item's kind by name, loaded through the tool's validated registry path."""
    process = subprocess.run(
        [str(tool), "search", "--registry", str(REPOSITORY_ROOT), "--format", "json"],
        capture_output=True, text=True,
    )
    if process.returncode != 0:
        raise RuntimeError(process.stderr.strip() or f"{tool} search exited {process.returncode}")
    return {item["name"]: item["kind"] for item in json.loads(process.stdout)}


def is_preset_code(tool: Path, code: str) -> bool:
    return subprocess.run([str(tool), "preset", "url", code], capture_output=True).returncode == 0


def build_app(derived_data: Path, udid: str) -> Path:
    print("building the Showcase...", flush=True)
    run([
        "xcodebuild",
        "-workspace", str(WORKSPACE),
        "-scheme", SCHEME,
        "-destination", f"id={udid}",
        "-derivedDataPath", str(derived_data),
        "-quiet",
        "build",
    ])
    products = derived_data / "Build" / "Products"
    apps = list(products.glob("*/SweetUIShowcase.app"))
    if not apps:
        raise RuntimeError(f"No built app under {products}")
    return apps[0]


def boot(udid: str) -> None:
    subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def first_pixel(path: Path) -> tuple[int, int, int]:
    """The top-left pixel of a PNG, decoded without an image library."""
    data = path.read_bytes()
    position = 8
    width = 0
    channels = 3
    compressed = b""
    while position < len(data):
        length = int.from_bytes(data[position:position + 4], "big")
        kind = data[position + 4:position + 8]
        body = data[position + 8:position + 8 + length]
        if kind == b"IHDR":
            width = int.from_bytes(body[0:4], "big")
            channels = 4 if body[9] == 6 else 3
        elif kind == b"IDAT":
            compressed += body
        elif kind == b"IEND":
            break
        position += 12 + length
    # The first byte of the row is its filter; every filter leaves the very
    # first pixel unchanged, so no reconstruction is needed for it.
    row = zlib.decompressobj().decompress(compressed, 1 + width * channels)
    return (row[1], row[2], row[3])


def pixel(path: Path, x: int, y: int, scratch: Path) -> tuple[int, int, int]:
    """One pixel of a PNG, cropped out with sips and decoded without an image library."""
    tiny = scratch / f"{path.stem}-pixel.png"
    run(["sips", str(path), "--cropToHeightWidth", "1", "1", "--cropOffset", str(y), str(x), "--out", str(tiny)])
    return first_pixel(tiny)


def shows_app_background(path: Path, appearance: str, scratch: Path) -> bool:
    """Whether a screenshot shows the app's own background at its leading
    edge, halfway down: white in light appearance, black in dark. The home
    screen wallpaper is neither. The corner pixel is not used because the
    simulator masks the display's rounded corners black."""
    height = int(next(
        line.split()[-1]
        for line in run(["sips", "-g", "pixelHeight", str(path)]).stdout.splitlines()
        if "pixelHeight" in line
    ))
    red, green, blue = pixel(path, 8, height // 2, scratch)
    if appearance == "dark":
        return max(red, green, blue) <= 8
    return min(red, green, blue) >= 245


def capture(
    udid: str,
    name: str,
    appearance: str,
    destination: Path,
    *,
    theme: str | None = None,
    preset: str | None = None,
    scratch: Path,
) -> None:
    info_path = scratch / f"{name}-{appearance}.json"
    raw_path = scratch / f"{name}-{appearance}-raw.png"
    info_path.unlink(missing_ok=True)

    run(["xcrun", "simctl", "ui", udid, "appearance", appearance])
    # The locale is part of the capture, not of the simulator: dates, currency,
    # and the calendar come out the same on any device the script is pointed at.
    launch = [
        "xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE_ID,
        "-item", name, "-appearance", appearance, "-capture-info", str(info_path),
        "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
    ]
    if theme:
        launch += ["-theme", theme]
    if preset:
        launch += ["-preset", preset]
    run(launch)

    deadline = time.monotonic() + 8
    while not info_path.exists() and time.monotonic() < deadline:
        time.sleep(0.1)
    if not info_path.exists():
        raise RuntimeError(f"{name} ({appearance}) never reported its frame; is the demo registered?")
    # Let the first layout pass, symbol effects, and the tab-less window settle.
    time.sleep(0.9)
    # The frame arrives at first layout, which on a cold launch (the first
    # after an install) can precede the app reaching the screen; a screenshot
    # taken then is the home screen. Accept a capture only when its top-left
    # pixel is the app's own background for the requested appearance.
    for _ in range(12):
        run(["xcrun", "simctl", "io", udid, "screenshot", "--type=png", str(raw_path)])
        if shows_app_background(raw_path, appearance, scratch):
            break
        time.sleep(0.5)
    else:
        raise RuntimeError(
            f"{name} ({appearance}) never reached the foreground; the screenshot is not the app"
        )

    info = json.loads(info_path.read_text())
    scale = info["scale"]
    screen = run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(raw_path)]).stdout
    pixel_width = int(next(line.split()[-1] for line in screen.splitlines() if "pixelWidth" in line))
    pixel_height = int(next(line.split()[-1] for line in screen.splitlines() if "pixelHeight" in line))

    top = max(0, int((info["y"] - TOP_MARGIN_POINTS) * scale))
    bottom = min(pixel_height, int((info["y"] + info["height"] + BOTTOM_MARGIN_POINTS) * scale))
    height = max(1, bottom - top)
    # sips crops around the center; offset it to the content's top edge.
    run([
        "sips", str(raw_path),
        "--cropToHeightWidth", str(height), str(pixel_width),
        "--cropOffset", str(top), "0",
        "--out", str(raw_path),
    ])
    destination.parent.mkdir(parents=True, exist_ok=True)
    run([
        "sips", str(raw_path),
        "--resampleWidth", str(pixel_width // 2),
        "--setProperty", "format", "png",
        "--out", str(destination),
    ])


def record_screenshots(names: list[str]) -> None:
    """Point each captured item's metadata at its images, then say what to regenerate."""
    for name in names:
        path = REPOSITORY_ROOT / "Registry" / "items" / f"{name}.json"
        item = json.loads(path.read_text(encoding="utf-8"))
        preview = item.setdefault("preview", {})
        preview["screenshots"] = [
            f"docs/images/items/{name}-{appearance}.png" for appearance in APPEARANCES
        ]
        path.write_text(json.dumps(item, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("metadata updated; run sweetui generate catalog, showcase-manifest, and site-data")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("items", nargs="*", help="Item names to capture (default: every item)")
    parser.add_argument("--udid", default=PINNED_UDID)
    parser.add_argument("--app", type=Path, help="A built SweetUIShowcase.app")
    parser.add_argument("--tool", type=Path, help="A built sweetui binary (default: swift build -c release from this clone)")
    parser.add_argument("--themes", action="store_true", help="Capture the theme presets instead of items")
    parser.add_argument("--ipad", action="store_true", help="Capture the named items (every item by default) on the iPad into docs/images/ipad")
    parser.add_argument("--blocks", action="store_true", help="Capture only the blocks on the iPad into docs/images/ipad (--ipad limited to blocks)")
    parser.add_argument("--scene", metavar="NAME", help="Capture a Showcase scene that is not an item (its -item route) into docs/images/themes")
    parser.add_argument("--preset", metavar="CODE", help="Capture the theme preview under a preset code instead of items")
    parser.add_argument("--output", type=Path, help="Folder for --preset captures; required with --preset")
    parser.add_argument("--no-metadata", action="store_true", help="Do not write preview.screenshots")
    arguments = parser.parse_args()

    try:
        tool = registry_tool(arguments.tool)
        kinds = catalog(tool)
    except subprocess.CalledProcessError as error:
        parser.error(error.stderr or str(error))
    except RuntimeError as error:
        parser.error(str(error))
    names = arguments.items or sorted(kinds)
    if arguments.themes:
        presets = arguments.items or list(THEME_PRESETS)
        unknown = [preset for preset in presets if preset not in THEME_PRESETS]
        if unknown:
            parser.error(f"unknown presets: {', '.join(unknown)} (known: {', '.join(THEME_PRESETS)})")
    elif not arguments.scene:
        unknown = [name for name in names if name not in kinds]
        if unknown:
            parser.error(f"unknown items: {', '.join(unknown)}")
    if arguments.preset and not is_preset_code(tool, arguments.preset):
        parser.error(f"invalid preset code: {arguments.preset}")
    if arguments.preset and arguments.output is None:
        parser.error("--preset needs --output")

    if (arguments.ipad or arguments.blocks) and arguments.udid == PINNED_UDID:
        arguments.udid = IPAD_UDID
    with tempfile.TemporaryDirectory() as directory:
        scratch = Path(directory)
        boot(arguments.udid)
        app = arguments.app or build_app(scratch / "DerivedData", arguments.udid)
        run(["xcrun", "simctl", "install", arguments.udid, str(app)])

        if arguments.ipad or arguments.blocks:
            targets = [name for name in names if kinds[name] == "block"] if arguments.blocks else names
            for name in targets:
                for appearance in APPEARANCES:
                    destination = IPAD_OUTPUT / f"{name}-ipad-{appearance}.png"
                    capture(arguments.udid, name, appearance, destination, scratch=scratch)
                    print(f"captured {destination.relative_to(REPOSITORY_ROOT)}")
        elif arguments.preset:
            for appearance in APPEARANCES:
                destination = arguments.output / f"preset-{arguments.preset}-{appearance}.png"
                capture(
                    arguments.udid, "theme-preview", appearance, destination,
                    preset=arguments.preset, scratch=scratch,
                )
                print(f"captured {destination}")
        elif arguments.scene:
            for appearance in APPEARANCES:
                destination = THEME_OUTPUT / f"{arguments.scene}-{appearance}.png"
                capture(arguments.udid, arguments.scene, appearance, destination, scratch=scratch)
                print(f"captured {destination.relative_to(REPOSITORY_ROOT)}")
        elif arguments.themes:
            for preset in presets:
                for appearance in APPEARANCES:
                    destination = THEME_OUTPUT / f"{preset.lower()}-{appearance}.png"
                    capture(
                        arguments.udid, "theme-preview", appearance, destination,
                        theme=preset, scratch=scratch,
                    )
                    print(f"captured {destination.relative_to(REPOSITORY_ROOT)}")
        else:
            for name in names:
                for appearance in APPEARANCES:
                    destination = OUTPUT / f"{name}-{appearance}.png"
                    capture(arguments.udid, name, appearance, destination, scratch=scratch)
                    print(f"captured {destination.relative_to(REPOSITORY_ROOT)}")
            if not arguments.no_metadata:
                record_screenshots(names)

        run(["xcrun", "simctl", "ui", arguments.udid, "appearance", "light"])
        subprocess.run(["xcrun", "simctl", "terminate", arguments.udid, BUNDLE_ID], capture_output=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        sys.stderr.write(error.stderr or str(error))
        raise SystemExit(1)
