# Electronite Build Notes

Electronite is a version of Electron that is patched to support rendering [graphite](https://github.com/silnrsi/graphite) enabled fonts.

Originally based on wiki notes for `electronite-v12.0.5` from: https://github.com/unfoldingWord/electronite/wiki

# Building

- [Windows build notes](WindowsBuildNotes.md)
- [MacOS build notes](MacBuildNotes.md)
- [Linux build notes](LinuxBuildNotes.md)

Copy `electronite-tools-4.sh` (or `electronite-tools-4.bat` on Windows) into an empty build folder with 150GB+ free. Version 4 is required for `electronite-v44.9.3-beta` - older versions apply the graphite2 patch by hand and will fail or skip it. Running the script without arguments will display the following commands which you will generally want to execute in order:
1. `get <ref>` fetches all of the code. Where `<ref>` is a branch or tag.
2. `build [target]` compiles Electronite for target (`x64` or `arm64`, default is `x64`)
3. `release [target]` creates the distributable (must match the build target)

To build every architecture for a platform in one run, use the scripts in `meta_builds/` (e.g. `build_all_mac.sh`, `build_all_linux.sh`, `build_all_win.bat`).

Also, you'll want to build code from a properly tagged release because [other tooling](https://github.com/topics/electronite) expects a specific naming convention.
When tagging a new release of Electronite use the same naming convention as Electron with the addition of a `-graphite` suffix. For example if Electron has a `v44.9.3` release, Electronite will have a corresponding `v44.9.3-graphite` release.

> Note: When building Electronite you will need to download about 20 gb of source code.

After running the above commands you will have a zipped file at `./src/out/Release-<target>/dist.zip`. You can rename this file and upload it as an artifact to the proper release on Github. Here's the naming convention:

* `electronite-<version>-win32-x64.zip`
* `electronite-<version>-win32-arm64.zip`
* `electronite-<version>-linux-x64.zip`
* `electronite-<version>-linux-arm64.zip`
* `electronite-<version>-darwin-x64.zip`
* `electronite-<version>-darwin-arm64.zip`

Where `<version>` is the tagged release without the `-graphite` suffix. e.g. `electronite-v44.9.3-linux-x64.zip`

> 32-bit Windows (`win32-ia32`) is no longer built starting with Electron 44 - upstream removed its PGO profile and no longer builds it.

> You must compile Electronite on a Linux, Windows, and macOS in order to generate the distributables above.
>  Cross compilation for different OS is not possible.

## Requirements

Chromium sets the toolchain, and it changes with every Chromium version. For `electronite-v44.9.3-beta` (Chromium `152.0.7977.167`):

* **macOS**: Xcode 26.6 with the macOS 26.5 SDK
* **Windows**: Visual Studio 2026 (18.x) with "Desktop development with C++" and MFC/ATL, Windows 11 SDK 10.0.26100.7705, and the SDK's "Debugging Tools for Windows"
* **Linux**: Ubuntu 22.04 or 24.04 (including Xubuntu 24.04); run `./src/build/install-build-deps.sh` after `get`
* **Node.js**: 22.12 or newer (Node 22.0 fails with `ERR_REQUIRE_ESM` while building `default_app.asar`)

See `CLAUDE.md`, "Toolchain Requirements", for how to look these up for a new Chromium version.

## Troubleshooting

#### Find the real build error
`ninja: build stopped: subcommand failed.` is only a summary. The real error is in the `FAILED:` block above it. Re-run the build to put it near the top, or search the log for `FAILED:`.

#### `Could not read file ... features.gni` or a PGO error naming `chrome/build/pgo_profiles`
The Chromium patches were never applied. Re-run `get` and read its output - an earlier failure stops the sync before patches are applied.

#### Windows: `UnicodeEncodeError: 'charmap' codec can't encode character`
Set `PYTHONUTF8=1` and `PYTHONIOENCODING=utf-8` before syncing. The v4 `.bat` scripts do this for you. In PowerShell use `$env:PYTHONUTF8 = "1"`, not `set`.

#### Windows: `dbghelp.dll not found`
Install the SDK's "Debugging Tools for Windows": Settings → Apps → Windows Software Development Kit → Modify → Change.

#### Delete cached repository
If you encounter errors while fetching the source code (this includes chromium) you may need to delete one of the cached repositories, or a lock file. Look through the console output to identify the repository that was being fetched when the download failed. Delete the identified repository from your `git_cache` and also delete any `.lock` files. Re-run the download and it should succeed.

#### Disable your VPN
This problem has only been seen on some Linux systems.
It is necessary to disable any active VPNs on the computer in order to successfully download the source code. If you do not, you may get errors about not being able to reach one of the source code servers. If this occurs, delete the affected cached repository if any and try again after turning off your VPN.

#### Select Xcode build tools

If you get an error like the following:
```
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

You need to select the Xcode application
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Help!

Check out this [Electronite playlist](https://www.youtube.com/playlist?list=PLf7IRQ2kP73kmC8y8gLQoHs4I26LzrRrq) on YouTube if you need some help using the scripts.

# Testing Graphite support in the Electronite build

A build that compiles does not prove Graphite works. Once you have a compiled Electronite binary you can test it by visiting this page https://graphite.sil.org/graphite_fontdemo#normal-truetype-font-loaded-from-a-server. Do this by:

* Run Electronite
* Open the developer console in the running Electronite instance (`Control-Shift-I`).
* execute `window.location="https://graphite.sil.org/graphite_fontdemo#normal-truetype-font-loaded-from-a-server"`
* Ensure all the tests pass by visually inspecting the rendered fonts and comparing against the image samples on the site.

## Troubleshooting

Some font elements need to be enabled via css flags, and these flags are specific to each browser.
On the test page mentioned above, the padauk font uses a Mozilla specific css flag, but since Electronite is based on chromium those don't work. Therefore, it is necessary to tweak the css a little.


```diff
.padauk_ttf {
  font-family: PadaukT, sans-serif;     
  font-size: 150%;
-  -moz-font-feature-settings: "wtri=1";
-  -moz-font-feature-settings: "wtri" 1;
+  font-feature-settings: "wtri" 1;
}
```

See [this issue](https://github.com/unfoldingWord/translationCore/issues/6879#issuecomment-624429380) for a detailed explanation.

If none of the Graphite fonts render correctly, check that `add_graphite.patch` still adds `graphite2` to the shaper lists in `harfbuzz_shaper.cc` (see [ElectroniteBuildNotes.md](ElectroniteBuildNotes.md), "Patching Electron").
