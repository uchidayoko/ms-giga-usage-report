<#
    .SYNOPSIS
        SharePointサイトに対してアクセス権を付与するためのEntra ID セキュリティグループの作成

    .DESCRIPTION
        SharePointサイトに対してアクセス権を付与するためのEntra ID セキュリティグループの作成

    .EXAMPLE
        PS> Create-EntraIdGroup.ps1
#>

# 変数定義
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$GroupName = "M365UsageRecords_site_access_group"
$NewGroupParams = @{
    DisplayName     = $GroupName
    MailEnabled     = $false
    MailNickname    = $GroupName
    SecurityEnabled = $true
    GroupTypes      = @()
}


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
Write-Log -Message "Start executing Create-EntraIdGroup.ps1"

try{
    Write-Log -Message "Getting information of the currently signed-in user."
    $currentUserId = az ad signed-in-user show --query id --output tsv
    
    # セキュリティグループの作成
    try {
        Write-Log -Message "Creating security group: $GroupName"
        $SecurityGroup = New-MgGroup -BodyParameter $NewGroupParams
        if (-not $SecurityGroup) {
            throw "Security group '$GroupNamecreation' returned null"
        }
        Write-Log -Message "Security group created successfully."
    } 
    catch {
        throw "Error: $_"
    }

    # SecurityGroupIdの確認
    $SecurityGroupId = $SecurityGroup.Id

    if ([string]::IsNullOrEmpty($SecurityGroupId)) {
        Write-Log -Message "Failed to get the security group ID."
        throw "Failed to get Security group ID"
    } else {
        Write-Log -Message "Security group ID got successfully: $SecurityGroupId"
    }

    # ユーザーをグループに追加
    try {
        New-MgGroupMember -GroupId $SecurityGroupId -DirectoryObjectId $currentUserId
        Write-Log -Message "Added the current user to the security group."
    } catch {
        throw "Failed to add user to the security group. : $_"
    }

    # ユーザーが追加されたかの確認
    $groupMembers = Get-MgGroupMember -GroupId $SecurityGroupId | Where-Object { $_.Id -eq $currentUserId }

    if ($groupMembers) {
        Write-Log -Message "User with ID '$currentUserId' successfully added to the group '$GroupName'."
    } else {
        throw "Failed to verify that the user was added to the group"
    }

    # データを変更
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.securityGroupObjectId = $SecurityGroupId
    $outputs.deployProgress."04" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-EntraIdGroup.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # エラーが発生した場合
    $outputs.deployProgress."04" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    throw
}