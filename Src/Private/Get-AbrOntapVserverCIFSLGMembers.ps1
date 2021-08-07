function Get-AbrOntapVserverCIFSLGMembers {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Local Group Members information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Collecting ONTAP CIFS Local Group Members information."
    }

    process {
        $VserverData = Get-NcCifsLocalGroupMember
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Group Name' = $Item.GroupName
                    'Description' = $Item.Member
                    'Vserver' = $Item.Vserver
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "CIFS Connected Local Group Members Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}