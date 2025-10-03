# Deploy Firebase Storage Rules

Write-Host "🔥 Deploying Firebase Storage Rules..." -ForegroundColor Cyan

# Check if Firebase CLI is installed
try {
    firebase --version | Out-Null
    Write-Host "✅ Firebase CLI detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g firebase-tools
}

# Deploy storage rules
Write-Host "📤 Deploying storage rules..." -ForegroundColor Cyan
firebase deploy --only storage

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Storage rules deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 You can now upload profile pictures!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Refresh your app (F5)" -ForegroundColor White
    Write-Host "2. Go to Profile Settings" -ForegroundColor White
    Write-Host "3. Try uploading a profile picture" -ForegroundColor White
    Write-Host "4. Check browser console for success logs" -ForegroundColor White
} else {
    Write-Host "❌ Deployment failed. Trying to login..." -ForegroundColor Red
    firebase login
    Write-Host "📤 Retrying deployment..." -ForegroundColor Cyan
    firebase deploy --only storage
}
