Function ValidateNSSession {
    <#
    #>

    If ($NSSession -isnot [Microsoft.PowerShell.Commands.WebRequestSession])
    {
        Throw "No connection with an NS has been established.  Run Connect-NSSession to create a session."
    }
}