<#
    .SYNOPSIS
        GitHub Actions��p����M365�e�i���g�f�[�^�擾�̂��߂̊��\�z: 2

    .DESCRIPTION
        �uparams.json�v�̒l�ɏ]���Ċ��\�z���s�����߁A���O�ɐݒ肵�Ă���

    .EXAMPLE
        PS> deploy2.ps1
#>

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$paramsFilePath = ".\params.json"
$outputsFilePath = ".\outputs.json"
$runningScript = ""


# �֐���`
## ���O�o�͊֐�
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
    # ���O�t�@�C���ɏo��
    $logMessage | Out-File -FilePath $logFile -Append
}

# log�t�H���_�����݂��Ȃ��ꍇ�͍쐬
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
Write-Log -Message "Start executing deploy2.ps1"

try{
    # outputs�̓ǂݍ���
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    # params.json ��ǂݍ��݁A�I�u�W�F�N�g�ɕϊ�
    Write-Log -Message "Loading params.json and converting it to an object."
    $params = Get-Content -Path $paramsFilePath | ConvertFrom-Json
    $tenantName = $params.tenantName
    $adminUrl = "https://$tenantName-admin.sharepoint.com"

    # GitHub�A�J�E���g�Ƀ��O�C��
    Write-Log -Message "Logging into GitHub account."
    Write-Host "Please follow the instructions to log in."
    gh auth login --web --git-protocol https

    # ���O�C���ɐ����������𔻒�
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "GitHub CLI login failed with exit code $exitCode"
    }
    else {
        Write-Log -Message "GitHub CLI login succeeded."
    }

    # Azure CLI�Ƀ��O�C��
    if($outputs.deployProgress."03" -ne "completed" -or $outputs.deployProgress."04" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Logging into Azure CLI."
        az login --allow-no-subscriptions

        # ���O�C���ɐ����������𔻒�
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Azure CLI login failed with exit code $exitCode"
        } else {
            Write-Log -Message "Azure CLI login succeeded."
        }
    }

    # Azure�A�J�E���g�Ƀ��O�C��
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

    # Microsoft Graph�ɐڑ�
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
    
    # SharePoint Online�Ǘ��V�F���ւ̐ڑ�
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

    # GitHub�v���C�x�[�g���|�W�g���փt�@�C�����R�s�[
    $runningScript = "02_Copy-GitHub\Copy-GitHub.ps1"
    if($outputs.deployProgress."02" -ne "completed") {
        Write-Log -Message "Forking GitHub repository."
        .\02_Copy-GitHub\Copy-GitHub.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName -githubAccountName $params.githubAccountName -githubAccountMail $params.githubAccountMail
    }

    # Entra ID �A�v���P�[�V�����쐬
    $runningScript = "03_Create-EntraIDApplication\Create-EntraIdApplication.ps1"
    if($outputs.deployProgress."03" -ne "completed") {
        Write-Log -Message "Creating Entra ID application."
        .\03_Create-EntraIDApplication\Create-EntraIdApplication.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }
    
    # Entra ID �O���[�v�쐬
    $runningScript = "04_Create-EntraIDGroup\Create-EntraIdGroup.ps1"
    if($outputs.deployProgress."04" -ne "completed") {
        Write-Log -Message "Creating Entra ID group."
        .\04_Create-EntraIDGroup\Create-EntraIdGroup.ps1
    }
    
    # outputs�̍ēǂݍ���
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    
    # SharePoint�T�C�g�쐬
    $runningScript = "05_Create-SharePointSite\Create-SharepointSite.ps1"
    if($outputs.deployProgress."02" -eq "completed" -and $outputs.deployProgress."03" -eq "completed" -and $outputs.deployProgress."04" -eq "completed" -and $outputs.deployProgress."05" -ne "completed") {
        Write-Log -Message "Creating SharePoint site."
        .\05_Create-SharePointSite\Create-SharepointSite.ps1 -applicationId $outputs.appId -securityGroupObjectId $outputs.securityGroupObjectId -tenantName $params.tenantName
    }

    # outputs�̍ēǂݍ���
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json

    # �V�[�N���b�g�̍쐬�ƃ��[�N�t���[�̎��s
    $runningScript = "06_Exec-GitHubActions\Exec-GitHubActions.ps1"
    if($outputs.deployProgress."05" -eq "completed") {
        Write-Log -Message "Adding GitHub secret and executing GitHub Actions workflows."
        .\06_Exec-GitHubActions\Exec-GitHubActions.ps1 -tenantId $outputs.tenantId -tenantName $params.tenantName -applicationId $outputs.appId -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }

    Write-Log -Message "Deployment is complete."
}
catch{
    # �G���[�����������ꍇ
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry exec.bat." -Level "Error"
}
finally {
    # GitHub�A�J�E���g���烍�O�A�E�g
    Write-Log -Message "Logging out from GitHub."
    gh auth logout

    # Azure CLI���烍�O�A�E�g
    Write-Log -Message "Logging out from Azure CLI."
    az logout

    # Azure�A�J�E���g�ւ̐ڑ���ؒf
    Write-Log -Message "Disconnect from Azure account."
    Disconnect-AzAccount

    # Microsoft Graph�ւ̐ڑ���ؒf
    Write-Log -Message "Disconnect from Microsoft Graph."
    Disconnect-MgGraph
    
    # SharePoint Online �Ǘ��V�F���ւ̐ڑ���ؒf
    Write-Log -Message "Disconnect from SPO Service."
    Disconnect-SPOService

    Write-Log -Message "---------------------------------------------"
}
