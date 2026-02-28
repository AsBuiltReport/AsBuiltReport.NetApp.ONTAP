- [x] Migrate [PSCustomObject] @{ to $inObj
- [x] Finish Get-AbrOntapDiskInv.ps1
  - [x] Add Firmware
  - [x] Add Type
  - [x] Add Aggregate
  - [x] Fix Capacity Formatting

- [ ] Aggregate Diagram
- [ ] Add Raid group information to the Aggregate Diagram
- [ ] Add Disk information to the Aggregate Diagram

- [] Network Port Diagram
  - [] Cluster Network Ports:
    - [] Document all ports and lifs used by the cluster nodes for cluster communication.
  - [] Network Ports:
    - [] Ifgrps:
      - [] Document all ifgrps used in the cluster and their associated ports.
    - [] Vlan Interface Ports:
    - [] Document all ports used by management access to the cluster nodes.
    - [] Document all ports used for replication traffic.

- [x] Vserver Diagram
  - [x] Document all vservers running on the cluster.
  - [x] Document the purpose of each vserver.
  - [x] Document the data access methods used by each vserver (NFS, SMB, iSCSI, etc.).
  - [x] Document the storage resources allocated to each vserver.
  - [x] Data Network Ports:
    - [x] Document all ports used for data access to the vservers running on the cluster

- [] Add Health check for Nodes without intercluster interface (Replication Information)

- [x] Add Per Volumes Export Policies
- [] Implement InfoLevel 1/2 on every section
  - Example
    - Aggegate Option
    - Volumes Options
    - Lun Summary vs Lun Full Information

- [] Vserver Information
  - [x] Add Vserver Lifs
      - [] IP
  - [] Add healthcheck for no route in vserver
    - [] Configure at least one route to ensure client can assess the vserver services.


```powershell
Import-Module AsBuiltReport.NetApp.ONTAP -Force
Import-Module NetApp.ONTAP -Force
Import-Module Diagrammer.Core -Force
Import-Module AsBuiltReport.Chart -Force

New-AsBuiltReport -Report NetApp.ONTAP -AsBuiltConfigFilePath "$($env:HOME)/script/AsBuiltReport.json" -OutputFolderPath "$($env:HOME)" -Target 192.168.7.60 -Format HTML -EnableHealthCheck -UserName 'admin' -Password 'P@ssw0rd' -ReportConfigFilePath "$($env:HOME)/script/AsBuiltReport.NetApp.ONTAP.json"
```

```powershell
$password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("admin", $password)

Connect-NcController 192.168.5.72 -Credential $Cred

Import-Module AsBuiltReport.NetApp.ONTAP -Force
Import-Module NetApp.ONTAP -Force
Import-Module Diagrammer.Core -Force
Import-Module AsBuiltReport.Chart -Force

New-AsBuiltReport -Report NetApp.ONTAP -AsBuiltConfigFilePath "$($env:HOME)/script/AsBuiltReport.json" -OutputFolderPath "$($env:HOME)" -Target 192.168.5.72 -Format HTML -EnableHealthCheck -UserName 'admin' -Password 'P@ssw0rd' -ReportConfigFilePath "$($env:HOME)/script/AsBuiltReport.NetApp.ONTAP.json"

```powershell
$password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("admin", $password)

Connect-NcController 172.23.4.60 -Credential $Cred

Import-Module AsBuiltReport.NetApp.ONTAP -Force
Import-Module NetApp.ONTAP -Force
Import-Module Diagrammer.Core -Force
Import-Module AsBuiltReport.Chart -Force

New-AsBuiltReport -Report NetApp.ONTAP -AsBuiltConfigFilePath "$($env:HOME)/script/AsBuiltReport.json" -OutputFolderPath "$($env:HOME)" -Target 172.23.4.60 -Format HTML -EnableHealthCheck -Credential $Cred -ReportConfigFilePath "$($env:HOME)/script/AsBuiltReport.NetApp.ONTAP.json"
```