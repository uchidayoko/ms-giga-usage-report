<#
    .SYNOPSIS
        SharePointサイトの作成

    .DESCRIPTION
        M365テナントデータを蓄積するためのSharePointサイトの作成
        及び、Entra ID アプリケーションへの権限付与

    .PARAMETER applicationId
        [必須] Entra ID アプリケーションID

    .PARAMETER securityGroupObjectId
        [必須] SharePointサイトに対してアクセス権を付与するためのEntra ID セキュリティグループのObject ID
        
    .PARAMETER sharepointDomain
        [必須] SharePointサイトのドメイン
        ex. SharePonitサイトURLが"https://contoso.sharepoint.com"の時、"contoso.sharepoint.com"
    
    .EXAMPLE
        PS> Create-SharepointSite.ps1 -applicationId "your-application-id" -securityGroupObjectId "your-security-group-object-id" -sharepointDomain "your-sharepoint-domain"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$securityGroupObjectId,

    [Parameter(Mandatory=$true)]
    [String]$sharepointDomain
)

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$spoSiteName = "M365UsageRecords"
$spoSiteUrl = "https://$sharepointDomain/sites/$spoSiteName"
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

# ログフォルダが存在しない場合は作成
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
Write-Log -Message "Start executing Create-SharepointSite.ps1"

try {
    Write-Log -Message "Get information of the currently signed-in user."

    # サインインしているユーザーのメールアドレスを取得
    $userMail = az ad signed-in-user show --query userPrincipalName --output tsv
    if ([string]::IsNullOrEmpty($userMail)) {
        Write-Log -Message "Failed to get signed-in user's email address."
        throw "Failed to get signed-in user information"
    } else {
        Write-Log -Message "Signed-in user email got successfully: $userMail"
    }

    # テナント情報を取得
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
        # SharePointサイトが既に存在するか確認
        Get-SPOSite -Identity $spoSiteUrl -ErrorAction SilentlyContinue
        Write-Log -Message "SharePoint site already exists. No action taken." -Level "Warning"
    }
    catch {
        Write-Log -Message "No existing SharePoint site found. Creating a new site."
        # SharePointサイトを新規作成
        New-SPOSite -Url $spoSiteUrl -Owner $userMail -StorageQuota $spoSiteStorageQuota -Template $spoSiteTemplate -LocaleId $spoSiteLocaleId -Title $spoSiteName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create SharePoint site."
            throw "SharePoint site creation failed."
        } else {
            Write-Log -Message "SharePoint site created successfully."
        }
    }

    Write-Log -Message "Creating LoginName for the security group."
    # セキュリティグループのログイン名を作成
    $securityGroupLoginName = "c:0t.c|tenant|$securityGroupObjectId"

    Write-Log -Message "Adding the security group as a site collection administrator."
    $groupName = "Access Permission Group for M365 Usage Report"

    # グループが存在しない場合は新規作成
    $group = Get-SPOSiteGroup -Site $spoSiteUrl | Where-Object { $_.Title -eq $groupName }

    if ($null -eq $group) {
        New-SPOSiteGroup -Site $spoSiteUrl -Group $groupName -PermissionLevels "Full Control"
    }

    # セキュリティグループをサイトコレクション管理者として追加
    Add-SPOUser -Site $spoSiteUrl -LoginName $securityGroupLoginName -Group $groupName

    Write-Log -Message "Creating a service principal."
    # サービスプリンシパルを作成
    New-MgServicePrincipal -AppId $applicationId -ErrorAction SilentlyContinue

    Write-Log -Message "Getting the service principal."
    # サービスプリンシパルを取得
    $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$applicationId'"

    Write-Log -Message "Service Principal ID: $($servicePrincipal.Id)"

    Write-Log -Message "Getting site information."
    # サイト情報を取得
    $siteInfo = Get-MgSite -SiteId "${sharepointDomain}:/sites/$spoSiteName"
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
    # アプリケーションにサイトへの権限を付与
    New-MgSitePermission -SiteId $siteId -BodyParameter $params

    Write-Log -Message "Writing updated data to outputs.json file."
    # 更新されたデータをoutputs.jsonファイルに書き込む
    $outputs.tenantId = $tenantId
    $outputs.siteUrl = $spoSiteUrl
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
