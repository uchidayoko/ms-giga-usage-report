<#
    .SYNOPSIS
        マスタリポジトリの内容を作業者のGitHub上の構築先リポジトリにコピー

    .DESCRIPTION
        マスタリポジトリ内のフォルダの内容を作業者のGitHub上の構築先リポジトリにコピー

    .PARAMETER githubOrganizationName
        [必須] 作業者のGitHub上の構築先組織名

    .PARAMETER githubRepositoryName
        [必須] 作業者のGitHub上の構築先プライベートリポジトリ名

    .PARAMETER githubAccountName
        [必須] 作業者のGitHubアカウント名

    .PARAMETER githubAccountMail
        [必須] 作業者のGitHubへの登録メールアドレス

    .EXAMPLE
        PS> Github-Copy.ps1 -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name" -githubAccountName "your-github-account-name"  -githubAccountMail "your-github-account-email"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$githubOrganizationName,

    [Parameter(Mandatory=$true)]
    [String]$githubRepositoryName,

    [Parameter(Mandatory=$true)]
    [String]$githubAccountName,

    [Parameter(Mandatory=$true)]
    [String]$githubAccountMail
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
Write-Log -Message "Start executing Copy-Github.ps1"

try{
    # 現在のパスを取得
    $returnPath = Get-Location

    # ローカルにコピーしたマスタリポジトリ内のすべてのフォルダへのパスを取得
    Set-Location ../..
    $sourcePath = Resolve-Path -Path "./*"
    Set-Location ..

    # 作業者のGitHub上の構築先プライベートリポジトリをクローン
    Write-Host "Cloning the target GitHub private repository."
    git clone https://github.com/$githubOrganizationName/$githubRepositoryName.git
    Set-Location $githubRepositoryName
    
    # マスタリポジトリの全てのフォルダをローカルのブランチにコピー
    Write-Host "Creating a new branch 'copy-dir' and copying all folders from the master repository."

    # ブランチの存在確認
    $branchName = "copy-dir"
    $branchExists = git branch --list $branchName
    if (-not $branchExists) {
        # ブランチが存在しない場合、新しいブランチを作成してチェックアウト
        git checkout -b $branchName
        Write-Output "Created and switched to branch '$branchName'"

    } else {
        # ブランチが既に存在する場合、そのブランチにチェックアウト
        git checkout $branchName
        Write-Output "Switched to existing branch '$branchName'"
    }

    # コピー先のパスを取得
    $destinationPath = (Get-Location).Path
    Write-Host "Copying from '$sourcePath' to '$destinationPath'"

    # ローカルにコピーしたマスタリポジトリ内のすべてのファイルをコピー
    Copy-Item -Path $sourcePath.Path -Destination $destinationPath -Recurse -Force

    # コピー後の確認
    ## コピーしたフォルダ名の取得
    $sourceFolders = Get-Item $sourcePath | Select-Object Name
    ForEach( $folder in $sourceFolders ) {
        $folderName = $folder.Name
        if ( !(Test-Path -Path "$destinationPath\$folderName") ) {
            Write-Error "Failed to copy '$folderName' folder to '$destinationPath'. : $_"
            exit 1
        } else {
            Write-Host "'$folderName' folder copied successfully to '$destinationPath'."           
        }
    }
    git add .
    git config --global user.name $githubAccountName
    git config --global user.email $githubAccountMail
    git commit -m "Copy folders to private repo"
    
    # 作業者のGitHub上の構築先プライベートリポジトリにプッシュする
    Write-Host "Pushing changes to the remote repository."
    git push origin copy-dir:main

    Set-Location $returnPath
    
    # データを変更
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."02" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Copy-Github.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    $outputs.deployProgress."02" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}