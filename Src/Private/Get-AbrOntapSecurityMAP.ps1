function Get-AbrOntapSecurityMAP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Multi-Admin Approval information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.5
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP Security Vserver Multi-Admin Approval information."
    }

    process {
        try {
            $Data =  Get-NetAppOntapAPI -uri "/api/security/multi-admin-verify/approval-groups?fields=**&return_records=true&return_timeout=15"
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Approvers' = Switch ([string]::IsNullOrEmpty($Item.Approvers)) {
                                $true {'-'}
                                $false {$Item.Approvers -join ', '}
                                default {'-'}
                            }
                            'Email' = Switch ([string]::IsNullOrEmpty($Item.Email)) {
                                $true {'-'}
                                $false {$Item.Email -join ', '}
                                default {'-'}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Multi-Admin Approval - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 34,33, 33
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}