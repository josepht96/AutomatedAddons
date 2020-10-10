[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$DownloadDir,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$AddonDir
)

function Get-AddonList() {
    <#
        .SYNOPSIS
        Get a list of Dirs from provided Addons Dir
    #>
    $Ads = Get-ChildItem -Path $AddonDir
    return $Ads
}
function Get-DownloadList() {
    <#
        .SYNOPSIS
        Get a list of .zip Dirs in provided download Dir.
        Dirs must have been downloaded within the last two hours, as it wouldnt be good
        to copy every .zip in Downloads.
    #>
    $Dls = Get-ChildItem -Recurse -Path $DownloadDir | `
        Where-Object { $_.Extension -eq ".zip" -and $_.LastWriteTime -gt (Get-Date).AddHours($TimeLapse) }
    return $Dls
}
function Expand-Addons($Downloads, $StagingDir) {
    <#
        .SYNOPSIS
        Logically its more complicated to compare archived folder structure to
        that of the AddonsDir. StagingDir acts as a temp Addons Dir.
        It gets deleted at the end of the script. It does mean theres an additional
        two steps of 1. Copying Dirs to Addons, 2. Deleting StagingDir
    #>
    $Downloads | ForEach-Object {
        Write-Host "Extracting $($_.Name)..."
        Expand-Archive -Path $_.FullName -DestinationPath "$DownloadDir\$StagingDir" -Force
    }
    $NewList = Get-ChildItem -Path "$DownloadDir\$StagingDir" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours($TimeLapse) }
    return $NewList
}
function Update-Addons($Addons, $ExtractList) {
    <#
        .SYNOPSIS
        If Dir exists in both Addons and extracted TempDir123, then copy the Dir
        to Addons to update addon. If the Addon contains a new Dir, prompt the user. 
        However, as long as no unrelated zips were downloaded in the prior 2 hours...
        it should be fine. 
    #>
    $CopyAll = $false
    $AskToRepeat = $true
    $ExtractList | ForEach-Object {
        if ((Test-Path $AddonDir\$($_.Name)) -or $CopyAll -eq $true) {
            Write-Host "Copying $($_.Name) to $AddonDir\$($_.Name)"
            Copy-Item -Path $_.FullName -Destination $AddonDir -Force
        }
        else {
            Write-Host "$($_.Name) doesnt exist within $AddonDir..."
            $UserResponse = Read-Host "y to copy anyhow, n to skip. y/n"
    
            if ($AskToRepeat -eq $true) {
                $RepeatResponse = Read-Host "Would you like to copy all remaining folders? y/n"
                if ($RepeatResponse.ToLower() -eq "y" ) {
                    Write-Host "Copying all remaining folders..."
                    $CopyAll = $true
                }
            }
            $AskToRepeat = $false

            if ($UserResponse.ToLower() -eq "y" ) {
                Write-Host "Copying $($_.Name) to $AddonDir\$($_.Name)"
                Copy-Item -Path $_.FullName -Destination $AddonDir -Force
            }
            else {
                Write-Host "Something other than y or Y was pressed so $($_.Name) will not be copied to $AddonDir."
            }
        }
    }
}
#Make sure provided paths exist
if (!(Test-Path $DownloadDir)) {
    Write-Host "The provided Downloads folder, $DownloadDir, doesn't exist. Please provide a valid path."
    & cmd /c pause
    exit
}
if (!(Test-Path $AddonDir)) {
    Write-Host "The provided Addon folder, $AddonDir, doesn't exist. Please provide a valid path."
    Write-Host "Check: C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
    & cmd /c pause
    exit
}
#Create temp Dir for transition extract
$StagingDir = "Addon_Staging"
if (!(Test-Path "$DownloadDir\$StagingDir")) {
    New-Item -ItemType Directory -Path "$DownloadDir\$StagingDir"
}
$TimeLapse = -3
$Addons = Get-AddonList
$Downloads = Get-DownloadList

$ExtractList = Expand-Addons $Downloads $StagingDir
Update-Addons $Addons $ExtractList

Write-Host "Script completed. Addons have been updated."
& cmd /c pause
exit
#Update-Addons
