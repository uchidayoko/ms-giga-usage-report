<#
    .SYNOPSIS
        �K�v�ȃ��W���[���̃C���X�g�[�����s��

    .DESCRIPTION
        ���p���郂�W���[���Ɨp�r�͈ȉ��̒ʂ�
        �ESharePoint Online�Ǘ��V�F��
            �p�r�FSharePoint�T�C�g�쐬�Ȃ�
        �EMicrosoft Graph
            �p�r�F�e�i���g���擾�AEntra ID�O���[�v�̍쐬�Ȃ�
        �EAz
            �p�r�FEntra ID�A�v���P�[�V�����쐬�A�����t�^�Ȃ�
        �EMicrosoft.Graph.Sites
            �p�r�FEntra ID�A�v���P�[�V�����ɑ΂���SharePoint Online�T�C�g�ւ̌����t�^�Ȃ�

    .EXAMPLE
        PS> Install-Module.ps1
#>

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = $logFolder + "\" + "${date}_log.txt"
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
Write-Log -Message "Start executing Install-Module.ps1"

try{
    # �K�v�ȃ��W���[���̃C���X�g�[�����J�n���܂�
    Write-Log -Message "Starting the installation of required modules..."
    
    # �C���X�g�[�����郂�W���[�����
    $RequiredModules = 'Microsoft.Online.SharePoint.PowerShell', 'Az', 'Microsoft.Graph', 'Microsoft.Graph.Sites'
    # ���ɃC���X�g�[������Ă��邩���肵�A�C���X�g�[������Ă��Ȃ��ꍇ�̓C���X�g�[�����s��
    ForEach( $Module in $RequiredModules ) {
        If ( !(Get-InstalledModule -Name $Module) ) {
            Write-Log -Message "Installing $Module..."
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
            Write-Log -Message "$Module installation completed."
        }
    }

    # �f�[�^��ύX
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."01" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Install-Module.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # �G���[�����������ꍇ
    $outputs.deployProgress."01" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    throw
}