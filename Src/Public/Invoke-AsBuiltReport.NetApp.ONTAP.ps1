function Invoke-AsBuiltReport.NetApp.ONTAP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of NetApp ONTAP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of NetApp ONTAP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.0
        Author:         Jonathan Colon Feliciano
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # General information
    $TextInfo = (Get-Culture).TextInfo

    #Connect to Ontap Storage Array using supplied credentials
    foreach ($OntapArray in $Target) {
        Try {
            Write-PScriboMessage "Connecting to NetApp Storage '$OntapArray'."
            $Array = Connect-NcController -Name $OntapArray -Credential $Credential -ErrorAction Stop -HTTPS
        } Catch {
            Write-Verbose "Unable to connect to the $OntapArray Array"
            throw
        }
        $ClusterInfo = Get-NcCluster -Controller $Array

        #---------------------------------------------------------------------------------------------#
        #                                 Cluster Section                                             #
        #---------------------------------------------------------------------------------------------#
        Section -Style Heading1 "Report for Cluster $($ClusterInfo.ClusterName)" {
            Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
            BlankLine
            #region Cluster Section
            Write-PScriboMessage "Cluster InfoLevel set at $($InfoLevel.Cluster)."
            if ($InfoLevel.Cluster -gt 0) {
                Section -Style Heading2 'Cluster Information' {
                    # Ontap Cluster
                    Get-AbrOntapCluster
                    Section -Style Heading3 'Cluster HA Status' {
                        Paragraph "The following section provides a summary of the Cluster HA Status on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapClusterHA
                    }
                    Section -Style Heading3 'Cluster AutoSupport Status' {
                        Paragraph "The following section provides a summary of the Cluster AutoSupport Status on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapClusterASUP
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 Node Section                                                #
        #---------------------------------------------------------------------------------------------#

            Write-PScriboMessage "Node InfoLevel set at $($InfoLevel.Node)."
            if ($InfoLevel.Node -gt 0) {
                Section -Style Heading2 'Node Summary' {
                    Paragraph "The following section provides a summary of the Node on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Node Inventory' {
                        Paragraph "The following section provides the node inventory on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNodes
                        Section -Style Heading4 'Node Vol0 Inventory' {
                            Paragraph "The following section provides the node vol0 inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNodeStorage
                        }
                        Section -Style Heading4 'Node Hardware Inventory' {
                            Paragraph "The following section provides the node hardware inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNodesHW
                        }
                        if (Get-NcServiceProcessor  -Controller $Array | Where-Object {$NULL -ne $_.IpAddress -and $NULL -ne $_.MacAddress}) {
                            Section -Style Heading4 'Node Service-Processor Inventory' {
                                Paragraph "The following section provides the node service-processor information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNodesSP
                            }
                        }
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 Storage Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Storage InfoLevel set at $($InfoLevel.Node)."
            if ($InfoLevel.Storage -gt 0) {
                Section -Style Heading2 'Storage Summary' {
                    Paragraph "The following section provides a summary of the storage hardware on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Aggregate Inventory' {
                        Paragraph "The following section provides the Aggregates on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapStorageAGGR
                        if (Get-NcAggrObjectStore -Controller $Array) {
                            Section -Style Heading4 'FabricPool' {
                                Paragraph "The following section provides the FabricPool information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapStorageFabricPool
                                if (Get-NcAggrObjectStoreConfig -Controller $Array) {
                                    Section -Style Heading5 'FabriPool Object Store Configuration' {
                                        Paragraph "The following section provides the FabriPool Object Store Configuration on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapEfficiencyAggrConfig
                                    }
                                }
                            }
                        }
                    }
                    Section -Style Heading3 'Disk Summary' {
                        Paragraph "The following section provides the disk summary information on controller $($ClusterInfo.ClusterName)."
                        BlankLine
                        Section -Style Heading4 'Per Node Disk Assignment' {
                            Paragraph "The following section provides the number of disks assigned to each controller on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskAssign
                        }
                        $Nodes = Get-NcNode -Controller $Array
                        foreach ($Node in $Nodes) {
                            Section -Style Heading4 "Disk Owned by Node $Node" {
                                Paragraph "The following section provides the inventory of disks owned by each controller on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapDiskOwner -Node $Node
                            }
                        }
                        Section -Style Heading4 'Disk Container Type' {
                            Paragraph "The following section provides a summary of disk status on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskType
                        }
                        if (Get-NcDisk -Controller $Array | Where-Object{ $_.DiskRaidInfo.ContainerType -eq "broken" }) {
                            Section -Style Heading4 'Failed Disk' {
                                Paragraph "The following section show failed disks on cluster $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapDiskBroken
                            }
                        }
                        If (Get-NcNode -Controller $Array | Select-Object Node | Get-NcShelf -Controller $Array -ErrorAction SilentlyContinue) {
                            Section -Style Heading3 'Shelf Inventory' {
                                Paragraph "The following section provides the available Shelf on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapDiskShelf
                            }
                        }
                        Section -Style Heading4 'Disk Inventory' {
                            Paragraph "The following section provides the Disks installed on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskInv
                        }
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 License Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "License InfoLevel set at $($InfoLevel.License)."
            if ($InfoLevel.License -gt 0) {
                Section -Style Heading2 'Licenses Summary' {
                    Paragraph "The following section provides a summary of the license usage on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Get-AbrOntapClusterLicense
                    Section -Style Heading4 'License Feature' {
                        Paragraph "The following section provides the License Feature Usage on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapClusterLicenseUsage
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 Network Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Network InfoLevel set at $($InfoLevel.Network)."
            if ($InfoLevel.Network -gt 0) {
                Section -Style Heading2 'Network Summary' {
                    Paragraph "The following section provides a summary of the networking features on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'IPSpace' {
                        Paragraph "The following section provides the IPSpace information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNetworkIpSpace
                        $Nodes = Get-NcNode -Controller $Array
                        foreach ($Node in $Nodes) {
                            Section -Style Heading4 "$Node Network Ports" {
                                Paragraph "The following section provides per ode physical ports on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkPort -Node $Node
                            }
                        }
                        foreach ($Node in $Nodes) {
                            if (Get-NcNetPortIfgrp -Node $Node -Controller $Array) {
                                Section -Style Heading4 "$Node Network Link Aggregation Group" {
                                    Paragraph "The following section provides per Node IFGRP Aggregated Ports on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapNetworkIfgrp -Node $Node
                                }
                            }
                        }
                        foreach ($Node in $Nodes) {
                            if (Get-NcNetPortVlan -Node $Node -Controller $Array) {
                                Section -Style Heading4 "$Node Vlans" {
                                    Paragraph "The following section provides the Vlan information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapNetworkVlans -Node $Node
                                }
                            }
                        }
                        Section -Style Heading4 'Broadcast Domain' {
                            Paragraph "The following section provides the Broadcast Domain information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkBdomain
                        }
                        Section -Style Heading4 'Failover Group' {
                            Paragraph "The following section provides the Failover Group information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkFailoverGroup
                        }
                        if (Get-NcNetSubnet -Controller $Array) {
                            Section -Style Heading4 'Network Subnet' {
                                Paragraph "The following section provides the Subnet information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkSubnet
                            }
                        }
                        $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -ne "node" -and $_.VserverType -ne "system" } | Select-Object -ExpandProperty Vserver
                        foreach ($SVM in $Vservers) {
                            if (Get-NcNetRoute -VserverContext $SVM -Controller $Array) {
                                Section -Style Heading4 "$SVM Vserver Routes" {
                                    Paragraph "The following section provides the Routes information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapNetworkRoutes -Vserver $SVM
                                    Section -Style Heading5 "Network Interface Routes" {
                                        Paragraph "The following section provides the Per Network Interface Routes information on $($SVM)."
                                        BlankLine
                                        Get-AbrOntapNetworkRouteLifs -Vserver $SVM
                                    }
                                }
                            }
                        }
                        Section -Style Heading4 'Network Interfaces' {
                            Paragraph "The following section provides the Network Interfaces information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkMgmt
                        }
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 Vserver Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Vserver InfoLevel set at $($InfoLevel.Vserver)."
            if ($InfoLevel.Vserver -gt 0) {
                if (Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data"}) {
                    Section -Style Heading2 'Vserver Summary' {
                        Paragraph "The following section provides a summary of the vserver information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" } | Select-Object -ExpandProperty Vserver
                        foreach ($SVM in $Vservers) {
                            Section -Style Heading3 "$SVM Vserver Configuration" {
                                Paragraph "The following section provides the configuration of the vserver $($SVM)."
                                BlankLine
                                Get-AbrOntapVserverSummary -Vserver $SVM
                                if (Get-NcVol -Controller $Array | Select-Object -ExpandProperty VolumeQosAttributes) {
                                    Section -Style Heading4 'Volumes QoS Policy' {
                                        Paragraph "The following section provides the Vserver QoS Configuration on $($ClusterInfo.ClusterName)."
                                        Section -Style Heading5 'Volumes Fixed QoS Policy' {
                                            Paragraph "The following section provides the Volume Fixed QoS Group information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQosGPFixed
                                        }
                                        Section -Style Heading5 'Volumes Adaptive QoS Policy' {
                                            Paragraph "The following section provides the Volumes Adaptive QoS Group information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQosGPAdaptive
                                        }
                                    }
                                }
                                if (Get-NcVol -VserverContext $SVM  -Controller $Array | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}) {
                                    Section -Style Heading4 "Storage Volumes" {
                                        Paragraph "The following section provides $SVM Volumes Information on $($SVM)."
                                        BlankLine
                                        Get-AbrOntapVserverVolumes -Vserver $SVM
                                        if (Get-NcVol -VserverContext $SVM -Controller $Array | Select-Object -ExpandProperty VolumeQosAttributes) {
                                            Section -Style Heading4 "Per Volumes QoS Policy" {
                                                Paragraph "The following section provides the Vserver per Volumes QoS Configuration on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesQos -Vserver $SVM
                                            }
                                        }
                                        if (Get-NcVol -VserverContext $SVM -Controller $Array | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsFlexgroup -eq "True"}) {
                                            Section -Style Heading4 "FlexGroup Volumes" {
                                                Paragraph "The following section provides the Vserver FlexGroup Volumes Configuration on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesFlexgroup -Vserver $SVM
                                            }
                                        }
                                        if (Get-NcVolClone -VserverContext $SVM -Controller $Array) {
                                            Section -Style Heading4 "Flexclone Volumes" {
                                                Paragraph "The following section provides the Vserver Flexclone Volumes Configuration on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesFlexclone -Vserver $SVM
                                            }
                                        }
                                        if ((Get-NcFlexcacheConnectedCache -VserverContext $SVM -Controller $Array) -or (Get-NcFlexcache -Controller $Array)) {
                                            Section -Style Heading4 "Flexcache Volumes" {
                                                Paragraph "The following section provides the Vserver Flexcache Volumes Configuration on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesFlexcache -Vserver $SVM
                                            }
                                        }
                                    }
                                    if (Get-NcVol -VserverContext $SVM -Controller $Array | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'} | Get-NcSnapshot -Controller $Array) {
                                        Section -Style Heading4 "Volumes Snapshot Configuration" {
                                            Paragraph "The following section provides the Vserver Volumes Snapshot Configuration on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumeSnapshot -Vserver $SVM
                                            if ($HealthCheck.Vserver.Snapshot) {
                                                Get-AbrOntapVserverVolumeSnapshotHealth -Vserver $SVM
                                            }
                                        }
                                    }
                                    if (Get-NcExportRule -VserverContext $SVM -Controller $Array) {
                                        Section -Style Heading4 "Export Policy" {
                                            Paragraph "The following section provides the Vserver Volumes Export policy Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesExportPolicy -Vserver $SVM
                                        }
                                    }
                                    if (Get-NcQtree -VserverContext $SVM -Controller $Array | Where-Object {$NULL -ne $_.Qtree}) {
                                        Section -Style Heading4 "Qtrees" {
                                            Paragraph "The following section provides the Vserver Volumes Qtree Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQtree -Vserver $SVM
                                        }
                                    }
                                    if (Get-NcQuota -VserverContext $SVM -Controller $Array) {
                                        Section -Style Heading4 "Volume Quota" {
                                            Paragraph "The following section provides the Vserver Volumes Quota Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQuota -Vserver $SVM
                                        }
                                    }
                                    Section -Style Heading4 "Protocol Information Summary" {
                                        Paragraph "The following section provides a summary of the Vserver protocol information on $($SVM)."
                                        BlankLine
                                        #---------------------------------------------------------------------------------------------#
                                        #                                 NFS Section                                                 #
                                        #---------------------------------------------------------------------------------------------#
                                        if (Get-NcNfsService -VserverContext $SVM -Controller $Array) {
                                            Section -Style Heading5 "NFS Services" {
                                                Paragraph "The following section provides the NFS Service Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverNFSSummary -Vserver $SVM
                                                Section -Style Heading6 "NFS Options" {
                                                    Paragraph "The following section provides the NFS Service Options Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverNFSOptions -Vserver $SVM
                                                }
                                                if (Get-NcVserver -VserverContext $SVM -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' } | Get-NcNfsExport) {
                                                    Section -Style Heading6 "NFS Volume Export" {
                                                        Paragraph "The following section provides the VServer NFS Service Exports Information on $($SVM)."
                                                        BlankLine
                                                        Get-AbrOntapVserverNFSExport -Vserver $SVM
                                                    }
                                                }
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                                 CIFS Section                                                #
                                        #---------------------------------------------------------------------------------------------#
                                        if (Get-NcVserver -VserverContext $SVM -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' } | Get-NcCifsServerStatus -Controller $Array) {
                                            Section -Style Heading5 "CIFS Services Summary" {
                                                Paragraph "The following section provides the CIFS Service Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSSummary -Vserver $SVM
                                                Section -Style Heading6 'CIFS Service Configuration' {
                                                    Paragraph "The following section provides the Cifs Service Configuration Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSSecurity -Vserver $SVM
                                                }
                                                Section -Style Heading6 'CIFS Domain Controller' {
                                                    Paragraph "The following section provides the Connected Domain Controller Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSDC -Vserver $SVM
                                                }
                                                Section -Style Heading6 'CIFS Local Group' {
                                                    Paragraph "The following section provides the Cifs Service Local Group Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSLocalGroup -Vserver $SVM
                                                    BlankLine
                                                    Paragraph "The following section provides the Cifs Service Local Group Memeber Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSLGMembers -Vserver $SVM
                                                }
                                                Section -Style Heading6 'CIFS Options' {
                                                    Paragraph "The following section provides the CIFS Service Options Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSOptions -Vserver $SVM
                                                }
                                                Section -Style Heading6 'CIFS Share' {
                                                    Paragraph "The following section provides the CIFS Service Shares Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSShare -Vserver $SVM
                                                    BlankLine
                                                    Paragraph "The following section provides the CIFS Shares Properties & Acl Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverCIFSShareProp -Vserver $SVM
                                                }
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                                 ISCSI Section                                               #
                                        #---------------------------------------------------------------------------------------------#
                                        if ( Get-NcIscsiService  -Controller $Array| Where-Object {$_.Vserver -eq $SVM} ) {
                                            Section -Style Heading5 "ISCSI Services Summary" {
                                                Paragraph "The following section provides the ISCSI Service Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverIscsiSummary -Vserver $SVM
                                                Section -Style Heading6 "ISCSI Interface" {
                                                    Paragraph "The following section provides the ISCSI Interface Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverIscsiInterface -Vserver $SVM
                                                }
                                                if (Get-NcIscsiInitiator -VS $SVM -Controller $Array) {
                                                    Section -Style Heading6 "ISCSI Client Initiator" {
                                                        Paragraph "The following section provides the ISCSI Interface Information on $($SVM)."
                                                        BlankLine
                                                        Get-AbrOntapVserverIscsiInitiator -Vserver $SVM
                                                    }
                                                }
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                                 FCP Section                                                 #
                                        #---------------------------------------------------------------------------------------------#
                                        if ( Get-NcFcpService -Controller $Array | Where-Object {$_.Vserver -eq $SVM} ) {
                                            Section -Style Heading5 'FCP Services Summary' {
                                                Paragraph "The following section provides the FCP Service Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverFcpSummary -Vserver $SVM
                                                Section -Style Heading6 'FCP Interface' {
                                                    Paragraph "The following section provides the FCP Interface Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverFcpInterface -Vserver $SVM
                                                }
                                                Section -Style Heading6 'FCP Physical Adapter' {
                                                    Paragraph "The following section provides the FCP Physical Adapter Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverFcpAdapter
                                                }
                                            }
                                        }
                                        if (Get-NcLun -Controller $Array | Where-Object {$_.Vserver -eq $SVM}) {
                                            Section -Style Heading5 'FCP/ISCSI Lun Storage' {
                                                Paragraph "The following section provides the Lun Storage Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverLunStorage -Vserver $SVM
                                                if (Get-NcIgroup -Vserver $SVM -Controller $Array) {
                                                    Section -Style Heading6 'Igroup Mapping' {
                                                        Paragraph "The following section provides the Igroup Mapping Information on $($SVM)."
                                                        BlankLine
                                                        Get-AbrOntapVserverLunIgroup -Vserver $SVM
                                                    }
                                                    if ($Healthcheck.Vserver.Status) {
                                                        Section -Style Heading6 'HealthCheck - Non-Mapped Lun Information' {
                                                            Paragraph "The following section provides information of Non Mapped Lun on $($SVM)."
                                                            BlankLine
                                                            Get-AbrOntapVserverNonMappedLun -Vserver $SVM
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                                 S3 Section                                                  #
                                        #---------------------------------------------------------------------------------------------#
                                        $S3Data = Get-NetAppOntapAPI -uri "/api/protocols/s3/services?svm=$SVM&fields=*&return_records=true&return_timeout=15"
                                        if ($S3Data) {
                                            Section -Style Heading5 'S3 Services Configuration Summary' {
                                                Paragraph "The following section provides the S3 Service Information on $($SVM)."
                                                BlankLine
                                                Get-AbrOntapVserverS3Summary -Vserver $SVM
                                                Section -Style Heading6 'S3 Buckets' {
                                                    Paragraph "The following section provides the S3 Bucket Information on $($SVM)."
                                                    BlankLine
                                                    Get-AbrOntapVserverS3Bucket -Vserver $SVM
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        #---------------------------------------------------------------------------------------------#
        #                                 Replication Section                                         #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Replication InfoLevel set at $($InfoLevel.Replication)."
            if ($InfoLevel.Replication -gt 0) {
                if (Get-NcClusterPeer -Controller $Array) {
                    Section -Style Heading2 'Replication Summary' {
                        Paragraph "The following section provides a summary of the replication information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Section -Style Heading3 'Cluster Peer Information' {
                            Paragraph "The following section provides the Cluster Peer information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapRepClusterPeer
                        }
                        if (Get-NcVserverPeer -Controller $Array) {
                            Section -Style Heading3 'Vserver Peer Information' {
                                Paragraph "The following section provides the Vserver Peer information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapRepVserverPeer
                                if (Get-NcSnapmirror -Controller $Array) {
                                    Section -Style Heading4 'SnapMirror Relationship Information' {
                                        Paragraph "The following section provides the SnapMirror Relationship information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapRepRelationship
                                        Section -Style Heading5 'SnapMirror Replication History Information' {
                                            Paragraph "The following section provides the SnapMirror Operation information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapRepHistory
                                        }
                                    }
                                }
                                if (Get-NcSnapmirrorDestination -Controller $Array) {
                                    Section -Style Heading4 'SnapMirror Destinations Information' {
                                        Paragraph "The following section provides the SnapMirror (List-Destination) information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapRepDestinations
                                    }
                                }
                                if (Get-NetAppOntapAPI -uri "/api/cluster/mediators?") {
                                    Section -Style Heading4 'Ontap Mediator Information' {
                                        Paragraph "The following section provides the SnapMirror Mediator information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapRepMediator
                                    }
                                }
                            }
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Efficiency Section                                          #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Efficiency InfoLevel set at $($InfoLevel.Efficiency)."
            if ($InfoLevel.Efficiency -gt 0) {
                $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" } | Select-Object -ExpandProperty Vserver
                if (Get-NcAggrEfficiency -Controller $Array) {
                    Section -Style Heading2 'Efficiency Summary' {
                        Paragraph "The following section provides the Storage Efficiency Saving information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapEfficiencyConfig
                        Section -Style Heading3 'Aggregate Total Efficiency' {
                            Paragraph "The following section provides the Aggregate Efficiency Saving information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapEfficiencyAggr
                            foreach ($SVM in $Vservers) {
                                $VolFilter = Get-ncvol -VserverContext $SVM -Controller $Array | Where-Object {$_.State -eq "online"}
                                if (Get-NcEfficiency -Volume $VolFilter.Name -Controller $Array | Where-Object {$_.Name -ne "vol0"}) {
                                    Section -Style Heading4 "$SVM Vserver Volume Deduplication" {
                                        Paragraph "The following section provides the Volume Deduplication Summary on $($SVM)."
                                        BlankLine
                                        Get-AbrOntapEfficiencyVolSisStatus -Vserver $SVM
                                        Section -Style Heading5 "Volume Efficiency" {
                                            Paragraph "The following section provides the Volume Efficiency Saving Detailed information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapEfficiencyVol -Vserver $SVM
                                        }
                                        Section -Style Heading5 "Volume Efficiency Detail" {
                                            Paragraph "The following section provides the Volume Efficiency Saving Detailed information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapEfficiencyVolDetailed -Vserver $SVM
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Security Section                                          #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Security InfoLevel set at $($InfoLevel.Security)."
            if ($InfoLevel.Security -gt 0) {
                $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" } | Select-Object -ExpandProperty Vserver
                Section -Style Heading2 'Security Summary' {
                    Paragraph "The following section provides the Security related information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    foreach ($SVM in $Vservers) {
                        if (Get-NcUser -Vserver $SVM -Controller $Array) {
                            Section -Style Heading3 "$SVM Vserver Local User" {
                                Paragraph "The following section provides the Local User information on $($SVM)."
                                BlankLine
                                Get-AbrOntapSecurityUsers -Vserver $SVM
                            }
                        }
                    }
                    if (Get-NcSecuritySsl -Controller $Array) {
                        Section -Style Heading3 'Vserver SSL Certificate' {
                            Paragraph "The following section provides the Vserver SSL Certificates information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySSLVserver
                            Paragraph "The following section provides the Vserver SSL Certificates Detailed information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySSLDetailed
                        }
                    }
                    if (Get-NcSecurityKeyManagerKeyStore -ErrorAction SilentlyContinue -Controller $Array) {
                        Section -Style Heading3 'Key Management Service (KMS)' {
                            Paragraph "The following section provides the Key Management Service type on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityKMS
                            if (Get-NcSecurityKeyManagerExternal -Controller $Array) {
                                Section -Style Heading4 'External Key Management Service (KMS)' {
                                    Paragraph "The following section provides the External KMS information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapSecurityKMSExt
                                    Section -Style Heading5 'External Key Management Service (KMS) Status' {
                                        Paragraph "The following section provides the External KMS Status information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSecurityKMSExtStatus
                                    }
                                }
                            }
                        }
                    }
                    if (Get-NcAggr -Controller $Array) {
                        Section -Style Heading3 'Aggregate Encryption (NAE)' {
                            Paragraph "The following section provides the Aggregate Encryption (NAE) information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityNAE
                            Section -Style Heading4 'Volume Encryption (NVE)' {
                                Paragraph "The following section provides the Volume Encryption (NVE) information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSecurityNVE
                            }
                        }
                    }
                    Section -Style Heading3 'Snaplock Compliance Clock Information' {
                        Paragraph "The following section provides the Snaplock Compliance Clock information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapSecuritySnapLockClock
                        Section -Style Heading4 'Aggregate Snaplock Type Information' {
                            Paragraph "The following section provides the Aggregate Snaplock Type information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySnapLockAggr
                            Section -Style Heading5 'Volume Snaplock Type Information' {
                                Paragraph "The following section provides the Volume Snaplock Type information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSecuritySnapLockVol
                                if (Get-Ncvol -Controller $Array | Where-Object {$_.VolumeSnaplockAttributes.SnaplockType -in "enterprise","compliance"}) {
                                    Section -Style Heading6 'Snaplock Volume Attributes Information' {
                                        Paragraph "The following section provides the Snaplock Volume Attributes information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSecuritySnapLockVollAttr
                                    }
                                }
                            }
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 System Configuration Section                                #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "System Configuration InfoLevel set at $($InfoLevel.System)."
            if ($InfoLevel.System -gt 0) {
                if (Get-NcTime) {
                    Section -Style Heading2 'System Configuration Summary' {
                        Paragraph "The following section provides the Cluster System Configuration on $($ClusterInfo.ClusterName)."
                        BlankLine
                        if (Get-NcSystemImage -Controller $Array) {
                            Section -Style Heading3 'System Image Configuration' {
                                Paragraph "The following section provides the System Image Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigImage
                            }
                        }
                        if (Get-NcSystemServicesWebNode -Controller $Array) {
                            Section -Style Heading3 'System Web Service' {
                                Paragraph "The following section provides the System Web Service Status on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigWebStatus
                            }
                        }
                        if (Get-NcNetDns -Controller $Array) {
                            Section -Style Heading3 'DNS Configuration' {
                                Paragraph "The following section provides the DNS Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigDNS
                            }
                        }
                        if (Get-NcSnmp -Controller $Array | Where-Object { $NULL -ne $_.Traphost -and $NULL -ne $_.Communities}) {
                            Section -Style Heading3 'SNMP Configuration' {
                                Paragraph "The following section provides the SNMP Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigSNMP
                            }
                        }
                        if (Get-NcConfigBackupUrl -Controller $Array) {
                            Section -Style Heading3 'Configuration Backup Setting' {
                                Paragraph "The following section provides the Configuration Backup Setting on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigBackupURL
                                $Nodes = Get-NcNode -Controller $Array
                                foreach ($Node in $Nodes) {
                                    if (Get-NcConfigBackup -Node $Node -Controller $Array) {
                                        Section -Style Heading4 "$Node Configuration Backup Items" {
                                            Paragraph "The following section provides the Configuration Backup Items on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapSysConfigBackup -Node $Node
                                        }
                                    }
                                }
                            }
                        }
                        if (Get-NcEmsDestination -Controller $Array) {
                            Section -Style Heading3 'EMS Configuration' {
                                Paragraph "The following section provides the EMS Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigEMSSettings
                                $Nodes = Get-NcNode -Controller $Array
                                foreach ($Node in $Nodes) {
                                    if ($HealthCheck.System.EMS -and (Get-NcEmsMessage -Node $Node -Count 30 -Severity "emergency","alert" -Controller $Array)) {
                                        Section -Style Heading4 "$Node Emergency and Alert Messages" {
                                            Paragraph "The following section provides Cluster Emergency and Alert Messages  on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapSysConfigEMS -Node $Node
                                        }
                                    }
                                }
                            }
                        }
                        if (Get-NcTimezone -Controller $Array) {
                            Section -Style Heading3 'System Timezone Configuration' {
                                Paragraph "The following section provides the System Timezone Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigTZ
                                if (Get-NcNtpServer -Controller $Array) {
                                    Section -Style Heading4 'Network Time Protocol Configuration' {
                                        Paragraph "The following section provides the Network Time Protocol Configuration on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSysConfigNTP
                                        Section -Style Heading5 'Network Time Protocol Node Status Information' {
                                            Paragraph "The following section provides the Network Time Protocol Node Status on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapSysConfigNTPHost
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    #$global:CurrentNcController = $null
}