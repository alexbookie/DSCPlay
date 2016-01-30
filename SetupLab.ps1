$secpasswd = ConvertTo-SecureString "NotReallySecure1" -AsPlainText -Force
$domainCred = New-Object System.Management.Automation.PSCredential ("psdsc\Administrator", $secpasswd)
$safemodeAdministratorCred = New-Object System.Management.Automation.PSCredential ("psdsc\Administrator", $secpasswd)
$userCred = New-Object System.Management.Automation.PSCredential ("psdsc\Administrator", $newpasswd)

configuration PSDSCLab
{
    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.Where{$_.Role -eq "DC"}.Nodename
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }
        
        WindowsFeature RSATTools 
        { 
            DependsOn= '[WindowsFeature]ADDSInstall'
            Ensure = 'Present'
            Name = 'RSAT-AD-Tools'
            IncludeAllSubFeature = $true
        }  

        xADDomain FirstDS
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DependsOn = "[WindowsFeature]RSATTools"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $domaincred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        }

        xADUser FirstUser
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            UserName = "dummy"
            Password = $userCred
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

    }
}

$config = Invoke-Expression (Get-content $PSScriptRoot\LabConfig.psd1 -Raw)
PSDSCLab -configurationData $config

Start-DscConfiguration -ComputerName ps-dc-01 -Wait -Force -Verbose -path .\TestLab -Debug