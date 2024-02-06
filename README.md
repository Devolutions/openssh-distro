# Devolutions OpenSSH

## Distribution Repositories

[Devolutions/openssh-distro](https://github.com/Devolutions/openssh-distro):
This repository, contains scripts and patches to be applied on top of clean OpenSSH upstream releases.

[PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH):
Microsoft repository for the Win32-OpenSSH distribution. Used only for releases and submitting issues.

## OpenSSH Patches

[openssh/openssh-portable](https://github.com/openssh/openssh-portable): 
Official OpenSSH upstream repository on top of which we apply Microsoft and Devolutions patches.

[PowerShell/openssh-portable](https://github.com/PowerShell/openssh-portable)
Microsoft Win32-OpenSSH downstream fork containing all Windows-specific patches not accepted upstream.

Use the `Win32OpenSSHPatch.ps1` script from Linux to generate Microsoft patches which can be applied on top of the upstream repository:

```bash
./scripts/Win32OpenSSHPatch.ps1 9.5.0
```

## LibreSSL Patches

[libressl/portable](https://github.com/libressl/portable):
Official LibreSSL upstream repository on top of which we apply Microsoft patches.

[PowerShell/LibreSSL](https://github.com/PowerShell/LibreSSL):
Microsoft repository for the Win32-OpenSSH LibreSSL downstream fork with patches.

Use the `Win32LibreSSLPatch.ps1` script from Linux to generate Microsoft patches which can be applied on top of the upstream repository:

```bash
./scripts/Win32LibreSSLPatch.ps1 3.8.2
```

## libfido2 Patches

[Yubico/libfido2](https://github.com/Yubico/libfido2):
Official libfido2 upstream repository from Yubico on top of which we apply Microsoft patches.

[PowerShell/libfido2](https://github.com/PowerShell/libfido2):
Microsoft repository for the Win32-OpenSSH libfido2 downstream fork with patches.

Use the `Win32LibFIDO2Patch.ps1` script from Linux to generate Microsoft patches which can be applied on top of the upstream repository:

```bash
./scripts/Win32LibFIDO2Patch.ps1 1.14.0
```

In the case of libfido2, the changes from Microsoft are fairly minimal.
