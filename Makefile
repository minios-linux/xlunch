.PHONY: all clone orig add-debian check-deps build-package lintian clean

PACKAGE   := xlunch
VERSION   := 4.7.6
TAG       := v$(VERSION)
REPO      := https://github.com/Tomas-M/xlunch.git
BUILD_DIR := build/$(PACKAGE)-$(VERSION)

all: check-deps build-package lintian

clone:
	@echo "Cloning $(PACKAGE) $(VERSION)..."
	@mkdir -p build
	@rm -rf $(BUILD_DIR)
	@git clone --branch $(TAG) $(REPO) $(BUILD_DIR)

orig: clone
	@echo "Creating orig tarball..."
	@tar czf build/$(PACKAGE)_$(VERSION).orig.tar.gz -C build $(PACKAGE)-$(VERSION)

add-debian: orig
	@echo "Adding debian directory..."
	@cp -r debian $(BUILD_DIR)/

check-deps:
	@echo "Checking build dependencies..."
	@MISSING=$$(dpkg-checkbuilddeps 2>&1 \
	              | sed -n 's/^.*Unmet build dependencies: //p'); \
	if [ -n "$$MISSING" ]; then \
	  echo "Missing build-deps: $$MISSING"; \
	  echo "Installing..."; \
	  sudo apt-get update && sudo apt-get install -y $$MISSING; \
	else \
	  echo "All build-dependencies satisfied."; \
	fi

build-package: add-debian
	@echo "Building package..."
	@cd $(BUILD_DIR) && dpkg-buildpackage -us -uc

lintian:
	@echo "Running lintian..."
	@lintian --show-overrides build/$(PACKAGE)_*.changes

clean:
	@echo "Cleaning up..."
	@rm -rf build
