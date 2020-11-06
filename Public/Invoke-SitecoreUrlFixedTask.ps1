Set-StrictMode -Version 2.0
Function Invoke-SitecoreUrlFixedTask {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams','')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SitecoreInstanceRoot,
        [Parameter(Mandatory=$true)]
        [string]$SitecoreActionPath,
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$Password
    )

    $actionPage = "$SitecoreInstanceRoot/$SitecoreActionPath"

    if($PSCmdlet.ShouldProcess("$actionPage", "Invoke-SitecoreUrlFixedTask")) {

        function GetAuthorizedSession {

            WriteTaskInfo -MessageData $actionPage -Tag "Authenticating"
            $uri = "$SitecoreInstanceRoot/sitecore/login?fbc=1"
            $authResponse = Invoke-WebRequest -uri $uri -SessionVariable session -UseBasicParsing
            TestStatusCode $authResponse

            # Set login info
            $fields = @{}
            $authResponse.InputFields.ForEach({
                if($_.HasMember('Value')){
                    $fields[$_.Name] = $_.Value
                }
            })

            $fields.UserName = $Username
            $fields.Password = $Password
            $fields.Remove("ctl11")

            # Login using the same session
            $authResponse = Invoke-WebRequest -uri $uri -WebSession $session -Method POST -Body $fields -UseBasicParsing
            TestStatusCode $authResponse
            TestCookie $session.Cookies

            return $session
        }

        function TestStatusCode {
            param($response)

            if($response.StatusCode -ne 200) {
                throw "The request returned a non-200 status code [$($response.StatusCode)]"
            }
        }

        function TestCookie {
            param([System.Net.CookieContainer]$cookies)

            $discovered = @($cookies.GetCookies($SitecoreInstanceRoot) |
                Where-Object { $_.Name -eq '.ASPXAUTH' -Or $_.Name -eq '.AspNet.Cookies' })

            if($discovered.Count -ne 1){
                throw "Authentication failed. Check username and password"
            }
        }

        try {

            # Get an authorized session
            $authSession = GetAuthorizedSession

            # Use the session to perform the actual request
            WriteTaskInfo -MessageData $actionPage -Tag "Requesting"
            $actionResponse = Invoke-WebRequest -uri $actionPage -WebSession $authSession -UseBasicParsing
            TestStatusCode $actionResponse

            WriteTaskInfo -MessageData "Completed Request" -Tag "Success"
        }
        catch {
            Write-Error -Message ("Error requesting $actionPage" + ": $($_.Exception.Message)")
        }
    }
}