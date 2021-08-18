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
                        Section -Style Heading4 'Node Hardware Inventory' {
                            Paragraph "The following section provides the node hardware inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNodesHW
                        }
                        Section -Style Heading4 'Node Service-Processor Inventory' {
                            Paragraph "The following section provides the node service-processor information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNodesSP
                            PageBreak
                        }
                    }
                }
            }#endregion Node Section

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
                        If ($Nodeshelf) {
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
                            PageBreak
                        }
                    }
                }
            }#endregion Storage Section
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
                            PageBreak
                        }
                    }
                }
            }#endregion License Section
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
                        Section -Style Heading4 'Network Link Aggregation Group Summary' {
                            Paragraph "The following section provides the IFGRP Aggregated Ports on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkIfgrp
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
                            }
                        }
                        Section -Style Heading4 'Network Interfaces Summary' {
                            Paragraph "The following section provides the Network Interfaces information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkMgmt
                            PageBreak
                        }
                    }
                }
            }#endregion Network Section
            #region Vserver Section
        #---------------------------------------------------------------------------------------------#
        #                                 Vserver Section                                             #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Vserver InfoLevel set at $($InfoLevel.Vserver)."
            if ($InfoLevel.Vserver -gt 0) {
                Section -Style Heading2 'Vserver Summary' {
                    Paragraph "The following section provides a summary of the vserver information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Vserver Information Summary' {
                        Paragraph "The following section provides a summary of the configured vserver on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapVserverSummary
                        Section -Style Heading4 'Vserver Storage Volumes Summary' {
                            Paragraph "The following section provides the Vserver Volumes Information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapVserverVolumes
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
                            Section -Style Heading5 'Vserver Volumes Snapshot Summary' {
                                Paragraph "The following section provides the Vserver Volumes Snapshot Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapVserverVolumeSnapshot
                                if ($HealthCheck.Vserver.Snapshot) {
                                    Get-AbrOntapVserverVolumeSnapshotHealth
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
                                    PageBreak
                                }
                            }
                        }
                    }
                }
        #---------------------------------------------------------------------------------------------#
        #                                 Vserver Protocol Section                                    #
        #---------------------------------------------------------------------------------------------#
                    Section -Style Heading3 'Vserver Protocol Information Summary' {
                        Paragraph "The following section provides a summary of the vserver protocol information on $($ClusterInfo.ClusterName)."
                        BlankLine
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
        #---------------------------------------------------------------------------------------------#
        #                                 FCP Section                                                 #
        #---------------------------------------------------------------------------------------------#
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
                        Section -Style Heading4 'Vserver FCP/ISCSI Lun Storage Summary' {
                            Paragraph "The following section provides the Lun Storage Information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapVserverLunStorage
                            Section -Style Heading5 'Igroup Mapping Summary' {
                                Paragraph "The following section provides the Lun  Interface Information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapVserverLunIgroup
                                PageBreak
                            }
                        }
        #---------------------------------------------------------------------------------------------#
        #                                 NFS Section                                                 #
        #---------------------------------------------------------------------------------------------#
                        if (Get-AbrOntapApi -Uri "/api/protocols/nfs/services?" ) {
                            Section -Style Heading4 'NFS Services Summary' {
                                Paragraph "The following section provides the NFS Service Information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapVserverNFSSummary
                                Section -Style Heading5 'NFS Options Summary' {
                                    Paragraph "The following section provides the NFS Service Options Information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapVserverNFSOptions
                                    Section -Style Heading6 'NFS Volume Export Summary' {
                                        Paragraph "The following section provides the VServer NFS Service Exports Information on $($ClusterInfo.ClusterName)."
                                        BlankLine
                                        Get-AbrOntapVserverNFSExport
                                    }
                                }
                            }
                        }
        #---------------------------------------------------------------------------------------------#
        #                                 CIFS Section                                                #
        #---------------------------------------------------------------------------------------------#
                        if (Get-AbrOntapApi -Uri "/api/protocols/cifs/services?") {
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
                                        PageBreak
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
                                        PageBreak
                                    }
                                }
                            }
                        }
                    }
                }
            }#endregion Vserver Section
            #region Replication Section
        #---------------------------------------------------------------------------------------------#
        #                                 Replication Section                                         #
        #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Replication InfoLevel set at $($InfoLevel.Replication)."
            if ($InfoLevel.Replication -gt 0) {
                Section -Style Heading2 'Replication Summary' {
                    Paragraph "The following section provides a summary of the replication information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Cluster Peer Information' {
                        Paragraph "The following section provides the Cluster Peer information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapRepClusterPeer
                    }
                    Section -Style Heading3 'Vserver Peer Information' {
                        Paragraph "The following section provides the Vserver Peer information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapRepVserverPeer
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
                        Section -Style Heading4 'SnapMirror Destinations Information' {
                            Paragraph "The following section provides the SnapMirror (List-Destination) information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapRepDestinations
                        }
                        Section -Style Heading4 'Ontap Mediator Information' {
                            Paragraph "The following section provides the SnapMirror Mediator information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapRepMediator
                            PageBreak
                        }
                    }
                }
            }#endregion Replication Section

            #---------------------------------------------------------------------------------------------#
            #                                 Efficiency Section                                          #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Efficiency InfoLevel set at $($InfoLevel.Efficiency)."
            if ($InfoLevel.Efficiency -gt 0) {
                Section -Style Heading2 'Efficiency Summary' {
                    Paragraph "The following section provides the Storage Efficiency Saving information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Get-AbrOntapEfficiencyConfig
                    Section -Style Heading3 'Aggregate Total Efficiency Summary' {
                        Paragraph "The following section provides the Aggregate Efficiency Saving information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapEfficiencyAggr
                        Section -Style Heading4 'Volume Efficiency Summary' {
                            Paragraph "The following section provides the Volume Efficiency Saving Summary information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapEfficiencyVol
                            Section -Style Heading5 'Volume Efficiency Detail' {
                                Paragraph "The following section provides the Volume Efficiency Saving Detailed information on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapEfficiencyVolDetailed
                                PageBreak
                            }
                        }
                    }
                }
            }
        }
    }
    #$global:CurrentNcController = $null
}