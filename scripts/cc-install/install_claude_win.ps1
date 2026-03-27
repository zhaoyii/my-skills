# ==========================================
# Claude Code Windows 一键安装脚本 (10808 代理版)
# ==========================================

# 1. 设置当前会话代理（匹配你的 10808 端口）
$proxy = "http://127.0.0.1:10808"
$env:HTTP_PROXY = $proxy
$env:HTTPS_PROXY = $proxy

Write-Host "已设置代理为: $proxy" -ForegroundColor Cyan

# 2. 强制启用 TLS 1.2 协议（防止旧版系统连接失败）
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# 3. 绕过 SSL 证书验证错误 (核心：解决之前的 certificate verification error)
Write-Host "正在配置临时证书绕过策略..." -ForegroundColor Yellow
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# 4. 执行官方安装脚本
Write-Host "开始从 Claude.ai 下载安装程序..." -ForegroundColor Green
irm https://claude.ai/install.ps1 | iex

# 5. 验证安装
Write-Host "`n--- 验证安装结果 ---" -ForegroundColor Cyan
if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude --version
    Write-Host "安装成功！现在输入 'claude' 即可开启 AI 编程之旅。" -ForegroundColor Green
} else {
    Write-Host "安装似乎未生效，请检查网络后重试。" -ForegroundColor Red
}