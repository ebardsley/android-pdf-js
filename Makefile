# -*- Mode: Makefile -*-
#
# Makefile for Android PDF.js
#

FILES = manifest.json \
        icon.svg \
        resource-delivery.js \
        pdfHandler.js \
        preserve-referer.js

ADDON = android-pdfjs

VERSION = $(shell jq -r .version < manifest.json)
PDFJS_VERSION = 2.16.105

ANDROIDDEVICE = $(shell adb devices | cut -s -d$$'\t' -f1 | head -n1)

trunk: $(ADDON)-trunk.xpi

release: $(ADDON)-$(VERSION).xpi
	@echo ""
	@echo "This Add-on contains Mozilla PDF.js as third-party library"
	@echo "Path in Add-on: content/build"
	@echo "Official source archive: https://github.com/mozilla/pdf.js/releases/download/v$(PDFJS_VERSION)/pdfjs-$(PDFJS_VERSION)-dist.zip"

%.xpi: $(FILES) content
	@zip -r9 - $^ > $@

# I don't want to mess with building PDF.js on my own.
# This gives us a "web build" of PDF.js without any browser specific messaging.
# We also add a community patch for pinch gestures here.
content:
	wget "https://github.com/mozilla/pdf.js/releases/download/v$(PDFJS_VERSION)/pdfjs-$(PDFJS_VERSION)-dist.zip"
	rm -rf content.build
	unzip "pdfjs-$(PDFJS_VERSION)-dist.zip" -d "content.build"
	rm content.build/web/compressed.tracemonkey-pldi-09.pdf
	rm content.build/web/*.js.map
	rm content.build/build/*.js.map
	rm "pdfjs-$(PDFJS_VERSION)-dist.zip"

	cat patches/pdfjs-pinch-gestures-larsneo.js >> content.build/web/viewer.js
	mv content.build content

clean:
	rm -f $(ADDON)-*.xpi
	rm -rf content

# Starts local debug session
run: content
	web-ext run --bc --pref=pdfjs.disabled=true -u "https://github.com/mozilla/pdf.js/blob/gh-pages/web/compressed.tracemonkey-pldi-09.pdf"

# Starts debug session on connected Android device
arun: content
	@if [ -z "$(ANDROIDDEVICE)" ]; then \
	  echo "No android devices found!"; \
	else \
	  web-ext run --target=firefox-android --firefox-apk=org.mozilla.fenix --android-device="$(ANDROIDDEVICE)"; \
	fi
