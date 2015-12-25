Function Get-NSBinding {
    <#
    .SYNOPSYS
        Retrieve the bindings of NS objects
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [string]$ResourceType
    )

    Begin {
        #Validate valid NSSession is available
        ValidateNSSession

        #Define returned property (of course they're not the same across objects)
        $BindingProperty = @{
            "csvserver" = @("csvserver_cspolicy_binding")
            "server" = @("server_service_binding","server_servicegroup_binding")
        }
    }

    Process {
        $Data = Invoke-NSCustomQuery -ResourceType "$ResourceType`_binding" -ResourceName $Name

        If ($BindingProperty.ContainsKey($ResourceType))
        {
            ForEach ($ServiceType in $BindingProperty[$ResourceType])
            {
                If ($Data | Get-Member -Name $ServiceType)
                {
                    $Data | Select -ExpandProperty $ServiceType
                    Break
                }
            }
        }
        Else
        {
            $Data | Select * -ExcludeProperty ResourceTYpe
        }
    }
}