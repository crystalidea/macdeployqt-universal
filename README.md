With Apple transition from Intel to Apple Silicon (arm64) CPUs, developers have to deal with Universal binaries in macOS (again) in order to support their apps running smoothly on both architectures. For Qt developers things get much more complicated because we have to take care of signing, notarization and Universal binaries creation without using XCode.

This article explains how we at CrystalIDEA are currently deploying macOS versions of [our apps](https://crystalidea.com/). We hope that it can be useful for other indie developers and the Qt development community. Let's also hope that Qt Creator will simplify things in future ([QTBUG-85279](https://bugreports.qt.io/browse/QTBUG-85279)).

The build process takes place on Intel machine using Qt 5.15.2 (migrating to Qt 6 is not possible for us because it doesn't support macOS 10.13 and Windows 7). Currently we're using macOS 10.15.7 (Catalina) and XCode 12.4.

**Disclaimer**: the described process is unlikely to be optimal, any improvement ideas and comments are welcome.

## Prerequisites

- Qt built for x86_64. It's installed (by default) to /usr/local/Qt-5.15.2
- Qt built for arm64 using the `QMAKE_APPLE_DEVICE_ARCHS=arm64` configure switch and `-prefix /usr/local/Qt-5.15.2-arm` to install it to /usr/local/Qt-5.15.2-arm
- our modified version of [macdeployqt](macdeployqt_src) with support of the `-qtdir` switch that speficies actual Qt directory. You can compile it yourself but easier is to download the [precompiled binary](bin/macdeployqt) (it has no dependencies as Qt is statically linked)
- [makeuniversal](https://github.com/nedrysoft/makeuniversal) tool. This tool merges two folders with  x86_64 and arm64 binaries into a universal binary. [Precompiled binary](bin/makeuniversal) with zero dependencies
- A tool to notarize macOS apps. We recommended [xcnotary](https://github.com/akeru-inc/xcnotary) which is also available as a [precompiled binary](bin/xcnotary)

## Build steps

1. Compile release configurations of your app for both arm64 and x86_64. They should be located in different folders e.g. *release/youApp.app* and *release-arm/youApp.app*. Use Qt Creator different kits and build configurations to compile for x86_64 and arm64 binaries of your app separately. See [example screenshots](screens) for more information. 
2. Once both binaries are compiled, run **macdeployqt** on both to integrate correspondent Qt frameworks:

`macdeployqt "release/youApp.app" -verbose=1 -qtdir=/usr/local/Qt-5.15.2`\
`macdeployqt "release-arm/youApp.app" -verbose=1 -qtdir=/usr/local/Qt-5.15.2-arm`

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
