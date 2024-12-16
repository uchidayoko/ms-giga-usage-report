<#
    .SYNOPSIS
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築: 2

    .DESCRIPTION
        「params.json」の値に従って環境構築を行うため、事前に設定しておく

    .EXAMPLE
        PS> deploy2.ps1
#>

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$paramsFilePath = ".\params.json"
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
Write-Log -Message "Start executing deploy2.ps1"

try{
    # outputsの読み込み
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    # params.json を読み込み、オブジェクトに変換
    Write-Log -Message "Loading params.json and converting it to an object."
    $params = Get-Content -Path $paramsFilePath | ConvertFrom-Json
    $tenantName = $params.tenantName
    $adminUrl = "https://$tenantName-admin.sharepoint.com"

    # GitHubアカウントにログイン
    Write-Log -Message "Logging into GitHub account."
    Write-Host "Please follow the instructions to log in."
    gh auth login --web --git-protocol https

    # ログインに成功したかを判定
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "GitHub CLI login failed with exit code $exitCode"
    }
    else {
        Write-Log -Message "GitHub CLI login succeeded."
    }

    # Azure CLIにログイン
    if($outputs.deployProgress."03" -ne "completed" -or $outputs.deployProgress."04" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Logging into Azure CLI."
        az login --allow-no-subscriptions

        # ログインに成功したかを判定
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Azure CLI login failed with exit code $exitCode"
        } else {
            Write-Log -Message "Azure CLI login succeeded."
        }
    }

    # Azureアカウントにログイン
    if($outputs.deployProgress."03" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Logging into Azure account."
        try {
            Connect-AzAccount
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to connect to Azure account."
            }
            Write-Log -Message "Connected to Azure account successfully."
        } 
        catch {
            throw "Azure account connection failed. : $_"
        }
    }

    # Microsoft Graphに接続
    if($outputs.deployProgress."04" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Connecting to Microsoft Graph."
        try {
            Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read", "Application.ReadWrite.All", "Sites.Read.All", "Sites.FullControl.All"
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to connect to Microsoft Graph."
            }
            Write-Log -Message "Connected to Microsoft Graph successfully."
        } 
        catch {
            throw "Microsoft Graph connection failed. : $_"
        }
    }
    
    # SharePoint Online管理シェルへの接続
    if($outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Connecting to SharePoint Online Management Shell."
        Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
        Connect-SPOService -Url $adminUrl
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to connect to SharePoint Online Management Shell."
            throw "SharePoint Online Management Shell connection failed."
        } else {
            Write-Log -Message "Connected to SharePoint Online Management Shell successfully."
        }
    }

    # GitHubプライベートリポジトリへファイルをコピー
    $runningScript = "02_Copy-GitHub\Copy-GitHub.ps1"
    if($outputs.deployProgress."02" -ne "completed") {
        Write-Log -Message "Forking GitHub repository."
        .\02_Copy-GitHub\Copy-GitHub.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName -githubAccountName $params.githubAccountName -githubAccountMail $params.githubAccountMail
    }

    # Entra ID アプリケーション作成
    $runningScript = "03_Create-EntraIDApplication\Create-EntraIdApplication.ps1"
    if($outputs.deployProgress."03" -ne "completed") {
        Write-Log -Message "Creating Entra ID application."
        .\03_Create-EntraIDApplication\Create-EntraIdApplication.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }
    
    # Entra ID グループ作成
    $runningScript = "04_Create-EntraIDGroup\Create-EntraIdGroup.ps1"
    if($outputs.deployProgress."04" -ne "completed") {
        Write-Log -Message "Creating Entra ID group."
        .\04_Create-EntraIDGroup\Create-EntraIdGroup.ps1
    }
    
    # outputsの再読み込み
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    
    # SharePointサイト作成
    $runningScript = "05_Create-SharePointSite\Create-SharepointSite.ps1"
    if($outputs.deployProgress."02" -eq "completed" -and $outputs.deployProgress."03" -eq "completed" -and $outputs.deployProgress."04" -eq "completed" -and $outputs.deployProgress."05" -ne "completed") {
        Write-Log -Message "Creating SharePoint site."
        .\05_Create-SharePointSite\Create-SharepointSite.ps1 -applicationId $outputs.appId -securityGroupObjectId $outputs.securityGroupObjectId -tenantName $params.tenantName
    }

    # outputsの再読み込み
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json

    # シークレットの作成とワークフローの実行
    $runningScript = "06_Exec-GitHubActions\Exec-GitHubActions.ps1"
    if($outputs.deployProgress."05" -eq "completed") {
        Write-Log -Message "Adding GitHub secret and executing GitHub Actions workflows."
        .\06_Exec-GitHubActions\Exec-GitHubActions.ps1 -tenantId $outputs.tenantId -tenantName $params.tenantName -applicationId $outputs.appId -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }

    Write-Log -Message "Deployment is complete."
}
catch{
    # エラーが発生した場合
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry exec.bat." -Level "Error"
}
finally {
    # GitHubアカウントからログアウト
    Write-Log -Message "Logging out from GitHub."
    gh auth logout

    # Azure CLIからログアウト
    Write-Log -Message "Logging out from Azure CLI."
    az logout

    # Azureアカウントへの接続を切断
    Write-Log -Message "Disconnect from Azure account."
    Disconnect-AzAccount

    # Microsoft Graphへの接続を切断
    Write-Log -Message "Disconnect from Microsoft Graph."
    Disconnect-MgGraph
    
    # SharePoint Online 管理シェルへの接続を切断
    Write-Log -Message "Disconnect from SPO Service."
    Disconnect-SPOService

    Write-Log -Message "---------------------------------------------"
}
