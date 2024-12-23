<#
    .SYNOPSIS
        SharePoint�T�C�g�̍쐬

    .DESCRIPTION
        M365�e�i���g�f�[�^��~�ς��邽�߂�SharePoint�T�C�g�̍쐬
        �y�сAEntra ID �A�v���P�[�V�����ւ̌����t�^

    .PARAMETER applicationId
        [�K�{] Entra ID �A�v���P�[�V����ID

    .PARAMETER securityGroupObjectId
        [�K�{] SharePoint�T�C�g�ɑ΂��ăA�N�Z�X����t�^���邽�߂�Entra ID �Z�L�����e�B�O���[�v��Object ID
        
    .PARAMETER sharepointDomain
        [�K�{] SharePoint�T�C�g�̃h���C��
        ex. SharePonit�T�C�gURL��"https://contoso.sharepoint.com"�̎��A"contoso.sharepoint.com"
    
    .EXAMPLE
        PS> Create-SharepointSite.ps1 -applicationId "your-application-id" -securityGroupObjectId "your-security-group-object-id" -sharepointDomain "your-sharepoint-domain"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$securityGroupObjectId,

    [Parameter(Mandatory=$true)]
    [String]$sharepointDomain
)

# �ϐ���`
$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json
$spoSiteName = "M365UsageRecords"
$spoSiteUrl = "https://$sharepointDomain/sites/$spoSiteName"
$spoSiteTemplate = "STS#3"
$spoSiteLocaleId = 1041
$spoSiteStorageQuota = 1024

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
Write-Log -Message "Start executing Create-SharepointSite.ps1"

try {
    Write-Log -Message "Get information of the currently signed-in user."

    # �T�C���C�����Ă��郆�[�U�[�̃��[���A�h���X���擾
    $userMail = az ad signed-in-user show --query userPrincipalName --output tsv
    if ([string]::IsNullOrEmpty($userMail)) {
        Write-Log -Message "Failed to get signed-in user's email address."
        throw "Failed to get signed-in user information"
    } else {
        Write-Log -Message "Signed-in user email got successfully: $userMail"
    }

    # �e�i���g�����擾
    $tenantInfo = Get-AzTenant
    if (-not $tenantInfo) {
        Write-Log -Message "Failed to get tenant information."
        throw "Failed to get Tenant information"
    } else {
        Write-Log -Message "Tenant information got successfully."
    }

    Write-Log -Message "Get tenant information."
    $tenantId = $tenantInfo.Id

    Write-Log -Message "Checking if the SharePoint site already exists."
    try {
        # SharePoint�T�C�g�����ɑ��݂��邩�m�F
        Get-SPOSite -Identity $spoSiteUrl -ErrorAction SilentlyContinue
        Write-Log -Message "SharePoint site already exists. No action taken." -Level "Warning"
    }
    catch {
        Write-Log -Message "No existing SharePoint site found. Creating a new site."
        # SharePoint�T�C�g��V�K�쐬
        New-SPOSite -Url $spoSiteUrl -Owner $userMail -StorageQuota $spoSiteStorageQuota -Template $spoSiteTemplate -LocaleId $spoSiteLocaleId -Title $spoSiteName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create SharePoint site."
            throw "SharePoint site creation failed."
        } else {
            Write-Log -Message "SharePoint site created successfully."
        }
    }

    Write-Log -Message "Creating LoginName for the security group."
    # �Z�L�����e�B�O���[�v�̃��O�C�������쐬
    $securityGroupLoginName = "c:0t.c|tenant|$securityGroupObjectId"

    Write-Log -Message "Adding the security group as a site collection administrator."
    $groupName = "Access Permission Group for M365 Usage Report"

    # �O���[�v�����݂��Ȃ��ꍇ�͐V�K�쐬
    $group = Get-SPOSiteGroup -Site $spoSiteUrl | Where-Object { $_.Title -eq $groupName }

    if ($null -eq $group) {
        New-SPOSiteGroup -Site $spoSiteUrl -Group $groupName -PermissionLevels "Full Control"
    }

    # �Z�L�����e�B�O���[�v���T�C�g�R���N�V�����Ǘ��҂Ƃ��Ēǉ�
    Add-SPOUser -Site $spoSiteUrl -LoginName $securityGroupLoginName -Group $groupName

    Write-Log -Message "Creating a service principal."
    # �T�[�r�X�v�����V�p�����쐬
    New-MgServicePrincipal -AppId $applicationId -ErrorAction SilentlyContinue

    Write-Log -Message "Getting the service principal."
    # �T�[�r�X�v�����V�p�����擾
    $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$applicationId'"

    Write-Log -Message "Service Principal ID: $($servicePrincipal.Id)"

    Write-Log -Message "Getting site information."
    # �T�C�g�����擾
    $siteInfo = Get-MgSite -SiteId "${sharepointDomain}:/sites/$spoSiteName"
    if (-not $siteInfo) {
        Write-Log -Message "Failed to get site information for '$spoSiteName'."
        throw "Failed to get site information."
    } else {
        Write-Log -Message "Site information got successfully for '$spoSiteName'."
    }
    $siteId = $siteInfo.Id

    Write-Log -Message "Site ID: $siteId"

    $params = @{
        roles = @("write")
        grantedToIdentities = @(
            @{
                application = @{
                    id = $applicationId
                    displayName = $servicePrincipal.DisplayName
                }
            }
        )
    }

    Write-Log -Message "Granting the application permissions to the site."
    # �A�v���P�[�V�����ɃT�C�g�ւ̌�����t�^
    New-MgSitePermission -SiteId $siteId -BodyParameter $params

    Write-Log -Message "Writing updated data to outputs.json file."
    # �X�V���ꂽ�f�[�^��outputs.json�t�@�C���ɏ�������
    $outputs.tenantId = $tenantId
    $outputs.siteUrl = $spoSiteUrl
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
