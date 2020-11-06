<#
    Private scoped functions supporting extraction of Solr error messages
#>

Set-StrictMode -Version 2.0

Function GetSolrResponseError {
    param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebException]$Exception
    )

	try {
		$404Error = Handle404 $Exception
		if($404Error) { return $404Error }

		$responseData = GetExceptionResponseBody -Exception $Exception
		$responseJson = ConvertFrom-Json -InputObject $responseData

	    return $responseJson.error.msg
	}
	catch {
		return $_
	}
}

Function Handle404 {
	param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebException]$Exception
    )

	$message = $null
	try {
		$webex = $Exception.Response -as [System.Net.HttpWebResponse]
		if($webex.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
			$message = "$($webex.StatusCode) - $($webex.ResponseUri)"
		}
	} catch {
		$message = $null
	}

	return $message
}

Function GetExceptionResponseBody {
	param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebException]$Exception
    )

	if($null -eq $Exception.Response)
	{
		return ConvertTo-Json -InputObject  @{ "error" = @{ "msg" = $Exception.Message } }
	}

	$responseStream = GetExceptionResponseStream -Exception $Exception

	$reader = New-Object System.IO.StreamReader($responseStream)
	$reader.BaseStream.Position = 0
	$reader.DiscardBufferedData()

	$responseBody = $reader.ReadToEnd()

	if($responseBody.Length -eq 0)
	{
		return ConvertTo-Json -InputObject  @{ "error" = @{ "msg" = $Exception.Message } }
	}

	return $responseBody
}

Function GetExceptionResponseStream {
	param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebException]$Exception
    )

	if($null -eq $Exception.Response)
	{
		return New-Object -TypeName System.IO.MemoryStream
	}

	$responseStream = $Exception.Response.GetResponseStream()

	if($null -eq $responseStream)
	{
		return New-Object -TypeName System.IO.MemoryStream
	}

	return $responseStream
}

Function CreateSolrKeyValue {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Key,
		[AllowNull()]
		[AllowEmptyString()]
		[string]$Value
	)

	$result = $Key
	if(-not [string]::IsNullOrWhiteSpace($Value)) {
		$result += "=$Value"
	}

	$result
}

Function NewSolrParameter {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Name,
		[AllowNull()]
		[AllowEmptyString()]
		[psobject]$Value
	)

	$argument = "$Name"

	if($Value) {
		if($Value -is [System.Collections.IDictionary]) {
			$collected = $Value.Keys | ForEach-Object {
				CreateSolrKeyValue $_ $Value.$_
			}
			$argument += '='
			$argument += $collected -join ','
		} else {
			if(-not [string]::IsNullOrWhiteSpace($Value)) {
				$argument += '='
				$argument += $Value
			}
		}
	}

	$argument
}
