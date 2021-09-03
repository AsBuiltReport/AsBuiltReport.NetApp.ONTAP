function Get-AbrOntapSecurityUsers {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Local Users information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Security Local Users information."
    }

    process {
        $Data =  Get-NcUser
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'User Name' = $Item.UserName
                    'Application' = $TextInfo.ToTitleCase($Item.Application)
                    'Auth Method' = $Item.AuthMethod
                    'RoleName' = $Item.RoleName
                    'Locked' = Switch ($Item.IsLocked) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Security.Users) {
                $OutObj | Where-Object { $_.'Locked' -eq 'Yes' -and $_.'User Name' -ne "vsadmin"} | Set-Style -Style Warning -Property 'Locked'
            }

            $TableParams = @{
                Name = "Security Local Users information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 14, 14, 20, 12, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}