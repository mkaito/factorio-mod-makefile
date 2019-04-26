PACKAGE_NAME := $(shell cat info.json|jq -r .name)
PACKAGE_NAME := $(if $(DEV),$(PACKAGE_NAME)-dev,$(PACKAGE_NAME))
VERSION_STRING := $(shell cat info.json|jq -r .version)
OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)
BUILD_DIR := .build
OUTPUT_DIR := $(BUILD_DIR)/$(OUTPUT_NAME)
CONFIG = ./$(OUTPUT_DIR)/config.lua
MODS_DIR := $(HOME)/.factorio/mods
MOD_DIR := $(MODS_DIR)/$(OUTPUT_NAME)

PKG_COPY := $(wildcard *.md) $(wildcard .*.md) $(wildcard graphics) $(wildcard locale) $(wildcard sounds) $(shell cat PKG_COPY || true)

SED_FILES := $(shell find . -iname '*.json' -type f -not -path "./.*/*") \
             $(shell find . -iname '*.lua' -type f -not -path "./.*/*")

OUT_FILES := $(SED_FILES:%=$(OUTPUT_DIR)/%)

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

all: package

release: clean package tag

package-copy: $(PKG_DIRS) $(PKG_FILES) $(OUT_FILES)
	mkdir -p $(OUTPUT_DIR)
ifneq ($(strip $(PKG_COPY)),)
	cp -r $(PKG_COPY) $(OUTPUT_DIR)
endif

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@
	@luac -p $@
	@luacheck $@


$(OUTPUT_DIR)/%: %
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@

symlink: cleandest
	ln -s $(PWD) $(MODS_DIR)/$(OUTPUT_NAME)

tag:
	git tag -f v$(VERSION_STRING)

nodebug:
	@[ -e $(CONFIG) ] && \
	echo Removing debug switches from config.lua && \
	sed -i 's/^\(.*DEBUG.*=\).*/\1 false/' $(CONFIG) && \
	sed -i 's/^\(.*LOGLEVEL.*=\).*/\1 0/' $(CONFIG) && \
	sed -i 's/^\(.*loglevel.*=\).*/\1 0/' $(CONFIG)

package: package-copy $(OUT_FILES) nodebug
	@cd $(BUILD_DIR) && zip -rq $(OUTPUT_NAME).zip $(OUTPUT_NAME)
	@echo $(OUTPUT_NAME).zip ready

install: package cleandest
	cp $(BUILD_DIR)/$(OUTPUT_NAME).zip $(MOD_DIR).zip

clean:
	@rm -rf $(BUILD_DIR)

cleandest:
	rm -rf $(MODS_DIR)/$(PACKAGE_NAME)*
