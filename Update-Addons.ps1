[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$DownloadFolder,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$AddonFolder
)

function Get-AddonList() {
    <#
        .SYNOPSIS
        Get a list of folders from provided Addons folder
    #>
    $Ads = Get-ChildItem -Path $AddonFolder
    return $Ads
}
function Get-DownloadList() {
    <#
        .SYNOPSIS
        Get a list of .zip folders in provided download folder.
        Folders must have been downloaded within the last two hours, as it wouldnt be good
        to copy every .zip in Downloads.
    #>
    $Dls = Get-ChildItem -Recurse -Path $DownloadFolder | `
        Where-Object { $_.Extension -eq ".zip" -and $_.LastWriteTime -gt (Get-Date).AddHours(-2) }
    return $Dls
}
function Expand-Addons($Downloads, $TempFolder) {
    <#
        .SYNOPSIS
        Logically its more complicated to compare archived folder structure to
        that of the AddonsFolder. TempFolder123 acts as a temp Addons folder.
        It gets deleted at the end of the script. It does mean theres an additional
        two steps of 1. Copying folders to Addons, 2. Deleting TempFolder123
    #>
    foreach ($Download in $Downloads) {
        Write-Host "Extracting $Download.FullName..."
        Expand-Archive -Path $Download.FullName -DestinationPath "$DownloadFolder\$TempDownloads" -Force
    }
    $NewList = Get-ChildItem -Path "$DownloadFolder\$TempDownloads"
    return $NewList
}
function Update-Addons($Addons, $ExtractList) {
    <#
        .SYNOPSIS
        If folder exists in both Addons and extracted TempFolder123, then copy the folder
        to Addons to update addon. If the Addon contains a new folder, prompt the user. 
        However, as long as no unrelated zips were downloaded in the prior 2 hours...
        it should be fine. 
    #>
    $NoMatchBool = $false
    $ExtractList | ForEach-Object {
        if ((Test-Path $AddonFolder\$($_.Name)) -or $NoMatchBool -eq $true) {
            Write-Host "Copying $($_.Name) to $AddonFolder\$($_.Name)"
            Copy-Item -Path $_.FullName -Destination $AddonFolder -Force
        }
        else {
            Write-Host "$($_.Name) doesnt exist within $AddonFolder..."
            $UserResponse = Read-Host "Press Y to copy anyhow, press N to skip..."
            $RepeatResponse = Read-Host "Would you like to do this for all folders? Press Y for yes, N for no"
            $UR = $UserResponse.ToLower()
            $RR = $RepeatResponse.ToLower()
            if ($RR -eq "y" ) {
                Write-Host "Copying all folders..."
                $NoMatchBool = $true
            }
            if ($UR -eq "y" ) {
                Write-Host "Copying $($_.Name) to $AddonFolder\$($_.Name)"
                Copy-Item -Path $_.FullName -Destination $AddonFolder -Force
            }
            else {
                Write-Host "Something other than y or Y was pressed so $($_.Name) will not be copied to $AddonFolder."
            }
        }
    }
}
#Make sure provided paths exist
if (!(Test-Path $DownloadFolder)) {
    Write-Host "The provided Downloads folder, $DownloadFolder, doesn't exist. Please provide a valid path."
    & cmd /c pause
    exit
}
if (!(Test-Path $AddonFolder)) {
    Write-Host "The provided addon folder, $AddFolder, doesn't exist. Please provide a valid path."
    & cmd /c pause
    exit
}
#Create temp folder for transition extract
$TempDownloads = "TempFolder123"
if (!(Test-Path "$DownloadFolder\$TempDownloads")) {
    New-Item -ItemType Directory -Path "$DownloadFolder\$TempDownloads"
}
$TempFolder = "$DownloadFolder\TempFolderToBeDeleted"

$Addons = Get-AddonList
$Downloads = Get-DownloadList

$ExtractList = Expand-Addons $Downloads $TempFolder
Update-Addons $Addons $ExtractList

Write-Host "Script completed. Addons have been updated."
& cmd /c pause
exit
#Update-Addons