#
# contrib.mk
# Use CMake to build baresip for iOS, simplifying the process by compiling multiple architectures simultaneously
#
# Copyright (C) 2010 - 2020 Alfred E. Heggestad
#

DEPLOYMENT_TARGET_VERSION=13.0

#
# Path settings
#

SOURCE_PATH   := $(CURDIR)

OPENSSL_SOURCE  := $(SOURCE_PATH)/openssl.tar.gz
LIBRE_PATH    := $(SOURCE_PATH)/re
BARESIP_PATH  := $(SOURCE_PATH)/baresip

BUILD_DIR     := $(CURDIR)/build
CONTRIB_DIR   := $(CURDIR)/contrib
OUTPUT_DIR    := $(CURDIR)/output

# Define build directories for device and simulator
BUILD_OPENSSL				:= $(BUILD_DIR)/openssl
BUILD_DEVICE				:= $(BUILD_DIR)/device
BUILD_SIMULATOR			:= $(BUILD_DIR)/simulator

CONTRIB_DEVICE     := $(CONTRIB_DIR)/device
CONTRIB_SIMULATOR  := $(CONTRIB_DIR)/simulator

OUTPUT_DEVICE      := $(OUTPUT_DIR)/iphoneos
OUTPUT_SIMULATOR   := $(OUTPUT_DIR)/iphonesimulator

CONTRIB_DEVICE_OPENSSL    := $(CONTRIB_DEVICE)/openssl
CONTRIB_SIMULATOR_OPENSSL := $(CONTRIB_SIMULATOR)/openssl

#
# Tools and SDK
#

# Automatically detect the latest SDK paths and compilers
SDK_ARM := $(shell xcrun -sdk iphoneos --show-sdk-path)
SDK_SIM := $(shell xcrun -sdk iphonesimulator --show-sdk-path)
CC_ARM  := $(shell xcrun -sdk iphoneos -find clang)
CPP_ARM := $(shell xcrun -sdk iphoneos -find clang++)
CC_SIM  := $(shell xcrun -sdk iphonesimulator -find clang)
CPP_SIM := $(shell xcrun -sdk iphonesimulator -find clang++)

#
# OPENSSL configuration
#

OPENSSL_DEVICE_TARGETS := ios64-xcrun
OPENSSL_SIMULATOR_TARGETS := iossimulator-x86_64-xcrun iossimulator-arm64-xcrun

#
# Common settings
#

CMAKE_GENERATOR := Unix Makefiles

CMAKE_FLAGS_COMMON := -DCMAKE_SYSTEM_NAME=iOS \
											-DCMAKE_OSX_DEPLOYMENT_TARGET=$(DEPLOYMENT_TARGET_VERSION) \
											-DCMAKE_BUILD_TYPE=Release

CMAKE_FLAGS_RE := $(CMAKE_FLAGS_COMMON) \
  								-DCMAKE_C_FLAGS="-Werror -Wno-deprecated-declarations -Wno-incompatible-pointer-types -Wno-cast-align -Wno-shorten-64-to-32 -Wno-aggregate-return"

CMAKE_FLAGS_BARESIP := $(CMAKE_FLAGS_COMMON) \
                       -DCMAKE_MACOSX_BUNDLE=OFF \
                       -DSTATIC=ON \
                       -DCMAKE_EXE_LINKER_FLAGS="-framework CoreFoundation" \
                       -DCMAKE_C_FLAGS="-Werror -Wno-deprecated-declarations -Wno-incompatible-pointer-types \
                       -Wno-cast-align -Wno-shorten-64-to-32 -Wno-aggregate-return" \
                       -DMODULES="g711;audiounit;avcapture;ctrl_tcp;debug_cmd;ebuacip;echo;fakevideo;httpd;ice;menu;mwi;natpmp;presence;srtp;stun;turn;uuid;vidbridge;vumeter;mixausrc;mixminus;aubridge;aufile;ausine"

#
# Architecture settings
#

# Device (arm64) configuration
DEVICE_CMAKE_FLAGS := -DCMAKE_OSX_ARCHITECTURES=arm64 \
                      -DCMAKE_OSX_SYSROOT=$(SDK_ARM) \
                      -DCMAKE_C_COMPILER=$(CC_ARM) \
                      -DCMAKE_CXX_COMPILER=$(CPP_ARM)

