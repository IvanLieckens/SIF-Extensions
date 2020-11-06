using namespace System.Management.Automation;

Set-StrictMode -Version 2.0

<#
    .SYNOPSIS
    Returns relevant information for the currents host
#>
Function GetHost {
    $h = Get-Host
    $result = @{
        Width = 80
        ForegroundColor = $null
        BackgroundColor = $null
    }

    if($h.HasMemberPath('UI.RawUI.Buffersize.Width')){
        $result.Width = $h.UI.RawUI.Buffersize.Width
    }

    if($h.HasMemberPath('UI.RawUI.ForegroundColor')){
        $result.ForegroundColor = $h.UI.RawUI.ForegroundColor
    }

    if($h.HasMemberPath('UI.RawUI.BackgroundColor')){
        $result.BackgroundColor = $h.UI.RawUI.BackgroundColor
    }
    $result
}


Function WriteHeader {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Settings
    )

    $actualWidth = (GetHost).Width
    $mid = ($actualWidth - ($actualWidth % 2)) /2
    $moduleName = "Sitecore Install Framework"
    # Prerelease versions must access the prerelease string from the psd1 file
    $version = $PSCmdlet.MyInvocation.MyCommand.Module.Version.ToString()
    $prVersion = GetPrereleaseTag
    $versionString = "Version - $version$prVersion"
    $delimiter = '*' * ($moduleName.Length+10)

    $strings = @(
        $delimiter
        $moduleName
        $versionString
        $delimiter
    )

    $strings.ForEach({ WriteColoredInfo -Message $_.PadLeft($mid + ($_.Length/2)) -ForegroundColor Cyan })

    $info = [pscustomobject]$settings | Format-List | Out-String

    WriteInfo -MessageData $info
}

# private function to support testing
Function GetPrereleaseTag {
    $psdata = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.PsData
    if($psdata.ContainsKey('prerelease')){
        $prVersion = $psdata.prerelease
        return "-$prVersion"
    }

    return $null
}

Function WriteTaskHeader {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','')]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [string]$TaskType
    )

    function StringFormat {
        param(
            [int]$length,
            [string]$value,
            [string]$prefix = '',
            [string]$postfix = '',
            [switch]$padright
        )

        # wraps string in spaces so we reduce length by two
        $length = $length - 2 #- $postfix.Length - $prefix.Length
        if($value.Length -gt $length){
            # Reduce to length - 4 for elipsis
            $value = $value.Substring(0, $length - 4) + '...'
        }

        $value = " $value "
        if($padright){
            $value = $value.PadRight($length, '-')
        } else {
            $value = $value.PadLeft($length, '-')
        }

        return $prefix + $value + $postfix
    }

    $actualWidth = (GetHost).Width
    $width = $actualWidth - ($actualWidth % 2)
    $half = $width / 2

    $leftString = StringFormat -length $half -value $TaskName -prefix '[' -postfix ':'
    $rightString = StringFormat -length $half -value $TaskType -postfix ']' -padright

    $message = ($leftString + $rightString)
    WriteColoredInfo
    WriteColoredInfo -Message $message -ForegroundColor Green
}

Function WriteTaskInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$MessageData,
        [string]$Tag = '',
        [string[]]$Tags = @(),
        [string]$TaskName = (Get-Variable currentTask -Scope script -ErrorAction SilentlyContinue | ForEach-Object value -WhatIf:$false)
    )

    # We only append extra info when passed a string
    # Object may contain additonal meta info - e.g. when writing coloured output

    $value = $MessageData
    if($MessageData -is [string]){
        [string]$value = $MessageData

        if($Tag){
            $value = "[$Tag] $value"
        }

        if($TaskName){
            $value = "[$TaskName]:$value"
        }
    }

    WriteInfo -MessageData $value -Tags $Tags
}

Function WriteColoredInfo {
    param(
        [string]$Message = '',
        [Nullable[ConsoleColor]]$ForegroundColor = ((GetHost).ForegroundColor),
        [Nullable[ConsoleColor]]$BackgroundColor = ((GetHost).BackgroundColor)
    )

    $msg = [HostInformationMessage]@{
        Message         = $Message
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
    }

    WriteInfo -MessageData $msg
}

# Wrapper for original implementation of Write-Information
Function WriteInfo {
    [CmdletBinding()]
    param(
        [Object]$MessageData,
        [String[]]$Tags
    )

    Microsoft.PowerShell.Utility\Write-Information @PSBoundParameters
}
