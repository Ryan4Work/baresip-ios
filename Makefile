#
# Makefile
# 更新為使用 CMake 的版本，適用於 baresip v3.16.0
#
# Copyright (C) 2010 - 2016 Alfred E. Heggestad 
#

BUILD_DIR   := build
CONTRIB_DIR := contrib
OUTPUT_DIR  := output

include mk/contrib.mk

all: contrib

clean:
	@rm -rf $(BUILD_DIR) $(CONTRIB_DIR) $(OUTPUT_DIR)
	@rm -rf baresip re openssl.tar.gz

.PHONY: download
download:
	rm -fr baresip re openssl.tar.gz
	curl -L -o openssl.tar.gz https://www.openssl.org/source/openssl-3.4.0.tar.gz
	git clone --depth 1 -b v3.21.0 https://github.com/baresip/baresip.git
	git clone --depth 1 -b v3.21.0 https://github.com/baresip/re.git