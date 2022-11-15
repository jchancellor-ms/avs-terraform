#set the password for the credential using random output entry
$password = ConvertTo-SecureString ${password} -AsPlainText -Force
#install ad and ad tools features
Add-WindowsFeature -name ad-domain-services -IncludeManagementTools
#install DNS feature
Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools -ErrorAction SilentlyContinue
#configure a basic domain
Install-ADDSForest -CreateDnsDelegation:$false -DomainMode WinThreshold -DomainName ${active_directory_domain} -DomainNetbiosName ${active_directory_netbios_name} -ForestMode WinThreshold -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true



