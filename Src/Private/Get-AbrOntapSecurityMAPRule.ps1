function Get-AbrOntapSecurityMAPRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Multi-Admin Approval rules information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Security Vserver Multi-Admin Approval rules information."
    }

    process {
        try {
            $Data = Get-NetAppOntapAPI -uri "/api/security/multi-admin-verify/rules?fields=**&return_records=true&return_timeout=15"
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'operation' = $Item.operation
                            'query' = ConvertTo-EmptyToFiller $Item.query
                            'Approval Groups' = Switch ([string]::IsNullOrEmpty($Item.approval_groups.name)) {
                                $true { '-' }
                                $false { $Item.approval_groups.name }
                                default { '-' }
                            }
                            'Required Approvers' = ConvertTo-EmptyToFiller $Item.required_approvers
                            'System Defined' = ConvertTo-TextYN $Item.system_defined

                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Multi-Admin Approval Rules - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 26, 25, 25, 12, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property 'System Defined' | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}