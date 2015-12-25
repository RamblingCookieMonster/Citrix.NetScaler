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
    [CmdletBinding(
        DefaultParameterSetName='SimpleQuery',
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    Param (
        [validateset("config","stat")]
        [string]$QueryType="config",

        [Parameter( ParameterSetName='List' )]
        [switch]$List,

        [Parameter( ParameterSetName='SimpleQuery' )]
        [Parameter( ParameterSetName='AdvancedQuery' )]
        [ValidateScript({
            If ($Global:NSEnumeration -contains $_)
            {
                $true
            }
        })]
        #[validatescript({$_ -notmatch "\W"})]
        [string]$ResourceType = $null,

        [Parameter( ParameterSetName='SimpleQuery' )]
        [Parameter( ParameterSetName='AdvancedQuery' )]
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
        [string]$Action = $null
    )

    #Define default views
    $DefaultView = @{
        "server"        = @("Name","IPAddress")
        "lbmonitor"     = @("Name","Type")
        "service"       = @("Name","ServerName","ServiceType","Port","SvrState")
        "servicegroup"  = @("Name","ServiceType","ServiceGroupEffectiveState")
        "lbvserver"     = @("Name","IPv46","ServiceType","EffectiveState")
        "csvserver"     = @("Name","IPv46","ServiceType","Port")
    }

    #Define the URI
    $Uri = "https://$($NSSession.Address)/nitro/v1/$($QueryType.tolower())/"
    
    #Build up the URI for non-list queries
    If (-not $List)
    {
        
        #Add the resource type
        If ($ResourceType)
        {
            Write-Verbose "Added ResourceType $ResourceType to URI"
            $Uri += "$($ResourceType.tolower())/"
            
            #Allow a resourcename to be specified
            If ($ResourceName)
            {
                Write-Verbose "Added ResourceName $ResourceName to URI"
                $Uri += "$($ResourceName.tolower())/"
            }
            #Add an argument (e.g. a valid lbvserver for lbvserver_binding resource)
            ElseIf ($Argument)
            {
                Write-Verbose "Added Argument $Argument to URI"
                $Uri += "$Argument"
            }
        }

        #Create a filter string from the provided hash table
        if($FilterTable)
        {
            $Uri = $Uri.TrimEnd("/")
            $Uri += "?filter="
            $Uri += $(
                ForEach ($Key in $FilterTable.Keys)
                {
                    "$Key`:$($FilterTable[$Key])"
                }
            ) -join ","
        }
        ElseIf ($Action)
        {
            $Uri = $Uri.TrimEnd("/")
            #Add tolower()?
            $Uri += "?action=$Action"
        }
    }

    #Build up invoke-Restmethod parameters based on input
    $IRMParam = @{
        Method = $Method
        URI = $Uri
        WebSession = $NSSession
        ErrorAction = "Stop"
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
    If ($PsCmdlet.ParameterSetName -eq "AdvancedQuery")
    {
        If ($PsCmdlet.ShouldProcess("IRM Parameters:`n $($IRMParam | Format-Table -AutoSize -wrap | out-string)", "Invoke-RESTMethod with the following parameters"))
        {
            $Result = CallInvokeRESTMethod
        }
        Else
        {
            break
        }
    }
    Else
    {
        $Result = CallInvokeRESTMethod
    }

    #Display the results
    If ($Result)
    {
        If ($Raw)
        {
            #user wants raw output from invoke-restmethod
            $Result
        }
        ElseIf ($List)
        {
            #list parameterset, expand the properties!
            $Result | select -ExpandProperty "$QueryType`objects" | select -ExpandProperty objects
        }
        ElseIf ($ResourceType)
        {
            If ($Result.$ResourceType){
                #expand the resourcetype
                $Output = $Result | select -ExpandProperty $ResourceType -ErrorAction stop

                #Normalize Name of the service to Name property
                Switch ($ResourceType)
                {
                    "lbmonitor"     { $Output = $Output | Select @{Name="Name";Expression={ $_.MonitorName }},* -ExcludeProperty MonitorName; Break }
                    "servicegroup"  { $Output = $Output | Select @{Name="Name";Expression={ $_.servicegroupname }},* -ExcludeProperty servicegroupname; Break }
                }

                #Add default object view for readability
                If ($DefaultView[$ResourceType])
                {
                    $Output | Add-Member MemberSet PSStandardMembers ([System.Management.Automation.PSMemberInfo[]]@(New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[String[]]@($DefaultView[$ResourceType]))))
                }
                #Add ResourceType to object, used in later functions
                $Output | Add-Member -MemberType NoteProperty -Name ResourceType -Value $ResourceType

                Write-Output $Output
            }
            ElseIf ($Result.errorcode -ne 0)
            {
                Write-Error "Result did not have expected property '$ResourceType' and errorcode mismatch.  Invoke-RESTMethod output:`n"
                $Result
            }
        }
    }
    Else
    {
        Write-Error "Invoke-RESTMethod output was empty.  Try troubleshooting with -verbose switch"
    }
}