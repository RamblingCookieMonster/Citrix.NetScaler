Function GetNSisPrimary {
    <#
    .SYNOPSIS
        Get the current HA state for a NetScaler, used in the Connect-NSSessionCookie function to determine if you are connecting to a primary HA pair

    .PARAMETER NSSession
        Required NSSession object from Connect-NSSessionCookie
    
    .EXAMPLE
        #Create a session on the NetScaler
            $session = Get-NSSessionCookie -Address "CTX-NS-TST-01"

        #$true or $false depending on whether ctx-ns-tst-01 is the primary in an HA cluster
            GetNSisPrimary -NSSession $session

    .FUNCTIONALITY
        NetScaler

    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline,Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$NSSession
    )

    #Define the URI
    $Uri = "https://$($NSSession.Address)/nitro/v1/stat/ns/"
    
    #Build up invoke-Restmethod parameters based on input
    $IRMParam = @{
        Method = "Get"
        URI = $Uri
        WebSession = $NSSession
        ErrorAction = "Stop" 
    }

    #Collect Results
    $Result = $null
    $Result = CallInvokeRESTMethod -IRMParam $IRMParam -AllowHTTPAuth $NSSession.AllowHTTPAuth -ErrorAction Stop

    #Take action depending on -raw parameter and the data in $Result
    If ($Result)
    {
        #Result exists with no error
        If($Result.errorcode -eq 0)
        {
            If ($Result.ns.hacurmasterstate -eq "Primary")
            {
                $true
            }
            Else
            {
                $false
            }
        }
        Else
        {
            Write-Error "Something went wrong.  Full Invoke-RESTMethod output: `n"
            $Result
        }
    }
    else
    {
        Write-Error "Invoke-RESTMethod output was empty.  Try troubleshooting with -verbose switch"
    }
}