# Simulator (arm64 and x86_64) configuration
SIMULATOR_CMAKE_FLAGS := -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
                         -DCMAKE_OSX_SYSROOT=$(SDK_SIM) \
                         -DCMAKE_C_COMPILER=$(CC_SIM) \
                         -DCMAKE_CXX_COMPILER=$(CPP_SIM)

# Configuration for libre
DEVICE_RE_FLAGS := -DRE_INCLUDE_DIR=$(CONTRIB_DEVICE)/re/include/re \
                   -DRE_LIBRARY=$(CONTRIB_DEVICE)/re/lib/libre.a \
                   -Dre_DIR=$(CONTRIB_DEVICE)/re/lib/cmake/re

SIMULATOR_RE_FLAGS := -DRE_INCLUDE_DIR=$(CONTRIB_SIMULATOR)/re/include/re \
                      -DRE_LIBRARY=$(CONTRIB_SIMULATOR)/re/lib/libre.a \
                      -Dre_DIR=$(CONTRIB_SIMULATOR)/re/lib/cmake/re

# OpenSSL configuration
DEVICE_SSL_FLAGS := -DOPENSSL_ROOT_DIR=$(CONTRIB_DEVICE_OPENSSL) \
                    -DOPENSSL_INCLUDE_DIR=$(CONTRIB_DEVICE_OPENSSL)/include \
                    -DOPENSSL_SSL_LIBRARY=$(CONTRIB_DEVICE_OPENSSL)/lib/libssl.a \
                    -DOPENSSL_CRYPTO_LIBRARY=$(CONTRIB_DEVICE_OPENSSL)/lib/libcrypto.a

SIMULATOR_SSL_FLAGS := -DOPENSSL_ROOT_DIR=$(CONTRIB_SIMULATOR_OPENSSL) \
                       -DOPENSSL_INCLUDE_DIR=$(CONTRIB_SIMULATOR_OPENSSL)/include \
                       -DOPENSSL_SSL_LIBRARY=$(CONTRIB_SIMULATOR_OPENSSL)/lib/libssl.a \
                       -DOPENSSL_CRYPTO_LIBRARY=$(CONTRIB_SIMULATOR_OPENSSL)/lib/libcrypto.a

#
# Targets
#

.PHONY: contrib openssl libre baresip output info

# Main target: build baresip and its dependencies
contrib: baresip info

#
# OpenSSL
#
# Copies pre-built OpenSSL libraries and headers for device and simulator
#

# Ensure OpenSSL libraries for device and simulator are available
openssl: $(CONTRIB_DEVICE_OPENSSL)/lib/libssl.a $(CONTRIB_SIMULATOR_OPENSSL)/lib/libssl.a

define build_openssl_rule
$(BUILD_OPENSSL)/$(1):
	@echo "Building OpenSSL for $(1)"
	mkdir -p $$@
	tar -xzf $(OPENSSL_SOURCE) -C $$@ --strip-components=1
	cd $$@ && ./Configure $(1) --prefix=$$@/install no-deprecated no-async no-shared no-tests
	cd $$@ && make -j && make install_dev
endef

$(foreach target,$(OPENSSL_DEVICE_TARGETS),$(eval $(call build_openssl_rule,$(target))))
$(foreach target,$(OPENSSL_SIMULATOR_TARGETS),$(eval $(call build_openssl_rule,$(target))))

$(CONTRIB_DEVICE_OPENSSL)/lib/libssl.a: $(OPENSSL_DEVICE_TARGETS:%=$(BUILD_OPENSSL)/%)
	mkdir -p $(CONTRIB_DEVICE_OPENSSL)
	cp -a $(BUILD_OPENSSL)/$(firstword $(OPENSSL_DEVICE_TARGETS))/install/ $(CONTRIB_DEVICE_OPENSSL)/

$(CONTRIB_SIMULATOR_OPENSSL)/lib/libssl.a: $(OPENSSL_SIMULATOR_TARGETS:%=$(BUILD_OPENSSL)/%)
	mkdir -p $(CONTRIB_SIMULATOR_OPENSSL)/include
	mkdir -p $(CONTRIB_SIMULATOR_OPENSSL)/lib
	cp -a $(BUILD_OPENSSL)/$(firstword $(OPENSSL_SIMULATOR_TARGETS))/install/include/ $(CONTRIB_SIMULATOR_OPENSSL)/include/
	lipo -create $(foreach target,$(OPENSSL_SIMULATOR_TARGETS),$(BUILD_OPENSSL)/$(target)/install/lib/libssl.a) -output $(CONTRIB_SIMULATOR_OPENSSL)/lib/libssl.a
	lipo -create $(foreach target,$(OPENSSL_SIMULATOR_TARGETS),$(BUILD_OPENSSL)/$(target)/install/lib/libcrypto.a) -output $(CONTRIB_SIMULATOR_OPENSSL)/lib/libcrypto.a

