<#
.SYNOPSIS
  This is a script that can scan perform vmdk virus scans using an Ubuntu linux scan host.  
  This script assumes that powershell core and microsoft defender for endpoint are configured on the scan host
  and that the scan host has been properly permissioned to the NFS share and has connectivity.
.DESCRIPTION
  This script mounts an NFS datastore and scans each of the files in the datastore.  
  If the file is an OVA it will untar into a directory in /tmp.  The script then scans all files
  and if the file is a vmdk it will mount it as a block device so it can scan within the file.
.PARAMETER mountPath
    The local path where the NFS share will be mounted
.PARAMETER tempTarget
    The temp path root where the OVA files will be unpacked and the VMDK mount points will be located
.PARAMETER logLocation
    The path for the script log output file.
.PARAMETER nfsMountSource
    The NFS share mount target ipaddress and filename

.NOTES
  Version:        1.0
  Author:         Jon Chancellor
  Creation Date:  2023.06.01
  Purpose/Change: Initial baseline release
  
.EXAMPLE
  sudo pwsh ./scanDataStoreImages.ps1 -mountpath "/home/azureuser/test_av_volume" -nfsMountSource "10.1.3.4:/test-av-volume"
#>

param(
    [string[]]$mountPath = "/home/azureuser/test_av_volume",
    [string[]]$tempTarget = "/tmp/scans/",
    [string[]]$logLocation = "/var/log/avScanLog.log",
    [string[]]$nfsMountSource = "10.1.3.4:/test-av-volume"
)

############## functions #####################

#Function to write timestamped output to a log file
function Write-toLogFile {
    Param (
        [Parameter(ValueFromPipeline)]
        [string[]]$logString,
        [string[]]$sourceString,
        [string[]]$logPath
    )
    if($logString){
        $timeStamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
        $message = "$timeStamp :: $sourceString :: $logString"
        Add-Content -Path $logPath -Value $message
    }    
}

#Function to scan VMDK files by mounting them and scanning individual files in the block devices
function Start-vmdkFileScan {
    [CmdletBinding()]
    param (
        [string[]]$sourceFilePath,
        [string[]]$tempTargetPath,
        [string[]]$nbdPath  = "/dev/nbd1"        
    )
    #update this to reflect the partition types to scan
    $scanPartTypes = @("Linux","Microsoft")
    $startTime = get-date
    Write-Host ("Scanning vmdk file $sourceFilePath")
    Write-Output "Scanning vmdk file $sourceFilePath" | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

    #connect the device using qemu utilities                   
    #Make sure nothing is previously using the device
    $disconnectCmd = "sudo qemu-nbd -d $nbdPath"
    Write-Host $disconnectCmd
    Invoke-Command -ScriptBlock { bash -c $disconnectCmd } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

    $connectCmd = "sudo qemu-nbd -r -c $nbdPath $sourceFilePath"
    Write-Host $connectCmd
    Invoke-Command -ScriptBlock { bash -c $connectCmd } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

    #create new mount points for the devices created and attempt to mount them
    $nbdPathString = "$($nbdPath)p" 
    $fdiskCmd = ("sudo fdisk $nbdPath -l -o Device,Type | sudo grep $nbdPathString")
    $nbdItems = (Invoke-Command -ScriptBlock { bash -c  $fdiskCmd }) 
    Write-Output $nbdItems | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
    foreach ($nbdItem in $nbdItems) {
        if ($nbdItem.split(" ")[1] -in $scanPartTypes) {
            #create a directory in the temp location
            Write-Host "Initiating scan on partition $nbdItem from file $sourceFilePath"
            Write-Output "Initiating scan on partition $nbdItem" | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
            
            Write-Host "$tempTargetPath/"
            Write-Host "/$($nbdItem.split(" ")[0].Split("/")[-1])"

            $newPartitionDir = "$($tempTargetPath.TrimEnd())/$($nbdItem.Trim().split(" ")[0].Split("/")[-1])"

            Write-Host $newPartitionDir
            If (!(Test-Path -PathType container $newPartitionDir)) {
                New-Item -ItemType Directory -Path $newPartitionDir | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
            }
            else {
                #cancel any running scan so there isn't a lock on the mount
                $cancelCommand = "sudo mdatp scan cancel"
                Invoke-Command -ScriptBlock { bash -c "$cancelCommand" } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
                
                #make sure a stale mount doesn't exist
                $newPartitionUnMountCmd = "sudo umount $newPartitionDir"
                Invoke-Command -ScriptBlock { bash -c "$newPartitionUnMountCmd" } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
            }
           
            #attempt a mount on the current partition
            $newPartitionMountCmd = "sudo mount -r $($nbdItem.split(" ")[0].trim()) $newPartitionDir"
            Invoke-Command -ScriptBlock { bash -c "$newPartitionMountCmd" } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

            #scan the partition directory
            $nbdMdatpCommand = "sudo /usr/bin/mdatp scan custom --path $newPartitionDir"
            Invoke-Command -ScriptBlock { bash -c "$nbdMdatpCommand" } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

            #unmount the partitions
            $newPartitionUnMountCmd = "sudo umount $newPartitionDir"
            Invoke-Command -ScriptBlock { bash -c "$newPartitionUnMountCmd" } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

            #give the unmount time to completely unmount
            Start-Sleep -Seconds 5

            #remove the directory
            Write-Output( "removing $newPartitionDir") | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
            Remove-Item -Path $newPartitionDir -Recurse | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
        }
    }
    #disconnect the device
    Invoke-Command -ScriptBlock { bash -c $disconnectCmd } | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath

    $scanTime = ((Get-Date) - $startTime)
    Write-Output ("Scan of vmdk file $sourceFilePath completed in $scanTime ")  | Write-toLogFile -logPath $logLocation -sourceString $sourceFilePath
}

