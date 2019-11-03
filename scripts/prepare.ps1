. "$PSScriptRoot\helpers.ps1"

# 切换目录

Set-Location $projectDir
Write-Host "当前工程目录：$projectDir"

# 检查是否预编译依赖

if (Test-VcpkgIsPrebuilt $vcpkgRoot)
{
    Write-Failure "已经安装了预编译依赖，请不要混合使用 prepare.ps1 和 prepare_prebuilt.ps1"
    SafeExit 1
}

# 检查必要命令

if (-not (Get-Command -Name git -ErrorAction SilentlyContinue))
{
    Write-Failure "请先安装 Git，并确保 git 命令已添加到 PATH 环境变量"
    SafeExit 1
}

# 检查 vcpkg

if (-not (Test-Path $vcpkgCmd))
{
    Write-Host "Vcpkg 未安装，即将安装……"
    Remove-Item -Recurse -Force $vcpkgRoot -ErrorAction SilentlyContinue

    Write-Host "正在克隆 vcpkg 仓库……"
    git clone https://github.com/Microsoft/vcpkg.git "$vcpkgRoot"

    Write-Host "正在构建 vcpkg……"
    & "$vcpkgRoot\bootstrap-vcpkg.bat"
    if ($?)
    {
        Write-Success "Vcpkg 构建成功"
    }
    else
    {
        Write-Failure "Vcpkg 构建失败"
        SafeExit 1
    }
}
else
{
    Write-Success "Vcpkg 已安装"
}

$vcpkgTripletPath = "$vcpkgRoot\triplets\$vcpkgTriplet.cmake"

if (-not (Test-Path $vcpkgTripletPath))
{
    Write-Host "正在创建 vcpkg triplet……"
    Copy-Item "$projectDir\cmake\$vcpkgTriplet.cmake" $vcpkgTripletPath
}
Write-Success "Vcpkg triplet 已创建"

# 检查依赖

Write-Host "正在检查依赖……"

$vcpkgCommit = Get-Content "$projectDir\vcpkg-commit.txt" -ErrorAction SilentlyContinue
if ($vcpkgCommit)
{
    git -C $vcpkgRoot fetch --depth=1 origin $vcpkgCommit
    git -C $vcpkgRoot checkout $vcpkgCommit -- ports
    if ($?)
    {
        Write-Success "Vcpkg 包版本已固定到 $vcpkgCommit"
    }
    else
    {
        Write-Failure "固定 vcpkg 包版本失败"
        SafeExit 1
    }
}

& "$vcpkgCmd" --vcpkg-root "$vcpkgRoot" remove --outdated
if ($?) { Write-Success "已移除过时的依赖" }

foreach ($package in Get-Content "$projectDir\vcpkg-requirements.txt")
{
    $package = $package.trim()
    if ($package)
    {
        Write-Host "正在安装依赖 $package……"
        & "$vcpkgCmd" --vcpkg-root "$vcpkgRoot" --triplet $vcpkgTriplet install $package
        if ($?)
        {
            Write-Success "依赖 $package 已安装"
        }
        else
        {
            Write-Failure "依赖 $package 安装失败"
            SafeExit 1
        }
    }
}

Write-Success "构建环境准备完成"

# 退出

SafeExit 0
