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

$UpstreamGitRepo = "https://github.com/Yubico/libfido2"
if ([string]::IsNullOrEmpty($UpstreamGitTag)) {
    $UpstreamGitTag = "${Version}"
}

$DownstreamGitRepo = "https://github.com/PowerShell/libfido2"
if ([string]::IsNullOrEmpty($DownstreamGitTag)) {
    $DownstreamGitTag = "${Version}"
}

if ([string]::IsNullOrEmpty($TemporaryPath)) {
    $TemporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) "libfido2-git"
}

if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $TemporaryPath "libfido2-patches"
}

# create temporary directory for upstream and downstream git repositories
New-Item -Path $TemporaryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Push-Location && Set-Location $TemporaryPath

# clone upstream libfido2 git repository, remove .git directory:
Remove-Item -Path libfido2-upstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $UpstreamGitTag --depth 1 $UpstreamGitRepo libfido2-upstream

# clone downstream libfido2 git repository, remove .git directory:
Remove-Item -Path libfido2-downstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $DownstreamGitTag --depth 1 $DownstreamGitRepo libfido2-downstream

# generate single patch file from upstream and downstream directories:
diff -ruN --exclude=.git libfido2-upstream/ libfido2-downstream/ > Win32-libfido2.patch

# generate a list of binary files which differ between upstream and downstream directories:
diff -ruN --exclude=.git libfido2-upstream/ libfido2-downstream/ | grep "^Binary files" |
    awk -F ' and ' '{split($1, a, " "); sub("^[^/]*/", "", a[3]); print a[3]}' > Win32-libfido2-bin.txt

# copy binary (non-textual) files from downstream to upstream directory
foreach($BinaryFile in (Get-Content ./Win32-libfido2-bin.txt)) {
    Write-Host "Copying binary file $BinaryFile"
    $DestinationFile = Join-Path (Get-Location) "libfido2-upstream" $BinaryFile
    $DestinationPath = [System.IO.Path]::GetDirectoryName($DestinationFile)
    New-Item -Path $DestinationPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "./libfido2-downstream/$BinaryFile" $DestinationFile -Force
}
#Remove-Item ./Win32-libfido2-bin.txt | Out-Null

# apply downstream Win32-libfido2 patches on top of upstream libfido2 repository
cd libfido2-upstream
$Win32PatchBranch = "Win32-v${Version}"
git branch $Win32PatchBranch && git checkout $Win32PatchBranch
Get-Content ../Win32-libfido2.patch -Raw | patch -s -p1
Remove-Item ../Win32-libfido2.patch | Out-Null

# Create new commits from the applied changes
git add $(git ls-files -o --exclude-standard)
git commit -m "Win32-libfido2 v${Version} added files"
git add -A
git commit -m "Win32-libfido2 v${Version} modified files"
git format-patch -2
cd ..

New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Get-Item "$OutputPath/*v${Version}*.patch" | Remove-Item
Move-Item ./libfido2-upstream/*.patch $OutputPath

Write-Host "Created Win32-libfido2 v$Version patches on top of $UpstreamGitTag upstream git tag"
Write-Host "From your libfido2 local git repository, run the following to import them:"
Write-Host "git checkout $UpstreamGitTag"
Write-Host "git checkout -b v${Version}-patches"
Write-Host "git am --whitespace=nowarn $OutputPath/*v${Version}*.patch"

# Sample usage:
# ./Win32LibFIDO2Patch.ps1 1.14.0
