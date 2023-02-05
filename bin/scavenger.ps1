## SCOOP #####################################################################

# ## GET 7Z
# $DLpage= iwr "https://www.7-zip.org/download.html"
# $DLpage.RawContent -match "7z.+-x64.exe"
# wget -q "https://www.7-zip.org/a/$($matches[0])"
# wget -q https://www.7-zip.org/a/7zr.exe
# ./7zr x $matches[0] -o7zdir
# mv .\7zdir\7z.exe .
# remove-item 7zr*,*x64.exe,7zdir -Recurse -Force


## GET List of Buckets from Scoop-Directory website
$scoopDBURL = "https://rasa.github.io/scoop-directory/by-apps.html"
$ErrorActionPreference = 'SilentlyContinue'

## CREATE BUCKETS LIST: $lBuckets
$lBuckets = [System.Collections.ArrayList]@()
$source = iwr $scoopDBURL
$source.Content -split '\r?\n' | ForEach-Object -Process {
    if ($_ -match '<h2.*(http[^\"]+)"'){
        [void]$lBuckets.Add($matches[1])
    }
}
$lBuckets >> Known_Buckets.txt

## GET all JSONs from BUCKETS in ./jsons
$Jobs = 6
$progress=0
$nbuckets=$lBuckets.Count
Remove-Item zips,jsons,ERROR_Downloading.txt,ERROR_empty_buckets.txt -Force -Recurse
mkdir zips  -Force | Out-Null
mkdir jsons -Force | Out-Null
Write-Host "Downloading and extracting manifests from $nbuckets buckets...`n"
Foreach ($repo in $lBuckets){
    Do{$running = (Get-Job -State Running | measure).count} 
    Until ($running -le $Jobs)
    Start-Job -Name $repo -ScriptBlock { 
        $repoURL = $Using:repo 
        if( -not ($repoURL -match 'https:\/\/github.com\/(.+)')){
            $repoURL >> badrepos.txt
            return}
        $owner_repo=$matches[1]
        $basename=$owner_repo.replace('/','~')
        $ZIPURL = "$repoURL/archive/refs/heads/master.zip" 
        $zipfile="./zips/$basename.zip"
        wget -q $ZIPURL -O "$zipfile"
        if(-not (test-path "$zipfile")){
            $ZIPURL >> ERROR_Downloading.txt
            return}
        7z e -y "$zipfile" -o"jsons/$basename" */bucket/*.json */*.json | Out-Null
        rm "$zipfile"
        if(-not (test-path "jsons/$basename")){
            $repoURL >> ERROR_empty_buckets.txt
            return}
    }  | Out-Null
    Get-Job -State Completed | Remove-Job | Out-Null
    $progress++
    $percent = [math]::round(100 * $progress / $nbuckets)
    Write-Output "$progress/$nbuckets  ( $percent% ):  $repo"
    # Write-Progress -Activity "Processing " -Status "$percent% ($running) processing: $repo" -PercentComplete $percent
}
Wait-Job -State Running
Get-Job -State Completed | Remove-Job
Remove-Item zips,jsons/*/.*.json -Force -Recurse
$nJsons=(cmd.exe /c dir /s /b /a-d jsons).count
Write-Host "PROCESS COMPLETED. $nJsons manifests extracted from $nbuckets buckets."
if(Test-Path ERROR_downloading.txt){
    Write-Host "There where errors downloading the following files:"
    cat ./ERROR_Downloading.txt
}
if(Test-Path ERROR_empty_buckets.txt){
    Write-Host "The following buckets were empty:"
    cat ./ERROR_empty_buckets.txt
}


## PROCESS JSON FILES

mkdir local -Force | Out-Null
Remove-Item local/* -Recurse -Force
Remove-Item ERROR_manifest.txt -Force
$progress=0
$oldpercent=0
$nlocal=0
$hVersion = @{}
$hDate = @{}
$hBucket = @{}
$njsons=(cmd.exe /c dir /s /b /a-d jsons).count
Write-Host "Processing $njsons manifests...`n"
gci jsons/*/*.json | ForEach-Object{
    # FOR EACH PACKETFILE IN BUCKET
    $name=$_.BaseName
    try{$version=(Get-Content $_ | ConvertFrom-Json).version}
    catch{
        $_.fullname >> ERROR_manifest.txt
        return
    }
    $date=$_.LastWriteTimeUtc
    if  (-NOT $hVersion.ContainsKey($name)){
        # Package not in local repo.
        Move-Item $_ ./local -Force
        $hVersion.add($name,$version)
        $hDate.add($name,$date)
        $hBucket.add($name,$bucket)
        $nlocal++
    }elseif (($date -gt $hDate[$name])){
        # Newer manifest
        Move-Item $_ ./local -Force
        $hVersion.Set_Item($name,$version)
        $hDate.Set_Item($name,$date)
        $hBucket.Set_Item($name,$bucket)
    }else {
        # older version or same version but older manifest
    }
    $progress++
    $percent = [math]::round(100 * $progress / $njsons)
    if ($percent -ne $oldpercent){
        Write-Output "$progress/$njsons  ( $percent% )"
        $oldpercent=$percent
    }
    # Write-Progress -Activity "Processing " -Status "$percent% (Selected: $nlocal) processing: $name" -PercentComplete $percent
}
Remove-Item jsons -Force -Recurse
Write-Host "PROCESS COMPLETED. $nlocal different packages with the most recent manifest out of a total of $nJsons manifests."
if(Test-Path ERROR_manifest.txt){
    Write-Host "The following manifests have errors:"
    cat ./ERROR_manifest.txt
} 





