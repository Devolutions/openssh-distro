#!/usr/bin/env pwsh
#Requires -PSEdition Core

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({
        if ($_ -match '^\d+\.\d+\.\d+$') { $true }
        else { throw "Version must be in the format: X.Y.Z" }
    })]
    [string] $Version,
    [Parameter(Position=1)]
    [string] $OutputPath,
    [string] $TemporaryPath,
    [string] $UpstreamGitTag,
    [string] $DownstreamGitTag
)

if ($IsWindows) {
    throw "this script should be run from Linux"
}

$VersionParts = [Version] $Version
$MajorVersion = $VersionParts.Major
$MinorVersion = $VersionParts.Minor
$PatchVersion = $VersionParts.Build

$UpstreamGitRepo = "https://github.com/libressl/portable"
if ([string]::IsNullOrEmpty($UpstreamGitTag)) {
    $UpstreamGitTag = "v${Version}"
}

$DownstreamGitRepo = "https://github.com/PowerShell/LibreSSL"
if ([string]::IsNullOrEmpty($DownstreamGitTag)) {
    $DownstreamGitTag = "V${Version}.0"
}

if ([string]::IsNullOrEmpty($TemporaryPath)) {
    $TemporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) "libressl-git"
}

if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $TemporaryPath "libressl-patches"
}

# create temporary directory for upstream and downstream git repositories
New-Item -Path $TemporaryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Push-Location && Set-Location $TemporaryPath

# clone upstream libressl git repository, remove .git directory:
Remove-Item -Path libressl-upstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $UpstreamGitTag --depth 1 $UpstreamGitRepo libressl-upstream

# clone downstream libressl git repository, remove .git directory:
Remove-Item -Path libressl-downstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $DownstreamGitTag --depth 1 $DownstreamGitRepo libressl-downstream

# generate single patch file from upstream and downstream directories:
diff -ruN --exclude=.git libressl-upstream/ libressl-downstream/ > Win32-LibreSSL.patch

# generate a list of binary files which differ between upstream and downstream directories:
diff -ruN --exclude=.git libressl-upstream/ libressl-downstream/ | grep "^Binary files" |
    awk -F ' and ' '{split($1, a, " "); sub("^[^/]*/", "", a[3]); print a[3]}' > Win32-LibreSSL-bin.txt

# copy binary (non-textual) files from downstream to upstream directory
foreach($BinaryFile in (Get-Content ./Win32-LibreSSL-bin.txt)) {
    Write-Host "Copying binary file $BinaryFile"
    $DestinationFile = Join-Path (Get-Location) "libressl-upstream" $BinaryFile
    $DestinationPath = [System.IO.Path]::GetDirectoryName($DestinationFile)
    New-Item -Path $DestinationPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "./libressl-downstream/$BinaryFile" $DestinationFile -Force
}
#Remove-Item ./Win32-LibreSSL-bin.txt | Out-Null

# apply downstream Win32-LibreSSL patches on top of upstream LibreSSL repository
cd libressl-upstream
$Win32PatchBranch = "Win32-v${Version}"
git branch $Win32PatchBranch && git checkout $Win32PatchBranch
Get-Content ../Win32-LibreSSL.patch -Raw | patch -s -p1
Remove-Item ../Win32-LibreSSL.patch | Out-Null

# Create new commits from the applied changes
git add $(git ls-files -o --exclude-standard)
git commit -m "Win32-LibreSSL v${Version} added files"
git add -A
git commit -m "Win32-LibreSSL v${Version} modified files"
git format-patch -2
cd ..

New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Get-Item "$OutputPath/*v${Version}*.patch" | Remove-Item
Move-Item ./libressl-upstream/*.patch $OutputPath

Write-Host "Created Win32-LibreSSL v$Version patches on top of $UpstreamGitTag upstream git tag"
Write-Host "From your libressl local git repository, run the following to import them:"
Write-Host "git checkout $UpstreamGitTag"
Write-Host "git checkout -b v${Version}-patches"
Write-Host "git am --whitespace=nowarn $OutputPath/*v${Version}*.patch"

# Sample usage:
# ./Win32LibreSSLPatch.ps1 3.8.2
