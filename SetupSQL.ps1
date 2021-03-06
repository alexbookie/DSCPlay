configuration LabSQL
{
    param 
    ( 
        [Parameter(Mandatory)] 
        [string]$MachineName, 

        [Parameter(Mandatory)] 
        [string]$Domain, 

        [Parameter(Mandatory)] 
        [pscredential]$DomainCredential 
    ) 

    #Import the required DSC Resources 
    Import-DscResource -Module xComputerManagement 
    
    Node $AllNodes.Where{$_.Role -eq "SQL"}.Nodename
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
            Credential    = $DomainCredential  # Credential to join to domain 
        } 
         
        
    }
}

$config = Invoke-Expression (Get-content $PSScriptRoot\LabConfig.psd1 -Raw)

LabSQL -configurationData $config `
    -MachineName "ps-sql-01" `
    -Domain "psdsc.waterstonslabs.com" `
    -DomainCredential (Get-Credential -UserName "alex" `
        -Message "Domain Admin Credential")
        
Set-DSCLocalConfigurationManager -Path .\LabSQL -Verbose   

Start-DscConfiguration -ComputerName ps-sql-01 -Wait -Force -Verbose -path .\LabSQL -Debug