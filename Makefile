.PHONY: all clone orig add-debian check-deps build-package lintian clean

PACKAGE   := xlunch
VERSION   := 4.7.6+git20260524.da1ff9f
UPSTREAM_REF := da1ff9fdc85e565370ed3fa7639a855f3cdbd509
REPO      := https://github.com/Tomas-M/xlunch.git
BUILD_DIR := build/$(PACKAGE)-$(VERSION)

all: check-deps build-package lintian

clone:
	@echo "Cloning $(PACKAGE) at $(UPSTREAM_REF)..."
	@mkdir -p build
	@rm -rf $(BUILD_DIR)
	@git clone $(REPO) $(BUILD_DIR)
	@git -C $(BUILD_DIR) checkout --detach $(UPSTREAM_REF)
	@test "$$(git -C $(BUILD_DIR) rev-parse HEAD)" = "$(UPSTREAM_REF)"

orig: clone
	@echo "Creating orig tarball..."
	@tar --exclude=.git -czf build/$(PACKAGE)_$(VERSION).orig.tar.gz -C build $(PACKAGE)-$(VERSION)

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
