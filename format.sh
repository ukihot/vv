#!/bin/bash

# Format Haskell files with explicit language extensions
find . -name '*.hs' -print0 | xargs -0 fourmolu \
  --ghc-opt=-XImportQualifiedPost \
  --ghc-opt=-XLambdaCase \
  --ghc-opt=-XMultiWayIf \
  --ghc-opt=-XOverloadedStrings \
  --ghc-opt=-XOverloadedRecordDot \
  --ghc-opt=-XRecordWildCards \
  --ghc-opt=-XDerivingStrategies \
  --ghc-opt=-XDeriveAnyClass \
  --ghc-opt=-XDataKinds \
  --ghc-opt=-XTypeFamilies \
  --ghc-opt=-XGADTs \
  --ghc-opt=-XViewPatterns \
  --ghc-opt=-XPatternSynonyms \
  --ghc-opt=-XStrictData \
  --mode inplace