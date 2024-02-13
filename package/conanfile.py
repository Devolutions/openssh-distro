from conans import ConanFile
import os

class DevolutionsTie(ConanFile):
    settings = 'os', 'arch', 'build_type'

    def build_requirements(self):
        import_package = os.getenv("CONAN_IMPORT_PACKAGE", "")
        self.build_requires(import_package)

    def imports(self):
        dotnet_os = {'Windows':'win','Macos':'osx','Linux':'linux'}[str(self.settings.os)]
        dotnet_arch = {'x86':'x86','x86_64':'x64','armv8':'arm64'}[str(self.settings.arch)]
        import_dir = 'runtimes/%s-%s/native' % (dotnet_os, dotnet_arch)
        self.copy("ssh.exe", dst=import_dir, src="bin")
        self.copy("ssh", dst=import_dir, src="bin")
