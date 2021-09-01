# NetApp Ontap Storage As Built Report Changelog
## [0.3] - 2021-90-01

### Changed

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

  - Added network interfaces (Cluster, Management, Intercluster & Data)

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

## [0.2] - 2021-06-26

### Changed

- Add HealthCheck Support

- Add Report Info for Disk,License,Shelf,Service-Processor & AutoSupport

- Fix Code Indentation

- Add Report Sample Images and HTML file

## [0.1] - 2021-06-14

### Changed

- Initial Report structure creation
