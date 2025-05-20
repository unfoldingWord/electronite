# Electronite Build Notes

Electronite is a version of Electron that is patched to support rendering [graphite](https://github.com/silnrsi/graphite) enabled fonts.

Based on wiki notes for `electronite-v12.0.5` from: https://github.com/unfoldingWord/electronite/wiki

# Building

- [Windows build notes](WindowsBuildNotes.md)
- [MacOS build notes](MacBuildNotes.md)
- [Linux build notes](LinuxBuildNotes.md)

Running the scripts without arguments will display the following commands which you will generally want to execute in order:
1. `get <ref>` fetches all of the code. Where `<ref>` is a branch or tag.
2. `build [target]` compiles Electronite for target (default is x64)
3. `release [target]` creates the distributable (default is x64)

Also, you'll want to build code from a properly tagged release because [other tooling](https://github.com/topics/electronite) expects a specific naming convention.
When tagging a new release of Electronite use the same naming convention as Electron with the addition of a `-graphite` suffix. For example if Electron has a `v7.2.3` release, Electronite will have a corresponding `v7.2.3-graphite` release.

> Note: When building Electronite you will need to download about 20 gb of source code.

After running the above commands you will have a zipped file at `./electron-gn/src/out/Release/dist.zip`. You can rename this file and  upload it as an artifact to the proper release on Github. Here's the naming convention:

* `electronite-<version>-win32-x64.zip`
* `electronite-<version>-win32-ia32.zip`
* `electronite-<version>-linux-x64.zip`
* `electronite-<version>-darwin-x64.zip`

Where `<version>` is the tagged release without the `-graphite` suffix. e.g. `electronite-v7.2.3-linux-x64.zip`

> You must compile Electronite on a Linux, Windows, and macOS in order to generate the three distributables above.
>  Cross compilation for different OS is not possible.

## Troubleshooting

#### Delete cached repository
If you encounter errors while fetching the source code (this includes chromium) you may need to delete one of the cached repositories, or a lock file. Look through the console output to identify the repository that was being fetched when the download failed. Delete the identified repository from your `.git_cache` and also delete any `.lock` files. Re-run the download and it should succeed.

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

# Testing

Once you have a compiled Electronite binary you can test it by visiting this page https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo.

* Run Electronite
* Open the developer console in the running Electronite instance.
* execute `window.location="the test url above"`
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

See [this issue](https://github.com/unfoldingWord/translationCore/issues/6879#issuecomment-624429380) for a detailed explaination.