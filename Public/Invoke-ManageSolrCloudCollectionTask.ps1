Set-StrictMode -Version 2.0

Function Invoke-ManageSolrCloudCollectionTask {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
		[ValidateSet('create', 'modifycollection', 'reindexcollection', 'reload', 'rename', 'splitshard', 'createshard', 'deleteshard', 'createalias', 'listaliases', 'aliasprop', 'deletealias', 'delete', 'deletereplica', 'addreplica', 'clusterprop', 'collectionprop', 'colstatus', 'migrate', 'addrole', 'removerole', 'overseerstatus', 'clusterstatus', 'requeststatus', 'deletestatus', 'list', 'addreplicaprop', 'deletereplicaprop', 'balanceshardunique', 'rebalanceleaders', 'forceleader', 'migratestateformat', 'backup', 'restore', 'deletenode', 'replacenode', 'movereplica', 'utilizenode')]
		[string]$Action,
        [Parameter(Mandatory=$true)]
        [string]$Address,
        [System.Collections.IDictionary]$Arguments = @{},
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

		$uri = "$Address/admin/collections?action=$Action&$uriParameters&wt=json"

		try {
			if($PSCmdlet.ShouldProcess($Address, "Invoke-ManageSolrCloudCollectionTask -Address $Address -Action $Action")) {
				WriteTaskInfo -MessageData ("Performing $Action on $Address" | Out-String) -Tag 'SolrCloudCollection'

				if($Action -eq "create") {
					$list = Invoke-ManageSolrCloudCollectionTask -Action "list" -Address $Address
					if(!($list.collections -contains $Arguments.name)) {
						Write-Verbose "Updating SolrCloud: Uri => '$uri'"
						Invoke-RestMethod -Uri $uri -UseBasicParsing
					}
					else {
						WriteTaskInfo -MessageData ("Performing $Action on $Address skipped, collection already exists" | Out-String) -Tag 'SolrCloudCollection'
					}
				} else {
					Write-Verbose "Updating SolrCloud: Uri => '$uri'"
					Invoke-RestMethod -Uri $uri -UseBasicParsing
				}
			}
			else {
				WriteTaskInfo -MessageData ("Performing $Action on $Address" | Out-String) -Tag 'SolrCloudCollection'
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
