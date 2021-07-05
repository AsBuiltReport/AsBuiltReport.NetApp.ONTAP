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

        #region VxRail Section
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
        }#endregion Cluster Section
            #region Node Section
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
                        }
                    }
                }
            }#endregion Node Section
            #region Storage Section
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
                        Section -Style Heading4 'Failed Disk Summary' {
                            Paragraph "The following section show failed disks on cluster $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskBroken
                        }
                        Section -Style Heading4 'Disk Inventory' {
                            Paragraph "The following section provides the Disks installed on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskInv
                        }
                    }
                    If ($Nodeshelf) {
                        Section -Style Heading3 'Shelf Inventory' {
                            Paragraph "The following section provides the available Shelf on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapDiskShelf
                        }
                    }
                }
            }#endregion Storage Section
            #region Storage Section
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
            Write-PScriboMessage "Network InfoLevel set at $($InfoLevel.Network)."
            if ($InfoLevel.Network -gt 0) {
                Section -Style Heading2 'Network Summary' {
                    Paragraph "The following section provides a summary of the networking features on $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Network Ports Summary' {
                        Paragraph "The following section provides the physical ports on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Get-AbrOntapNetworkPorts
                        Section -Style Heading4 'Network Link Aggregation Group Summary' {
                            Paragraph "The following section provides the IFGRP Aggregated Ports on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkIfgrp
                        }
                        Section -Style Heading4 'IPSpace Summary' {
                            Paragraph "The following section provides the IPSpece information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            Get-AbrOntapNetworkIpSpace
                        }
                    }
                }
            }#endregion License Section
        }
    }
