Function Get-NSServer {
    <#
    .SYNOPSIS
        Get server objects for Citrix Netscaler
    .PARAMETER Name
        Filter on the name property, wildcards accepted
    .EXAMPLE
        Get-NSServer

        Retrieves all server objects on the NS
    .EXAMPLE
        Get-NSServer -Name ping*

        Retrieves all server objects whose name begins with ping
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
    Invoke-NSCustomQuery -ResourceType server | Where Name -like $Name
}