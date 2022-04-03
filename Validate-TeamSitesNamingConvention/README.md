# Teams Naming Convention Validator

This is a simple PowerShell script that validates Teams naming convention within the M365 tenant. If the name does not comply, the owner is notified via email. Requirements for the script:

> Assume an organization with several thousands of users distributed across the world and encompassing several companies all under the same M365 tenant, would like that all Teams names are distinguishable at the global level. Users can create Teams spaces on their own. As a measure toward this result, the IT Department would like to verify that the name chosen by the owner is followed by a standard suffix that to reflect the country and whether the team is labelled as Local or Global. The suffix will be something like (GLO-XX) or (LOC-XX), where XX is the two letter ISO country code.
> * Could you write a PowerShell script that can be scheduled to run daily and send an email to the Teams owner if the name is not following this convention and ask him/her to change it?
> * We don’t need a fully functional script, only the most important pieces of code could be in it. Any useful explanations or useful comments can be part of another document.

## Installation
Enable script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

Install [PnP Modules](https://pnp.github.io/powershell/articles/installation.html): 
```powershell
Install-Module -Name "PnP.PowerShell"
```

Grant Admin Consent for PnP Management Shell by running:
```powershell
Register-PnPManagementShellAccess
```

Optional steps:

> Store Credentials in Windows Credential Manager:
> ```powershell
> Add-PnPStoredCredential -Name TeamsNamingConventionValidator -Username [account]@[tenant].onmicrosoft.com -Password > (ConvertTo-SecureString -String "[password]" -AsPlainText -Force)
> ```
Or (*recommanded*)

> Connect by using your own Azure AD Application. You will have to create your own Azure AD Application registration, or you can create one using:
> ```powershell
> Register-PnPAzureADApp -ApplicationName "Teams Naming Convention Validator" -Tenant [tenant].onmicrosoft.com -Store LocalMachine -Interactive
> ``` 
> The certificated that can be used to establish connection to M365 tenant will be added to machine store (Personal). Save Thumbprint and Client Id presented on the screen after operation is completed.

## Usage

Using certificate (*recommended*):
```powershell
.\Validate-TeamSitesNamingConvention.ps1 -SiteURL https://[tenant].sharepoint.com -Tenant [tenant].onmicrosoft.com -Thumbprint B318643B29CFD5E0D6448C1864C8885864652406 -ClientId 2f215ff0-aa3e-4449-b83e-5e860f0071da 
```

Using credentials:
```powershell
$UserName= "login@tenant.onmicrosoft.com"
$Password = "password"
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword

.\Validate-TeamSitesNamingConvention.ps1 -SiteURL https://[tenant].sharepoint.com -Credentials $Cred
```

Using credential store:
```powershell
.\Validate-TeamSitesNamingConvention.ps1 -SiteURL https://[tenant].sharepoint.com -WindowsCredentialsStore PnPPS:TeamsNamingConventionValidator
```

## Things to note
* The requirement is to run the script in daily schedule. I assume [Windows Task Scheduler](https://o365reports.com/2019/08/02/schedule-powershell-script-task-scheduler/) will be used.
* It's never a good idea to run scripts with login and password stored in the script or passed as parameters. The script allows it only for testing purposed. Also, if multi-factor authentication is configured, this approach will not work (same with Windows Credentials Store).
* I recommend to use the certificate. The setup saves it in the local machine store, so service account will also have access to it. There is no need to run this setup logged in as a service account.
* The solution is using M365 Groups (`Get-PnPMicrosoft365Group`). Groups are internally synchronized with Teams. When a Team is removed, renamed, owner changes etc., the associated group has the same changes applied. PnP allows to query Teams directly via `Get-PnPTeamsTeam` and `Get-PnPTeamsUser -Team $team.Id -Role Owner` but the returned objects do not have e-mail address property that's required for notification (only `UserPrincipalName`). It's possible that with some more digging this could be done differently.
* Naming convention is checked via regular expression. Default pattern is `(GLO|LOC)[-](CH|US|HK|JP|LU|SG)$` and can be adjusted using script parameter. More country codes can be added and different constrains applied. It's probably the most flexible and generic way to achieve this.
* E-mail title and body can also be adjusted using script parameters.

## License
[MIT](https://choosealicense.com/licenses/mit/)