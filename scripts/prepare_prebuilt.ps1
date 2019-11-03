. "$PSScriptRoot\helpers.ps1"

# 切换目录

Set-Location $projectDir
Write-Host "当前工程目录：$projectDir"

# 检查是否完整 Vcpkg

if ((Test-Path $vcpkgRoot) -and (-not (Test-VcpkgIsPrebuilt $vcpkgRoot)))
{
    Write-Failure "已经安装了完整的 Vcpkg，请不要混合使用 prepare.ps1 和 prepare_prebuilt.ps1"
    SafeExit 1
}

# 检查必要命令

if (-not (Get-Command -Name git -ErrorAction SilentlyContinue))
{
    Write-Failure "请先安装 Git，并确保 git 命令已添加到 PATH 环境变量"
    SafeExit 1
}

function Remove-TempDeps
{
    Remove-Item -Recurse -Force ./temp-deps -ErrorAction SilentlyContinue
}

if (-not (Test-Path $vcpkgRoot))
{
    Write-Host "预编译依赖未安装，即将安装……"

    Write-Host "正在克隆预编译依赖仓库……"
    Remove-TempDeps
    git clone --depth=1 https://github.com/richardchien/coolq-cpp-sdk-deps temp-deps

    Write-Host "正在解压预编译依赖……"
    Expand-Archive -Path ./temp-deps/vcpkg-export-*.zip -DestinationPath ./
    if ($?)
    {
        Write-Success "预编译依赖安装成功"
        Remove-TempDeps
    }
    else
    {
        Write-Failure "预编译依赖安装失败"
        Remove-TempDeps
        SafeExit 1
    }
}
else
{
    Write-Success "预编译依赖已安装，如需更新或重装，请删除工程目录下 vcpkg-export- 开头的文件夹后重新运行"
}

# 退出

SafeExit 0
