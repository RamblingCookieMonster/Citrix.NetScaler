Function Invoke-NSCustomQuery {
    <#
    .SYNOPSIS
        Execute a custom query against a Citrix NetScaler

    .DESCRIPTION
        Execute a custom query against a Citrix NetScaler

        This function builds up a URI and other details for an Invoke-RESTMethod call against a Citrix NetScaler

        Use Verbose output for details (e.g. to view the final Invoke-RESTMethod parameters)

        This is a work in progress function.  Please be sure to run it with -whatif to verify it builds your Invoke-RESTMethod call correctly.

    .PARAMETER Address
        Hostname or IP for the NetScaler

    .PARAMETER Credential
        PSCredential object to authenticate with NetScaler.  Prompts if you don't provide one.

    .PARAMETER WebSession
        If specified, use an existing web session rather than an explicit credential

    .PARAMETER QueryType
        Query type.  Valid options are 'config' and 'stat'.  See list parameter

    .PARAMETER List
        If this switch is specified, provide a list of all valid objects for specified QueryType

    .PARAMETER ResourceType
        Type of object to query for

    .PARAMETER ResourceName
        Name of an object to query for

    .PARAMETER Argument
        If specified, the argument for a query

    .PARAMETER FilterTable
        If specified, use this hashtable of attribute/value pairs to filter results.  Examples:
            @{ipv46="1.1.1.1"}
            @{state="ENABLED";ipv46="1.1.1.1"}

    .PARAMETER Raw
        Provide direct results from Invoke-RESTMethod

    .PARAMETER Method
        This is directly mapped to the same parameter on Invoke-RESTMethod.  Get-Help Invoke-RESTMethod -full for more details

    .PARAMETER ContentType
        This is directly mapped to the same parameter on Invoke-RESTMethod.  Get-Help Invoke-RESTMethod -full for more details

    .PARAMETER Body
        This is directly mapped to the same parameter on Invoke-RESTMethod.  Get-Help Invoke-RESTMethod -full for more details

    .PARAMETER Headers
        This is directly mapped to the same parameter on Invoke-RESTMethod.  Get-Help Invoke-RESTMethod -full for more details

    .PARAMETER Action
        Action to run.  Example:  Disable.

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .EXAMPLE
        #Return details on lbvservers from CTX-NS-TST-01 where IPV46 is "1.1.1.1"
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "lbvserver" -FilterTable @{ipv46="1.1.1.1"}
    
    .EXAMPLE
        #Return all enabled servers on CTX-NS-TST-01
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "server" -FilterTable @{state="ENABLED"}
        #Return all disabled servers on CTX-NS-TST-01
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "server" -FilterTable @{state="DISABLED"}
    
    .EXAMPLE
        #Return details on lbvserver with name SomeLBVServer from CTX-NS-TST-01
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "lbvserver" -ResourceName "SomeLBVServer"

    .EXAMPLE
        #List available 'config' objects we can query.  lbvserver, server, service and servicegroup are a few examples:
            Invoke-NSCustomQuery -Address CTX-NS-TST-01 -QueryType config -list -Credential $cred

        #pull the same list for the stat objects
            Invoke-NSCustomQuery -Address CTX-NS-TST-01 -QueryType stat -list -Credential $cred

    .EXAMPLE

        #Pull all lbvservers, servers, services, servicegroups from ctx-ns-tst-01
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "lbvserver" -Credential $cred
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "server" -Credential $cred
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "service" -Credential $cred
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "servicegroup" -Credential $cred

    .EXAMPLE

        #These two queries pull the same information.  Invoke-NSCustomQuery provides the data, but does not help parsing the results or validating vserver:
            #Get-NSLBVServerBinding -Address CTX-NS-TST-01 -VServer "SomeValidVServerName" -Credential $cred
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "lbvserver_binding" -Argument "SomeValidVServerName" -Credential $cred

    .EXAMPLE
        
    #This example illustrates how to disable a server.  Note that this does not save changes!

        #Build the JSON for a server you want to disable
$json = @"
{
    "server": {
        "name":"SomeServerName"
    }
}
"@

        #Create a session on CTX-NS-TST-01
            $session = Get-NSSessionCookie -Address ctx-ns-tst-01 -AllowHTTPAuth

        #use that session to disable a server
            Invoke-NSCustomQuery -Address "CTX-NS-TST-01" -ResourceType "server" -method Post -Body $json -ContentType application/vnd.com.citrix.netscaler.server+json -AllowHTTPAuth -action disable -verbose -WebSession $session
            #Note that an error will be returned indicating null output.  Not sure how else to handle this, as null output is usually bad.  Will work on it...
            
        #verify the change:
            Invoke-NSCustomQuery -Address CTX-NS-TST-01 -ResourceType server -ResourceName SomeServerName -Credential $cred -AllowHTTPAuth

    .NOTES
        There isn't much detail out there about using this API with PowerShell.  I suspect this wrapper will be limited in the calls it can make.
        
        A few resources for further reading:
            http://blogs.citrix.com/2011/08/05/nitro-apis-fun-over-http/
            http://support.citrix.com/proddocs/topic/netscaler-main-api-10-map/ns-nitro-rest-landing-page-con.html
            http://support.citrix.com/servlet/KbServlet/download/30602-102-681756/NS-Nitro-Gettingstarted-guide.pdf

    .FUNCTIONALITY
        NetScaler

    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler

    #>
[cmdletbinding(
    DefaultParameterSetName='SimpleQuery',
    SupportsShouldProcess=$true,
    ConfirmImpact='High'
)]
param(

    [Parameter()]
    [validateset("CTX-NS-01","CTX-NS-02","CTX-NS-03","CTX-NS-04","CTX-NS-TST-01","CTX-NS-TST-02")]
        [string]$Address = "CTX-NS-TST-01",

    [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = $null,

    [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession = $null,
    
    [Parameter()]
    [validateset("config","stat")]
        [string]$QueryType="config",

    [Parameter( ParameterSetName='List' )]
        [switch]$list,

    [Parameter( ParameterSetName='SimpleQuery' )]
    [Parameter( ParameterSetName='AdvancedQuery' )]
    [validatescript({$_ -notmatch "\W"})]
        [string]$ResourceType = $null,

    [Parameter( ParameterSetName='SimpleQuery' )]
    [Parameter( ParameterSetName='AdvancedQuery' )]
    [validatescript({$_ -notmatch "\W"})]
        [string]$ResourceName = $null,
    
    [Parameter( ParameterSetName='SimpleQuery' )]
    [Parameter( ParameterSetName='AdvancedQuery' )]
    [validatescript({$_ -notmatch "\W"})]
        [string]$Argument = $null,

    [Parameter( ParameterSetName='SimpleQuery' )]
    [Parameter( ParameterSetName='AdvancedQuery' )]
    [validatescript({
        #We don't want any non word characters as a key...
        #values are harder to test, e.g. could be an IP...
        foreach($key in $_.keys){
            if($key -match "\W"){
                Throw "`nError:`n`FilterTable contains key '$key' with a non-word character"
            }
        }
        $true
    })]
        [System.Collections.Hashtable]$FilterTable = $null,
    
    [Parameter()]
        [switch]$Raw,

    [Parameter( ParameterSetName='AdvancedQuery' )]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "Get",

    [Parameter( ParameterSetName='AdvancedQuery' )]
        [string]$ContentType = $null,

    [Parameter( ParameterSetName='AdvancedQuery' )]
        [string]$Body = $null,

    [Parameter( ParameterSetName='AdvancedQuery' )]
        [string]$Headers = $null,

    [Parameter( ParameterSetName='AdvancedQuery' )]
        [string]$Action = $null,

    [Parameter()]
        [switch]$AllowHTTPAuth,

    [Parameter()]
        [bool]$TrustAllCertsPolicy = $true

)

    if(-not $WebSession -and -not $Credential)
    {
        Write-Warning "No WebSession or Credential provided.  Please provide credentials"
        $Credential = $( Get-Credential -Message "Provide credentials for '$Address'" )
        if(-not $Credential)
        {
            break
        }
    }

    #Run Set-TrustAllCertsPolicy unless otherwise specified.
    if( $TrustAllCertsPolicy )
    {
        Try{
            #Dependency on GitHub repo https://github.com/RamblingCookieMonster/Citrix.NetScaler
            Set-TrustAllCertsPolicy -ErrorAction stop
        }
        Catch{
            Write-Warning "Set-TrustAllCertsPolicy does not exist or produced an error.  Proceeding.  Details: $_"
        }

    }

    #Function to invoke rest method and fall back to HTTP if needed and specified
    Function Invoke-InvokeRESTMethod {
        [cmdletbinding()]
        param($IRMParam = $IRMParam, $AllowHTTPAuth = $AllowHTTPAuth)
        
        Try
        { 
            Invoke-RestMethod @IRMParam
        }
        
        Catch
        {
            Write-Warning "Error calling Invoke-RESTMethod: $_"
            if($AllowHTTPAuth)
            {
                Try
                {
                    Write-Verbose "Reverting to HTTP"
                    $IRMParam["URI"] = $IRMParam["URI"] -replace "^https","http"
                    Invoke-RestMethod @IRMParam
                }
                Catch
                {
                    Throw "Fallback to HTTP Failed: $_"
                    break
                }
            }
        }
    }

    #Define the URI
    $uri = "https://$address/nitro/v1/$($QueryType.tolower())/"
    
    #Build up the URI for non-list queries
    if(-not $list)
    {
        
        #Add the resource type
        if($ResourceType)
        {
            
            Write-Verbose "Added ResourceType $ResourceType to URI"
            $uri += "$($ResourceType.tolower())/"
            
            #Allow a resourcename to be specified
            if($ResourceName)
            {
                Write-Verbose "Added ResourceName $ResourceName to URI"
                $uri += "$($ResourceName.tolower())/"
            }
            #Add an argument (e.g. a valid lbvserver for lbvserver_binding resource)
            elseif($Argument)
            {
                Write-Verbose "Added Argument $Argument to URI"
                $uri += "$Argument"
            }
        }

        #Create a filter string from the provided hash table
        if($FilterTable)
        {
            $uri = $uri.TrimEnd("/")
            $uri += "?filter="
            $uri += $(
                foreach($key in $FilterTable.keys)
                    {
                        "$key`:$($FilterTable[$key])"
                    }
            ) -join ","
        }
        elseif($Action)
        {
            $uri = $uri.TrimEnd("/")
            #Add tolower()?
            $uri += "?action=$Action"
        }
    }

    #Build up invoke-Restmethod parameters based on input
    $IRMParam = @{
        Method = $Method
        URI = $URI
        ErrorAction = "Stop"
    }
    If($Credential)
    {
        $IRMParam.add("Credential",$Credential)
    }
    If($WebSession)
    {
        $IRMParam.add("WebSession",$WebSession)
    }
    If($ContentType)
    {
        $IRMParam.add("ContentType",$ContentType)
    }
    If($Body)
    {
        $IRMParam.add("Body",$Body)
    }
    If($Headers)
    {
        $IRMParam.add("Headers",$Headers)
    }

    Write-Verbose "Invoke-RESTMethod params: $($IRMParam | Format-Table -AutoSize -wrap | out-string)"
    
    #Invoke the REST Method
    if($PsCmdlet.ParameterSetName -eq "AdvancedQuery")
    {
        if ($pscmdlet.ShouldProcess("IRM Parameters:`n $($IRMParam | Format-Table -AutoSize -wrap | out-string)", "Invoke-RESTMethod with the following parameters"))
        {
            $result = Invoke-InvokeRESTMethod
        }
        else
        {
            break
        }
    }
    else
    {
        $result = Invoke-InvokeRESTMethod
    }

    #Display the results
    if($result)
    {
        if($raw)
        {
            #user wants raw output from invoke-restmethod
            $result
        }
        elseif($list)
        {
            #list parameterset, expand the properties!
            $result | select -ExpandProperty "$QueryType`objects" | select -ExpandProperty objects
        }
        elseif($ResourceType)
        {
            if($result.$ResourceType){
                #expand the resourcetype
                $result | select -ExpandProperty $ResourceType -ErrorAction stop
            }
            elseif($result.errorcode -eq 0)
            {
                Return $null
            }
            else
            {
                Write-Error "Result did not have expected property '$ResourceType' and errorcode mismatch.  Invoke-RESTMethod output:`n"
                $result
            }
        }
    }
    else
    {
        Write-Error "Invoke-RESTMethod output was empty.  Try troubleshooting with -verbose switch"
    }
}