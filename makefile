NAME := HyperSign
PLATFORM := iphoneos
SCHEMES := Ksign
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release-$(PLATFORM)

.PHONY: all clean $(SCHEMES)

all: $(SCHEMES)

clean:
	rm -rf "$(TMP)"
	rm -rf packages
	rm -rf Payload

deps:
	mkdir -p deps
	@if [ ! -f deps/server.crt ] || [ ! -f deps/server.pem ]; then \
		echo "Fetching SSL certificates from pack.json..."; \
		curl -s -L https://backloop.dev/pack.json -o deps/pack.json || true; \
		if [ -s deps/pack.json ]; then \
			python3 -c "import json; data=json.load(open('deps/pack.json')); open('deps/server.crt','w').write(data['cert']); open('deps/server.pem','w').write(data['key1']+data['key2']); open('deps/commonName.txt','w').write(data['info']['domains']['commonName'])" 2>/dev/null || true; \
			rm -f deps/pack.json; \
		fi \
	fi
	@if [ ! -f deps/commonName.txt ]; then echo "*.backloop.dev" > deps/commonName.txt; fi

$(SCHEMES): deps
	xcodebuild \
	    -project Ksign.xcodeproj \
	    -scheme "$@" \
	    -configuration Release \
	    -arch arm64 \
	    -sdk $(PLATFORM) \
	    -derivedDataPath $(TMP) \
	    -skipPackagePluginValidation \
	    COMPILER_INDEX_STORE_ENABLE=NO \
	    CODE_SIGNING_ALLOWED=NO \
	    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
	    SWIFT_STRICT_CONCURRENCY=minimal

	rm -rf Payload
	rm -rf "$(STAGE)/"
	mkdir -p "$(STAGE)/Payload"

	@if [ -d "$(APP)/HyperSign.app" ]; then \
		mv "$(APP)/HyperSign.app" "$(STAGE)/Payload/HyperSign.app"; \
	elif [ -d "$(APP)/$(NAME).app" ]; then \
		mv "$(APP)/$(NAME).app" "$(STAGE)/Payload/HyperSign.app"; \
	elif [ -d "$(APP)/LemonSign.app" ]; then \
		mv "$(APP)/LemonSign.app" "$(STAGE)/Payload/HyperSign.app"; \
	elif [ -d "$(APP)/2809.app" ]; then \
		mv "$(APP)/2809.app" "$(STAGE)/Payload/HyperSign.app"; \
	elif [ -d "$(APP)/$@.app" ]; then \
		mv "$(APP)/$@.app" "$(STAGE)/Payload/HyperSign.app"; \
	else \
		mv "$$(find $(APP) -name '*.app' -maxdepth 1)" "$(STAGE)/Payload/HyperSign.app"; \
	fi

	chmod -R 0755 "$(STAGE)/Payload/HyperSign.app"
	strip -x -S "$$(find $(STAGE)/Payload/HyperSign.app -maxdepth 1 -type f -perm +111 2>/dev/null | head -n 1)" 2>/dev/null || true
	codesign --force --sign - --timestamp=none "$(STAGE)/Payload/HyperSign.app"

	cp deps/* "$(STAGE)/Payload/HyperSign.app/" || true
	cp -f Ksign/Resources/AppIcons/*.png "$(STAGE)/Payload/HyperSign.app/" || true

	rm -rf "$(STAGE)/Payload/HyperSign.app/_CodeSignature"
	ln -sf "$(STAGE)/Payload" Payload
	
	mkdir -p packages
	zip -r9 "packages/HyperSign.ipa" Payload
	rm -f packages/LemonSign.ipa packages/2809.ipa packages/Ksign.ipa
