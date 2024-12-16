<#
    .SYNOPSIS
        �}�X�^���|�W�g���̓��e����Ǝ҂�GitHub��̍\�z�惊�|�W�g���ɃR�s�[

    .DESCRIPTION
        �}�X�^���|�W�g�����̃t�H���_�̓��e����Ǝ҂�GitHub��̍\�z�惊�|�W�g���ɃR�s�[

    .PARAMETER githubOrganizationName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��g�D��

    .PARAMETER githubRepositoryName
        [�K�{] ��Ǝ҂�GitHub��̍\�z��v���C�x�[�g���|�W�g����

    .PARAMETER githubAccountName
        [�K�{] ��Ǝ҂�GitHub�A�J�E���g��

    .PARAMETER githubAccountMail
        [�K�{] ��Ǝ҂�GitHub�ւ̓o�^���[���A�h���X

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
Write-Log -Message "Start executing Copy-Github.ps1"

try{
    # ���݂̃p�X���擾
    $returnPath = Get-Location

    # ���[�J���ɃR�s�[�����}�X�^���|�W�g�����̂��ׂẴt�H���_�ւ̃p�X���擾
    Set-Location ../..
    $sourcePath = Resolve-Path -Path "./*"
    Set-Location ..

    # ��Ǝ҂�GitHub��̍\�z��v���C�x�[�g���|�W�g�����N���[��
    Write-Host "Cloning the target GitHub private repository."
    git clone https://github.com/$githubOrganizationName/$githubRepositoryName.git
    Set-Location $githubRepositoryName
    
    # �}�X�^���|�W�g���̑S�Ẵt�H���_�����[�J���̃u�����`�ɃR�s�[
    Write-Host "Creating a new branch 'copy-dir' and copying all folders from the master repository."

    # �u�����`�̑��݊m�F
    $branchName = "copy-dir"
    $branchExists = git branch --list $branchName
    if (-not $branchExists) {
        # �u�����`�����݂��Ȃ��ꍇ�A�V�����u�����`���쐬���ă`�F�b�N�A�E�g
        git checkout -b $branchName
        Write-Output "Created and switched to branch '$branchName'"

    } else {
        # �u�����`�����ɑ��݂���ꍇ�A���̃u�����`�Ƀ`�F�b�N�A�E�g
        git checkout $branchName
        Write-Output "Switched to existing branch '$branchName'"
    }

    # �R�s�[��̃p�X���擾
    $destinationPath = (Get-Location).Path
    Write-Host "Copying from '$sourcePath' to '$destinationPath'"

    # ���[�J���ɃR�s�[�����}�X�^���|�W�g�����̂��ׂẴt�@�C�����R�s�[
    Copy-Item -Path $sourcePath.Path -Destination $destinationPath -Recurse -Force

    # �R�s�[��̊m�F
    ## �R�s�[�����t�H���_���̎擾
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
    
    # ��Ǝ҂�GitHub��̍\�z��v���C�x�[�g���|�W�g���Ƀv�b�V������
    Write-Host "Pushing changes to the remote repository."
    git push origin copy-dir:main

    Set-Location $returnPath
    
    # �f�[�^��ύX
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."02" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Copy-Github.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    # �G���[�����������ꍇ
    $outputs.deployProgress."02" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}