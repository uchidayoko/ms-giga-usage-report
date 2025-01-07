<#
    .SYNOPSIS
        ��Ǝ҂�GitHub��̍\�z�惊�|�W�g���ɑ΂��ăA�N�Z�X����t�^���邽�߂�Entra ID �A�v���P�[�V�����쐬

    .DESCRIPTION
        ��Ǝ҂�GitHub��̍\�z�惊�|�W�g���ɑ΂��ăA�N�Z�X����t�^���邽�߂�Entra ID �A�v���P�[�V�����쐬

    .PARAMETER githubOrganizationName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��g�D��

    .PARAMETER githubRepositoryName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��v���C�x�[�g���|�W�g����

    .EXAMPLE
        PS> Create-EntraIdApplication.ps1 -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$githubOrganizationName,

    [Parameter(Mandatory=$true)]
    [String]$githubRepositoryName
)

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$appDisplayName = "MsDeviceUsageReport-App"


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
Write-Log -Message "Start executing Create-EntraIdApplication.ps1"

try{
    # �A�v���P�[�V�����̍쐬
    Write-Log -Message "Start creating Entra ID Application."
    ## �����̃A�v�������݂��邩�m�F
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

    # �A�v���P�[�V����ID (appId) ���擾
    Write-Log -Message "Getting the Entra ID Application ID."
    $appId = $(az ad app list --display-name $appDisplayName --query "[].appId" -o tsv)
    $appObjectId = $(az ad app list --display-name $appDisplayName --query "[].id" -o tsv)

    # �A�v���P�[�V����ID���擾�ł��Ă��Ȃ��ꍇ�̓G���[�Ƃ���
    if ([string]::IsNullOrEmpty($appId) -or [string]::IsNullOrEmpty($appObjectId)) {
        throw "Failed to get Entra ID Application ID or Object ID for '$appDisplayName'"
    } else {
        Write-Log -Message "Entra ID Application ID got successfully: $appId"
        Write-Log -Message "Entra ID Application Object ID got successfully: $appObjectId"
    }

    # Microsoft Graph API�̃A�N�Z�X���̒ǉ�
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

    # API�A�N�Z�X���ɂ��āA�Ǘ��҂̓��ӂ�^����
    Write-Log -Message "Granting admin consent for API permissions."
    az ad app permission admin-consent --id $appId
    Start-Sleep -Seconds 5
    az ad app permission admin-consent --id $appId
    if ($? -ne $true) {
        throw "Failed to grant admin consent for API permissions"
    }

    # �t�F�f���[�V�����F�؂̐ݒ�
    Write-Log -Message "Setting up federated authentication."
    New-AzADAppFederatedCredential -ApplicationObjectId $appObjectId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name 'GitHub-Actions-Credential' -Subject "repo:$githubOrganizationName/${githubRepositoryName}:ref:refs/heads/main"

    $federatedCredential = Get-AzADAppFederatedCredential -ApplicationObjectId $appObjectId

    if ($federatedCredential) {
        Write-Log -Message "Federated authentication setup was successful."
    } else {
        throw "Failed to set up federated authentication"
    }

    # �f�[�^��ύX
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.appId = $appId
    $outputs.deployProgress."03" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-EntraIdApplication.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # �G���[�����������ꍇ
    $outputs.deployProgress."03" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    throw
}
