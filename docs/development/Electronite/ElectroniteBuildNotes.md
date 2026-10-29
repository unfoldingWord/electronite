# Electronite Build Notes

Electronite is a version of Electron that is patched to support rendering [graphite](https://github.com/silnrsi/graphite) enabled fonts.

Originally based on wiki notes for `electronite-v12.0.5` from: https://github.com/unfoldingWord/electronite/wiki

# Updating

When updating the code, the standard is to create new branches like `electronite-v44.9.3-beta`. These eventually get pushed up to the server and tagged for the release (e.g. `v44.9.3-graphite`).

## What Electronite Changes

The fork is deliberately thin - every piece has to be carried forward by hand at each Electron release:

| Piece | Location |
|---|---|
| graphite2 source and `setup_graphite` hook | `DEPS` |
| Chromium GN wiring, OTS table allow-list, and Graphite shaper selection | `patches/chromium/add_graphite.patch`, listed in `patches/chromium/.patches` |
| graphite2 C++ standards fixes | `patches/graphite2/add_graphite_cpp_std_iterator.patch`, listed in `patches/graphite2/.patches` |
| graphite2 patch target registration | `patches/config.json` |
| Record of all of the above | `electronite.patch` (in this folder) |

Both patches are applied by Electron's `patch_chromium` hook during `gclient sync`. Never apply them with a bare `git apply` from a build script - an uncommitted edit makes the next `gclient sync` fail with `You have uncommitted changes`.

## Graphite

For minor graphite updates you can simply change the version of graphite needed in `/DEPS`.

For example, this updates graphite from [1.3.13](https://github.com/silnrsi/graphite/releases/tag/1.3.13) to [1.3.14](https://github.com/silnrsi/graphite/releases/tag/1.3.14).
```diff
-'graphite_version': 'b45f9b271214b95f3b42e5c9863eae4b0bfb7fd7',
+'graphite_version': '92f59dcc52f73ce747f1cdc831579ed2546884aa',
```

If there are larger changes to the graphite API you may need to update `patches/graphite2/add_graphite_cpp_std_iterator.patch`.

## Patching Electron

The simplest way to update Electronite is to start from the new upstream Electron tag and carry the Electronite files forward. This avoids merge conflicts and an ugly commit history.

1. Run `make_new_electronite.sh` with the new Electron tag and the previous Electronite branch:
   ```
   ./make_new_electronite.sh v44.9.3 electronite-v39.2.6-beta [github-token]
   ```
   This creates `<tag>-electron` and `electronite-<tag>-beta`, carries forward this folder, `add_graphite.patch`, `patches/graphite2/`, `README-Electronite.md`, and `CLAUDE.md` (as `CLAUDE.oldElectronite.md`), adds a patched `electron.d.ts`, then commits and pushes.
2. Apply the `DEPS`, `patches/chromium/.patches`, and `patches/config.json` changes by hand, using `electronite.patch` as the reference.
3. Re-verify `add_graphite.patch` against the new Chromium - context and line numbers drift every roll. Check all of:
   - `third_party/harfbuzz/BUILD.gn` (this was `third_party/harfbuzz-ng` before Electron 44)
   - `third_party/blink/renderer/platform/fonts/web_font_decoder.cc` (OTS must keep the Graphite tables)
   - `third_party/blink/renderer/platform/fonts/shaping/harfbuzz_shaper.cc` (Blink must list `graphite2` as a shaper - since Chromium 152 Blink passes an explicit shaper list, and without `graphite2` in it Graphite is silently never used)

   Test with the tool the build uses: `git apply --check --verbose <patch>; echo "exit=$?"`.
4. Regenerate `electronite.patch` (see `CLAUDE.md`, "Regenerating electronite.patch").
5. Merge the Electronite sections of `CLAUDE.oldElectronite.md` into the new `CLAUDE.md`, then delete it.
6. Update the toolchain versions in the per-platform build notes (see `CLAUDE.md`, "Toolchain Requirements").
7. Build and test the Electronite branch (see below).
8. If everything is working properly, push the branch and tag the release using the proper naming convention, and create a new release based on your new tag with the compiled binaries attached to it.
9. Upload the patched `electron.d.ts` to the release as well for easy reference. See https://github.com/unfoldingWord-dev/electronite-cli/blob/master/README.md#development for details.

# Building

[Build Notes](ElectroniteCurrentVersionBuildNotes.md)

# Other Electronite Steps

Will need to update and publish these packages:
- https://github.com/unfoldingWord-dev/electronite-cli
    - look at the README.md
- https://github.com/unfoldingWord-box3/electronite-packager
    - this doesn't have notes yet - merge in the matching Electron release from upstream to update the version
