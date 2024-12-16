<#
    .SYNOPSIS
        SharePoint繧ｵ繧､繝医�菴懈�

    .DESCRIPTION
        M365繝�リ繝ｳ繝医ョ繝ｼ繧ｿ繧定塘遨阪☆繧九◆繧√�SharePoint繧ｵ繧､繝医�菴懈�
        蜿翫�縲・ntra ID 繧｢繝励Μ繧ｱ繝ｼ繧ｷ繝ｧ繝ｳ縺ｸ縺ｮ讓ｩ髯蝉ｻ倅ｸ

    .PARAMETER applicationId
        [蠢�� Entra ID 繧｢繝励Μ繧ｱ繝ｼ繧ｷ繝ｧ繝ｳID

    .PARAMETER securityGroupObjectId
        [蠢�� SharePoint繧ｵ繧､繝医↓蟇ｾ縺励※繧｢繧ｯ繧ｻ繧ｹ讓ｩ繧剃ｻ倅ｸ弱☆繧九◆繧√�Entra ID 繧ｻ繧ｭ繝･繝ｪ繝�ぅ繧ｰ繝ｫ繝ｼ繝励�Object ID

    .PARAMETER tenantName
        [必須] テナント名（ドメインの一部）
        ex. ドメイン名が"example.onmicrosoft.com"の場合、"example"とする。

    .EXAMPLE
        PS> Create-SharepointSite.ps1 -applicationId "your-application-id" -securityGroupObjectId "your-security-group-object-id" -tenantName "your-tenant-name"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$securityGroupObjectId,

    [Parameter(Mandatory=$true)]
    [String]$tenantName
)

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$spoSiteName = "M365UsageRecords"
$spoSiteUrl = "https://$tenantName.sharepoint.com/sites/$spoSiteName"
$spoSiteTemplate = "STS#3"
$spoSiteLocaleId = 1041
$spoSiteStorageQuota = 1024


# 関数定義
## ログ出力関数
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
        
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    switch ($Level) {
        "Info" {
            Write-Host "[INFO] $Message" -ForegroundColor White
            $logMessage = "$timestamp - [INFO] $Message"
        }
        "Warning" {
            Write-Host "[WARNING] $Message" -ForegroundColor Yellow
            $logMessage = "$timestamp - [WARNING] $Message"
        }
        "Error" {
            Write-Host "[ERROR] $Message" -ForegroundColor Red
            $logMessage = "$timestamp - [ERROR] $Message"
        }
    }
    $logMessage | Out-File -FilePath $logFile -Append
}


if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
Write-Log -Message "Start executing Create-SharepointSite.ps1"

try {
    Write-Log -Message "Get information of the currently signed-in user."

    $userMail = az ad signed-in-user show --query userPrincipalName --output tsv
    if ([string]::IsNullOrEmpty($userMail)) {
        Write-Log -Message "Failed to get signed-in user's email address."
        throw "Failed to get signed-in user information"
    } else {
        Write-Log -Message "Signed-in user email got successfully: $userMail"
    }

    $tenantInfo = Get-AzTenant
    if (-not $tenantInfo) {
        Write-Log -Message "Failed to get tenant information."
        throw "Failed to get Tenant information"
    } else {
        Write-Log -Message "Tenant information got successfully."
    }

    Write-Log -Message "Get tenant information."
    $tenantId = $tenantInfo.Id

    Write-Log -Message "Checking if the SharePoint site already exists."
    try {
        Get-SPOSite -Identity $spoSiteUrl -ErrorAction SilentlyContinue
        Write-Log -Message "SharePoint site already exists. No action taken." -Level "Warning"
    }
    catch {
        Write-Log -Message "No existing SharePoint site found. Creating a new site."
        New-SPOSite -Url $spoSiteUrl -Owner $userMail -StorageQuota $spoSiteStorageQuota -Template $spoSiteTemplate -LocaleId $spoSiteLocaleId -Title $spoSiteName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create SharePoint site."
            throw "SharePoint site creation failed."
        } else {
            Write-Log -Message "SharePoint site created successfully."
        }
    }

    Write-Log -Message "Creating LoginName for the security group."
    $securityGroupLoginName = "c:0t.c|tenant|$securityGroupObjectId"

    Write-Log -Message "Adding the security group as a site collection administrator."
    $groupName = "Access Permission Group for M365 Usage Report"

    $group = Get-SPOSiteGroup -Site $spoSiteUrl | Where-Object { $_.Title -eq $groupName }

    if ($null -eq $group) {
        New-SPOSiteGroup -Site $spoSiteUrl -Group $groupName -PermissionLevels "Full Control"
    }

    Add-SPOUser -Site $spoSiteUrl -LoginName $securityGroupLoginName -Group $groupName

    Write-Log -Message "Creating a service principal."
    New-MgServicePrincipal -AppId $applicationId -ErrorAction SilentlyContinue

    Write-Log -Message "Getting the service principal."
    $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$applicationId'"

    Write-Log -Message "Service Principal ID: $($servicePrincipal.Id)"

    Write-Log -Message "Getting site information."
    $siteInfo = Get-MgSite -SiteId "$tenantName.sharepoint.com:/sites/$spoSiteName"
    if (-not $siteInfo) {
        Write-Log -Message "Failed to get site information for '$spoSiteName'."
        throw "Failed to get site information."
    } else {
        Write-Log -Message "Site information got successfully for '$spoSiteName'."
    }
    $siteId = $siteInfo.Id

    Write-Log -Message "Site ID: $siteId"

    $params = @{
        roles = @("write")
        grantedToIdentities = @(
            @{
                application = @{
                    id = $applicationId
                    displayName = $servicePrincipal.DisplayName
                }
            }
        )
    }

    Write-Log -Message "Granting the application permissions to the site."
    New-MgSitePermission -SiteId $siteId -BodyParameter $params

    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.tenantId = $tenantId
    $outputs.siteUrl = $spoSiteUrl
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 is complete."
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
}
finally{
    Write-Log -Message "Logging out from SharePoint Online Management Shell."
    Disconnect-SPOService

    Write-Log -Message "---------------------------------------------"
}
