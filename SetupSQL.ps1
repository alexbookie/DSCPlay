configuration LabSQL
{
    param 
    ( 
        [string[]]$NodeName="localhost", 

        [Parameter(Mandatory)] 
        [string]$MachineName, 

        [Parameter(Mandatory)] 
        [string]$Domain, 

        [Parameter(Mandatory)] 
        [pscredential]$DomainCredential 
    ) 

    #Import the required DSC Resources 
    Import-DscResource -Module xComputerManagement 
    
    Node $AllNodes.Where($_.Role -eq "SQL").Nodename
    {

        LocalConfigurationManager 
        { 
            RebootNodeIfNeeded = $true 
            ConfigurationMode = "ApplyOnly" 
        }
        
        xComputer JoinDomain 
        { 
            Name          = $MachineName  
            DomainName    = $Domain 
            Credential    = $Credential  # Credential to join to domain 
        } 
         
        
    }
}