# Deploying macOS universal binaries using Qt 5.15.7

- If you own a commercial license, this tutorial is not for you because Qt started supporting universal builds since Qt 5.15.9. Qt 6.2 and later also have macOS universal binaries support
- Qt 5.15.7 source code is officially available [here](https://download.qt.io/official_releases/qt/5.15/5.15.7/)
- Qt 5.15.9 will be publicly released [April 05, 2023](https://crystalidea.com/blog/qt-5-15-lts-commercial-source-code)

With Apple transition from Intel to Apple Silicon (arm64) CPUs, developers have to deal with Universal binaries in macOS (again) in order to support their apps running smoothly on both architectures. For Qt developers things get much more complicated because we have to take care of signing, notarization and Universal binaries creation without using XCode.

This article explains how we at CrystalIDEA used to deploy macOS versions of [our apps](https://crystalidea.com/) (before official support of universal builds in Qt). We hope that it can be useful for other indie developers who are still on Qt 5.15.7 for various reasons (e.g. Windows 7 & macOS 10.13 support). 

The build process takes place on Intel machine running macOS 10.15 (Catalina) or 11 (Big Sur), Qt Creator 5/6 and XCode 12/13. 

**Disclaimer**: the described process is unlikely to be optimal, any improvement ideas and comments are welcome.

## Prerequisites

- Qt built for x86_64. It's installed (by default) to /usr/local/Qt-5.15.7
- Qt built for arm64 using the `QMAKE_APPLE_DEVICE_ARCHS=arm64` configure switch and `-prefix /usr/local/Qt-5.15.7-arm` to install it to /usr/local/Qt-5.15.7-arm
- Qt Creator should have these two Qt versions added and two corresponding kits for each

![](/screens/qt_versions.png)

![](/screens/qt_kits.png)

- Our modified version of [macdeployqt](macdeployqt_src) with support of the `-qtdir` switch that speficies actual Qt directory. You can compile it yourself or download our [precompiled binary](bin/macdeployqt) (it has no dependencies as Qt is statically linked)
- [makeuniversal](https://github.com/nedrysoft/makeuniversal) tool which merges two folders with  x86_64 and arm64 binaries of your app into a universal binary. Here we also provice the [precompiled binary](bin/makeuniversal) with zero dependencies
- A tool to notarize macOS apps. We do recommend [xcnotary](https://github.com/akeru-inc/xcnotary) which is also available as a [precompiled binary](bin/xcnotary)

## Build steps

1. Your Qt Creator project must have two separate build configurations for each Qt kit:

![](/screens/qt_configurations.png)

Compile release builds of your app for both 5.15 and 5.15-arm kits. Binaries should be located in different folders e.g. *release/youApp.app* and *release-arm/youApp.app*. 
2. Once both binaries are compiled, run **macdeployqt** on both to integrate correspondent Qt frameworks:

`macdeployqt "release/youApp.app" -verbose=1 -qtdir=/usr/local/Qt-5.15.7`\
`macdeployqt "release-arm/youApp.app" -verbose=1 -qtdir=/usr/local/Qt-5.15.7-arm`

3. Run **makeuniversal** to merge folders into a universal binary:

`makeuniversal release-universal release release-arm`

4. Sign the universal binary:

`codesign --remove-signature youApp.app # for some reason required for arm64`\
`codesign -v --deep youApp.app -s "Developer ID..." -o runtime --entitlements codesign_entitlements.plist`

We use [codesign_entitlements.plist](etc/codesign_entitlements.plist) to disable [Library Validation Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_disable-library-validation?language=objc).

5. Notarize the binary using **xcnotary**:

`xcnotary notarize youApp.app --developer-account your@apple.id --developer-password-keychain-item your_notarize_k`

It's supposed that the *your_notarize_k* keychain item already added:

`xcrun altool --store-password-in-keychain-item your_notarize_k -u your@apple.id -p paswd`

## Automation

Internally we have **deploy.prj** file to include in a Qt .pro file that uses QMAKE_POST_LINK to run macdeployqt, makeuniversal and xcnotary. Deliberately we don't publish our automation scripts yet, they should be more polished and universal.

## Misc

For reference you can use our [build scripts for Qt 5.15.2](https://github.com/crystalidea/qt-build-tools/tree/master/5.15.2) and also some custom macOS-related patches applied.