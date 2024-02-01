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

# https://github.com/PowerShell/Win32-OpenSSH/issues/1929

if ($IsWindows) {
    throw "this script should be run from Linux"
}

$VersionParts = [Version] $Version
$MajorVersion = $VersionParts.Major
$MinorVersion = $VersionParts.Minor
$PatchVersion = $VersionParts.Build
$PatchNumber = "P$($PatchVersion + 1)"

$UpstreamGitRepo = "https://github.com/openssh/openssh-portable"
if ([string]::IsNullOrEmpty($UpstreamGitTag)) {
    $UpstreamGitTag = "V_${MajorVersion}_${MinorVersion}_${PatchNumber}"
}

$DownstreamGitRepo = "https://github.com/PowerShell/openssh-portable"
if ([string]::IsNullOrEmpty($DownstreamGitTag)) {
    $DownstreamGitTag = "v${Version}.0"
}

if ([string]::IsNullOrEmpty($TemporaryPath)) {
    $TemporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) "openssh-git"
}

if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $TemporaryPath "openssh-patches"
}

# create temporary directory for upstream and downstream git repositories
New-Item -Path $TemporaryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Push-Location && Set-Location $TemporaryPath

# clone upstream openssh-portable git repository, remove .git directory:
Remove-Item -Path openssh-upstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $UpstreamGitTag --depth 1 $UpstreamGitRepo openssh-upstream

# clone downstream openssh-portable git repository, remove .git directory:
Remove-Item -Path openssh-downstream -Recurse -Force -ErrorAction SilentlyContinue
git clone -b $DownstreamGitTag --depth 1 $DownstreamGitRepo openssh-downstream

# generate single patch file from upstream and downstream directories:
diff -ruN --exclude=.git openssh-upstream/ openssh-downstream/ > Win32-OpenSSH.patch

# apply downstream Win32-OpenSSH patches on top of upstream OpenSSH repository
cd openssh-upstream
$Win32PatchBranch = "Win32-v${Version}"
git branch $Win32PatchBranch && git checkout $Win32PatchBranch
Get-Content ../Win32-OpenSSH.patch -Raw | patch -s -p1
Remove-Item ../Win32-OpenSSH.patch | Out-Null
git add $(git ls-files -o --exclude-standard)
git commit -m "Win32-OpenSSH v${Version} added files"
git add -A
git commit -m "Win32-OpenSSH v${Version} modified files"
git format-patch -2
cd ..

New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Get-Item "$OutputPath/*v${Version}*.patch" | Remove-Item
Move-Item ./openssh-upstream/*.patch $OutputPath

Write-Host "Created Win32-OpenSSH v$Version patches on top of $UpstreamGitTag upstream git tag"
Write-Host "From your openssh-portable local git repository, run the following to import them:"
Write-Host "git checkout $UpstreamGitTag"
Write-Host "git checkout -b v${Version}-patches"
Write-Host "git am --whitespace=nowarn $OutputPath/*v${Version}*.patch"

# Sample usage:
# ./Win32OpenSSHPatch.ps1 8.9.0
# ./Win32OpenSSHPatch.ps1 9.5.0 /tmp/openssh-patches
