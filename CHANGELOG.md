# Changelog

All notable changes to this project will be documented in this file.  
This project follows a simple, human-readable changelog format inspired by
[Keep a Changelog](https://keepachangelog.com/) and adheres to semantic versioning.

---

## [1.1.2]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.1.1]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.1.0]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.0.9]

### Fixed
- Resolved issues when invoking methods with nullable parameters, such as  
  `String login(User user, String? locale)`.

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.0.8]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.0.7]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`

---

## [1.0.6]

### Changed
- Updated dependencies

---

## [1.0.5]

### Changed
- Updated dependencies

---

## [1.0.4]

### Changed
- Updated dependencies

---

## [1.0.3]

### Changed
- Updated dependencies

---

## [1.0.2]

### Changed
- Updated dependencies

---

## [1.0.1+1]

Patch release focused on autowire candidate resolution.

### Fixed
- Fixed recursive behavior when resolving a dependency with multiple candidate types.
- Added additional test coverage for the pod factory and its subclasses.
- Resolved failing and unstable package tests.

---

## [1.0.1]

Patch release focused on dependency alignment and maintenance.

### Fixed
- Updated dependency pins and performed internal housekeeping to align with
  other JetLeaf packages.

---

## [1.0.0]

Initial release.

### Added
- Core dependency injection (IoC) and pod lifecycle management APIs.
- Service registration, resolution, and lifecycle hooks for JetLeaf applications.

### Notes
- This package serves as the core runtime support for JetLeaf modules requiring
  lifecycle management and dependency injection primitives. Any future breaking
  changes will be documented with clear migration guidance.

---

## Links

- Homepage: https://jetleaf.hapnium.com  
- Documentation: https://jetleaf.hapnium.com/docs/pod  
- Repository: https://github.com/jetleaf/jetleaf_pod  
- Issues: https://github.com/jetleaf/jetleaf_pod/issues  

---

**Contributors:** Hapnium & JetLeaf contributors