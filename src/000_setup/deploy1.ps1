<#
    .SYNOPSIS
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築: 1

    .DESCRIPTION
        1: 必要なモジュールのインストール

    .EXAMPLE
        PS> deploy1.ps1
#>

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputsFilePath = ".\outputs.json"
$runningScript = ""


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
Write-Log -Message "Start executing deploy1.ps1"

try{
    # JSONファイルを読み込み、オブジェクトに変換
    Write-Log -Message "Loading outputs.json and converting it to an object."
    
    # outputsの読み込み
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    # モジュールのインストール
    $runningScript = "01_Install-Module\Install-Module.ps1"
    if($outputs.deployProgress."01" -ne "completed") {
        Write-Log -Message "Starting module installation."
        .\01_Install-Module\Install-Module.ps1
    }
    Write-Log -Message "deploy1.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry exec.bat." -Level "Error"
    Write-Log -Message "---------------------------------------------"
}