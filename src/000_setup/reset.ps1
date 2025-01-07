<#
    .SYNOPSIS
        deploy2.ps1�ō\�z���������폜

    .DESCRIPTION
        Entra ID �A�v���P�[�V�����AEntra ID �O���[�v�ASharePoint�T�C�g�̍폜

    .EXAMPLE
        PS> reset.ps1
#>

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$paramsFilePath = ".\params.json"
$outputsFilePath = ".\outputs.json"
$mgGraphConnection = $false
$spoServiceConnection = $false


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

$confirmation = Read-Host "Reset the environment you built? (yes/no)"
if ( $confirmation -ne "yes") {
    exit 0
}

Write-Log -Message "Start executing reset.ps1"

try{
    # params.json��ǂݍ��݁A�I�u�W�F�N�g�ɕϊ�
    Write-Log -Message "Loading params.json and converting it to an object."
    $params = Get-Content -Path $paramsFilePath | ConvertFrom-Json

    # outputs.json��ǂݍ��݁A�I�u�W�F�N�g�ɕϊ�
    Write-Log -Message "Loading outputs.json and converting it to an object."
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    
    # Microsoft Graph�ɐڑ�
    Write-Log -Message "Connecting to Microsoft Graph."
    
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "Application.ReadWrite.All"
    if ($? -ne $true) {
        throw "Failed to connect to Microsoft Graph."
    }
    $mgGraphConnection = $true
    Write-Log -Message "Connected to Microsoft Graph successfully."
    
    # Entra ID �A�v���P�[�V�����̍폜
    $app = Get-MgApplication -Filter "displayName eq 'MsDeviceUsageReport-App'"
    if ($null -ne $app.id){
        Write-Log -Message "Deleting the Entra ID application named 'MsDeviceUsageReport-App'."
        Remove-MgApplication -ApplicationId $app.id
        $outputs.appId = ""
        $outputs.deployProgress."03" = ""
        $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    }

    # Entra ID �O���[�v�̍폜
    $securityGroups = Get-MgGroup -Filter "DisplayName eq 'M365UsageRecords_site_access_group'"
    if ($null -ne $securityGroups){
        Write-Log -Message "Deleting the security group named 'M365UsageRecords_site_access_group'."
        ForEach( $securityGroup in $securityGroups ) {
            Remove-MgGroup -GroupId $securityGroup.id
        }
        $outputs.securityGroupObjectId = ""
        $outputs.deployProgress."04" = ""
        $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    }

    # SharePoint Online�Ǘ��V�F���ւ̐ڑ�
    $sharepointDomain = $params.sharepointDomain
    $tenantName = ($sharepointDomain -split "\.")[0]
    $adminUrl = "https://$tenantName-admin.sharepoint.com"

    Write-Log -Message "Connecting to SharePoint Online Management Shell."
    Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
    Connect-SPOService -Url $adminUrl
    if ($? -ne $true) {
        throw "Failed to connect to SharePoint Online Management Shell."
    } else {
        $spoServiceConnection = $true
        Write-Log -Message "Connected to SharePoint Online Management Shell successfully."
    }

    # SharePoint�T�C�g�̍폜
    $spoSiteUrl = "https://$sharepointDomain/sites/M365UsageRecords"

    try {
        Write-Log -Message "Deleting the SharePoint site named 'M365UsageRecords'."
        Remove-SPOSite -Identity $spoSiteUrl
        Remove-SPODeletedSite -Identity $spoSiteUrl
        $outputs.tenantId = ""
        $outputs.siteUrl = ""
        $outputs.deployProgress."05" = ""
        $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    }
    catch {
        Write-Log -Message "No existing SharePoint site found."
    }

    Write-Log -Message  "Reset is complete."
}
catch{
    # �G���[�����������ꍇ
    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "Please retry reset.bat." -Level "Error"
}
finally {
    # Microsoft Graph�ւ̐ڑ���ؒf
    if ($mgGraphConnection) {
        Write-Log -Message "Disconnect from Microsoft Graph."
        Disconnect-MgGraph
    }
    
    # SharePoint Online �Ǘ��V�F���ւ̐ڑ���ؒf
    if ($spoServiceConnection) {
        Write-Log -Message "Disconnect from SPO Service."
        Disconnect-SPOService
    }

    Write-Log -Message "---------------------------------------------"
}
