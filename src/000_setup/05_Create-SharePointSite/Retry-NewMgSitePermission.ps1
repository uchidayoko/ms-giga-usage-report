<#
    .SYNOPSIS
        New-MgSitePermission��ʃE�B���h�E�ōĎ��s����X�N���v�g

    .DESCRIPTION
        ���{�X�N���v�g��Create-SharepointSite.ps1����Ăяo�����
        Create-SharepointSite.ps1��New-MgSitePermission�����s�����ꍇ�ɁA
        �ʃE�B���h�E��New-MgSitePermission���Ď��s����X�N���v�g
        
        (�w�i)
        �ȉ��̃��W���[���̃o�[�W������2.24.0���_�ł�Create-SharepointSite.ps1������ɓ��삵�Ă������A
        �o�[�W�������X�V���ꂽ���Ƃɂ��ANew-MgSitePermission������ɓ��삵�Ȃ��Ȃ����B
        �EMicrosoft.Graph.Sites
        �EMicrosoft.Graph.Authentication
        �EMicrosoft.Graph
        
        (�Ή�)
        New-MgSitePermission�����s�����O�ɁA����E�B���h�E����Get-SPOSite�����s�����ۂɃG���[���������Ă����Ԃł��邽�߁A
        �ʃE�B���h�E��New-MgSitePermission���Ď��s���邱�ƂŖ{���ۂ��������B

    .PARAMETER siteId
        [�K�{] SharePoint Online �T�C�gID
    
    .PARAMETER applicationId
        [�K�{] Entra ID �A�v���P�[�V�����̃N���C�A���gID

    .PARAMETER displayName
        [�K�{] Entra ID �A�v���P�[�V������
    
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$siteId,

    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$displayName
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
    $logMessage | Out-File -FilePath $logFile -Append
}

# ���O�t�H���_�����݂��Ȃ��ꍇ�͍쐬
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

Write-Log -Message "Start executing Retry-NewMgSitePermission.ps1"

try {
    Start-Sleep -Seconds 1
    # Microsoft Graph�ɐڑ�
    Write-Log -Message "Connecting to Microsoft Graph."   
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read", "Application.ReadWrite.All", "Sites.Read.All", "Sites.FullControl.All"
    # �ڑ��ɐ����������𔻒�
    if ($? -ne $true) {
        throw "Failed to connect to Microsoft Graph"
    }
    Write-Log -Message "Connected to Microsoft Graph successfully."
    
    $params = @{
        roles = @("write") 
        grantedToIdentities = @(
            @{
                application = @{
                    id = $applicationId
                    displayName = $displayName
                }
            }
        )
    }

    Write-Log -Message "Granting the application permissions to the site."
    New-MgSitePermission -SiteId $siteId -BodyParameter $params -ErrorAction Stop

    Write-Log -Message "Writing updated data to outputs.json file."
    # �X�V���ꂽ�f�[�^��outputs.json�t�@�C���ɏ�������
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 & Retry-NewMgSitePermission.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
    Start-Sleep -Seconds 3
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    throw
}
