param(
  [string]$RepoPath = "D:\Code\mskaymaz\M_HaydiNamaza"
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archive = Join-Path $RepoPath "_archive_instruction_old\$stamp"
$packageRoot = Split-Path -Parent $PSScriptRoot

New-Item -ItemType Directory -Path $archive -Force | Out-Null

$rootMarkdownToArchive = @(
  "ADR.md", "ARCH_BASE.md", "BAGLAM.md", "BISMILLAH.md", "BOOT.md",
  "CLEANUP_PLAN.md", "CONVENTIONS.md", "DECISIONS.md", "ENTEGRASYON_HARITASI.md",
  "ENTEGRASYON_REHBERI.md", "FAZ_YOL_HARITASI.md", "FLOW.md", "HEDEF_MIMARI.md",
  "HISTORY.md", "ISTISARE.md", "KOMUT_SOZLUGU.md", "KURAL_KAYNAGI.md",
  "OPTIMIZE_POLITIKASI.md", "PLAN.md", "PROFIL_REHBERI.md", "PROTOKOL.md",
  "PUSH_LOG.md", "QUALITY_GATE.md", "RULES.md", "RUNBOOK.md", "SESSION.md",
  "TASK-*.md", "Tasks.md", "TEMIZLIK_POLITIKASI.md", "TOKEN_RULES.md",
  "UI_NOTES.md", "UI_SYSTEM.md", "WORKBOARD-1.md", "WORKBOARD.md", "chatKomut.md",
  "calisma_plani.md"
)

foreach ($pattern in $rootMarkdownToArchive) {
  Get-ChildItem -Path $RepoPath -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
    Move-Item -Path $_.FullName -Destination (Join-Path $archive $_.Name) -Force
  }
}

$foldersToArchive = @(
  "Besmele", "besmele", "BesmeleGenel", "ContextKit", "core", "rules", "flows",
  "plans", "sessions", "oturumlar", "hooks", "optional", "tools"
)

foreach ($folder in $foldersToArchive) {
  $path = Join-Path $RepoPath $folder
  if (Test-Path $path) {
    Move-Item -Path $path -Destination (Join-Path $archive $folder) -Force
  }
}

Copy-Item -Path (Join-Path $packageRoot "root\*") -Destination $RepoPath -Recurse -Force
Copy-Item -Path (Join-Path $packageRoot "Besmele") -Destination $RepoPath -Recurse -Force
Copy-Item -Path (Join-Path $packageRoot "docs") -Destination $RepoPath -Recurse -Force

Write-Host "Clean instruction structure applied."
Write-Host "Old instruction files archived at: $archive"
Write-Host "Next: run flutter analyze, then start Besmele/TASKS.md TASK-00."
