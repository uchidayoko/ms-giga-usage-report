<#
    .SYNOPSIS
        GitHub Actions��p����M365�e�i���g�f�[�^�擾�̂��߂̊��\�z: 1

    .DESCRIPTION
        1: �K�v�ȃ��W���[���̃C���X�g�[��

    .EXAMPLE
        PS> deploy1.ps1
#>

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
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
Write-Log -Message "Start executing deploy1.ps1"

try{
    # JSON�t�@�C����ǂݍ��݁A�I�u�W�F�N�g�ɕϊ�
    Write-Log -Message "Loading outputs.json and converting it to an object."
    
    # outputs�̓ǂݍ���
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    # ���W���[���̃C���X�g�[��
    $runningScript = "01_Install-Module\Install-Module.ps1"
    if($outputs.deployProgress."01" -ne "completed") {
        Write-Log -Message "Starting module installation."
        .\01_Install-Module\Install-Module.ps1
    }
    Write-Log -Message "deploy1.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # �G���[�����������ꍇ
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry exec.bat." -Level "Error"
    Write-Log -Message "---------------------------------------------"
}