function Get-AbrOntapSecurityUser {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Local Users information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Security Local Users information."
    }

    process {
        try {
            $Data = Get-NcUser -Vserver $Vserver -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'User Name' = $Item.UserName
                            'Application' = $TextInfo.ToTitleCase($Item.Application)
                            'Auth Method' = $Item.AuthMethod
                            'Role Name' = $Item.RoleName
                            'Locked' = ConvertTo-TextYN $Item.IsLocked
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Security.Users) {
                    $OutObj | Where-Object { $_.'Locked' -eq 'Yes' -and $_.'User Name' -ne "vsadmin" } | Set-Style -Style Warning -Property 'Locked'
                }

                $TableParams = @{
                    Name = "Security Local Users - $($Vserver)"
                    List = $false
                    ColumnWidths = 25, 15, 15, 30, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}