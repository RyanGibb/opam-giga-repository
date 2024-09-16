import qualified Data.Text as T
import Distribution.CabalSpecVersion
import Distribution.Simple.PackageDescription
import Distribution.Text (display)
import Distribution.Types.CondTree
import Distribution.Types.ConfVar
import Distribution.Types.Dependency
import Distribution.Types.GenericPackageDescription
import Distribution.Types.PackageDescription
import Distribution.Types.PackageId
import Distribution.Types.PackageName
import Distribution.Types.VersionInterval
import Distribution.Utils.ShortText
import System.Environment
import System.Exit

toOpamDep :: Dependency -> String
toOpamDep (Dependency name versionRange _) =
  "\"cabal-" ++ unPackageName name ++ "\"" ++ intervals constraints
  where
    constraints = asVersionIntervals versionRange

    lowerBoundStr :: Bound -> String
    lowerBoundStr ExclusiveBound = ">"
    lowerBoundStr InclusiveBound = ">="

    upperBoundStr :: Bound -> String
    upperBoundStr ExclusiveBound = "<"
    upperBoundStr InclusiveBound = "<="

    interval :: VersionInterval -> String
    interval x =
      case x of
        (VersionInterval (LowerBound lowerVersion lowerBound) (UpperBound upperVersion upperBound)) -> lowerBoundStr lowerBound ++ " \"" ++ display lowerVersion ++ "\" & " ++ upperBoundStr upperBound ++ " \"" ++ display upperVersion ++ "\""
        (VersionInterval (LowerBound lowerVersion lowerBound) NoUpperBound) -> lowerBoundStr lowerBound ++ " \"" ++ display lowerVersion ++ "\""

    intervals_rec :: [VersionInterval] -> String
    intervals_rec [x] = interval x
    intervals_rec (x : xs) = interval x ++ " | " ++ intervals_rec xs

    intervals :: [VersionInterval] -> String
    intervals [] = ""
    intervals l = " {" ++ intervals_rec l ++ "}"

extractDeps :: GenericPackageDescription -> [Dependency]
extractDeps genDesc = extractConditionTree $ condLibrary genDesc

extractConditionTree :: Maybe (CondTree ConfVar [Dependency] a) -> [Dependency]
extractConditionTree Nothing = []
extractConditionTree (Just (CondNode _ deps _)) = deps

escapeQuotes :: String -> String
escapeQuotes s = T.unpack (T.replace (T.pack "\"") (T.pack "\\\"") (T.pack s))

cabal2opam :: GenericPackageDescription -> String
cabal2opam genDesc =
  let pkg = packageDescription genDesc
      packageId = package pkg
      name = pkgName packageId
      version = pkgVersion packageId
      author_str = escapeQuotes (fromShortText (author pkg))
      maintainer_str = fromShortText (maintainer pkg)
      homepage_str = fromShortText (homepage pkg)
      license_str = show (license pkg)
      deps = unlines . map (("  " ++) . toOpamDep) . extractDeps $ genDesc
   in unlines
        [ "opam-version: \"2.0\"",
          "maintainer: \"" ++ maintainer_str ++ "\"",
          "authors: \"" ++ author_str ++ "\"",
          "homepage: \"" ++ homepage_str ++ "\"",
          "bug-reports: \"" ++ homepage_str ++ "\"",
          "dev-repo: \"" ++ homepage_str ++ "\"",
          -- "license: \"" ++ license_str ++ "\"",
          "depends: [",
          deps ++ "]"
        ]

main :: IO ()
main = do
  args <- getArgs
  case args of
    [cabalFile] -> do
      genDesc <- readGenericPackageDescription maxBound cabalFile
      putStrLn $ cabal2opam genDesc
    _ -> die "Usage: cabal2opam [FILE]"
