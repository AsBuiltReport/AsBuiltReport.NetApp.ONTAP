function Invoke-AsBuiltReport.NetApp.ONTAP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of NetApp ONTAP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of NetApp ONTAP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon Feliciano
        Twitter:
        Github:
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    # Check if the required version of Modules are installed
    Get-AbrOntapRequiredModule

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
            $Array = Connect-NcController -Name $OntapArray -Credential $Credential -ErrorAction Stop
        } Catch {
            Write-Verbose "Unable to connect to the $OntapArray Array"
            throw
        }
        $ClusterInfo = Get-NcCluster

        #region Cluster
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
                    Section -Style Heading3 'Cluster Auto Support Status' {
                        Paragraph "The following section provides a summary of the Cluster AutoSupport Status on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapClusterASUP
                    }
                }
            }
        #endregion Cluster Section
        #region Node
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
                        if (Get-NcServiceProcessor | Where-Object {$NULL -ne $_.IpAddress -and $NULL -ne $_.MacAddress}) {
                            Section -Style Heading4 'Node Service-Processor Inventory' {
                                Paragraph "The following section provides the node service-processor information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNodesSP
                            }
                        }
                    }
                }
            }#endregion Node Section
            if ($InfoLevel.Node -gt 0) {
                PageBreak
            }

        #region Storage
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
                        if (Get-NcAggrObjectStore) {
                            Section -Style Heading4 'Aggregate FabricPool Summary' {
                                Paragraph "The following section provides the FabricPool information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapStorageFabricPool
                                if (Get-NcAggrObjectStoreConfig) {
                                    Section -Style Heading5 'Aggregate  FabriPool Object Store Configuration Summary' {
                                        Paragraph "The following section provides the  FabriPool Object Store Configuration on $($ClusterInfo.ClusterName)."
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
                        Section -Style Heading4 'Assigned Disk Summary' {
                            Paragraph "The following section provides the number of disks assigned to each controller on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskAssign
                        }
                        Section -Style Heading4 'Disk Container Type Summary' {
                            Paragraph "The following section provides a summary of disk status on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskType
                        }
                        if (Get-NcDisk | Where-Object{ $_.DiskRaidInfo.ContainerType -eq "broken" }) {
                            Section -Style Heading4 'Failed Disk Summary' {
                                Paragraph "The following section show failed disks on cluster $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapDiskBroken
                            }
                        }
                        If (Get-NcNode | Select-Object Node | Get-NcShelf -ErrorAction SilentlyContinue) {
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
            }#endregion Storage Section
            if ($InfoLevel.Storage -gt 0) {
                PageBreak
            }
            #region License Section
        #---------------------------------------------------------------------------------------------#
        #                                 License Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "License InfoLevel set at $($InfoLevel.License)."
            if ($InfoLevel.License -gt 0) {
                Section -Style Heading2 'Licenses Summary' {
                    Paragraph "The following section provides a summary of the license usage on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'License Usage Summary' {
                        Paragraph "The following section provides the installed licenses on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapClusterLicense
                        Section -Style Heading4 'License Feature Summary' {
                            Paragraph "The following section provides the License Feature Usage on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapClusterLicenseUsage
                        }
                    }
                }
            }#endregion License Section
            if ($InfoLevel.License -gt 0) {
                PageBreak
            }
            #region Network Section
        #---------------------------------------------------------------------------------------------#
        #                                 Network Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Network InfoLevel set at $($InfoLevel.Network)."
            if ($InfoLevel.Network -gt 0) {
                Section -Style Heading2 'Network Summary' {
                    Paragraph "The following section provides a summary of the networking features on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Network IPSpace Summary' {
                        Paragraph "The following section provides the IPSpace information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNetworkIpSpace
                        Section -Style Heading4 'Network Ports Summary' {
                            Paragraph "The following section provides the physical ports on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkPorts
                        }
                        if (Get-NcNetPortIfgrp) {
                            Section -Style Heading4 'Network Link Aggregation Group Summary' {
                                Paragraph "The following section provides the IFGRP Aggregated Ports on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkIfgrp
                            }
                        }
                        if (Get-NcNetPortVlan) {
                            Section -Style Heading4 'Vlan Summary' {
                                Paragraph "The following section provides the Vlan information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkVlans
                            }
                        }
                        Section -Style Heading4 'Broadcast Domain Summary' {
                            Paragraph "The following section provides the Broadcast Domain information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkBdomain
                        }
                        Section -Style Heading4 'Failover Group Summary' {
                            Paragraph "The following section provides the Failover Group information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkFailoverGroup
                        }
                        if (Get-NcNetSubnet) {
                            Section -Style Heading4 'Subnet Summary' {
                                Paragraph "The following section provides the Subnet information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkSubnet
                            }
                        }
                        if (Get-NcNetRoute) {
                            Section -Style Heading4 'Routes Summary' {
                                Paragraph "The following section provides the Routes information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapNetworkRoutes
                                Section -Style Heading5 'Per Network Interface Routes Summary' {
                                    Paragraph "The following section provides the Per Network Interface Routes information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapNetworkRouteLifs
                                }
                            }
                        }
                        Section -Style Heading4 'Network Interfaces Summary' {
                            Paragraph "The following section provides the Network Interfaces information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkMgmt
                        }
                    }
                }
            }#endregion Network Section
            if ($InfoLevel.Network -gt 0) {
                PageBreak
            }
            #region Vserver Section
        #---------------------------------------------------------------------------------------------#
        #                                 Vserver Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Vserver InfoLevel set at $($InfoLevel.Vserver)."
            if ($InfoLevel.Vserver -gt 0) {
                if (Get-NcVserver | Where-Object { $_.VserverType -eq "data"}) {
                    Section -Style Heading2 'Vserver Summary' {
                        Paragraph "The following section provides a summary of the vserver information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Section -Style Heading3 'Vserver Status Summary' {
                            Paragraph "The following section provides a summary of the configured vserver on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapVserverSummary
                            if (Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}) {
                                Section -Style Heading4 'Vserver Storage Volumes Summary' {
                                    Paragraph "The following section provides the Vserver Volumes Information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapVserverVolumes
                                    if (Get-NcVol | Select-Object -ExpandProperty VolumeQosAttributes) {
                                        Section -Style Heading5 'Vserver Volumes QoS Policy Summary' {
                                            Paragraph "The following section provides the Vserver QoS Configuration on $($ClusterInfo.ClusterName)."
                                            Section -Style Heading6 'Vserver Volumes Fixed QoS Policy' {
                                                Paragraph "The following section provides the Volume Fixed QoS Group information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesQosGPFixed
                                            }
                                            Section -Style Heading6 'Vserver Volumes Adaptive QoS Policy' {
                                                Paragraph "The following section provides the Volumes Adaptive QoS Group information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesQosGPAdaptive
                                            }
                                            Section -Style Heading6 'Vserver per Volumes QoS Policy Summary' {
                                                Paragraph "The following section provides the Vserver per Volumes QoS Configuration on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumesQos
                                            }
                                        }
                                    }
                                    if (Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsFlexgroup -eq "True"}) {
                                        Section -Style Heading5 'Vserver FlexGroup Volumes Summary' {
                                            Paragraph "The following section provides the Vserver FlexGroup Volumes Configuration on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesFlexgroup
                                        }
                                    }
                                    if (Get-NcVolClone) {
                                        Section -Style Heading5 'Vserver Flexclone Volumes Summary' {
                                            Paragraph "The following section provides the Vserver Flexclone Volumes Configuration on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesFlexclone
                                        }
                                    }
                                    if ((Get-NcFlexcacheConnectedCache) -or (Get-NcFlexcache)) {
                                        Section -Style Heading5 'Vserver Flexcache Volumes Summary' {
                                            Paragraph "The following section provides the Vserver Flexcache Volumes Configuration on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesFlexcache
                                        }
                                    }

                                    if (Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'} | Get-NcSnapshot) {
                                        Section -Style Heading5 'Vserver Volumes Snapshot Configuration Summary' {
                                            Paragraph "The following section provides the Vserver Volumes Snapshot Configuration on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumeSnapshot
                                            if ($HealthCheck.Vserver.Snapshot) {
                                                Paragraph "The following section provides the Vserver Volumes Snapshot HealthCheck on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverVolumeSnapshotHealth
                                            }
                                        }
                                    }
                                    if (Get-NcQtree | Where-Object {$NULL -ne $_.Qtree}) {
                                        Section -Style Heading5 'Vserver Qtree Summary' {
                                            Paragraph "The following section provides the Vserver Volumes Qtree Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQtree
                                            if (Get-NcExportRule) {
                                                Section -Style Heading6 'Vserver Export Policy Summary' {
                                                    Paragraph "The following section provides the Vserver Volumes Export policy Information on $($ClusterInfo.ClusterName)."
                                                    BlankLine
                                                    Get-AbrOntapVserverVolumesExportPolicy
                                                }
                                            }
                                        }
                                    if (Get-NcQuota) {
                                        Section -Style Heading5 'Vserver Volume Quota Summary' {
                                            Paragraph "The following section provides the Vserver Volumes Quota Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverVolumesQuota
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if ($InfoLevel.Vserver -gt 0) {
                        PageBreak
                    }
            #---------------------------------------------------------------------------------------------#
            #                                 Vserver Protocol Section                                    #
            #---------------------------------------------------------------------------------------------#
                            Section -Style Heading3 'Vserver Protocol Information Summary' {
                                Paragraph "The following section provides a summary of the vserver protocol information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                if (Get-NcIscsiService) {
                                    Section -Style Heading4 'ISCSI Services Summary' {
                                        Paragraph "The following section provides the ISCSI Service Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverIscsiSummary
                                        Section -Style Heading5 'ISCSI Interface Summary' {
                                            Paragraph "The following section provides the ISCSI Interface Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverIscsiInterface
                                        }
                                        if (Get-NcIscsiInitiator) {
                                            Section -Style Heading5 'ISCSI Client Initiator Summary' {
                                                Paragraph "The following section provides the ISCSI Interface Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverIscsiInitiator
                                            }
                                        }
                                    }
                                }
            #---------------------------------------------------------------------------------------------#
            #                                 FCP Section                                                 #
            #---------------------------------------------------------------------------------------------#
                                if (Get-NcFcpService) {
                                    Section -Style Heading4 'FCP Services Summary' {
                                        Paragraph "The following section provides the FCP Service Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverFcpSummary
                                        Section -Style Heading5 'FCP Interface Summary' {
                                            Paragraph "The following section provides the FCP Interface Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverFcpInterface
                                        }
                                        Section -Style Heading5 'FCP Physical Adapter Summary' {
                                            Paragraph "The following section provides the FCP Physical Adapter Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverFcpAdapter
                                        }
                                    }
                                }
                                if (get-nclun) {
                                    Section -Style Heading4 'Vserver FCP/ISCSI Lun Storage Summary' {
                                        Paragraph "The following section provides the Lun Storage Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverLunStorage
                                        if (Get-NcIgroup) {
                                            Section -Style Heading5 'Igroup Mapping Summary' {
                                                Paragraph "The following section provides the Igroup Mapping Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverLunIgroup
                                                if ($Healthcheck.Vserver.Status) {
                                                    Section -Style Heading6 'HealthCheck - Non-Mapped Lun Information' {
                                                        Paragraph "The following section provides information of Non Mapped Lun on $($ClusterInfo.ClusterName)."
                                                        BlankLine
                                                        Get-AbrOntapVserverNonMappedLun
                                                    }
                                                }

                                            }
                                        }
                                    }
                                }
            #---------------------------------------------------------------------------------------------#
            #                                 NFS Section                                                 #
            #---------------------------------------------------------------------------------------------#
                                if (Get-NcNfsService) {
                                    Section -Style Heading4 'NFS Services Summary' {
                                        Paragraph "The following section provides the NFS Service Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverNFSSummary
                                        Section -Style Heading5 'NFS Options Summary' {
                                            Paragraph "The following section provides the NFS Service Options Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverNFSOptions
                                            if (Get-NcVserver | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' } | Get-NcNfsExport) {
                                                Section -Style Heading6 'NFS Volume Export Summary' {
                                                    Paragraph "The following section provides the VServer NFS Service Exports Information on $($ClusterInfo.ClusterName)."
                                                    BlankLine
                                                    Get-AbrOntapVserverNFSExport
                                                }
                                            }
                                        }
                                    }
                                }
            #---------------------------------------------------------------------------------------------#
            #                                 CIFS Section                                                #
            #---------------------------------------------------------------------------------------------#
                                if (Get-NcVserver | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' } | Get-NcCifsServerStatus) {
                                    Section -Style Heading4 'CIFS Services Summary' {
                                        Paragraph "The following section provides the CIFS Service Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverCIFSSummary
                                        Section -Style Heading5 'CIFS Service Configuration Summary' {
                                            Paragraph "The following section provides the Cifs Service Configuration Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverCIFSSecurity
                                            Section -Style Heading6 'CIFS Domain Controller Summary' {
                                                Paragraph "The following section provides the Connected Domain Controller Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSDC
                                            }
                                            Section -Style Heading6 'CIFS Local Group Summary' {
                                                Paragraph "The following section provides the Cifs Service Local Group Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSLocalGroup
                                                BlankLine
                                                Paragraph "The following section provides the Cifs Service Local Group Memeber Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSLGMembers
                                            }
                                        }
                                        Section -Style Heading5 'CIFS Options Summary' {
                                            Paragraph "The following section provides the CIFS Service Options Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverCIFSOptions
                                            Section -Style Heading6 'CIFS Share Summary' {
                                                Paragraph "The following section provides the CIFS Service Shares Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSShare
                                                BlankLine
                                                Paragraph "The following section provides the CIFS Shares Properties & Acl Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverCIFSShareProp
                                            }
                                        }
                                    }
                                }
            #---------------------------------------------------------------------------------------------#
            #                                 S3 Section                                                  #
            #---------------------------------------------------------------------------------------------#
                                if (Get-AbrOntapApi -uri "/api/protocols/s3/services?") {
                                    Section -Style Heading4 'S3 Services Summary' {
                                        Paragraph "The following section provides the S3 Service Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Section -Style Heading5 'S3 Service Configuration Summary' {
                                            Paragraph "The following section provides the S3 Service Configuration Information on $($ClusterInfo.ClusterName)."
                                            BlankLine
                                            Get-AbrOntapVserverS3Summary
                                            Section -Style Heading6 'S3 Bucket Summary' {
                                                Paragraph "The following section provides the S3 Bucket Information on $($ClusterInfo.ClusterName)."
                                                BlankLine
                                                Get-AbrOntapVserverS3Bucket
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }#endregion Vserver Section
                if ($InfoLevel.Vserver -gt 0) {
                    PageBreak
                }
                #region Replication Section
        #---------------------------------------------------------------------------------------------#
        #                                 Replication Section                                         #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Replication InfoLevel set at $($InfoLevel.Replication)."
            if ($InfoLevel.Replication -gt 0) {
                if (Get-NcClusterPeer) {
                    Section -Style Heading2 'Replication Summary' {
                        Paragraph "The following section provides a summary of the replication information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Section -Style Heading3 'Cluster Peer Information' {
                            Paragraph "The following section provides the Cluster Peer information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapRepClusterPeer
                        }
                        if (Get-NcVserverPeer) {
                            Section -Style Heading3 'Vserver Peer Information' {
                                Paragraph "The following section provides the Vserver Peer information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapRepVserverPeer
                                if (Get-NcSnapmirror) {
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
                                if (Get-NcSnapmirrorDestination) {
                                    Section -Style Heading4 'SnapMirror Destinations Information' {
                                        Paragraph "The following section provides the SnapMirror (List-Destination) information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapRepDestinations
                                    }
                                }
                                if (Get-AbrOntapApi -uri "/api/cluster/mediators?") {
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
            }#endregion Replication Section
            if ($InfoLevel.Replication -gt 0) {
                PageBreak
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Efficiency Section                                          #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Efficiency InfoLevel set at $($InfoLevel.Efficiency)."
            if ($InfoLevel.Efficiency -gt 0) {
                if (Get-NcAggrEfficiency) {
                    Section -Style Heading2 'Efficiency Summary' {
                        Paragraph "The following section provides the Storage Efficiency Saving information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapEfficiencyConfig
                        Section -Style Heading3 'Aggregate Total Efficiency Summary' {
                            Paragraph "The following section provides the Aggregate Efficiency Saving information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapEfficiencyAggr
                            $VolFilter = Get-ncvol | Where-Object {$_.State -eq "online"}
                            if (Get-NcEfficiency -Volume $VolFilter.Name | Where-Object {$_.Name -ne "vol0"}) {
                                Section -Style Heading4 'Volume Deduplication Summary' {
                                    Paragraph "The following section provides the Volume Deduplication Summary on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapEfficiencyVolSisStatus
                                    Section -Style Heading5 'Volume Efficiency Summary' {
                                        Paragraph "The following section provides the Volume Efficiency Saving Detailed information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapEfficiencyVol
                                    }
                                    Section -Style Heading5 'Volume Efficiency Detail' {
                                        Paragraph "The following section provides the Volume Efficiency Saving Detailed information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapEfficiencyVolDetailed
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if ($InfoLevel.Efficiency -gt 0) {
                PageBreak
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Security Section                                          #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Security InfoLevel set at $($InfoLevel.Security)."
            if ($InfoLevel.Security -gt 0) {
                Section -Style Heading2 'Security Summary' {
                    Paragraph "The following section provides the Security related information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    if (Get-NcUser) {
                        Section -Style Heading3 'Local User Summary' {
                            Paragraph "The following section provides the Local User information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityUsers
                        }
                    }
                    if (Get-NcSecuritySsl) {
                        Section -Style Heading3 'Vserver SSL Certificate Summary' {
                            Paragraph "The following section provides the Vserver SSL Certificates information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySSLVserver
                            Paragraph "The following section provides the Vserver SSL Certificates Detailed information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySSLDetailed
                        }
                    }
                    if (Get-NcSecurityKeyManagerKeyStore -ErrorAction SilentlyContinue) {
                        Section -Style Heading3 'Key Management Service (KMS) Summary' {
                            Paragraph "The following section provides the Key Management Service type on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityKMS
                            if (Get-NcSecurityKeyManagerExternal) {
                                Section -Style Heading4 'External Key Management Service (KMS) Summary' {
                                    Paragraph "The following section provides the External KMS information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapSecurityKMSExt
                                    Section -Style Heading5 'External Key Management Service (KMS) Status Summary' {
                                        Paragraph "The following section provides the External KMS Status information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSecurityKMSExtStatus
                                    }
                                }
                            }
                        }
                    }
                    if (Get-NcAggr) {
                        Section -Style Heading3 'Aggregate Encryption (NAE) Summary' {
                            Paragraph "The following section provides the Aggregate Encryption (NAE) information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityNAE
                            Section -Style Heading4 'Volume Encryption (NVE) Summary' {
                                Paragraph "The following section provides the Volume Encryption (NVE) information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSecurityNVE
                            }
                        }
                    }
                    Section -Style Heading3 'Snaplock Compliance Clock Information Summary' {
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
                            }
                        }
                    }
                }
            }
            if ($InfoLevel.Security -gt 0) {
                PageBreak
            }
            #---------------------------------------------------------------------------------------------#
            #                                 System Configuration Section                                #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Efficiency InfoLevel set at $($InfoLevel.System)."
            if ($InfoLevel.System -gt 0) {
                if (Get-NcTime) {
                    Section -Style Heading2 'System Configuration Summary' {
                        Paragraph "The following section provides the Cluster System Configuration on $($ClusterInfo.ClusterName)."
                        BlankLine
                        if (Get-NcSystemImage) {
                            Section -Style Heading3 'System Image Configuration Summary' {
                                Paragraph "The following section provides the System Image Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigImage
                            }
                        }
                        if (Get-NcSystemServicesWebNode) {
                            Section -Style Heading3 'System Web Service Summary' {
                                Paragraph "The following section provides the System Web Service Status on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigWebStatus
                            }
                        }
                        if (Get-NcNetDns) {
                            Section -Style Heading3 'DNS Configuration Summary' {
                                Paragraph "The following section provides the DNS Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigDNS
                            }
                        }
                        if (Get-NcSnmp | Where-Object { $NULL -ne $_.Traphost -and $NULL -ne $_.Communities}) {
                            Section -Style Heading3 'SNMP Configuration Summary' {
                                Paragraph "The following section provides the SNMP Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigSNMP
                            }
                        }
                        if (Get-NcConfigBackupUrl) {
                            Section -Style Heading3 'Configuration Backup Setting Summary' {
                                Paragraph "The following section provides the Configuration Backup Setting on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigBackupURL
                                if (Get-NcConfigBackup) {
                                    Section -Style Heading4 'Configuration Backup Items Summary' {
                                        Paragraph "The following section provides the Configuration Backup Items on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSysConfigBackup
                                    }
                                }
                            }
                        }
                        if (Get-NcEmsDestination) {
                            Section -Style Heading3 'EMS Configuration Summary' {
                                Paragraph "The following section provides the EMS Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigEMSSettings
                                if ($HealthCheck.System.EMS) {
                                    Section -Style Heading4 'Cluster Emergency and Alert Messages Summary' {
                                        Paragraph "The following section provides Cluster Emergency and Alert Messages  on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapSysConfigEMS
                                    }
                                }
                            }
                        }
                        if (Get-NcTimezone) {
                            Section -Style Heading3 'System Timezone Configuration Summary' {
                                Paragraph "The following section provides the System Timezone Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigTZ
                                if (Get-NcNtpServer) {
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