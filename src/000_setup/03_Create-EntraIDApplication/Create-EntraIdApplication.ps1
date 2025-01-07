<#
    .SYNOPSIS
        作業者のGitHub上の構築先リポジトリに対してアクセス権を付与するためのEntra ID アプリケーション作成

    .DESCRIPTION
        作業者のGitHub上の構築先リポジトリに対してアクセス権を付与するためのEntra ID アプリケーション作成

    .PARAMETER githubOrganizationName
        [必須] 作業者のGitHub上の構築先組織名

    .PARAMETER githubRepositoryName
        [必須] 作業者のGitHub上の構築先プライベートリポジトリ名

    .EXAMPLE
        PS> Create-EntraIdApplication.ps1 -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$githubOrganizationName,

    [Parameter(Mandatory=$true)]
    [String]$githubRepositoryName
)

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$appDisplayName = "MsDeviceUsageReport-App"


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
    # ログファイルに出力
    $logMessage | Out-File -FilePath $logFile -Append
}


# logフォルダが存在しない場合は作成
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
Write-Log -Message "Start executing Create-EntraIdApplication.ps1"

try{
    # アプリケーションの作成
    Write-Log -Message "Start creating Entra ID Application."
    ## 同名のアプリが存在するか確認
    $appExists = az ad app list --filter "displayName eq '$appDisplayName'" | ConvertFrom-Json
    if ($appExists.Count -eq 0) {
        Write-Log -Message "No existing Entra ID Application found with the name '$appDisplayName'. Continue creating Entra ID Application."
        az ad app create --display-name $appDisplayName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create the Entra ID Application."
            throw "Entra ID Application creation failed"
        } else {
            Write-Log -Message "Entra ID Application created successfully."
        }
    } else {
        Write-Log -Message "Entra ID Application with the name '$appDisplayName' already exists. Skipping creation step." -Level "Warning"
    }

    # アプリケーションID (appId) を取得
    Write-Log -Message "Getting the Entra ID Application ID."
    $appId = $(az ad app list --display-name $appDisplayName --query "[].appId" -o tsv)
    $appObjectId = $(az ad app list --display-name $appDisplayName --query "[].id" -o tsv)

    # アプリケーションIDが取得できていない場合はエラーとする
    if ([string]::IsNullOrEmpty($appId) -or [string]::IsNullOrEmpty($appObjectId)) {
        throw "Failed to get Entra ID Application ID or Object ID for '$appDisplayName'"
    } else {
        Write-Log -Message "Entra ID Application ID got successfully: $appId"
        Write-Log -Message "Entra ID Application Object ID got successfully: $appObjectId"
    }

    # Microsoft Graph APIのアクセス許可の追加
    Write-Log -Message "Adding Microsoft Graph API permissions."
    ## GraphAPI
    Write-Log -Message "Adding permissions for GraphAPI."
    ### Directory.Read.All
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role
    ### Reports.Read.All
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 230c1aed-a721-4c5d-9cb4-a90514e508ef=Role
    ### ReportSettings.Read.All
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions ee353f83-55ef-4b78-82da-555bfa2b4b95=Role
    ### User.Read.All
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions df021288-bdef-4463-88db-98f22de89214=Role
    ## SharePoint
    Write-Log -Message "Adding permissions for SharePoint."
    ### Sites.Selected
    az ad app permission add --id $appId --api 00000003-0000-0ff1-ce00-000000000000 --api-permissions 20d37865-089c-4dee-8c41-6967602d4ac8=Role

    # APIアクセス許可について、管理者の同意を与える
    Write-Log -Message "Granting admin consent for API permissions."
    az ad app permission admin-consent --id $appId
    Start-Sleep -Seconds 5
    az ad app permission admin-consent --id $appId
    if ($? -ne $true) {
        throw "Failed to grant admin consent for API permissions"
    }

    # フェデレーション認証の設定
    Write-Log -Message "Setting up federated authentication."
    New-AzADAppFederatedCredential -ApplicationObjectId $appObjectId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name 'GitHub-Actions-Credential' -Subject "repo:$githubOrganizationName/${githubRepositoryName}:ref:refs/heads/main"

    $federatedCredential = Get-AzADAppFederatedCredential -ApplicationObjectId $appObjectId

    if ($federatedCredential) {
        Write-Log -Message "Federated authentication setup was successful."
    } else {
        throw "Failed to set up federated authentication"
    }

    # データを変更
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.appId = $appId
    $outputs.deployProgress."03" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-EntraIdApplication.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    $outputs.deployProgress."03" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    throw
}
