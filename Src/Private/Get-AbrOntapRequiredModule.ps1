function Get-AbrOntapRequiredModule {
    <#
    .SYNOPSIS
    Used by As Built Report to check the required 3rd party modules are installed
    .DESCRIPTION
    .NOTES
        Version:        0.1.1
        Author:         Tim Carman, Edited by Jonathan Colon
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE
    .LINK
    #>

    $OntapRequiredVersion = '9.9.1'
    $OntapRequiredModule = Get-Module -ListAvailable -Name 'Netapp.Ontap' | Sort-Object -Property Version -Descending | Select-Object -First 1
    $OntapModuleVersion = "$($OntapRequiredModule.Version.Major)" + "." + "$($OntapRequiredModule.Version.Minor)" + "." + "$($OntapRequiredModule.Version.Build)"
    if ($null -eq $OntapModuleVersion) {
        Write-Warning -Message "Netapp PSTK $OntapRequiredVersion or higher is required to run the NetApp Ontap As Built Report. Run 'Install-Module -Name Netapp.Ontap -MinimumVersion $OntapRequiredVersion' to install the required modules."
        break
    } elseif ($OntapModuleVersion -lt $OntapRequiredVersion) {
        Write-Warning -Message "Netapp PSTK $OntapRequiredVersion or higher is required to run the NetApp Ontap As Built Report. Run 'Update-Module -Name Netapp.Ontap -MinimumVersion $OntapRequiredVersion' to update Netapp.Ontapp modules."
        break
    }
}