#
# Build libre
#
# Build libre for device and simulator

libre: openssl $(CONTRIB_DEVICE)/re/lib/libre.a $(CONTRIB_SIMULATOR)/re/lib/libre.a

define build_libre
# Configure libre for $(1)
$(BUILD_$(1))/re/Makefile: $(CONTRIB_$(1)_OPENSSL)/lib/libssl.a
	mkdir -p $(BUILD_$(1))/re
	cd $(BUILD_$(1))/re && cmake $(LIBRE_PATH) \
		-G "$(CMAKE_GENERATOR)" \
		$(CMAKE_FLAGS_RE) \
		$($(1)_CMAKE_FLAGS) \
		$($(1)_SSL_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=$(CONTRIB_$(1))/re

# Build and install libre for $(1)
$(CONTRIB_$(1))/re/lib/libre.a: $(BUILD_$(1))/re/Makefile
	cmake --build $(BUILD_$(1))/re --target install -- -j
endef

# Invoke build_libre for DEVICE and SIMULATOR
$(eval $(call build_libre,DEVICE))
$(eval $(call build_libre,SIMULATOR))

#
# Build baresip
#
# Build baresip for device and simulator

baresip: libre $(CONTRIB_DEVICE)/baresip/lib/libbaresip.a $(CONTRIB_SIMULATOR)/baresip/lib/libbaresip.a

define build_baresip
# Configure baresip for $(1)
$(BUILD_$(1))/baresip/Makefile: $(CONTRIB_$(1))/re/lib/libre.a
	mkdir -p $(BUILD_$(1))/baresip
	cd $(BUILD_$(1))/baresip && cmake $(BARESIP_PATH) \
		-G "$(CMAKE_GENERATOR)" \
		$(CMAKE_FLAGS_BARESIP) \
		$($(1)_CMAKE_FLAGS) \
		$($(1)_RE_FLAGS) \
		$($(1)_SSL_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=$(CONTRIB_$(1))/baresip

# Build and install baresip for $(1)
$(CONTRIB_$(1))/baresip/lib/libbaresip.a: $(BUILD_$(1))/baresip/Makefile
	cmake --build $(BUILD_$(1))/baresip --target install -- -j
endef

# Invoke build_baresip for DEVICE and SIMULATOR
$(eval $(call build_baresip,DEVICE))
$(eval $(call build_baresip,SIMULATOR))

# Print results
info: baresip
	@echo "CONTRIB_DEVICE: $(CONTRIB_DEVICE)"
	@echo "CONTRIB_SIMULATOR: $(CONTRIB_SIMULATOR)"
	@echo "Done"

output: baresip
	rm -rf $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DEVICE)
	mkdir -p $(OUTPUT_SIMULATOR)
	mkdir -p $(OUTPUT_DIR)/include/openssl
	mkdir -p $(OUTPUT_DIR)/include/re
	mkdir -p $(OUTPUT_DIR)/include/baresip
	
# 複製標頭文件到公共的 include 目錄
	cp -r $(CONTRIB_DEVICE)/openssl/include/openssl/* $(OUTPUT_DIR)/include/openssl/
	cp -r $(CONTRIB_DEVICE)/re/include/re/* $(OUTPUT_DIR)/include/re/
	cp $(CONTRIB_DEVICE)/baresip/include/baresip.h $(OUTPUT_DIR)/include/baresip/
	
# 複製庫文件到各自的平台目錄
	cp $(CONTRIB_DEVICE)/openssl/lib/*.a $(OUTPUT_DEVICE)/
	cp $(CONTRIB_DEVICE)/re/lib/libre.a $(OUTPUT_DEVICE)/
	cp $(CONTRIB_DEVICE)/baresip/lib/libbaresip.a $(OUTPUT_DEVICE)/
	cp $(CONTRIB_SIMULATOR)/openssl/lib/*.a $(OUTPUT_SIMULATOR)/
	cp $(CONTRIB_SIMULATOR)/re/lib/libre.a $(OUTPUT_SIMULATOR)/
	cp $(CONTRIB_SIMULATOR)/baresip/lib/libbaresip.a $(OUTPUT_SIMULATOR)/