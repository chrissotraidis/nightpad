# Upstream delta ledger

The first baselines use the exact pins in `config/dependencies.lock.json` with
no engine source changes.

| Source | Original pin | NightPad change | Regression evidence |
| --- | --- | --- | --- |
| nightfire-cxbx | `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab` | HostPosix uses the iOS SDK's vm_* ABI instead of unavailable mach_vm_*; tracked as patches/0001-ios-host-vm-abi.patch | macOS gamewindow_test and native targets build; simulator pointer probe passes; physical device pending |
| nightfire-cxbx | `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab` | CrashReportPosix reads mappings through vm_region_64 on iOS; tracked as patches/0002-ios-crashreport-vm.patch | Both complete iPhoneOS engine targets compile and link |
| nightfire-cxbx | `8779cf79ff623b83b53b9acf9c0b0cd6639b75ab` | Adds an opt-in launch-request callback after the page write; default child-process behavior is unchanged; tracked as patches/0003-in-process-launch-request.patch | Native bridge page/thread test and 635-frame replay smoke pass |
| extract-xiso | `3f5b62cfe68f000b0e3c8a30104973f3a297948e` | None; guarded Python wrapper | ISO listing and extraction manifest |
| FFmpeg | `8ae0b34901ba60a802f183ee75a250a9fc3e09a5` | None; build with Xcode SDK | `macos-arm64` libraries built |
| SDL3 | `829a65d769d935c4852f8159e964312c0957260a` | None yet | CMake configure passed |
| SPIRV-Cross | `f11ba9f0b21ba8fc15153d50a2a1ae31ab1cf8f7` | None yet | CMake configure passed |

