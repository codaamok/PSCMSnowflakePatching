# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2022-09-19

### Fixed
- The `NumberOfRetries` was incorrectly reported in the output object (it really is fixed this time)

## [0.1.1] - 2022-09-19
### Added
- New parameters for `Invoke-CMSnowflakePatching`: `RebootTimeoutMins`, `InstallUpdatesTimeoutMins`, `SoftwareUpdateScanCycleTimeoutMins`, `InvokeSoftwareUpdateInstallTimeoutMins`. These were previously hardcoded values within the function.

### Fixed
- The `NumberOfRetries` was incorrectly reported in the output object

## [0.1.0] - 2022-09-18
### Added
- Initial release

[Unreleased]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.2..HEAD
[0.1.2]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.1..0.1.2
[0.1.1]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.0..0.1.1
[0.1.0]: https://github.com/codaamok/PSCMSnowflakePatching/tree/0.1.0