- [] Network Port Diagram
  - [] Cluster Network Ports:
    - [] Document all ports and lifs used by the cluster nodes for cluster communication.
  - [] Network Ports:
    - [] Ifgrps:
      - [] Document all ifgrps used in the cluster and their associated ports.
    - [] Vlan Interface Ports:
    - [] Document all ports used by management access to the cluster nodes.
    - [] Document all ports used for replication traffic.

- [] Vserver Diagram
  - [] Document all vservers running on the cluster.
  - [] Document the purpose of each vserver.
  - [] Document the data access methods used by each vserver (NFS, SMB, iSCSI, etc.).
  - [] Document the storage resources allocated to each vserver.
  - [] Data Network Ports:
    - [] Document all ports used for data access to the vservers running on the cluster

- [] Add Per Volumes Export Policies
- [] Implement InfoLevel 1/2 on every section
  - Example
    - Aggegate Option
    - Volumes Options
    - Lun Summary vs Lun Full Information

- [] Vserver Information
  - [] Add Vserver Lifs
      - [] IP


```powershell
$password = ConvertTo-SecureString "SuperSecret" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("admin", $password)

Connect-NcController 192.168.7.60 -Credential $cred

Import-Module AsBuiltReport.NetApp.ONTAP -Force
Import-Module NetApp.ONTAP -Force
Import-Module Diagrammer.Core -Force

New-AsBuiltReport -Report NetApp.ONTAP -AsBuiltConfigFilePath "$($env:HOME)\script\AsBuiltReport.json" -OutputFolderPath "$($env:HOME)\" -Target 192.168.7.60 -Format HTML -EnableHealthCheck -Credential $Cred -ReportConfigFilePath "$($env:HOME)\script\AsBuiltReport.NetApp.ONTAP.json"
```
