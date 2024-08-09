# :arrows_counterclockwise: NetApp ONTAP Storage As Built Report Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.7] - 2024-08-09

### Added

- Initial Vserver NVME support
- Added option for MetroCluster volume exclusions (*.mc) @MicKBfr

### Changed

- Update the Eomm/why-don-t-you-tweet action to v2.0.0
- General code cleanup/improvements
- Increased Required Modules version:
  - AsBuiltReport.Core v1.4.0
  - NetApp.Ontap v9.15.1.2407

### Fixed

- Fix [#40](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/40)
- Fix [#41](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/41)
- Fix [#42](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/42)
- Fix [#43](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/43)

## [0.6.6] - 2023-08-07

### Changed

- Improved bug and feature request templates
- Changed default logo from NetApp to the AsBuiltReport logo due to licensing requirements
- Changed default report style font to 'Segoe Ui'
- Changed Required Modules to AsBuiltReport.Core v1.3.0

### Fixed

- Fix [#35](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/35)

## [0.6.5] - 2022-11-06

### Added

- Added aggregate spare reporting [#26](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/26)
- Added Ontap Multi Admin Approval [#29](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/29)
- Added Consistency Group Support [#28](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/28)
- Added Audit Logs Support [#31](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/31)
- Added Audit log destination [#30](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/30)

### Fixed

- Fix #22
- Fix #23
- Fix #24
- Close #29
- Close #26
- Close #28
- Close #30
- Close #31
- Fixed SNMP section not shown in report.

## [0.6.4] - 2022-05-14

### Added

- Added Option to allow Vserver (SVM) filtering.

### Changed

- Migrated Sample Report URL to htmlpreview.github.io
- The minimum requirement for the AsBuiltReport.Core module has been increased to version 1.2.0.
- The minimum requirement for the NetApp.ONTAP module has been increased to version 9.10.1.2111

## [0.6.3] - 2022-01-31

### Changed

- Implemented better error handling.

## [0.6.2] - 2022-01-12

### Added

- Added more health check discovery.

### Changed

- Removes unneeded paragraph section.

### Fixed

- Fix for table caption error message "List table captions are only supported on tables with a single row"

## [0.6.1] - 2021-12-02

### Added

- None

### Changed

- Updated Changelog to reflect v0.6.0 changes

### Fixed

- None

## [0.6.0] - 2021-12-02

### Added

- Added Vserver CIFS Client Session information.
- Added Storage Aggregate Option Information.

### Changed

- The network section has been changed to show the content per node.
- Updated HTML Sample Report.
- Implemented the ability to specify the InfoLevel option.

### Fixed

- Fix Volume SnapShot Section logic to display content only when there are snapshots data available.

## [0.5.0] - 2021-10-11

### Added

- Added function to convert from empty content to "-".

### Changed

- Changed main report to use per Node/Vserver filtering.
- Changed Get-NetAppOntapAPI function to allow per Vserver Filtering.

### Fixed

- Fix to better detect unhealthy node.
- Fix for ASUP Health Check.

## [0.4.0] - 2021-09-22

- Add additional health check section support
- Added function to convert from True/False to Yes/No
- Implement a function to convert from T/F to Y/N
- Use HTTPS to connect to the Array (by Default)
- Add default option to the Switch cases.

### Changed

- Update Document Style colors

### Fixed

- Fix code to better support Powershell v5.X ([Fix #3](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues/3))

## [0.3.0] - 2021-09-01

### Changed in [0.3.0]

- Add aditional halthCheck section support
- Added aditional node section items:
  - Added node vol0 information and healthcheck
- Added aditional storage section items:
  - Added failed disk healthCheck
  - Added shelf inventory
  - Added cloud tier (Fabric Pool)
  - Added fabriPool object store configuration information
- Added aditional network section items:
  - Added IPSpace, Ifgrp, Vlan, Broadcast Domain, Subnet and Routes section support
    - Added per network interface routes information
  - Added network interfaces (Cluster, Management, Intercluster & Data) information and healthcheck
- Added network section:
  - Added SVM Status, Storage Volumes, Volumes QoS Policy, FlexGroup Volumes, Flexclone, Flexcache, Volumes Snapshot, Qtree & Quota
    - Added vserver protocol support (Cifs, NFs, FCP, ISCSI & S3)
      - Added protocol healthcheck support
- Added replication section:
  - Added cluster peer information
  - Added vserver peer information
  - Added SnapMirror/SnapVault information and healthcheck
  - Added ontap mediators information and healthcheck
- Added efficiency section:
  - Added aggregate efficiency information and healthcheck
  - Added volume efficiency information and healthcheck
- Added security section:
  - Added local user information and healthcheck
  - Added vserver ssl certificate information
  - Added Key Management Service (KMS) information and healthcheck
  - Added aggregate encryption (NAE) information
  - Added volume encryption (NVE)
  - Added snaplock information
- Added system configuration section:
  - Added system image configuration information
  - Added system web service information
  - Added dns configuration information
  - Added snmp configuration information
  - Added configuration backup information and healthcheck
  - Added ems configuration information
  - Added ntp and timezone configuration information
- Fix code logic to better detect of un-configured features
- Add fix for powershell v6+ support
- Add GitHub release workflow
- Update NetApp style script to align with NetApp branding colours & guidelines
- Update README & CHANGELOG
- Correct module version in module manifest

## [0.2.0] - 2021-06-26

### Changed in [0.2.0]

- Add HealthCheck Support
- Add Report Info for Disk,License,Shelf,Service-Processor & AutoSupport
- Fix Code Indentation
- Add Report Sample Images and HTML file

## [0.1.0] - 2021-06-14

### Changed in [0.1.0]

- Initial Report structure creation
