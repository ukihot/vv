module Support.IAM.Fixtures
    ( samplePendingUser
    , genUserId
    , genUserName
    , genEmail
    , shouldMakeUserId
    , shouldMakeUserName
    , shouldMakeEmail
    , shouldMakeRoleId
    , shouldMakeRoleName
    , shouldMakePermissionId
    , shouldMakePermissionName
    , shouldMakePermissionCode
    )
where

import Domain.IAM.Permission.ValueObjects.PermissionCode (PermissionCode, mkPermissionCode)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId, mkPermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionName (PermissionName, mkPermissionName)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId, mkRoleId)
import Domain.IAM.Role.ValueObjects.RoleName (RoleName, mkRoleName)
import Domain.IAM.User (User)
import Domain.IAM.User.Services.Factory (registerUser)
import Domain.IAM.User.ValueObjects.Email (Email, mkEmail)
import Domain.IAM.User.ValueObjects.UserId (UserId, mkUserId)
import Domain.IAM.User.ValueObjects.UserName (UserName, mkUserName)
import Domain.IAM.User.ValueObjects.UserState (UserState (Pending))
import Hedgehog (Gen)
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Text (fromStringText)
import Test.Tasty.HUnit (assertFailure)

samplePendingUser :: IO (User 'Pending)
samplePendingUser = do
    uid <- shouldMakeUserId "user-001"
    name <- shouldMakeUserName "Alice"
    email <- shouldMakeEmail "alice@example.com"
    pure (fst (registerUser uid name email))

genUserId :: Gen UserId
genUserId = do
    raw <- Gen.text (Range.linear 1 32) Gen.alphaNum
    either (fail . show) pure (mkUserId raw)

genUserName :: Gen UserName
genUserName = do
    raw <- Gen.text (Range.linear 1 32) Gen.alphaNum
    either (fail . show) pure (mkUserName raw)

genEmail :: Gen Email
genEmail = do
    localPart <- Gen.text (Range.linear 1 16) Gen.alphaNum
    domain <- Gen.text (Range.linear 1 12) Gen.alphaNum
    tld <- Gen.element ["com", "net", "org", "io"]
    either (fail . show) pure (mkEmail (localPart <> "@" <> domain <> "." <> tld))

shouldMakeUserId :: String -> IO UserId
shouldMakeUserId raw =
    either (assertFailure . ("invalid test user id: " <>) . show) pure (mkUserId (fromStringText raw))

shouldMakeUserName :: String -> IO UserName
shouldMakeUserName raw =
    either
        (assertFailure . ("invalid test user name: " <>) . show)
        pure
        (mkUserName (fromStringText raw))

shouldMakeEmail :: String -> IO Email
shouldMakeEmail raw = either (assertFailure . ("invalid test email: " <>) . show) pure (mkEmail (fromStringText raw))

shouldMakeRoleId :: String -> IO RoleId
shouldMakeRoleId raw =
    either (assertFailure . ("invalid test role id: " <>) . show) pure (mkRoleId (fromStringText raw))

shouldMakeRoleName :: String -> IO RoleName
shouldMakeRoleName raw =
    either
        (assertFailure . ("invalid test role name: " <>) . show)
        pure
        (mkRoleName (fromStringText raw))

shouldMakePermissionId :: String -> IO PermissionId
shouldMakePermissionId raw =
    either
        (assertFailure . ("invalid test permission id: " <>) . show)
        pure
        (mkPermissionId (fromStringText raw))

shouldMakePermissionName :: String -> IO PermissionName
shouldMakePermissionName raw =
    either
        (assertFailure . ("invalid test permission name: " <>) . show)
        pure
        (mkPermissionName (fromStringText raw))

shouldMakePermissionCode :: String -> IO PermissionCode
shouldMakePermissionCode raw =
    either
        (assertFailure . ("invalid test permission code: " <>) . show)
        pure
        (mkPermissionCode (fromStringText raw))
