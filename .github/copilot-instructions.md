# Copilot Instructions for openssh-distro

## Project Overview

This repository maintains patches and packaging for a custom OpenSSH distribution. It bridges three layers:
1. **Upstream**: Official `openssh/openssh-portable` repository
2. **Microsoft Win32-OpenSSH**: `PowerShell/openssh-portable` with Windows-specific patches
3. **Devolutions patches**: Custom features like RDP preconnection blob and askpass named pipe support

## Repository Structure

- `scripts/` — PowerShell scripts to generate patches by diffing upstream vs Microsoft forks
- `patches/vX.Y.Z/` — Version-specific patch files, numbered for ordered application
- `package/` — Conan packaging and NuGet distribution files

## Patch Generation Workflow

All patch generation scripts **must run from Linux** (PowerShell Core required):

```bash
# Generate OpenSSH patches (most common)
./scripts/Win32OpenSSHPatch.ps1 9.5.0

# Generate LibreSSL patches
./scripts/Win32LibreSSLPatch.ps1 3.8.2

# Generate libfido2 patches  
./scripts/Win32LibFIDO2Patch.ps1 1.14.0
```

Scripts clone upstream + Microsoft repos, diff them, and output numbered `.patch` files.

## Patch Naming Convention

Patches are numbered for sequential `git am` application:
- `0001-*`, `0002-*` — Microsoft Win32-OpenSSH base patches (auto-generated)
- `0003-*` onwards — Devolutions-specific feature patches (manually maintained)

**Devolutions patches** in current versions:
- `add-rdp-preconnection-blob-support.patch` — Sends RDP preconnection PDU via `SSH_PCB` env var
- `add-askpass-named-pipe-support.patch` — Unix socket/named pipe askpass via `SSH_ASKPASS_NAMED_PIPE`
- `fix-openbsd-compat-layer-portability.patch` — Cross-platform compat fixes
- `add-cmake-build-system.patch` — CMake build alternative

## Applying Patches

After generating patches, apply them to a clean openssh-portable checkout:

```bash
git checkout V_9_5_P1  # upstream tag
git checkout -b v9.5.0-patches
git am --whitespace=nowarn /path/to/patches/*v9.5.0*.patch
```

## Key Conventions

- Version format is always `X.Y.Z` (e.g., `9.5.0`)
- Upstream OpenSSH tags use underscore format: `V_9_5_P1`
- Microsoft downstream tags use dot format: `v9.5.0.0`
- Devolutions patches should be portable across C compilers (MSVC, GCC, Clang)
- Use `#ifndef WINDOWS` / `#ifdef WINDOWS` for platform-specific code in patches
