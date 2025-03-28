<#
    .SYNOPSIS
        New-MgSitePermissionを別ウィンドウで再実行するスクリプト

    .DESCRIPTION
        ※本スクリプトはCreate-SharepointSite.ps1から呼び出される
        Create-SharepointSite.ps1でNew-MgSitePermissionが失敗した場合に、
        別ウィンドウでNew-MgSitePermissionを再実行するスクリプト
        
        (背景)
        以下のモジュールのバージョンが2.24.0時点ではCreate-SharepointSite.ps1が正常に動作していたが、
        バージョンが更新されたことにより、New-MgSitePermissionが正常に動作しなくなった。
        ・Microsoft.Graph.Sites
        ・Microsoft.Graph.Authentication
        ・Microsoft.Graph
        
        (対応)
        New-MgSitePermissionが実行される前に、同一ウィンドウ内でGet-SPOSiteを実行した際にエラーが発生している状態であるため、
        別ウィンドウでNew-MgSitePermissionを再実行することで本事象を回避する。

    .PARAMETER siteId
        [必須] SharePoint Online サイトID
    
    .PARAMETER applicationId
        [必須] Entra ID アプリケーションのクライアントID

    .PARAMETER displayName
        [必須] Entra ID アプリケーション名
    
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$siteId,

    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$displayName
)

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json

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

Write-Log -Message "Start executing Retry-NewMgSitePermission.ps1"

try {
    Start-Sleep -Seconds 1
    # Microsoft Graphに接続
    Write-Log -Message "Connecting to Microsoft Graph."   
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read", "Application.ReadWrite.All", "Sites.Read.All", "Sites.FullControl.All"
    # 接続に成功したかを判定
    if ($? -ne $true) {
        throw "Failed to connect to Microsoft Graph"
    }
    Write-Log -Message "Connected to Microsoft Graph successfully."
    
    $params = @{
        roles = @("write") 
        grantedToIdentities = @(
            @{
                application = @{
                    id = $applicationId
                    displayName = $displayName
                }
            }
        )
    }

    Write-Log -Message "Granting the application permissions to the site."
    New-MgSitePermission -SiteId $siteId -BodyParameter $params -ErrorAction Stop

    Write-Log -Message "Writing updated data to outputs.json file."
    # 更新されたデータをoutputs.jsonファイルに書き込む
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 & Retry-NewMgSitePermission.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
    Start-Sleep -Seconds 3
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    throw
}
