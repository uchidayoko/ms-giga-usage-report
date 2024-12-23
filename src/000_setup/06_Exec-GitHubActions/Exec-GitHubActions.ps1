<#
    .SYNOPSIS
        GitHubシークレットの設定とワークフローの実行 

    .DESCRIPTION
        GitHubシークレットを設定したのちに、GitHubActionsのワークフローを実行

    .PARAMETER tenantId
        [必須] AzureテナントのテナントID

    .PARAMETER tenantName
        [必須] テナント名（ドメインの一部）
        ex. ドメイン名が"contoso.onmicrosoft.com"の場合、"contoso"とする。

    .PARAMETER applicationId
        [必須] Entra ID アプリケーションID

    .PARAMETER githubOrganizationName
        [必須] 作業者のGitHub上の構築先組織名

    .PARAMETER githubRepositoryName
        [必須] 作業者のGitHub上の構築先プライベートリポジトリ名

    .EXAMPLE
        PS> Exec-GitHubActions.ps1 -tenantId "your-tenant-id" -tenantName "your-tenant-name" -applicationId "your-application-id" -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$tenantId,

    [Parameter(Mandatory=$true)]
    [String]$tenantName,

    [Parameter(Mandatory=$true)]
    [String]$applicationId,

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
Write-Log -Message "Start executing Exec-GitHubActions.ps1"

try{
    Write-Log -Message "Start adding GitHub Secret and executing GitHubActions.."

    # GitHubシークレットの追加
    Write-Log -Message "Adding GitHub Sercret."
    gh secret set AZURE_TENANT_ID --body $tenantId --repo $githubOrganizationName/$githubRepositoryName
    gh secret set AZURE_TENANT_NAME --body $tenantName --repo $githubOrganizationName/$githubRepositoryName
    gh secret set AZURE_CLIENT_ID --body $applicationId --repo $githubOrganizationName/$githubRepositoryName

    # ワークフローの実行
    Write-Log -Message "Executing GitHub Actions workflows."
    gh workflow run daily_workflow.yml --repo $githubOrganizationName/$githubRepositoryName
    gh workflow run manual_workflow.yml --repo $githubOrganizationName/$githubRepositoryName -f date_range=27

    # データを変更
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."06" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
 
    Write-Log "Execution of Exec-GitHubActions.ps1 is complete."
    Write-Log "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    $outputs.deployProgress."06" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
