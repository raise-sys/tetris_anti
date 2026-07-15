# --- Arcade Tetris Deployment Script ---
# This script automates:
# 1. Backing up C# source code to the 'main' branch of GitHub
# 2. Compiling the project in Release mode
# 3. Patching base-href and adding .nojekyll for GitHub Pages compatibility
# 4. Force-pushing static files to the 'gh-pages' branch

$ErrorActionPreference = "Stop"

# Repository URL
$repoUrl = "https://github.com/raise-sys/tetris_anti.git"

Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "  Arcade Tetris GitHub Deployer (PS)      " -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta

# --- Step 1: Manage Main Source Code Repo ---
Write-Host "`n[1/4] Syncing C# source code to main branch..." -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    Write-Host "Initializing new local git repository..." -ForegroundColor Yellow
    git init
    git remote add origin $repoUrl
    git branch -M main
} else {
    # Ensure correct remote URL
    $existingRemote = git remote get-url origin 2>$null
    if ($existingRemote -ne $repoUrl) {
        git remote remove origin 2>$null
        git remote add origin $repoUrl
        Write-Host "Updated git remote origin to: $repoUrl" -ForegroundColor Yellow
    }
}

# Commit source changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    git add -A
    git commit -m "Update Tetris C# WebAssembly source code and deployment assets"
    Write-Host "Committed local source changes." -ForegroundColor Green
} else {
    Write-Host "Source code is already up-to-date. No local changes to commit." -ForegroundColor Yellow
}

# Push source to main
Write-Host "Pushing source code to GitHub 'main' branch..." -ForegroundColor Cyan
git push -u origin main

# --- Step 2: Compile Blazor WebAssembly ---
Write-Host "`n[2/4] Publishing Blazor WebAssembly project..." -ForegroundColor Cyan
# Clean previous build directories
Remove-Item -Recurse -Force bin, obj, publish -ErrorAction SilentlyContinue

# Publish command
dotnet publish -c Release -o publish

# --- Step 3: Configure Build for GitHub Pages ---
Write-Host "`n[3/4] Customizing assets for GitHub Pages..." -ForegroundColor Cyan

$wwwroot = "publish/wwwroot"

# 1. Create .nojekyll to prevent Jekyll from blocking _framework folders
New-Item -ItemType File -Path "$wwwroot/.nojekyll" -Force | Out-Null
Write-Host "✓ Created .nojekyll" -ForegroundColor Green

# 2. Copy index.html to 404.html to handle custom client-side routing on page reloads
Copy-Item -Path "$wwwroot/index.html" -Destination "$wwwroot/404.html" -Force
Write-Host "✓ Copied index.html to 404.html" -ForegroundColor Green

# 3. Patch <base href="/" /> to <base href="/tetris_anti/" />
Write-Host "Modifying base href in index.html and 404.html..." -ForegroundColor Yellow
$indexPath = "$wwwroot/index.html"
$path404 = "$wwwroot/404.html"

(Get-Content $indexPath) -replace '<base href="/"\s*/>', '<base href="/tetris_anti/" />' | Set-Content $indexPath
(Get-Content $path404) -replace '<base href="/"\s*/>', '<base href="/tetris_anti/" />' | Set-Content $path404
Write-Host "✓ Patched base href to '/tetris_anti/'" -ForegroundColor Green

# --- Step 4: Deploy Static Files to gh-pages branch ---
Write-Host "`n[4/4] Deploying compiled assets to gh-pages branch..." -ForegroundColor Cyan

# Change directory to published assets folder
Push-Location $wwwroot

try {
    # Initialize a temporary git repository in the build folder
    git init
    git remote add origin $repoUrl
    git checkout -b gh-pages
    git add -A
    git commit -m "Deploy compiled Tetris WebAssembly to GitHub Pages"
    
    Write-Host "Force pushing static build to origin/gh-pages..." -ForegroundColor Yellow
    git push -f origin gh-pages
    
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL!                  " -ForegroundColor Green
    Write-Host "  Source code pushed to: main             " -ForegroundColor Green
    Write-Host "  Pages site deployed to: gh-pages        " -ForegroundColor Green
    Write-Host "  Live URL (available in a few mins):     " -ForegroundColor Green
    Write-Host "  https://raise-sys.github.io/tetris_anti/" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
}
finally {
    # Restore original working directory
    Pop-Location
}
