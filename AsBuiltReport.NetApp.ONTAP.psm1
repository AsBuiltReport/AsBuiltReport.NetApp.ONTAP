# Get assemblies files and import them
$assemblyName = switch ($PSVersionTable.PSEdition) {
    'Core' {
        if ($IsMacOS) {
            @(Get-ChildItem -Path ("$PSScriptRoot{0}Src{0}Bin{0}Assemblies{0}net90{0}osx-x64{0}*.dll" -f [System.IO.Path]::DirectorySeparatorChar) -ErrorAction SilentlyContinue)
        } elseif ($IsLinux) {
            @(Get-ChildItem -Path ("$PSScriptRoot{0}Src{0}Bin{0}Assemblies{0}net90{0}linux-x64{0}*.dll" -f [System.IO.Path]::DirectorySeparatorChar) -ErrorAction SilentlyContinue)
        } elseif ($IsWindows) {
            @(Get-ChildItem -Path ("$PSScriptRoot{0}Src{0}Bin{0}Assemblies{0}net90{0}win-x64{0}*.dll" -f [System.IO.Path]::DirectorySeparatorChar) -ErrorAction SilentlyContinue)
        }
    }
    'Desktop' {
        @(Get-ChildItem -Path ("$PSScriptRoot{0}Src{0}Bin{0}Assemblies{0}net48{0}*.dll" -f [System.IO.Path]::DirectorySeparatorChar) -ErrorAction SilentlyContinue)
    }
    default {
        Write-Verbose -Message 'Unable to find compatible assemblies.'
    }
}

foreach ($Assembly in $assemblyName) {
    try {
        Write-Verbose -Message "Loading assembly '$($Assembly.Name)'."
        Add-Type -Path $Assembly.FullName -Verbose
    } catch {
        Write-Error -Message "Failed to add assembly $($Assembly.FullName): $_"
    }
}

# Get public and private function definition files and dot source them
$Public = @(Get-ChildItem -Path $PSScriptRoot\Src\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Src\Private\*.ps1 -ErrorAction SilentlyContinue)

foreach ($Module in @($Public + $Private)) {
    try {
        . $Module.FullName
    } catch {
        Write-Error -Message "Failed to import function $($Module.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
Export-ModuleMember -Function $Private.BaseName