[![Electron Logo](https://electronjs.org/images/electron-logo.svg)](https://github.com/unfoldingWord/electronite)

**Electronite** is a fork of **Electron** that is patched with [Graphite](https://github.com/silnrsi/graphite) support, so the complex scripts used by unfoldingWord's translation tools render correctly. Everything else is upstream Electron.

## What Electronite Adds

The fork is deliberately thin - every addition has to be carried forward by hand at each Electron release:

| Piece | Location |
|---|---|
| graphite2 source and `setup_graphite` hook | `DEPS` |
| Chromium GN wiring, OTS table allow-list, and Graphite shaper selection | `patches/chromium/add_graphite.patch` |
| graphite2 C++ standards fixes | `patches/graphite2/add_graphite_cpp_std_iterator.patch` |
| graphite2 patch target registration | `patches/config.json` |
| Record of all of the above | `docs/development/Electronite/electronite.patch` |

## Branches and Tags

- Working branches: `electronite-v<X.Y.Z>-beta`, one per Electron release
- Release tags: `v<X.Y.Z>-graphite` (Electron `v44.9.3` → `v44.9.3-graphite`)

## Building and Releasing

To build Electronite see the documents: `docs/development/Electronite/Creating A New Electronite Release <version>.*` for the steps in building, testing, and making a release.

Per-platform setup and build steps:

- `docs/development/Electronite/MacBuildNotes.md`
- `docs/development/Electronite/WindowsBuildNotes.md`
- `docs/development/Electronite/LinuxBuildNotes.md`

Release builds use `docs/development/Electronite/electronite-tools-4.sh` (or `.bat` on Windows), run from an empty build folder with 150GB+ free:

```
./electronite-tools-4.sh get electronite-v44.9.3-beta
./electronite-tools-4.sh build x64
./electronite-tools-4.sh release x64
```

`docs/development/Electronite/meta_builds/` has wrappers that build every architecture for a platform in one run. Each platform must be built on its own machine. Starting with Electron 44, 32-bit Windows (x86) is no longer built.

To start a new Electronite version from an Electron release, use `docs/development/Electronite/make_new_electronite.sh`.

## Testing Graphite

A build that compiles does not prove Graphite works. Launch the build, open the developer console (`Control-Shift-I`), and run:

```js
window.location = "https://graphite.sil.org/graphite_fontdemo#normal-truetype-font-loaded-from-a-server"
```

Compare the rendered fonts against the reference images on the page. The Padauk sample needs `font-feature-settings: "wtri" 1;` applied by hand in the Elements tab.

## Downstream

After a release, also update:

- [electronite-cli](https://github.com/unfoldingWord-dev/electronite-cli)
- [electronite-packager](https://github.com/unfoldingWord-box3/electronite-packager)
