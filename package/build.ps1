
$ErrorActionPreference = "Stop"

function Import-ConanPackage {
    Param(
        $Version = "9.5.0"
    )

    @(
        'windows-x86_64',
        'windows-arm64',
        'macos-x86_64',
        'macos-arm64',
        'linux-x86_64',
        'linux-arm64'
    ) | ForEach-Object {
        $Env:CONAN_IMPORT_PACKAGE="openssh/${Version}@devolutions/stable"
        & conan install . -pr $_ -s build_type=Release
    }
}

$CmdVerbs = @('import')

if ($args.Count -lt 1) {
    throw "not enough arguments!"
}

$CmdVerb = $args[0]
$CmdArgs = $args[1..$args.Count]

if ($CmdVerbs -NotContains $CmdVerb) {
    throw "invalid verb $CmdVerb, use one of: [$($CmdVerbs -Join ',')]"
}

switch ($CmdVerb) {
    "import" { Import-ConanPackage @CmdArgs }
}
