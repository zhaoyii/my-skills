param(
    [Parameter(Mandatory=$false)]
    [string]$Title = "通知",

    [Parameter(Mandatory=$false)]
    [string]$Message = "内容"
)

# 强制 UTF-8（避免中文乱码）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 检查 BurntToast 是否存在
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    try {
        Install-Module -Name BurntToast -Force -Scope CurrentUser -ErrorAction Stop
    } catch {
        Write-Error "BurntToast 安装失败，请手动执行（管理员权限）: Install-Module BurntToast"
        exit 1
    }
}

# 加载模块
Import-Module BurntToast

# 发送通知
New-BurntToastNotification -Text $Title, $Message