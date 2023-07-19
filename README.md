# Scoop Master Bucket/Database

</br>

**Scoop Master**, the way to keep all the apps in Scoop ultra-updated. One bucket for all.

(Do you find this project useful? give it a ⭐)

</br>

And don't miss **[SS (Scoop Super Search)](https://github.com/okibcn/ss)**, the associated CLI search utility.

</br>

<img width="1162" alt="image" src="https://user-images.githubusercontent.com/22417711/221735191-c92cf442-b29e-411b-a5c7-2b3ca8de6d50.png">

____

**FEATURES**
--------
</br>

To help users to maintain all the apss updated, this repo provides two services, a bucket with all the apps, and a database for fast app search. The platform surveys internet for known buckets and creates Bucket and database snapshots every 30 minutes. At this time the metrics for the **ScoopMaster** platform in its current snapshot are:

- The database indexes **177946** manifests.
- The harvester gathers data from **1539** buckets.
- The Bucket provides last versions for all the **43307** apps.

The system uses the platform in two ways:
</br>

## - As a Bucket

</br>

**ScoopMaster** provides manifests for every app in any known Scoop bucket, updated every 30 minutes to ensure fresh app versions. This way you only need one bucket in your Scoop bucket list. It takes the manifests from all the known buckets and maintains a bucket with the most recent version of each known package just for you.

</br>

## - As a Database

</br>

**ScoopMaster** also provides a **[database](https://github.com/okibcn/ScoopMaster/releases/tag/Databases)** with updated data of every known app manifest in internet. This way search engines such as **[SS (Scoop Super Search)](https://github.com/okibcn/ss)** can use it to provide ultra-fast — less than 500 milliseconds — and accurate search results, even better than the official [scoop.sh](https://scoop.sh) directory.

</br>


____
**INSTALLATION**
------------

</br>

## - Bucket installation

</br>

To add this bucket, paste this in a PowerShell session: 
```pwsh
scoop bucket add .SM https://github.com/okibcn/ScoopMaster
```
install any app in the bucket just type 
```
scoop install <app_name>
```
To remove the bucket just type:
```
scoop bucket rm .SM
```

If you want all your local apps to be updated to the latest version provided by ScoopMaster, just change the update source for that app. You can do it for all of them by copy-n-paste this in PowerShell:
```pwsh
gci ~/scoop/apps/*/current/install.json | % { 
    (gc $_) -Replace '(?<=bucket":\s+")[^"]+',".SM" |Set-Content $_ }
scoop update
scoop update *
```

</br>

## - Database installation

</br>

The **[database](https://github.com/okibcn/ScoopMaster/releases/tag/Databases)** doesn't need any install instructions. If want to use it for searching purposes, you can use the ultra-fast **[SS (Scoop Super Search)](https://github.com/okibcn/ss)** utility. it provides instant result to simple queries and complex regex searches. Refer to its homepage for installation instructions.



</br>

____
**USAGE**
------------

</br>

The bucket doesn't require any operation other than the installation, removal, and app installation already described above.

</br>

The **[database](https://github.com/okibcn/ScoopMaster/releases/tag/Databases)** is writen in CSV format with UTF-8 no BOM encoding. It is updated every 30 minutes. Raw and 7z compressed versions are provided in the **[Download page](https://github.com/okibcn/ScoopMaster/releases/tag/Databases)**.


IF you want to experience the speed and the data contained, you can use the official ScoopMaster search utility **[SS (Scoop Super Search)](https://github.com/okibcn/ss)** that can be installed typing:
```pwsh
scoop install ss
```

These are some examples of its capabilites:

</br>

- Search for all the packages with more than one word in the name or description:
```pwsh
ss scoop search fast
```
- Search for an app in which the app name contains both 'nvidia' AND 'driver'
```pwsh
ss -n nvidia driver 
```
- Simple search for the **ss** app
```pwsh
ss -s ss 
```
- Returns apps containing 'tool' and, 'nvidia' or 'radeon'
```pwsh
ss -n "nvidia|radeon" tool
```
- Get the manifests of the latests version of scoop search utilities
```pwsh
ss -l search scoop
```
- Full extended regex support. Latests versions of apps ending in 'ss' starting with 's'
```pwsh
ss -n -l -e ss$ ^s 
```
- UTF-8 search of all the apps containing the word 音乐 (music) in the description.
```pwsh
ss -l 音乐 
```
- stores in the `$apps` variable a PSObject with all the Scoop manifests — more than 52,000.
```pwsh
$apps = ss -r .* 
```

</br>

**How do I contribute new manifests?**
-------------------------------------------

</br>

The data in this repo is generated automatically from the rest of the buckets in internet. If you want your app to be indexed by the database and be available in the **ScoopMaster** Bucket, or you find a problem with an app, just modify any other bucket and the app will be updated in the next bucket and database snapshot within 30 minutes.

To make a new manifest contribution in any other bucket, please read the [Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md).

