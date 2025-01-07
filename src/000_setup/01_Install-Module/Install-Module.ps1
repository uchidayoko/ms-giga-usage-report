<#
    .SYNOPSIS
        必要なモジュールのインストールを行う

    .DESCRIPTION
        利用するモジュールと用途は以下の通り
        ・SharePoint Online管理シェル
            用途：SharePointサイト作成など
        ・Microsoft Graph
            用途：テナント情報取得、Entra IDグループの作成など
        ・Az
            用途：Entra IDアプリケーション作成、権限付与など
        ・Microsoft.Graph.Sites
            用途：Entra IDアプリケーションに対してSharePoint Onlineサイトへの権限付与など

    .EXAMPLE
        PS> Install-Module.ps1
#>

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = $logFolder + "\" + "${date}_log.txt"
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
    # ログファイルに出力
    $logMessage | Out-File -FilePath $logFile -Append
}

# logフォルダが存在しない場合は作成
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
Write-Log -Message "Start executing Install-Module.ps1"

try{
    # 必要なモジュールのインストールを開始します
    Write-Log -Message "Starting the installation of required modules..."
    
    # インストールするモジュールを列挙
    $RequiredModules = 'Microsoft.Online.SharePoint.PowerShell', 'Az', 'Microsoft.Graph', 'Microsoft.Graph.Sites'
    # 既にインストールされているか判定し、インストールされていない場合はインストールを行う
    ForEach( $Module in $RequiredModules ) {
        If ( !(Get-InstalledModule -Name $Module) ) {
            Write-Log -Message "Installing $Module..."
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
            Write-Log -Message "$Module installation completed."
        }
    }

    # データを変更
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."01" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Install-Module.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    $outputs.deployProgress."01" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    throw
}