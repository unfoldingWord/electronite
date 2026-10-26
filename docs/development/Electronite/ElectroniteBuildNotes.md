# Electronite Build Notes

Electronite is a version of Electron that is patched to support rendering [graphite](https://github.com/silnrsi/graphite) enabled fonts.

Based on wiki notes for `electronite-v12.0.5` from: https://github.com/unfoldingWord/electronite/wiki

# Updating

When updating the code, the standard is to create new branches like `electronite-v12.0.5`. These eventually get pushed up to the server and tagged for the release.

## Graphite

For minor graphite updates you can simply change the version of graphite needed in `/DEPS`.

For example, this updates graphite from [1.3.13](https://github.com/silnrsi/graphite/releases/tag/1.3.13) to [1.3.14](https://github.com/silnrsi/graphite/releases/tag/1.3.14).
```diff
-'graphite_version': 'b45f9b271214b95f3b42e5c9863eae4b0bfb7fd7',
+'graphite_version': '92f59dcc52f73ce747f1cdc831579ed2546884aa',
```

If there are larger changes to the graphite API you may need to do some patching in the Electron code see [[Graphite Patch]].

## Patching Electron

The simplest way to update Electronite is to pull down the branch from upstream and re-apply the [[Graphite Patch]]. This avoids merge conflicts and an ugly commit history.

Updating Electronite is pretty straight forward.
1. Get the version of Electron that you want to update to, e.g. `git checkout upstream v12.0.5`.
2. Create new electronite branch from Electron `git checkout -b electronite-v12.0.5`
3. Apply the [Graphite Patch](https://github.com/unfoldingWord/electronite/wiki/Graphite-Patch) `git am add-graphite-to-electron.patch` (you might need to manually apply it if there are conflicting changes from upstream).
4. Build and test the Electronite branch (see below).
5. If everything is working properly, push the branch and tag the release using the proper naming convention, and create a new release based on your new tag with the compiled binaries attached to it.
6. Upload a patched version of `electron.d.ts` to the release as well for easy reference. See https://github.com/unfoldingWord-dev/electronite-cli/blob/master/README.md#development for details.

# Building

[Build Notes](ElectroniteCurrentVersionBuildNotes.md)

# Other Electronite Steps

Will need to update and publish these packages:
- https://github.com/unfoldingWord-dev/electronite-cli
    - look at the README.md
- https://github.com/unfoldingWord-box3/electronite-packager
    - this doesn't have notes yet - for now just merged in master branch from Electron to update version to latest `15.4.0`
