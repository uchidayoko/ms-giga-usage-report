<#
    .SYNOPSIS
        GitHub�V�[�N���b�g�̐ݒ�ƃ��[�N�t���[�̎��s 

    .DESCRIPTION
        GitHub�V�[�N���b�g��ݒ肵���̂��ɁAGitHubActions�̃��[�N�t���[�����s

    .PARAMETER tenantId
        [�K�{] Azure�e�i���g�̃e�i���gID

    .PARAMETER tenantName
        [�K�{] �e�i���g���i�h���C���̈ꕔ�j
        ex. �h���C������"contoso.onmicrosoft.com"�̏ꍇ�A"contoso"�Ƃ���B

    .PARAMETER applicationId
        [�K�{] Entra ID �A�v���P�[�V����ID

    .PARAMETER githubOrganizationName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��g�D��

    .PARAMETER githubRepositoryName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��v���C�x�[�g���|�W�g����

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

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json


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
Write-Log -Message "Start executing Exec-GitHubActions.ps1"

try{
    Write-Log -Message "Start adding GitHub Secret and executing GitHubActions.."

    # GitHub�V�[�N���b�g�̒ǉ�
    Write-Log -Message "Adding GitHub Sercret."
    gh secret set AZURE_TENANT_ID --body $tenantId --repo $githubOrganizationName/$githubRepositoryName
    gh secret set AZURE_TENANT_NAME --body $tenantName --repo $githubOrganizationName/$githubRepositoryName
    gh secret set AZURE_CLIENT_ID --body $applicationId --repo $githubOrganizationName/$githubRepositoryName

    # ���[�N�t���[�̎��s
    Write-Log -Message "Executing GitHub Actions workflows."
    gh workflow run daily_workflow.yml --repo $githubOrganizationName/$githubRepositoryName
    gh workflow run manual_workflow.yml --repo $githubOrganizationName/$githubRepositoryName -f date_range=27

    # �f�[�^��ύX
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."06" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
 
    Write-Log "Execution of Exec-GitHubActions.ps1 is complete."
    Write-Log "---------------------------------------------"
}
catch{
    # �G���[�����������ꍇ
    $outputs.deployProgress."06" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
