# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure with modular architecture
- Core module for system initialization and event management
- Tracking module for afflictions, balances, and resources
- Curing module with priority-based curing logic
- Offense module with ability queuing system
- UI module for combat information display
- Comprehensive configuration system with example file
- Documentation (README, ARCHITECTURE, CONTRIBUTING)
- GitHub issue templates for bug reports and feature requests
- GitHub Actions workflow for Lua linting
- MIT License
- .gitignore for Lua/Mudlet development

## [0.1.0] - TBD

### Added
- First alpha release
- Basic affliction tracking
- Simple curing system
- Manual offense support
- Basic UI displays

---

## Version History

### Versioning Scheme

- **Major version (X.0.0)**: Incompatible API changes or major rewrites
- **Minor version (0.X.0)**: New features, backward-compatible
- **Patch version (0.0.X)**: Bug fixes, backward-compatible

### Release Cycle

- **Alpha**: Early development, unstable, may have bugs
- **Beta**: Feature-complete, testing phase, may have minor bugs
- **Stable**: Production-ready, well-tested

---

## Guidelines for Maintaining This Changelog

### Types of Changes

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Features that will be removed in future versions
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

### Example Entry

```markdown
## [1.2.0] - 2024-01-15

### Added
- New affliction: vertigo tracking and curing
- Support for Bard class abilities
- Custom strategy builder in UI

### Changed
- Improved curing priority algorithm for faster response
- Updated UI theme with better contrast

### Fixed
- Fixed bug where paralysis wasn't being cured properly
- Corrected balance tracking for dual-wielding classes

### Security
- Fixed XSS vulnerability in target name display
```

---

[Unreleased]: https://github.com/haterade22/LEVI-Achaea/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/haterade22/LEVI-Achaea/releases/tag/v0.1.0
