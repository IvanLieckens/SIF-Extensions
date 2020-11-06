Set-StrictMode -Version 2.0

#Requires -RunAsAdministrator

# Get Functions
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot Private) -Include *.ps1 -File -Recurse
$public = Get-ChildItem -Path (Join-Path $PSScriptRoot Public) -Include *.ps1 -File -Recurse

# Dot source to scope
# Private must be sourced first - usage in public functions during load
($private + $public) | ForEach-Object {
    try {
        . $_.FullName
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

Register-SitecoreInstallExtension -Command Invoke-ManageSolrCloudCollectionTask -As ManageSolrCloudCollection -Type Task
Register-SitecoreInstallExtension -Command Invoke-ManageSolrCloudConfigurationTask -As ManageSolrCloudConfiguration -Type Task
Register-SitecoreInstallExtension -Command Invoke-SitecoreUrlFixedTask -As SitecoreUrlFixed -Type Task