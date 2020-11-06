Set-StrictMode -Version 2.0

Function Invoke-ManageSolrCloudConfigurationTask {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
		[ValidateSet('upload', 'list', 'delete')]
		[string]$Action,
        [Parameter(Mandatory=$true)]
        [string]$Address,
        [System.Collections.IDictionary]$Arguments = @{},
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            if($PSBoundParameters["Action"] -eq "upload")
            {
                if(Test-Path $_ -Type Leaf)
                { $true }
                else
                { $false }
            }
            else
            { $true }
        })]
        [string]$ConfigZipPath,
        [ValidateScript({ $_ -gt 0 })]
        [int]$RetryCount = 5,
        [ValidateScript({ $_ -gt -1 })]
        [int]$RetryDelay = 2000,
        [ValidateScript({ $_ -gt -1 })]
        [int]$RequestTimeout = 0
    )

	try {
		Invoke-WebRequestTask -Uri $Address -RetryCount $RetryCount -RetryDelay $RetryDelay -RequestTimeout $RequestTimeout

		$solrArgs = @()
		foreach($key in $Arguments.Keys) {
			$value = $Arguments.$key
			if($value -is [array]) {
				foreach($entry in $value){
					$newArg = NewSolrParameter -Name $key -Value $entry
					$solrArgs += $newArg
				}
			} else {
				$newArg = NewSolrParameter -Name $key -Value $value
				$solrArgs += $newArg
			}
		}

		$uriParameters = $solrArgs -join "&"

		$uri = "$Address/admin/configs?action=$Action&$uriParameters&wt=json"

		try {
			if($PSCmdlet.ShouldProcess($Address, "Invoke-ManageSolrCloudConfigurationTask -Address $Address -Action $Action")) {
				WriteTaskInfo -MessageData ("Performing $Action on $Address" | Out-String) -Tag 'SolrCloudConfiguration'

                if($Action -eq "Upload") {
					$list = Invoke-ManageSolrCloudConfigurationTask -Action "list" -Address $Address
					if(!($list.configSets -contains $Arguments.name)) {
						Write-Verbose "Uploading to SolrCloud: Uri => '$uri'"
						Invoke-WebRequest -Uri $uri -Method Post -ContentType "application/octet-stream" -InFile $ConfigZipPath -UseBasicParsing
					}
					else {
						WriteTaskInfo -MessageData ("Performing $Action on $Address skipped, configuration already exists" | Out-String) -Tag 'SolrCloudConfiguration'
					}
                }
				else {
					Write-Verbose "Updating SolrCloud: Uri => '$uri'"
                    Invoke-RestMethod -Uri $uri -UseBasicParsing
                }
			}
			else {
				WriteTaskInfo -MessageData ("Performing $Action on $Address" | Out-String) -Tag 'SolrCloudConfiguration'
			}
		}
		catch {
			$ex = GetSolrResponseError -Exception $_.Exception
			Throw $ex
		}
	} catch {
		Write-Error $_
	}
}
