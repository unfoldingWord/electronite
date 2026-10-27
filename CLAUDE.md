# Electronite Development Guide

Electronite is unfoldingWord's fork of Electron, adding [Graphite](https://github.com/silnrsi/graphite) smart-font rendering to Chromium. Everything upstream Electron does still applies — this guide covers both, with Electronite-specific sections marked as such.

## Running node_modules binaries

**Never use `npx`.** It is considered dangerous because it can silently fetch and execute arbitrary packages from the registry. Always run binaries through one of these safer mechanisms instead:

1. **Preferred** — spawn the executable directly from `node_modules/.bin/<tool>` (or the platform equivalent on Windows). This is what `script/lint.js` does for `oxlint`.
2. **Acceptable** — invoke via `yarn <tool>` or `yarn run <tool>`, which resolves to the locally installed version without the registry fallback that `npx` performs.

This rule applies to shell commands you run yourself and to any scripts you author or modify in this repo.

## Project Overview

Electron is a framework for building cross-platform desktop applications using web technologies. It embeds Chromium for rendering and Node.js for backend functionality.

**Electronite** adds exactly one capability on top: Graphite font rendering, so the complex scripts used by unfoldingWord's translation tools render correctly. The fork is deliberately thin — a few `DEPS` entries plus two patches. Keep it that way; every addition has to be carried forward by hand at each Electron release.

| | |
|---|---|
| `origin` | `https://github.com/unfoldingWord/electronite.git` |
| `upstream` | `https://github.com/electron/electron.git` |
| Working branches | `electronite-v<X.Y.Z>-beta`, one per Electron release |
| Release tags | `v<X.Y.Z>-graphite` (Electron `v44.9.3` → `v44.9.3-graphite`) |
| This branch | `electronite-v44.9.3-beta`, Chromium `152.0.7977.167` (`DEPS:4-5`) |

