Function Get-NSCSvServer {
    <#
    .SYNOPSIS
        Get CSvServer objects for Citrix Netscaler
    .PARAMETER Name
        Filter on the name property, wildcards accepted
    .EXAMPLE
        Get-NSCSvServer

        Retrieves all CSvServer objects on the NS
    .EXAMPLE
        Get-NSCSvServer -Name ping*

        Retrieves all CSvServer objects whose name begins with ping
    .NOTES
        Author:             Martin Pugh
        Twitter:            @thesurlyadm1n
        Spiceworks:         Martin9700
        Blog:               www.thesurlyadmin.com
      
        Changelog:
            1.0             Initial Release
    .FUNCTIONALITY
        NetScaler
    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [CmdletBinding()]
    Param (
        [string]$Name = "*"
    )

    #Validate NSSession
    ValidateNSSession

    #Retrieve server data
    Invoke-NSCustomQuery -ResourceType csvserver | Where Name -like $Name
}