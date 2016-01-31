configuration PSDSCLab
{
    param             
    (             
        [Parameter(Mandatory)]             
        [pscredential]$safemodeAdministratorCred,             
        [Parameter(Mandatory)]            
        [pscredential]$domainCred,
        [Parameter(Mandatory)]            
        [pscredential]$userCred              
    )         
    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.Where{$_.Role -eq "DC"}.Nodename
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }       
        
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
PSDSCLab -configurationData $config `
    -safemodeAdministratorCred (Get-Credential -UserName '(Password Only)' `
        -Message "New Domain Safe Mode Administrator Password") `
    -domainCred (Get-Credential -UserName "psdsc\alex" `
        -Message "New Domain Admin Credential") `
    -userCred (Get-Credential -UserName "psdsc\dummy" `
        -Message "New Dummy User Credential")
      

# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\PSDSCLab -Verbose   

Start-DscConfiguration -ComputerName ps-dc-01 -Wait -Force -Verbose -path .\PSDSCLab -Debug