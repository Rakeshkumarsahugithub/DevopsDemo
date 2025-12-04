# AWS CLI Verification Script

Write-Host ""
Write-Host "AWS CLI VERIFICATION" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI is installed!" -ForegroundColor Green
    Write-Host "Version: $awsVersion" -ForegroundColor Gray
    Write-Host ""
    
    # Check if configured
    try {
        $identity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "AWS CLI is configured!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your AWS Identity:" -ForegroundColor Cyan
            Write-Host $identity
            Write-Host ""
            Write-Host "You're ready to deploy to AWS!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next: Follow the deployment guide" -ForegroundColor Yellow
            Write-Host "notepad NEXT_STEPS_AFTER_GITHUB_PUSH.md" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "AWS CLI is installed but not configured" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Run this command to configure:" -ForegroundColor Cyan
            Write-Host "aws configure" -ForegroundColor White
            Write-Host ""
            Write-Host "You'll need:" -ForegroundColor Yellow
            Write-Host "- AWS Access Key ID" -ForegroundColor Gray
            Write-Host "- AWS Secret Access Key" -ForegroundColor Gray
            Write-Host "- Default region (us-east-1)" -ForegroundColor Gray
            Write-Host "- Default output format (json)" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {
        Write-Host "AWS CLI is installed but not configured" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Run: aws configure" -ForegroundColor Cyan
        Write-Host ""
    }
} catch {
    Write-Host "AWS CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Close this PowerShell window" -ForegroundColor White
    Write-Host "2. Open a NEW PowerShell window" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
}
