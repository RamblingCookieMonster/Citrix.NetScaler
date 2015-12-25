Function Get-NSLBvServer {
    <#
    .SYNOPSIS
        Get lbvserver objects for Citrix Netscaler
    .PARAMETER Name
        Filter on the name property, wildcards accepted
    .EXAMPLE
        Get-NSlbvserver

        Retrieves all lbvserver objects on the NS
    .EXAMPLE
        Get-NSlbvserver -Name ping*

        Retrieves all lbvserver objects whose name begins with ping
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
    Invoke-NSCustomQuery -ResourceType lbvserver | Where Name -like $Name
}