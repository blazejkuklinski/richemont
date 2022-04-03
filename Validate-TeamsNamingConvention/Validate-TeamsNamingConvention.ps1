<#
    .DESCRIPTION

    Assume an organization with several thousands of users distributed across the world and encompassing several companies all under the same M365 tenant, would like that all Teams names are distinguishable at the global level. 
    Users can create Teams spaces on their own. As a measure toward this result, the IT Department would like to verify that the name chosen by the owner is followed by a standard suffix that to reflect the country and whether 
    the team is labelled as Local or Global. The suffix will be something like (GLO-XX) or (LOC-XX), where XX is the two letter ISO country code.

    .EXAMPLE
    .\Validate-TeamSitesNamingConvention.ps1 -SiteURL https://[tenant].sharepoint.com -Tenant [tenant].onmicrosoft.com -Thumbprint [CertificateThumbprint] -ClientId [ClientId]

    .LINK
    https://github.com/blazejkuklinski/richemont#readme
#>

[Cmdletbinding()]
param(

    [string][Parameter(Position=0,mandatory=$true)]$SiteURL,

    [System.Management.Automation.PSCredential]$Credentials,
    [string]$WindowsCredentialsStore,

    [string]$Thumbprint,
    [string]$ClientId,
    [string]$Tenant,

    [string]$RegexPattern = "(GLO|LOC)[-](CH|US|HK|JP|LU|SG)$",

    [string]$MailSubject = "Oops! Your Teams space does not comply with corporate standards...",
    [string]$MailBody = "<p>Dear {0}</p><p>We have noticed that your Team <b>{1}</b> does not follow corporate naming convention. Please rename you team.</p><p>If you need assistnace or have any questions, please contact IT department.<p><p>Best Reagrds, IT</p>"
)

if ((Get-Module -ListAvailable -Name PnP.PowerShell) -eq $null) {
    Write-Error "PnP.PowerShell module is required to run this script."
    exit 1;
}

Try {
    if ($Credentials -ne $null){
        Connect-PnPOnline -Url $SiteURL -Credentials $Credentials
    }
    elseif ($WindowsCredentialsStore){
        Connect-PnPOnline -Url $SiteURL -Credentials $WindowsCredentialsStore
    }
    elseif($Thumbprint) {
        Connect-PnPOnline -Url $SiteURL -Thumbprint $Thumbprint -ClientId $ClientId -Tenant $Tenant
    }
    else {
        throw "No authentication method was used."
    }
} Catch {
    Write-Error ("An error occured while trying to connect to SharePoint`n{0}" -f $_.Exception.Message)
    exit 1
}

Get-PnPMicrosoft365Group |? {$_.HasTeam -eq $true } |% { 
    $group = $_;
    if ($group.DisplayName -notmatch $RegexPattern) {
        Get-PnPMicrosoft365GroupOwners -Identity $group.GroupId |% {
            Write-Progress -Activity $group.DisplayName -Status ("Invalid, sending notification to {0} ({1})" -f $_.DisplayName, $_.Email)
            Send-PnPMail -To $_.Email -Subject $MailSubject -Body ($MailBody -f $_.DisplayName, $group.DisplayName)
        }
    } else {
        Write-Progress -Activity $group.DisplayName -Status "OK"
    }
}