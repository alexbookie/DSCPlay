@{
    AllNodes = @(

        @{
            Nodename = "ps-dc-01"
            Role = "DC"
            DomainName = "psdsc.waterstonslabs.com"
            PSDscAllowPlainTextPassword = $true
        RetryCount = 20 
        RetryIntervalSec = 30 
        },

    )
}