############## Main Script #####################
#ensure the nfs utilities are installed and latest
Invoke-Command -ScriptBlock { sudo apt-get install nfs-common -y } | Write-toLogFile -logPath $logLocation -sourceString "script"

#Make sure the directory for the nfs mount exists and create it if not
If (!(Test-Path -PathType container $mountPath)) {
    New-Item -ItemType Directory -Path $mountPath | Write-toLogFile -logPath $logLocation -sourceString "script"
}

#mount nfs for the datastore
$nfsMountCommand = "sudo mount -t nfs -o rw,hard,rsize=262144,wsize=262144,vers=3,tcp $nfsMountSource test_av_volume"
Invoke-Command -ScriptBlock { $nfsMountCommand } | Write-toLogFile -logPath $logLocation -sourceString "script"

#modprobe nbd so we can mount block devices
Invoke-Command -ScriptBlock { sudo modprobe nbd } | Write-toLogFile -logPath $logLocation -sourceString "script"

#make sure the temp processing directory exists
If (!(Test-Path -PathType container $tempTarget)) {
    New-Item -ItemType Directory -Path $tempTarget | Write-toLogFile -logPath $logLocation -sourceString "script"
}


#get a full list of files on the share
$items = Get-ChildItem $mountPath -Recurse | select-object FullName, Attributes

#for each file in the array
foreach ($item in $items) {
    if ($item.Attributes -ne "Directory") {
        #run an initial scan of the file
        $mdatpCommand = "sudo /usr/bin/mdatp scan custom --path $($item.FullName )"

        Invoke-Command -ScriptBlock { bash -c "$mdatpCommand" } | Write-toLogFile -logPath $logLocation -sourceString $item.FullName 
        #if the file is an OVA unpack it
        if ($item.FullName.split(".")[-1].ToLower().trim() -eq "ova" ) {
            #create a temp directory to unpack the ova for scanning
            $targetDir = $tempTarget.trim() + $item.FullName.split("/")[-1].trim()
            If (!(Test-Path -PathType container $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Write-toLogFile -logPath $logLocation -sourceString $item.FullName
            }

            #untar the OVA to the temp directory
            $untarCmd = "tar -xvf $($item.FullName) --directory $targetDir" 

            Invoke-Command -ScriptBlock { bash -c "$untarCmd" } | Write-toLogFile -logPath $logLocation -sourceString $item.FullName

            #scan the temp folder files
            $tempMdatpCommand = "sudo /usr/bin/mdatp scan custom --path $targetDir"
            Invoke-Command -ScriptBlock { bash -c "$tempMdatpCommand" } | Write-toLogFile -logPath $logLocation -sourceString $item.FullName

            #if any of the files are vmdk files, mount them 
            $ovaItems = Get-ChildItem $targetDir -Recurse | select-object FullName, Attributes
            foreach ($ovaItem in $ovaItems) {
                #if the item is an vmdk file mount it
                if ($ovaItem.FullName.split(".")[-1].ToLower().trim() -eq "vmdk" ) {
                    Start-vmdkFileScan $ovaItem.FullName $targetDir 
                }
            }
            #remove the temp directory
            Remove-Item -Path $targetDir -Recurse -Force | Write-toLogFile -logPath $logLocation -sourceString $item.FullName
        }

        #if file is a standalone vmdk copy and scan it
        if ($item.FullName.split(".")[-1].ToLower() -eq "vmdk" ) {
            $targetDir = $tempTarget.trim() + $item.FullName.split("/")[-1].trim()
            If (!(Test-Path -PathType container $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Write-toLogFile -logPath $logLocation -sourceString $item.FullName
            }
            #copy vmdk locally to improve scan times?
            Start-vmdkFileScan $item.FullName $targetDir 
        }        
    }
    
}

Remove-Item -Path $tempTarget -Recurse -Force | Write-toLogFile -logPath $logLocation -sourceString "script"


