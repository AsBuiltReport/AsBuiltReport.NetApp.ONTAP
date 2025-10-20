function Invoke-AsBuiltReport.NetApp.ONTAP {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of NetApp ONTAP in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of NetApp ONTAP in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.6.8
        Author:         Jonathan Colon Feliciano
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

    #Requires -RunAsAdministrator

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message "You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window."
        break
    }

    Write-Host "- Please refer to the AsBuiltReport.NetApp.ONTAP github website for more detailed information about this project."
    Write-Host "- Do not forget to update your report configuration file after each new version release."
    Write-Host "- Documentation: https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP"
    Write-Host "- Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/issues"
    Write-Host "- This project is community maintained and has no sponsorship from NetApp, its employees or any of its affiliates."


    # Check the version of the dependency modules
    $ModuleArray = @('AsBuiltReport.Netapp.ONTAP', 'Diagrammer.Core')

    foreach ($Module in $ModuleArray) {
        try {
            $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

            if ($InstalledVersion) {
                Write-Host "- $Module module v$($InstalledVersion.ToString()) is currently installed."
                $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                if ($InstalledVersion -lt $LatestVersion) {
                    Write-Host "  - $Module module v$($LatestVersion.ToString()) is available." -ForegroundColor Red
                    Write-Host "  - Run 'Update-Module -Name $Module -Force' to install the latest version." -ForegroundColor Red
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # General information
    $script:TextInfo = (Get-Culture).TextInfo

    #Connect to Ontap Storage Array using supplied credentials
    foreach ($OntapArray in $Target) {
        try {
            $OntapModuleInstalledVersion = Get-Module -ListAvailable -Name NetApp.ONTAP -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version
            Write-PScriboMessage "Connecting to NetApp Storage '$OntapArray'."
            if ($OntapModuleInstalledVersion.Minor -gt 10) {
                # Workaround for NetApp.ONTAP v9.11+ REST API Issues
                Write-PScriboMessage "Detected NetApp.ONTAP module version $($OntapModuleInstalledVersion.toString()). Enabling ONTAPI option."
                $Array = Connect-NcController -Name $OntapArray -Credential $Credential -ErrorAction Stop -ONTAPI
            } else {
                Write-PScriboMessage "Detected NetApp.ONTAP module version $($OntapModuleInstalledVersion.toString()). Disabling ONTAPI option."
                $Array = Connect-NcController -Name $OntapArray -Credential $Credential -ErrorAction Stop
            }
        } catch {
            Write-Verbose "Unable to connect to the $OntapArray Array"
            throw
        }
        $ClusterInfo = Get-NcCluster -Controller $Array

        #If metrocluster option remove all -mc vserver
        if ($Options.Exclude.MetroCluster) {
            $Options.Exclude.Vserver = $Options.Exclude.Vserver + (Get-NcVserver | Where-Object { $_ -like '*-mc' }).Vserver
            $exclude_vserver = $Options.Exclude.Vserver
            Write-PScriboMessage "exclude vserver = $exclude_vserver"
        }

        # Variable translating Icon to Image Path ($IconPath)
        $script:Images = @{
            "Ontap_LOGO" = "netapp-logo.png"
            "AsBuiltReport_LOGO" = "AsBuiltReport_Logo.png"
            "AsBuiltReport_Signature" = "AsBuiltReport_Signature.png"
            "Ontap_Node" = "ontap_node_new.png"
            "Abr_LOGO_Footer" = "AsBuiltReport.png"
            "Ontap_Node_Icon" = "netapp_node_icon.png"
            "Ontap_Aggregate" = "netapp_aggregate.png"
            "Ontap_SVM" = "ontap_svm.png"
            "Ontap_SVM_Icon" = "ontap_svm_icon.png"
        }
        $script:ColumnSize = $Options.DiagramColumnSize

        #---------------------------------------------------------------------------------------------#
        #                                 Cluster Section                                             #
        #---------------------------------------------------------------------------------------------#
        Section -Style Heading1 "$($ClusterInfo.ClusterName) Cluster Report" {
            Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
            BlankLine
            #region Cluster Section
            $ClusterDiagram = Get-AbrOntapClusterDiagram
            if ($ClusterDiagram) {
                Export-AbrOntapDiagram -DiagramObject $ClusterDiagram -MainDiagramLabel "$($ClusterInfo.ClusterName) Cluster Diagram" -FileName "AsBuiltReport.NetApp.Ontap.Cluster"
            } else {
                Write-PScriboMessage -IsWarning "Unable to generate the Cluster Diagram."
            }
            Write-PScriboMessage "Cluster InfoLevel set at $($InfoLevel.Cluster)."
            if ($InfoLevel.Cluster -gt 0) {
                Section -Style Heading2 'Cluster Information' {
                    # Ontap Cluster
                    Get-AbrOntapCluster
                    Section -Style Heading3 'Cluster HA Status' {
                        Get-AbrOntapClusterHA
                    }
                    if ($InfoLevel.Cluster -ge 2) {
                        Section -Style Heading3 'Cluster AutoSupport Status' {
                            Get-AbrOntapClusterASUP
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Node Section                                                #
            #---------------------------------------------------------------------------------------------#

            Write-PScriboMessage "Node InfoLevel set at $($InfoLevel.Node)."
            if ($InfoLevel.Node -gt 0) {
                Section -Style Heading2 'Node Information' {
                    Paragraph "The following section provides a summary of the Node on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Node Inventory' {
                        Paragraph "The following section provides the node inventory on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNode
                        Section -Style Heading4 'Node Vol0 Inventory' {
                            Get-AbrOntapNodeStorage
                        }
                        if ($InfoLevel.Node -ge 2) {
                            Section -Style Heading4 'Node Hardware Inventory' {
                                Get-AbrOntapNodesHW
                            }
                        }
                        if (Get-NcServiceProcessor  -Controller $Array | Where-Object { $NULL -ne $_.IpAddress -and $NULL -ne $_.MacAddress }) {
                            Section -Style Heading4 'Node Service-Processor Inventory' {
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
                Section -Style Heading2 'Storage Information' {
                    Paragraph "The following section provides a summary of the storage hardware on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Aggregate Inventory' {
                        Paragraph "The following section provides the Aggregates on $($ClusterInfo.ClusterName)."
                        BlankLine
                        if (Get-NcAggr -Controller $Array) {
                            $StorageAggrDiagram = Get-AbrOntapStorageAggrDiagram
                            if ($StorageAggrDiagram) {
                                Export-AbrOntapDiagram -DiagramObject $StorageAggrDiagram -MainDiagramLabel "Storage Aggregate Diagram" -FileName "AsBuiltReport.NetApp.Ontap.StorageAggr"
                            } else {
                                Write-PScriboMessage -IsWarning "Unable to generate the Storage Aggregate Diagram."
                            }
                            Get-AbrOntapStorageAGGR
                        }
                        if (Get-NcAggrObjectStore -Controller $Array -Aggregate (Get-NcAggr -Controller $Array).Name) {
                            Section -Style Heading4 'FabricPool' {
                                Get-AbrOntapStorageFabricPool
                                if ($InfoLevel.Storage -ge 2) {
                                    if (Get-NcAggrObjectStoreConfig -Controller $Array) {
                                        Section -Style Heading5 'FabriPool Object Store Configuration' {
                                            Get-AbrOntapEfficiencyAggrConfig
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Section -Style Heading3 'Disk Information' {
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
                                Get-AbrOntapDiskOwner -Node $Node
                            }
                        }
                        Section -Style Heading4 'Disk Container Type' {
                            Get-AbrOntapDiskType
                        }
                        if (Get-NcDisk -Controller $Array | Where-Object { $_.DiskRaidInfo.ContainerType -eq "broken" }) {
                            Section -Style Heading4 'Failed Disk' {
                                Get-AbrOntapDiskBroken
                            }
                        }
                        if (Get-NcNode -Controller $Array | Select-Object Node | Get-NcShelf -Controller $Array -ErrorAction SilentlyContinue) {
                            Section -Style Heading3 'Shelf Inventory' {
                                Get-AbrOntapDiskShelf
                            }
                        }
                        if ($InfoLevel.Storage -ge 2) {
                            Section -Style Heading4 'Disk Inventory' {
                                Get-AbrOntapDiskInv
                            }
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 License Section                                             #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "License InfoLevel set at $($InfoLevel.License)."
            if ($InfoLevel.License -gt 0) {
                Section -Style Heading2 'Licenses Information' {
                    Paragraph "The following section provides a summary of the license usage on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Get-AbrOntapClusterLicense
                    if ($InfoLevel.License -ge 2) {
                        Section -Style Heading4 'License Features' {
                            Get-AbrOntapClusterLicenseUsage
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                                 Network Section                                             #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Network InfoLevel set at $($InfoLevel.Network)."
            if ($InfoLevel.Network -gt 0) {
                Section -Style Heading2 'Network Information' {
                    Paragraph "The following section provides a summary of the networking features on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'IPSpace' {
                        Paragraph "The following section provides the IPSpace information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNetworkIpSpace
                        Section -Style Heading4 'Network Ports' {
                            Paragraph "The following section provides the physical network ports on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $Nodes = Get-NcNode -Controller $Array
                            foreach ($Node in $Nodes) {
                                Section -Style Heading5 "$Node Ports" {
                                    Get-AbrOntapNetworkPort -Node $Node
                                }
                            }
                        }
                        if (Get-NcNetPortIfgrp -Controller $Array) {
                            Section -Style Heading3 'Network Link Aggregation Group' {
                                Paragraph "The following section provides per Node IFGRP Aggregated Ports on  $($ClusterInfo.ClusterName)."
                                BlankLine
                                $Nodes = Get-NcNode -Controller $Array
                                foreach ($Node in $Nodes) {
                                    if (Get-NcNetPortIfgrp -Node $Node -Controller $Array) {
                                        Section -Style Heading4 "$Node IFGRP" {
                                            Get-AbrOntapNetworkIfgrp -Node $Node
                                        }
                                    }
                                }
                            }
                        }
                        Section -Style Heading3 'Network VLANs' {
                            Paragraph "The following section provides Network VLAN information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $Nodes = Get-NcNode -Controller $Array
                            foreach ($Node in $Nodes) {
                                if (Get-NcNetPortVlan -Node $Node -Controller $Array) {
                                    Section -Style Heading4 "$Node Vlans" {
                                        Get-AbrOntapNetworkVlan -Node $Node
                                    }
                                }
                            }
                        }
                        Section -Style Heading4 'Broadcast Domain' {
                            Get-AbrOntapNetworkBdomain
                        }
                        Section -Style Heading4 'Failover Groups' {
                            Get-AbrOntapNetworkFailoverGroup
                        }
                        if (Get-NcNetSubnet -Controller $Array) {
                            Section -Style Heading4 'Network Subnets' {
                                Get-AbrOntapNetworkSubnet
                            }
                        }
                        $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -ne "node" -and $_.VserverType -ne "system" -and $_.Vserver -notin $Options.Exclude.Vserver } | Select-Object -ExpandProperty Vserver
                        foreach ($SVM in $Vservers) {
                            if (Get-NcNetRoute -VserverContext $SVM -Controller $Array) {
                                Section -Style Heading4 "$SVM Vserver Routes" {
                                    Paragraph "The following section provides the Routes information on $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    Get-AbrOntapNetworkRoute -Vserver $SVM
                                    if ($InfoLevel.Network -ge 2) {
                                        Section -Style Heading5 "Network Interface Routes" {
                                            Get-AbrOntapNetworkRouteLif -Vserver $SVM
                                        }
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
                if (Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" }) {
                    Section -Style Heading2 'Vserver Information' {
                        Paragraph "The following section provides a summary of the vserver information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" -and $_.Vserver -notin $Options.Exclude.Vserver } | Select-Object -ExpandProperty Vserver
                        foreach ($SVM in $Vservers) {
                            Section -Style Heading3 "$SVM Vserver Configuration" {
                                Paragraph "The following section provides the configuration of the vserver $($SVM)."
                                BlankLine
                                Get-AbrOntapVserverSummary -Vserver $SVM
                                if ($InfoLevel.Vserver -ge 2) {
                                    if (Get-NcVol -Controller $Array | Select-Object -ExpandProperty VolumeQosAttributes) {
                                        Section -Style Heading4 'Volumes QoS Policy' {
                                            Paragraph "The following section provides the Vserver QoS Configuration on $($ClusterInfo.ClusterName)."
                                            Section -Style Heading5 'Volumes Fixed QoS Policy' {
                                                Get-AbrOntapVserverVolumesQosGPFixed
                                            }
                                            Section -Style Heading5 'Volumes Adaptive QoS Policy' {
                                                Get-AbrOntapVserverVolumesQosGPAdaptive
                                            }
                                        }
                                    }
                                }
                                if (Get-NcVol -VserverContext $SVM  -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }) {
                                    Section -Style Heading4 "Storage Volumes" {
                                        Get-AbrOntapVserverVolume -Vserver $SVM
                                        if ($InfoLevel.Vserver -ge 2) {
                                            if (Get-NcVol -VserverContext $SVM -Controller $Array | Select-Object -ExpandProperty VolumeQosAttributes) {
                                                Section -Style Heading5 "Per Volumes QoS Policy" {
                                                    Get-AbrOntapVserverVolumesQosSetting -Vserver $SVM
                                                }
                                            }
                                        }
                                        if (Get-NcVol -VserverContext $SVM -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsFlexgroup -eq "True" }) {
                                            Section -Style Heading4 "FlexGroup Volumes" {
                                                Get-AbrOntapVserverVolumesFlexgroup -Vserver $SVM
                                            }
                                        }
                                        if (Get-NcVolClone -VserverContext $SVM -Controller $Array) {
                                            Section -Style Heading4 "Flexclone Volumes" {
                                                Get-AbrOntapVserverVolumesFlexclone -Vserver $SVM
                                            }
                                        }
                                        if ((Get-NcFlexcacheConnectedCache -VserverContext $SVM -Controller $Array) -or ((Get-NcFlexcache -Controller $Array).CacheVolume).count -gt 0) {
                                            Section -Style Heading4 "Flexcache Volumes" {
                                                Get-AbrOntapVserverVolumesFlexcache -Vserver $SVM
                                            }
                                        }
                                    }
                                    if (Get-NcVol -VserverContext $SVM -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' } | Get-NcSnapshot -Controller $Array) {
                                        Section -Style Heading4 "Volumes Snapshot Configuration" {
                                            Get-AbrOntapVserverVolumeSnapshot -Vserver $SVM
                                            if ($HealthCheck.Vserver.Snapshot) {
                                                Get-AbrOntapVserverVolumeSnapshotHealth -Vserver $SVM
                                            }
                                        }
                                    }
                                    if (Get-NcExportRule -VserverContext $SVM -Controller $Array) {
                                        Section -Style Heading4 "Export Policy" {
                                            Get-AbrOntapVserverVolumesExportPolicy -Vserver $SVM
                                        }
                                    }
                                    if (Get-NcQtree -VserverContext $SVM -Controller $Array | Where-Object { $NULL -ne $_.Qtree }) {
                                        Section -Style Heading4 "Qtrees" {
                                            Get-AbrOntapVserverVolumesQtree -Vserver $SVM
                                        }
                                    }
                                    if (Get-NcQuota -VserverContext $SVM -Controller $Array) {
                                        Section -Style Heading4 "Volume Quota" {
                                            Get-AbrOntapVserverVolumesQuota -Vserver $SVM
                                        }
                                    }
                                }
                                Section -Style Heading4 "Protocol Information" {
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
                                            if ($InfoLevel.Vserver -ge 2) {
                                                Section -ExcludeFromTOC -Style Heading6 "NFS Options" {
                                                    Get-AbrOntapVserverNFSOption -Vserver $SVM
                                                }
                                            }
                                            if (Get-NcVserver -VserverContext $SVM -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' } | Get-NcNfsExport) {
                                                Section -ExcludeFromTOC -Style Heading6 "NFS Volume Export" {
                                                    Get-AbrOntapVserverNFSExport -Vserver $SVM
                                                }
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                 CIFS Section                                                #
                                    #---------------------------------------------------------------------------------------------#
                                    if (Get-NcVserver -VserverContext $SVM -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' } | Get-NcCifsServerStatus -Controller $Array -ErrorAction SilentlyContinue) {
                                        Section -Style Heading5 "CIFS Services Information" {
                                            Paragraph "The following section provides the CIFS Service Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverCIFSSummary -Vserver $SVM
                                            if ($InfoLevel.Vserver -ge 2) {
                                                Section -ExcludeFromTOC -Style Heading6 'CIFS Service Configuration' {
                                                    Get-AbrOntapVserverCIFSSecurity -Vserver $SVM
                                                }
                                                Section -ExcludeFromTOC -Style Heading6 'CIFS Domain Controller' {
                                                    Get-AbrOntapVserverCIFSDC -Vserver $SVM
                                                }
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'CIFS Local Group' {
                                                Get-AbrOntapVserverCIFSLocalGroup -Vserver $SVM
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'CIFS Local Group Members' {
                                                Get-AbrOntapVserverCIFSLGMember -Vserver $SVM
                                            }
                                            if ($InfoLevel.Vserver -ge 2) {
                                                Section -ExcludeFromTOC -Style Heading6 'CIFS Options' {
                                                    Get-AbrOntapVserverCIFSOption -Vserver $SVM
                                                }
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'CIFS Share' {
                                                Get-AbrOntapVserverCIFSShare -Vserver $SVM
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'CIFS Share Configuration' {
                                                Get-AbrOntapVserverCIFSShareProp -Vserver $SVM
                                            }
                                            if ($InfoLevel.Vserver -ge 2) {
                                                if (Get-NcCifsSession -VserverContext $SVM -Controller $Array) {
                                                    Section -ExcludeFromTOC -Style Heading6 'CIFS Sessions' {
                                                        Get-AbrOntapVserverCIFSSession -Vserver $SVM
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                 NVME Section                                                 #
                                    #---------------------------------------------------------------------------------------------#
                                    if ( Get-NcNvme -Controller $Array | Where-Object { $_.Vserver -eq $SVM } ) {
                                        Section -Style Heading5 'Nvme Services Information' {
                                            Paragraph "The following section provides the Nvme Service Information on $($SVM)."
                                            BlankLine
                                            # Get-AbrOntapVserverNvmeSummary -Vserver $SVM
                                            if (Get-NcNvmeInterface -VserverContext $Vserver -Controller $Array | Where-Object { $_.PhysicalProtocol -eq 'fibre_channel' }) {
                                                Section -ExcludeFromTOC -Style Heading6 'Nvme FC Physical Adapter' {
                                                    Get-AbrOntapVserverNvmeFcAdapter -Vserver $SVM
                                                }
                                            }
                                            if (Get-NcNvmeInterface -VserverContext $Vserver -Controller $Array | Where-Object { $_.PhysicalProtocol -eq 'ethernet' }) {
                                                Section -ExcludeFromTOC -Style Heading6 'Nvme TCP Physical Adapter' {
                                                    Get-AbrOntapVserverNvmeTcpAdapter -Vserver $SVM
                                                }
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'NVME Interfaces' {
                                                Get-AbrOntapVserverNvmeInterface -Vserver $SVM
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                 ISCSI Section                                               #
                                    #---------------------------------------------------------------------------------------------#
                                    if ( Get-NcIscsiService  -Controller $Array | Where-Object { $_.Vserver -eq $SVM } ) {
                                        Section -Style Heading5 "ISCSI Services" {
                                            Paragraph "The following section provides the ISCSI Service Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverIscsiSummary -Vserver $SVM
                                            Section -ExcludeFromTOC -Style Heading6 "ISCSI Interfaces" {
                                                Get-AbrOntapVserverIscsiInterface -Vserver $SVM
                                            }

                                            $ISCSIClientInitiators = Get-AbrOntapVserverIscsiInitiator -Vserver $SVM
                                            if ($ISCSIClientInitiators) {
                                                Section -ExcludeFromTOC -Style Heading6 "ISCSI Client Initiators" {
                                                    $ISCSIClientInitiators
                                                }
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                 FCP Section                                                 #
                                    #---------------------------------------------------------------------------------------------#
                                    if ( Get-NcFcpService -Controller $Array | Where-Object { $_.Vserver -eq $SVM } ) {
                                        Section -Style Heading5 'FCP Services Information' {
                                            Paragraph "The following section provides the FCP Service Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverFcpSummary -Vserver $SVM
                                            Section -ExcludeFromTOC -Style Heading6 'FCP Physical Adapter' {
                                                Get-AbrOntapVserverFcpAdapter
                                            }
                                            Section -ExcludeFromTOC -Style Heading6 'FCP Interfaces' {
                                                Get-AbrOntapVserverFcpInterface -Vserver $SVM
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                Lun Storage Section                                          #
                                    #---------------------------------------------------------------------------------------------#
                                    if (Get-NcLun -Controller $Array | Where-Object { $_.Vserver -eq $SVM }) {
                                        Section -Style Heading5 'Lun Storage' {
                                            Paragraph "The following section provides the Lun Storage Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverLunStorage -Vserver $SVM
                                            if (Get-NcIgroup -Vserver $SVM -Controller $Array) {
                                                Section -ExcludeFromTOC -Style Heading6 'Igroup Mapping' {
                                                    Get-AbrOntapVserverLunIgroup -Vserver $SVM
                                                }
                                                $NonMappedLun = Get-AbrOntapVserverNonMappedLun -Vserver $SVM
                                                if ($Healthcheck.Vserver.Status -and $NonMappedLun) {
                                                    Section -ExcludeFromTOC -Style Heading6 'HealthCheck - Non-Mapped Lun Information' {
                                                        Paragraph "The following section provides information of Non Mapped Lun on $($SVM)."
                                                        BlankLine
                                                        $NonMappedLun
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                         NameSpace & Subsystem Storage Section                               #
                                    #---------------------------------------------------------------------------------------------#
                                    if (Get-NcNvmeNamespace -Controller $Array | Where-Object { $_.Vserver -eq $SVM }) {
                                        Section -Style Heading5 'Namespace Storage' {
                                            Paragraph "The following section provides the Namespace Storage Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverNamespaceStorage -Vserver $SVM
                                            if (Get-NcNvmeSubsystem -Vserver $SVM -Controller $Array) {
                                                Section -ExcludeFromTOC -Style Heading6 'Subsystem Mapping' {
                                                    Get-AbrOntapVserverSubsystem -Vserver $SVM
                                                }
                                                $NonMappedNamespace = Get-AbrOntapVserverNonMappedNamespace -Vserver $SVM
                                                if ($Healthcheck.Vserver.Status -and $NonMappedNamespace) {
                                                    Section -ExcludeFromTOC -Style Heading6 'HealthCheck - Non-Mapped Namespace Information' {
                                                        Paragraph "The following table provides information about Non Mapped Namespace on $($SVM)."
                                                        BlankLine
                                                        $NonMappedNamespace
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                              Consistency Groups Section                                     #
                                    #---------------------------------------------------------------------------------------------#
                                    $CGs = Get-NetAppOntapAPI -uri "/api/application/consistency-groups?svm=$SVM&fields=**&return_records=true&return_timeout=15"
                                    if ($CGs) {
                                        Section -Style Heading5 'Consistency Groups' {
                                            Paragraph "The following section provides Consistency Group Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverCGSummary -Vserver $SVM
                                            foreach ($CG in $CGs) {
                                                if ($CG.luns) {
                                                    Section -ExcludeFromTOC -Style Heading6 "$($CG.name) Luns" {
                                                        Get-AbrOntapVserverCGLun -CGObj $CG
                                                    }
                                                }
                                                if ($CG.namespaces) {
                                                    Section -ExcludeFromTOC -Style Heading6 "$($CG.name) Namespaces" {
                                                        Get-AbrOntapVserverCGNamespace -CGObj $CG
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
                                        Section -Style Heading5 'S3 Services Configuration Information' {
                                            Paragraph "The following section provides the S3 Service Information on $($SVM)."
                                            BlankLine
                                            Get-AbrOntapVserverS3Summary -Vserver $SVM
                                            Section -ExcludeFromTOC -Style Heading6 'S3 Buckets' {
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

            #---------------------------------------------------------------------------------------------#
            #                                 Replication Section                                         #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Replication InfoLevel set at $($InfoLevel.Replication)."
            if ($InfoLevel.Replication -gt 0) {
                if (Get-NcClusterPeer -Controller $Array) {
                    Section -Style Heading2 'Replication Information' {
                        Paragraph "The following section provides a summary of the replication information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $ClusterReplicationDiagram = Get-AbrOntapClusterReplicationDiagram
                        if ($ClusterReplicationDiagram) {
                            Export-AbrOntapDiagram -DiagramObject $ClusterReplicationDiagram -MainDiagramLabel "Cluster Replication Diagram" -FileName "AsBuiltReport.NetApp.Ontap.Replication"
                        } else {
                            Write-PScriboMessage -IsWarning "Unable to generate the Cluster Replication Diagram."
                        }
                        Section -Style Heading3 'Cluster Peer' {
                            Paragraph "The following section provides the Cluster Peer information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapRepClusterPeer
                        }
                        if (Get-NcVserverPeer -Controller $Array) {
                            Section -Style Heading4 'Vserver Peer' {
                                Get-AbrOntapRepVserverPeer
                                if (Get-NcSnapmirror -Controller $Array) {
                                    Section -Style Heading5 'SnapMirror Relationship' {
                                        Get-AbrOntapRepRelationship
                                        if (($InfoLevel.Replication -ge 2) -and ($ReplicaData = Get-NcSnapmirrorHistory -Controller $Array)) {
                                            Section -ExcludeFromTOC -Style Heading6 'SnapMirror Replication History' {
                                                Get-AbrOntapRepHistory
                                            }
                                        }
                                    }
                                }
                                if (Get-NcSnapmirrorDestination -Controller $Array) {
                                    Section -Style Heading5 'SnapMirror Destinations' {
                                        Get-AbrOntapRepDestination
                                    }
                                }
                                if (Get-NetAppOntapAPI -uri "/api/cluster/mediators?") {
                                    Section -Style Heading5 'Ontap Mediator' {
                                        Get-AbrOntapRepMediator
                                    }
                                }
                            }
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------y
            Write-PScriboMessage "Efficiency InfoLevel set at $($InfoLevel.Efficiency)."
            if ($InfoLevel.Efficiency -gt 0) {
                $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" -and $_.Vserver -notin $Options.Exclude.Vserver } | Select-Object -ExpandProperty Vserver
                if (Get-NcAggrEfficiency -Controller $Array) {
                    Section -Style Heading2 'Efficiency Information' {
                        Paragraph "The following section provides the Storage Efficiency Saving information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapEfficiencyConfig
                        Section -Style Heading3 'Aggregate Total Efficiency' {
                            Paragraph "The following section provides the Aggregate Efficiency Saving information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapEfficiencyAggr
                            foreach ($SVM in $Vservers) {
                                $VolFilter = Get-NcVol -VserverContext $SVM -Controller $Array | Where-Object { ($_.State -eq "online") -and ($_.Name -ne "vol0") }
                                if (Get-NcEfficiency -Volume $VolFilter.Name[0] -Vserver $SVM -Controller $Array) {
                                    Section -Style Heading4 "$SVM Vserver Volume Deduplication" {
                                        Get-AbrOntapEfficiencyVolSisStatus -Vserver $SVM
                                        Section -Style Heading5 "Volume Efficiency" {
                                            Get-AbrOntapEfficiencyVol -Vserver $SVM
                                        }
                                        if ($InfoLevel.Efficiency -ge 2) {
                                            Section -Style Heading5 "Detailed Volume Efficiency" {
                                                Get-AbrOntapEfficiencyVolDetailed -Vserver $SVM
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
            #                                 Security Section                                            #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Security InfoLevel set at $($InfoLevel.Security)."
            if ($InfoLevel.Security -gt 0) {
                $Vservers = Get-NcVserver -Controller $Array | Where-Object { $_.VserverType -eq "data" -or $_.VserverType -eq "admin" -and $_.Vserver -notin $Options.Exclude.Vserver } | Select-Object -ExpandProperty Vserver
                Section -Style Heading2 'Security Information' {
                    Paragraph "The following section provides the Security related information on $($ClusterInfo.ClusterName)."
                    BlankLine
                    foreach ($SVM in $Vservers) {
                        if (Get-NcUser -Vserver $SVM -Controller $Array) {
                            Section -Style Heading3 "$SVM Vserver Local User" {
                                Paragraph "The following section provides the Local User information on $($SVM)."
                                BlankLine
                                Get-AbrOntapSecurityUser -Vserver $SVM
                            }
                        }
                    }
                    $MAPData = Get-NetAppOntapAPI -uri "/api/security/multi-admin-verify/approval-groups?fields=**&return_records=true&return_timeout=15"
                    if ($MAPData) {
                        Section -Style Heading3 'Multi-Admin Approval Configuration' {
                            Paragraph "The following section provides information about Multi-Admin Approval from $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityMAP
                            Section -Style Heading4 'Multi-Admin Approval Rules' {
                                Get-AbrOntapSecurityMAPRule
                            }
                        }
                    }
                    if (Get-NcSecuritySsl -Controller $Array) {
                        Section -Style Heading3 'Vserver SSL Certificate' {
                            Paragraph "The following section provides the Vserver SSL Certificates information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecuritySSLVserver
                            Section -Style Heading4 'Vserver SSL Certificate Details' {
                                Get-AbrOntapSecuritySSLDetailed
                            }
                        }
                    }
                    if (Get-NcSecurityKeyManagerKeyStore -ErrorAction SilentlyContinue -Controller $Array) {
                        Section -Style Heading3 'Key Management Service (KMS)' {
                            Paragraph "The following section provides the Key Management Service type on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapSecurityKMS
                            if (Get-NcSecurityKeyManagerExternal -Controller $Array) {
                                Section -Style Heading4 'External KMS' {
                                    Get-AbrOntapSecurityKMSExt
                                    Section -Style Heading5 'External KMS Status' {
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
                                Get-AbrOntapSecurityNVE
                            }
                        }
                    }
                    Section -Style Heading3 'Snaplock Compliance Clock' {
                        Paragraph "The following section provides the Snaplock Compliance Clock information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapSecuritySnapLockClock
                        Section -Style Heading4 'Aggregate Snaplock Type' {
                            Get-AbrOntapSecuritySnapLockAggr
                            Section -Style Heading5 'Volume Snaplock Type' {
                                Get-AbrOntapSecuritySnapLockVol
                                if ($InfoLevel.Security -ge 2) {
                                    if (Get-NcVol -Controller $Array | Where-Object { $_.VolumeSnaplockAttributes.SnaplockType -in "enterprise", "compliance" }) {
                                        Section -ExcludeFromTOC -Style Heading6 'Snaplock Volume Attributes' {
                                            Get-AbrOntapSecuritySnapLockVollAttr
                                        }
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
                    Section -Style Heading2 'System Configuration Information' {
                        Paragraph "The following section provides the Cluster System Configuration on $($ClusterInfo.ClusterName)."
                        BlankLine
                        if (Get-NcSystemImage -Controller $Array) {
                            Section -Style Heading3 'System Image Configuration' {
                                Get-AbrOntapSysConfigImage
                            }
                        }
                        if (Get-NcSystemServicesWebNode -Controller $Array) {
                            Section -Style Heading3 'System Web Service' {
                                Get-AbrOntapSysConfigWebStatus
                            }
                        }
                        if (Get-NcNetDns -Controller $Array | Where-Object { $_.Vserver -notin $Options.Exclude.Vserver }) {
                            Section -Style Heading3 'DNS Configuration' {
                                Get-AbrOntapSysConfigDNS
                            }
                        }
                        if (Get-NcSnmp -Controller $Array | Where-Object { $Null -ne $_.Communities -and ($_.IsTrapEnabled -or $_.IsSnmpEnabled) }) {
                            Section -Style Heading3 'SNMP Configuration' {
                                Get-AbrOntapSysConfigSNMP
                            }
                        }
                        if (Get-NcConfigBackupUrl -Controller $Array) {
                            Section -Style Heading3 'Configuration Backup Setting' {
                                Get-AbrOntapSysConfigBackupURL
                                if ($InfoLevel.System -ge 2) {
                                    $Nodes = Get-NcNode -Controller $Array
                                    foreach ($Node in $Nodes) {
                                        if (Get-NcConfigBackup -Node $Node -Controller $Array) {
                                            Section -Style Heading4 "$Node Configuration" {
                                                Get-AbrOntapSysConfigBackup -Node $Node
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if (Get-NcEmsDestination -Controller $Array) {
                            Section -Style Heading3 'EMS Configuration' {
                                Paragraph "The following section provides the EMS Configuration on $($ClusterInfo.ClusterName)."
                                BlankLine
                                Get-AbrOntapSysConfigEMSSetting
                                if ($InfoLevel.System -ge 2) {
                                    $Nodes = Get-NcNode -Controller $Array
                                    foreach ($Node in $Nodes) {
                                        if ($HealthCheck.System.EMS -and (Get-NcEmsMessage -Node $Node -Severity "emergency", "alert" -Controller $Array | Select-Object -First 30)) {
                                            Section -Style Heading4 "$Node Emergency and Alert Messages" {
                                                Get-AbrOntapSysConfigEMS -Node $Node
                                            }
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
                                    Section -Style Heading4 'NTP Configuration' {
                                        Get-AbrOntapSysConfigNTP
                                        if ($InfoLevel.System -ge 2) {
                                            Section -Style Heading5 'NTP Node Status Information' {
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
    }
    #$global:CurrentNcController = $null
}