Downstream consumers: [electronite-cli](https://github.com/unfoldingWord-dev/electronite-cli) and [electronite-packager](https://github.com/unfoldingWord-box3/electronite-packager) both need updating after a release.

## Directory Structure

```text
electron/                 # This repo (run `e` commands here)
├── shell/               # Core C++ application code
│   ├── browser/         # Main process implementation (107+ API modules)
│   ├── renderer/        # Renderer process code
│   ├── common/          # Shared code between processes
│   ├── app/             # Application entry points
│   └── services/        # Node.js service integration
├── lib/                 # TypeScript/JavaScript library code
│   ├── browser/         # Main process JS (47 API implementations)
│   ├── renderer/        # Renderer process JS
│   └── common/          # Shared JS modules
├── patches/             # Patches for upstream dependencies
│   ├── chromium/        # ~159 patches to Chromium
│   ├── node/            # ~48 patches to Node.js
│   └── ...              # Other targets (v8, boringssl, etc.)
├── spec/                # Test suite (1189+ TypeScript test files)
├── docs/                # API documentation and guides
│   └── development/Electronite/   # Electronite build scripts, notes, patches
│       ├── electronite-tools-3.*  # get / build / release driver scripts
│       ├── meta_builds/           # multi-target wrappers + S3 upload
│       ├── electronite.patch      # canonical record of the fork's delta
│       └── *BuildNotes.md         # per-platform setup notes
├── build/               # Build configuration
├── script/              # Build and automation scripts
└── chromium_src/        # Chromium source overrides
../                      # Parent directory is Chromium source
```

## Build Tools Setup

Electron uses `@electron/build-tools` for development. The `e` command is the primary CLI.

**Installation:**

```bash
npm i -g @electron/build-tools
```

**Configuration location:** `~/.electron_build_tools/configs/`

## Essential Commands

### Configuration Management

| Command | Purpose |
|---------|---------|
| `e init <name> --root=<path> --bootstrap testing` | Create new build config and sync |
| `e use <name>` | Switch to a different build configuration |
| `e show current` | Display active configuration name |
| `e show configs` | List all available configurations |

### Build & Development Loop

| Command | Purpose |
|---------|---------|
| `e sync` | Fetch/update all source code and apply patches |
| `e sync --3` | Sync with 3-way merge (required for Chromium upgrades) |
| `e build` | Build Electron (runs GN + Ninja) |
| `e build -k 999` | Build and continue on errors (up to 999) |
| `e build -t <target>` | Build specific target (e.g., `electron:node_headers`) |
| `e start` | Run the built Electron executable |
| `e start --version` | Verify Electron launches and print version |
| `e test` | Run the test suite |
| `e debug` | Run Electron in debugger (lldb on macOS, gdb on Linux) |

### Patch Management

| Command | Purpose |
|---------|---------|
| `e patches <target>` | Export patches for a target (chromium, node, v8, etc.) |
| `e patches all` | Export all patches from all targets |
| `e patches --list-targets` | List available patch targets |

## Typical Development Workflow

```bash
# 1. Ensure you're on the right config
e show current

# 2. Sync to get latest code
e sync

# 3. Make your changes in shell/ or lib/ or ../

# 4. Build
e build

# 5. Test your changes (Leave the user to do this, don't run these commands unless asked)
e start
e test

# 6. If you modified patched files in Chromium:
cd ..  # Go to Chromium repo
git add <files>
git commit -m "description of change"
cd electron
e patches chromium  # Export the patch
```

## Electronite Release Builds

Release binaries are **not** built with `e build`. They come from the standalone scripts in `docs/development/Electronite/`, which drive `gclient` and `ninja` directly. Copy the script for your platform into an empty build directory (needs 150GB+ free) and run, in order:

| Step | Command | Notes |
|---|---|---|
| Fetch | `./electronite-tools-3.sh get electronite-v44.9.3-beta` | ~20GB; hours on a cold git cache |
| Build | `./electronite-tools-3.sh build x64` | `arm64` also valid; default `x64` |
| Package | `./electronite-tools-3.sh release x64` | Must match the build target |

The distributable lands at `src/out/Release-<target>/dist.zip`. Rename for upload as `electronite-<version>-<platform>-<arch>.zip`, e.g. `electronite-v44.9.3-darwin-arm64.zip`. Cross-compiling across operating systems is not possible — each platform needs its own machine.

Script variants:

- `electronite-tools-3.sh` / `.bat` — current, uses Chromium build tools
- `electronite-tools-goma-3.*` — Goma-accelerated
- `electronite-tools-2.*`, `electronite-tools.*` — older, kept for reference
- `meta_builds/` — wrappers that chain every target and copy artifacts to S3

Per-platform setup lives in `WindowsBuildNotes.md`, `MacBuildNotes.md`, `LinuxBuildNotes.md`.

**Verifying Graphite actually works** — a build that compiles proves nothing about rendering. Launch the binary, open DevTools, and run:

```js
window.location = "https://graphite.sil.org/graphite_fontdemo.html"
```

Compare the rendered fonts against the reference images on the page. The Padauk sample needs `font-feature-settings: "wtri" 1;` applied by hand in DevTools — the page ships a Mozilla-only `-moz-font-feature-settings` flag that Chromium ignores.

## Cutting a New Electronite Release

`make_new_electronite.sh` rebases the fork onto a new Electron tag by carrying files forward rather than merging, which keeps the history clean:

```bash
./make_new_electronite.sh v44.9.3 electronite-v23.3.10 [github-token]
```

It stashes `docs/development/Electronite/` and `patches/chromium/add_graphite.patch` from the old branch, creates `<tag>-electron` and `electronite-<tag>-beta` from the upstream tag, restores those files, downloads `electron.d.ts` and rewrites `'electron` → `'electronite`, then commits and pushes.

What it does **not** do — these are manual:

1. Apply the `DEPS` and `patches/chromium/.patches` changes (see `electronite.patch`).
2. Re-verify `add_graphite.patch` against the new Chromium. Context and line numbers drift every roll.
3. Regenerate `docs/development/Electronite/electronite.patch` (see below).
4. Update the toolchain versions recorded in the `*BuildNotes.md` files.

## Graphite Integration

The fork's entire delta:

| Piece | Location | Applied by |
|---|---|---|
| graphite2 source dep | `DEPS` — `graphite_version`, `graphite_git`, `checkout_graphite`, `src/third_party/graphite/graphite2` | `gclient sync` |
| `setup_graphite` hook | `DEPS` → `pre_deps_hooks` | `gclient sync` |
| Chromium GN + OTS wiring | `patches/chromium/add_graphite.patch`, listed in `patches/chromium/.patches` | `patch_chromium` hook |
| graphite2 C++ standards fixes | `docs/development/Electronite/add_graphite_cpp_std_iterator.patch` | **manually**, by the build scripts |
| Record of all of the above | `docs/development/Electronite/electronite.patch` | reference only |

`graphite_version` is a commit SHA in `silnrsi/graphite`. A minor Graphite upgrade is just a hash bump in `DEPS`.

### The two patches are applied differently

`add_graphite.patch` goes through Electron's normal patch system — listed in `.patches`, applied to the **Chromium** repo by the `patch_chromium` hook.

`add_graphite_cpp_std_iterator.patch` is deliberately **not** in `.patches`. It targets `third_party/graphite/graphite2/`, a separate git repo cloned by gclient, which Electron's patch system cannot own. The build scripts apply it by hand from `src/`:

```bash
cd ./src
git apply --whitespace=warn ./electron/docs/development/Electronite/add_graphite_cpp_std_iterator.patch
```

Its `index` blob hashes belong to the graphite2 object database, not Chromium's, so a 3-way fallback only works from inside that repo:

```bash
cd src/third_party/graphite/graphite2
git apply -3 -p4 ../../../electron/docs/development/Electronite/add_graphite_cpp_std_iterator.patch
```

### Regenerating electronite.patch

`electronite.patch` records the fork's delta against a pristine Electron checkout. Its hunk line numbers and `index` hashes go stale whenever `DEPS` or `.patches` changes upstream, so regenerate rather than hand-editing. With the Electronite changes present as uncommitted edits to `DEPS` and `patches/chromium/.patches`:

```bash
git diff -U3 -- DEPS patches/chromium/.patches > /tmp/p1.diff
git diff --no-index /dev/null patches/chromium/add_graphite.patch > /tmp/p2.diff
cat /tmp/p1.diff /tmp/p2.diff > docs/development/Electronite/electronite.patch
```

Verify against pristine copies before trusting it — `add_graphite.patch` must be absent from the test tree, since the patch creates it:

```bash
mkdir -p /tmp/chk/patches/chromium
cp DEPS /tmp/chk/DEPS && cp patches/chromium/.patches /tmp/chk/patches/chromium/
git -C /tmp/chk init -q
git -C /tmp/chk apply --check -v $PWD/docs/development/Electronite/electronite.patch
```

## Toolchain Requirements

Electronite pins no toolchain — Chromium does, and the pin moves with every roll. For the current `chromium_version` (`152.0.7977.167`):

| Platform | Requirement |
|---|---|
| macOS | Xcode **26.6** (17F113) with macOS **26.5** SDK (25F70); `mac_sdk_min` 15; deployment target 13.0 |
| Windows | Visual Studio **2026** (18.x) with "Desktop development with C++" + MFC/ATL; Windows 11 SDK **10.0.26100.7705**; SDK **Debugging Tools for Windows** 10.0.26100.3323+ |

Re-derive after a Chromium roll — these are the authoritative sources:

```bash
V=$(grep -A1 "'chromium_version'" DEPS | tail -1 | tr -d " ',")
B="https://chromium.googlesource.com/chromium/src/+/$V"
curl -s "$B/build/mac_toolchain.py?format=TEXT"           | base64 -d | grep -i 'xcode .* sdk'
curl -s "$B/build/config/mac/mac_sdk.gni?format=TEXT"     | base64 -d | grep mac_sdk_official
curl -s "$B/build/vs_toolchain.py?format=TEXT"            | base64 -d | grep -E "^SDK_VERSION|'20"
curl -s "$B/docs/windows_build_instructions.md?format=TEXT" | base64 -d | sed -n '24,70p'
```

Caveats:

- Electron's own `docs/development/build-instructions-{macos,windows}.md` lag the Chromium roll. The Windows one still names VS 2019/2022, which will not build this branch. Chromium's docs win.
- The Electronite `.bat` scripts set `DEPOT_TOOLS_WIN_TOOLCHAIN=0`, so your locally installed VS and SDK are used. Electron CI sets it to `1` and uses Google's packaged toolchain — green CI says nothing about a local Windows build.
- `symstore.exe` from the SDK Debugging Tools is required to produce a full distribution.

## Patches System

Electron patches upstream dependencies (Chromium, Node.js, V8, etc.) to add features or modify behavior.

**How patches work:**

```text
patches/{target}/*.patch  →  [e sync --3]  →  target repo commits
                          ←  [e patches]   ←
```

**Patch configuration:** `patches/config.json` maps patch directories to target repos.

**Key rules:**

- Fix existing patches 99% of the time rather than creating new ones
- Preserve original authorship in TODO comments
- Never change TODO assignees (`TODO(name)` must retain original name)
- Each patch file includes commit message explaining its purpose

**Creating/modifying patches:**

1. Make changes in the target repo (e.g., `../` for Chromium)
2. Create a git commit
3. Run `e patches <target>` to export

**Fixing patch conflicts on an existing PR:**

If asked to fix a patch conflict on a branch that already has an open PR, check the PR's failed **Apply Patches** CI run for an `update-patches` artifact before running `e sync` locally. CI has already performed the 3-way merge and exported the resolved patch diff — applying it is much faster than a full local sync.

```bash
# Find the failed Apply Patches run for the PR and download the artifact
gh run list --repo electron/electron --branch <pr-branch> --workflow "Apply Patches" --limit 1
gh run download <run-id> --repo electron/electron --name update-patches

# Apply the CI-generated fix, then push
git am update-patches.patch
git push
```

If no artifact exists (e.g. the 3-way merge itself failed), fall back to `e sync --3` and resolve manually.

## Testing

**Test location:** `spec/` directory

**Running tests:**

```bash
e test                    # Run full test suite
```

**Test frameworks:** vitest (`describe`/`it`/`expect` imported from `vitest`; assertions use its matchers, `expect(x).toBe(y)`, never chai-style `.to.equal` chains), Sinon

## Build Configuration

**GN build arguments:** Located in `build/args/`:

- `testing.gn` - Debug/testing builds
- `release.gn` - Release builds
- `all.gn` - Common arguments for all builds

**Main build file:** `BUILD.gn`

**Feature flags:** `buildflags/buildflags.gni`

## Chromium Upgrade Workflow

When working on the `roller/chromium/main` branch to upgrade Chromium activate the "Electron Chromium Upgrade" skill.

## Node.js Upgrade Workflow

When working on the `roller/node/main` branch to upgrade Node.js activate the "Electron Node.js Upgrade" skill.

## Pull Requests

**Scope:** everything in this section applies to PRs opened against **upstream `electron/electron`**. Electronite's own branches live in `unfoldingWord/electronite`, target the `graphite` branch, and follow none of the `Notes:`/semver/backport conventions below.

PR bodies must always include a `Notes:` section as the **last line** of the body. This is a consumer-facing release note for Electron app developers — describe the user-visible fix or change, not internal implementation details. Use `Notes: none` if there is no user-facing change.

### PR Labeling (write-access only)

When the user has write access to `electron/electron`, add these labels when creating PRs:

**Semver label** — one of:

- `semver/none` — build changes, refactors, CI, or anything with no end-user impact
- `semver/patch` — backwards-compatible bug fixes
- `semver/minor` — backwards-compatible new functionality
- `semver/major` — incompatible API changes

**Backport target labels** — add `target/{N}-x-y` for each supported release branch the change should land on. Default policy:

- **Bug fixes** — backport to all active release lines _except the oldest_
- **Security fixes** — backport to all active release lines _including the oldest_
- **Features (semver/minor) and breaking changes (semver/major)** — no backport labels; main-only by default

To find which release branches are active, check label colors — active `target/*` labels use color `#ad244f`, older/EOL ones use `#ededed`:

```bash
gh label list --repo electron/electron --search target/ --json name,color --jq '.[] | select(.color == "ad244f") | .name'
```

## Code Style

**C++:** Follows Chromium style, enforced by clang-format
**TypeScript/JavaScript:** [oxlint](https://oxc.rs/docs/guide/usage/linter) configuration in `.oxlintrc.json`

**Linting:**

```bash
npm run lint              # Run all linters
npm run lint:js           # Run oxlint over all JS/TS/MJS sources
npm run lint:clang-format # C++ formatting
npm run lint:api-history  # Validate API history YAML blocks in docs
```

## Key Files

| File | Purpose |
|------|---------|
| `BUILD.gn` | Main GN build configuration |
| `DEPS` | Dependency versions and checkout paths |
| `patches/config.json` | Patch target configuration |
| `filenames.gni` | Source file lists by platform |
| `package.json` | Node.js dependencies and scripts |
| `patches/chromium/add_graphite.patch` | Graphite wiring into Chromium's GN + OTS |
| `docs/development/Electronite/electronite.patch` | Canonical record of the fork's delta |
| `docs/development/Electronite/add_graphite_cpp_std_iterator.patch` | graphite2 C++ fixes, applied manually |
| `docs/development/Electronite/electronite-tools-3.sh` / `.bat` | Release build driver |
| `docs/development/Electronite/make_new_electronite.sh` | Cuts a new Electronite branch from an Electron tag |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `GN_EXTRA_ARGS` | Additional GN arguments (useful in CI) |
| `ELECTRON_RUN_AS_NODE=1` | Run Electron as Node.js |

Set by the Electronite build scripts:

| Variable | Purpose |
|----------|---------|
| `DEPOT_TOOLS_WIN_TOOLCHAIN=0` | Windows: use the locally installed VS/SDK instead of Google's packaged toolchain |
| `GIT_CACHE_PATH` | Shared git cache, so a re-fetch doesn't re-download ~20GB |
| `CHROMIUM_BUILDTOOLS_PATH` | Points GN at `src/buildtools` |
| `NINJA_STATUS` | Progress format `[%r processes, %f/%t @ %o/s : %es]` |
| `BUILD_EXTRAS` | Passed through to ninja; set to `-vvvvv` for verbose build logging |

## Useful Git Commands for Chromium

```bash
# Find CL that changed a file
cd ..
git log --oneline -10 -- {file}
git blame -L {start},{end} -- {file}

# Look for Chromium CL reference in commit
git log -1 {commit_sha}  # Find "Reviewed-on:" line

# Find which patch affects a file
grep -l "filename.cc" patches/chromium/*.patch
```

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

- `build.yml` - Main build workflow
- `pipeline-electron-lint.yml` - Linting
- `pipeline-segment-electron-test.yml` - Testing

## Common Issues (Upstream Electron)

**Patch conflict during sync:**

- Use `e sync --3` for 3-way merge
- Check if file was renamed/moved upstream
- Verify patch is still needed

**Build error in patched file:**

- Find the patch: `grep -l "filename" patches/chromium/*.patch`
- Match existing patch style (#if 0 guards, BUILDFLAG conditionals, etc.)

**Remote build issues:**

- Try `e build --no-remote` to build locally
- Check reclient/siso configuration in your build config

## Common Issues (Electronite Builds)

**GN fails with `Unable to load ".../components/os_crypt/sync/features.gni"`**

Chromium patches were never applied. That file does not exist upstream — it is created by `patches/chromium/revert_oscrypt_remove_sync_backend.patch`. Re-run the sync and *read its output*: a failing entry in `pre_deps_hooks` aborts the whole sync before `patch_chromium` ever runs. Confirm these all exist before building again:

- `src/components/os_crypt/sync/features.gni`
- `src/build/util/LASTCHANGE.committime` (written by the `lastchange` hook)
- `src/electron/build/pgo_profiles/` (populated by the `electron_pgo_profiles_*` hooks)

**PGO error naming `chrome/build/pgo_profiles/chrome-<platform>-…profdata`**

Same root cause. `patches/chromium/build_resolve_pgo_profiles_from_electron_state_files.patch` redirects PGO resolution to Electron's own profiles; the Chrome path means it isn't applied. Do **not** follow the error's advice to set `checkout_pgo_profiles: True` — `DEPS` keeps it `False` deliberately.

**Windows: `dbghelp.dll not found in …\Windows Kits\10\Debuggers\x64\`**

The SDK "Debugging Tools for Windows" feature is missing. Settings → Apps → Windows Software Development Kit → Modify → Change → check Debugging Tools for Windows.

**`patch` succeeds but the build's `git apply` fails**

They are not equivalent. `patch` applies with fuzz and hunts for context at an offset; `git apply` demands exact context. Always test with the tool the build actually uses, and check the exit code:

```bash
git apply --check --verbose <patch>; echo "exit=$?"
```

To tell "already applied" apart from "context drifted":

```bash
git apply --reverse --check <patch>   # success ⇒ already applied
```

**`ninja: build stopped: subcommand failed.` with no visible error**

That is only the summary line. The real diagnostic is in the `FAILED:` block above it, often thousands of lines earlier under parallel jobs:

```bash
grep -n -A40 "FAILED:" <log>
```

Or just re-run the build — ninja is incremental and re-attempts only the failed edge, putting the error near the top of fresh output. Lines like `Target failed:` / `Distribution failed:` from the Electronite scripts are downstream noise.

## Known Issues in Electronite Tooling

- `MacBuildNotes.md` ("Used xcode 13.3.1") and `WindowsBuildNotes.md` ("VS 2019 … SDKs 10.0.19041.0 and 10.0.20348.0") record toolchains from far older Electronite versions and are wrong for this branch. See Toolchain Requirements.
- `docs/development/Electronite/electronite.patch` is stale as of commit `4bc461a95a`: its `setup_graphite` line predates the `exist_ok=True` fix, and its `index` hashes no longer match `DEPS`. Regenerate it (see Graphite Integration).
