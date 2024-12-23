<#
    .SYNOPSIS
        deploy2.ps1で構築した環境を削除

    .DESCRIPTION
        GitHubのリポジトリ、Entra ID アプリケーション、Entra ID グループ、SharePointサイトの削除

    .EXAMPLE
        PS> reset.ps1
#>

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$paramsFilePath = ".\params.json"
$outputsFilePath = ".\outputs.json"
$runningScript = ""
$mgGraphConnection = $false
$spoServiceConnection = $false


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

$confirmation = Read-Host "Reset the environment you built? (yes/no)"
if ( $confirmation -ne "yes") {
    exit 0
}

Write-Log -Message "Start executing reset.ps1"

try{
    # params.json を読み込み、オブジェクトに変換
    Write-Log -Message "Loading params.json and converting it to an object."
    $params = Get-Content -Path $paramsFilePath | ConvertFrom-Json

    # outputs.jsonの項目を削除
    Write-Log -Message "Loading outputs.json and converting it to an object."
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json

    Write-Log -Message "Resetting outputs.json"
    $outputs.appId = ""
    $outputs.securityGroupObjectId = ""
    $outputs.tenantId = ""
    $outputs.siteUrl = ""
    $outputs.deployProgress."02" = ""
    $outputs.deployProgress."03" = ""
    $outputs.deployProgress."04" = ""
    $outputs.deployProgress."05" = ""
    $outputs.deployProgress."06" = ""

    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    # Microsoft Graphに接続
    Write-Log -Message "Connecting to Microsoft Graph."
    try {
        Connect-MgGraph -Scopes "Group.ReadWrite.All", "Application.ReadWrite.All"
        if ($? -ne $true) {
            throw "Failed to connect to Microsoft Graph."
        }
        $mgGraphConnection = $true
        Write-Log -Message "Connected to Microsoft Graph successfully."
    } 
    catch {
        throw "Microsoft Graph connection failed. : $_"
    }

    # Entra ID アプリケーションの削除
    $app = Get-MgApplication -Filter "displayName eq 'MsDeviceUsageReport-App'"
    if ($null -ne $app.id){
        Write-Log -Message "Deleting Entra ID Application."
        Remove-MgApplication -ApplicationId $app.id
    }

    # Entra ID グループの削除
    $securityGroups = Get-MgGroup -Filter "DisplayName eq 'M365UsageRecords_site_access_group'"
    if ($null -ne $securityGroups){
        Write-Log -Message "Deleting security group."
        ForEach( $securityGroup in $securityGroups ) {
            Remove-MgGroup -GroupId $securityGroup.id
        }
    }

    # SharePoint Online管理シェルへの接続
    $sharepointDomain = $params.sharepointDomain
    $tenantName = ($sharepointDomain -split "\.")[0]
    $adminUrl = "https://$tenantName-admin.sharepoint.com"

    Write-Log -Message "Connecting to SharePoint Online Management Shell."
    Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
    Connect-SPOService -Url $adminUrl
    if ($? -ne $true) {
        Write-Log -Message "Failed to connect to SharePoint Online Management Shell."
        throw "SharePoint Online Management Shell connection failed."
    } else {
        $spoServiceConnection = $true
        Write-Log -Message "Connected to SharePoint Online Management Shell successfully."
    }

    # SharePointサイトの削除
    $spoSiteUrl = "https://$sharepointDomain/sites/M365UsageRecords"

    try {
        Get-SPOSite -Identity $spoSiteUrl -ErrorAction SilentlyContinue
        Write-Log -Message "Deleting SharePoint site."
        Remove-SPOSite -Identity $spoSiteUrl
        Remove-SPODeletedSite -Identity $spoSiteUrl
    }
    catch {
        Write-Log -Message "No existing SharePoint site found."
    }

    Write-Log -Message  "Reset is complete."
}
catch{
    # エラーが発生した場合
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry reset.bat." -Level "Error"
}
finally {
    # Microsoft Graphへの接続を切断
    if ($mgGraphConnection) {
        Write-Log -Message "Disconnect from Microsoft Graph."
        Disconnect-MgGraph
    }
    
    # SharePoint Online 管理シェルへの接続を切断
    if ($spoServiceConnection) {
        Write-Log -Message "Disconnect from SPO Service."
        Disconnect-SPOService
    }

    Write-Log -Message "---------------------------------------------"
}
