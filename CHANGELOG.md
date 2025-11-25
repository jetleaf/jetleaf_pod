# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-11-25

- Updated dependencies

## [1.0.1+1] - 2025-11-19

Patch release: Autowire candidates

### Fixed

- Fixed the recursive behaviour that occurs when resolving a dependency with multiple types.
- Added more tests for the pod factory and its sub classes
- Fixed test issues with the package

## [1.0.1] - 2025-11-17

Patch release: dependency alignment and maintenance.

### Fixed

- Updated dependency pins and internal housekeeping to align with other JetLeaf packages.

## [1.0.0] - 2025-11-17

Initial release.

### Added

- Core dependency injection (IoC) and pod lifecycle management APIs.
- Service registration, resolution and lifecycle hooks for JetLeaf applications.

### Notes

- This package is intended as the core runtime support for JetLeaf modules that require lifecycle and DI primitives. Breaking changes will be documented in future releases.

### Links

- Homepage: https://jetleaf.hapnium.com
- Documentation: https://jetleaf.hapnium.com/docs/pod
- Repository: https://github.com/jetleaf/jetleaf_pod
- Issues: https://github.com/jetleaf/jetleaf_pod/issues

Contributors: Hapnium & JetLeaf contributors