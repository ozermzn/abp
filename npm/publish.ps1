param(
  [string]$Version,
  [string]$Registry
)

npm install

$NextVersion = $(node publish-utils.js --nextVersion)
$RootFolder = (Get-Item -Path "./" -Verbose).FullName

if (-Not $Version) {
  $Version = $NextVersion;
}

if (-Not $Registry) {
  $Registry = "https://registry.npmjs.org";
}

$NgPacksPublishCommand = "npm run publish-packages -- --nextVersion $Version --skipGit --registry $Registry"
$PacksPublishCommand = "npm run lerna -- exec 'npm publish --registry $Registry'"
$UpdateGulpCommand = "npm run update-gulp"
$UpdateNgPacksCommand = "yarn update --registry $Registry"

$IsRc = $(node publish-utils.js --rc --customVersion $Version) -eq "true";



if ($IsRc) {
  $NgPacksPublishCommand += " --rc"
  $UpdateGulpCommand += " -- --rc"
  $PacksPublishCommand = $PacksPublishCommand.Substring(0, $PacksPublishCommand.Length - 1) + " --tag next'"
  $UpdateNgPacksCommand += " --rc"
}

$commands = (
  "npm run lerna -- version $Version --yes --no-commit-hooks --skip-git --force-publish",
  "npm run replace-with-tilde",
  $PacksPublishCommand,
  $UpdateNgPacksCommand,
  "cd ng-packs\scripts",
  "npm install",
  $NgPacksPublishCommand,
  "cd ../../",
  "cd scripts",
  "yarn",
  "yarn remove-lock-files",
  "cd ..",
  $UpdateGulpCommand
)

foreach ($command in $commands) { 
  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  Write-Host $command
  Invoke-Expression $command
  if ($LASTEXITCODE -ne '0' -And $command -notlike '*cd *') {
    Write-Host ("Process failed! " + $command)
    Set-Location $RootFolder
    exit $LASTEXITCODE
  }
  $timer.Stop()
  $total = $timer.Elapsed
  Write-Output "-------------------------"
  Write-Output "$command command took $total (Hours:Minutes:Seconds.Milliseconds)"
  Write-Output "-------------------------"
}