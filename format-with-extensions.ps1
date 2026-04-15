# PowerShell script to format Haskell files with explicit language extensions
# Run this from the project root directory

$extensions = @(
    "-XImportQualifiedPost",
    "-XLambdaCase", 
    "-XMultiWayIf",
    "-XOverloadedStrings",
    "-XOverloadedRecordDot",
    "-XRecordWildCards",
    "-XDerivingStrategies",
    "-XDeriveAnyClass",
    "-XDataKinds",
    "-XTypeFamilies",
    "-XGADTs",
    "-XViewPatterns",
    "-XPatternSynonyms",
    "-XStrictData"
)

# Build the ghc-opt arguments
$ghcOpts = $extensions | ForEach-Object { "--ghc-opt=$_" }

# Find all .hs files and format them
Get-ChildItem -Recurse -Filter "*.hs" | ForEach-Object {
    Write-Host "Formatting $($_.FullName)"
    & fourmolu --mode inplace @ghcOpts $_.FullName
}