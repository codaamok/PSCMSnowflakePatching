# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- New parameter `-UpdateNameFilter` for `Invoke-CMSnowflakePatching`

## [0.3.0] - 2022-09-23
### Added
- New properties added to output object: `OperatingSystem` (hidden), `PingResponse` (hidden), `LastBootUpTime` (hidden), and `TotalTime`.

### Fixed
- Property `NumberOfAttempts` was missing from output object if there were no updates to install on target host. Old and unused property name `NumberOfRetries` was there instead.

## [0.2.2] - 2022-09-22
### Fixed
- If an update returned a pending reboot, and the system rebooted, the output object would suggest a pending reboot is still required despite the update being successfully installed
- Removed null values in error records causing non-terminators when trying to throw a terminating error with said error record, lol.

## [0.2.1] - 2022-09-20
### Fixed
- `Invoke-CMSnowflakePatching` had incorrect logic to determine if target host had finished rebooting

## [0.2.0] - 2022-09-19
### Changed
- Renamed parameter `-Retry` to `-Attempts` for `Invoke-CMSnowflakePatching`

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

[Unreleased]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.3.0..HEAD
[0.3.0]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.2.2..0.3.0
[0.2.2]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.2.1..0.2.2
[0.2.1]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.2.0..0.2.1
[0.2.0]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.2..0.2.0
[0.1.2]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.1..0.1.2
[0.1.1]: https://github.com/codaamok/PSCMSnowflakePatching/compare/0.1.0..0.1.1
[0.1.0]: https://github.com/codaamok/PSCMSnowflakePatching/tree/0.1.0