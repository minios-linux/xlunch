# xlunch - MiniOS Build Package

This repository contains the Debian packaging files for xlunch (graphical app launcher for X with minimal dependencies).

## Structure

- `debian/` - Debian packaging files with MiniOS-specific customizations
- `Makefile` - Build automation that downloads upstream sources and builds the package

## Building

To build the package:

```bash
make all
```

This will:
1. Check build dependencies and install if missing
2. Clone the upstream xlunch repository (v4.7.6)
3. Create the orig tarball
4. Add our debian packaging
5. Build the .deb package
6. Run lintian checks

## Individual Steps

- `make clone` - Clone upstream sources
- `make orig` - Create orig tarball
- `make add-debian` - Add debian packaging
- `make check-deps` - Check/install build dependencies
- `make build-package` - Build the package
- `make lintian` - Run lintian checks
- `make clean` - Clean build artifacts

## CI/CD

This repository includes GitHub Actions workflow that automatically:
- Builds .deb packages for amd64 and i386 architectures
- Runs lintian checks for quality assurance
- Creates GitHub releases with packages when tags are pushed
- Uploads build artifacts for every push and PR

The workflow is triggered on:
- Pushes to master branch
- Pull requests to master branch  
- Tag pushes (creates releases)

## Upstream

The upstream xlunch project is maintained at:
https://github.com/Tomas-M/xlunch

Current version: 4.7.6
