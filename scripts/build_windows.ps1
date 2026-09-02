# Build a self-contained static meshoptimizer library for Windows (x64) with MSVC.
# Expects meshoptimizer checked out at ./meshoptimizer and a Visual Studio
# developer environment (cl.exe / lib.exe on PATH, e.g. via ilammy/msvc-dev-cmd).
# Output: build/meshopt_windows.lib
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (Test-Path obj) { Remove-Item -Recurse -Force obj }
New-Item -ItemType Directory -Force -Path obj, build | Out-Null

# /MD  : dynamic UCRT, matching Odin's default Windows linkage
# /GR- : no RTTI
# /Zc:threadSafeInit- : no thread-safe static init guards (no C++ runtime dep)
$flags = @("/nologo", "/std:c++14", "/O2", "/GR-", "/Zc:threadSafeInit-", "/MD", "/c")

$objs = @()
Get-ChildItem meshoptimizer/src/*.cpp | ForEach-Object {
	$obj = "obj/$($_.BaseName).obj"
	Write-Host "compiling $($_.Name)"
	& cl @flags $_.FullName "/Fo$obj"
	if ($LASTEXITCODE -ne 0) { throw "cl failed on $($_.Name)" }
	$objs += $obj
}

Write-Host "compiling shim.cpp"
& cl @flags scripts/shim.cpp "/Foobj/shim.obj"
if ($LASTEXITCODE -ne 0) { throw "cl failed on shim.cpp" }
$objs += "obj/shim.obj"

& lib /nologo /OUT:build/meshopt_windows.lib $objs
if ($LASTEXITCODE -ne 0) { throw "lib failed" }
Write-Host "built build/meshopt_windows.lib"
