# Baresip for iOS


## Overview

[Baresip](https://github.com/baresip) is a modular SIP user-agent


## Build 

To build static libraries for iOS run the following command:
```shell
$ make clean
$ make download
$ make
```

## Install
- Link XCode target with:
    - `contrib/fat/lib/libbaresip.a`, `contrib/fat/lib/libre.a`
    - `libresolv.9.dlyb`
    - `AVFoundation`, `SystemConfiguration`, `CFNetwork`, `CoreMedia`, `AudioToolbox`, `CoreVideo` frameworks
- Setup build settings:
    - header search path with:
        - `baresip/include`
        - `re/include`
    - library search path with:
        - `contrib/fat/lib`
