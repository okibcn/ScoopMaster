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
$lBuckets = [System.Collections.ArrayList]@()
$source = iwr $scoopDBURL
$source.Content -split '\r?\n' | ForEach-Object -Process {
    if ($_ -match '<h2.*(http[^\"]+)"'){
        [void]$lBuckets.Add($matches[1])
    }
}
$lBuckets >> Bucket_list.txt

## CREATE ZIP LIST for aria2c
$lZips=$lBuckets | %{
    if( -not ($_ -match 'https:\/\/github.com\/(.+)')){
        $_ >> badrepos.txt
        return}
    $owner_repo=$matches[1].replace('/','~')
    return "$_/archive/refs/heads/master.zip`n    out=$owner_repo.zip"
}
$lZips > zip_list.txt   

# DOWNLOAD BUCKETS
aria2c --save-session aria2-out.txt -j 16 -i zip_list.txt -d zips
$nZips=(cmd.exe /c dir /s /b /a-d zips).count
# EXTRACT MANIFESTS
7z e -y zips/*.zip  -ojsons/* */bucket/*.json */*.json
# PREPARE OUTPUT
Remove-Item -Force -Recurse jsons/*/.*.json
$nJsons=(cmd.exe /c dir /s /b /a-d jsons).count
Write-Host "PROCESS COMPLETED. $nJsons manifests extracted from $nZips downloaded buckets."

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
        $_.FullName >> ERROR_manifest.txt
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