## PROCESS PACKETS IN BUCKETS

# #Create version and date hash tables
# $hVersion = @{}
# $hDate = @{}
# $hBucket = @{}
# $nbuckets=$lBuckets.Count
# $progress=0
# $case1=0
# $case2=0
# $case3=0


# mkdir local -Force | Out-Null
# mkdir jsons -Force | Out-Null
# $lBuckets | %{
#     # FOR EACH BUCKET
#     $bucket=$_
#     $progress++
#     $percent = [math]::round(100 * $progress / $nbuckets)
#     Write-Progress -Activity "Processing " -Status "$percent% processing: $bucket" -PercentComplete $percent
#     $ZIPURL = "$bucket/archive/refs/heads/master.zip" 
#     wget -q $ZIPURL
#     if(test-path master.zip){
#         7z e master.zip */bucket/*.json -ojsons | Out-Null
#         rm master.zip
#     }else{
#         Write-Host("WARNING: Bucket $bucket doesnt exist.")
#     }
#     # Expand-Archive .\master.zip -Passthough | Out-Null
#     gci jsons/*.json | %{
#         # FOR EACH PACKETFILE IN BUCKET
#         $name=$_.BaseName
#         $errorCount=$error.Count
#         try{$version=(Get-Content $_ | ConvertFrom-Json).version}
#         catch{Write-Host("WARNING: error in Manifest $name.json in bucket $bucket")}
#         if ($errorCount -eq $error.count){
#             $date=$_.LastWriteTimeUtc
#             if  (-NOT $hVersion.ContainsKey($name)){
#                 # Package not in local repo.
#                 Move-Item $_ ./local -Force
#                 $hVersion.add($name,$version)
#                 $hDate.add($name,$date)
#                 $hBucket.add($name,$bucket)
#                 $case1++
#             }elseif (($date -gt $hDate[$name])){
#                 # Newer manifest
#                 Move-Item $_ ./local -Force
#                 $hVersion.Set_Item($name,$version)
#                 $hDate.Set_Item($name,$date)
#                 $hBucket.Set_Item($name,$bucket)
#                 $case2++
#             }else {
#                 # older version or same version but older manifest
#                 $case3++
#             }
#         }
#     }
#     Remove-Item jsons/* -Force
# }
# Write-Host "Case1: $case1;  Case2 $case2; Case3 $case3"
