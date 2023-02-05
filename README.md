# Scoop Master Bucket



This is THE bucket to rule them all. It is a meta-bucket for **[Scoop](https://scoop.sh)**, the Windows command-line package manager. It takes the manifests from all the rest of known buckets and maintains a bucket with the most recent version of each known package.

It takes the list of buckets in the **[Scoop Directory](https://rasa.github.io/scoop-directory)**.

How do I install these manifests?
---------------------------------

To add this bucket, run 
```pwsh
scoop bucket add .Scoop https://github.com/okibcn/ScoopMaster
```
To install any app in the bucket do 
```
scoop install <app_name>
```

How do I contribute new manifests?
----------------------------------

To make a new manifest contribution, please read the [Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md).

