{- | イベントの Text シリアライズ
persistent の payload カラム（Text）への変換。
JSON を使わず、シンプルな show/read ベースで実装する。
本番では aeson に差し替えること。
-}
module Infra.Write.Serialise (
    encodeUserEvent,
    decodeUserEvent,
    encodeRoleEvent,
    decodeRoleEvent,
    encodePermissionEvent,
    decodePermissionEvent,
) where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.Permission.Events (PermissionEventPayload (..))
import Domain.IAM.Permission.ValueObjects.PermissionCode (mkPermissionCode, unPermissionCode)
import Domain.IAM.Permission.ValueObjects.PermissionId (mkPermissionId, unPermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionName (mkPermissionName, unPermissionName)
import Domain.IAM.Role.Events (RoleEventPayload (..))
import Domain.IAM.Role.ValueObjects.RoleId (mkRoleId, unRoleId)
import Domain.IAM.Role.ValueObjects.RoleName (mkRoleName, unRoleName)
import Domain.IAM.User.Events (
    UserEventPayload (..),
    UserEventPayloadV1 (..),
    UserEventPayloadV2 (..),
 )
import Domain.IAM.User.ValueObjects.Email (mkEmail, unEmail)
import Domain.IAM.User.ValueObjects.UserId (mkUserId, unUserId)
import Domain.IAM.User.ValueObjects.UserName (mkUserName, unUserName)
import Infra.Write.Schema (PermissionEvent (..), RoleEvent (..), UserEvent (..))

-- ─────────────────────────────────────────────────────────────────────────────
-- User
-- ─────────────────────────────────────────────────────────────────────────────

encodeUserEvent :: UserEventPayload -> (Text, Text)
encodeUserEvent (V1 (UserRegistered uid name email)) =
    ("UserRegistered", T.intercalate "|" [unUserId uid, unUserName name, unEmail email])
encodeUserEvent (V1 (UserActivated uid)) =
    ("UserActivated", unUserId uid)
encodeUserEvent (V2 (UserSuspended uid)) =
    ("UserSuspended", unUserId uid)
encodeUserEvent (V2 (UserUnsuspended uid)) =
    ("UserUnsuspended", unUserId uid)
encodeUserEvent (V2 (UserDeactivated uid reason)) =
    ("UserDeactivated", T.intercalate "|" [unUserId uid, reason])
encodeUserEvent (V2 (UserEmailCorrected uid email)) =
    ("UserEmailCorrected", T.intercalate "|" [unUserId uid, unEmail email])
encodeUserEvent (V2 (UserNameCorrected uid name)) =
    ("UserNameCorrected", T.intercalate "|" [unUserId uid, unUserName name])
encodeUserEvent (V2 (UserRoleAssigned uid rid)) =
    ("UserRoleAssigned", T.intercalate "|" [unUserId uid, unRoleId rid])
encodeUserEvent (V2 (UserRoleRevoked uid rid)) =
    ("UserRoleRevoked", T.intercalate "|" [unUserId uid, unRoleId rid])

decodeUserEvent :: UserEvent -> [UserEventPayload]
decodeUserEvent row =
    case (userEventEventType row, T.splitOn "|" (userEventPayload row)) of
        ("UserRegistered", [uid, name, email]) ->
            case (mkUserId uid, mkUserName name, mkEmail email) of
                (Right u, Right n, Right e) -> [V1 (UserRegistered u n e)]
                _ -> []
        ("UserActivated", [uid]) ->
            case mkUserId uid of
                Right u -> [V1 (UserActivated u)]
                _ -> []
        ("UserSuspended", [uid]) ->
            case mkUserId uid of
                Right u -> [V2 (UserSuspended u)]
                _ -> []
        ("UserUnsuspended", [uid]) ->
            case mkUserId uid of
                Right u -> [V2 (UserUnsuspended u)]
                _ -> []
        ("UserDeactivated", [uid, reason]) ->
            case mkUserId uid of
                Right u -> [V2 (UserDeactivated u reason)]
                _ -> []
        ("UserEmailCorrected", [uid, email]) ->
            case (mkUserId uid, mkEmail email) of
                (Right u, Right e) -> [V2 (UserEmailCorrected u e)]
                _ -> []
        ("UserNameCorrected", [uid, name]) ->
            case (mkUserId uid, mkUserName name) of
                (Right u, Right n) -> [V2 (UserNameCorrected u n)]
                _ -> []
        ("UserRoleAssigned", [uid, rid]) ->
            case (mkUserId uid, mkRoleId rid) of
                (Right u, Right r) -> [V2 (UserRoleAssigned u r)]
                _ -> []
        ("UserRoleRevoked", [uid, rid]) ->
            case (mkUserId uid, mkRoleId rid) of
                (Right u, Right r) -> [V2 (UserRoleRevoked u r)]
                _ -> []
        _ -> []

-- ─────────────────────────────────────────────────────────────────────────────
-- Role
-- ─────────────────────────────────────────────────────────────────────────────

encodeRoleEvent :: RoleEventPayload -> (Text, Text)
encodeRoleEvent (RoleCreated rid name) =
    ("RoleCreated", T.intercalate "|" [unRoleId rid, unRoleName name])
encodeRoleEvent (RoleActivated uid rid) =
    ("RoleActivated", T.intercalate "|" [unUserId uid, unRoleId rid])
encodeRoleEvent (RoleDeactivated uid rid) =
    ("RoleDeactivated", T.intercalate "|" [unUserId uid, unRoleId rid])
encodeRoleEvent (PermissionAssignedToRole uid rid pid) =
    ("PermissionAssignedToRole", T.intercalate "|" [unUserId uid, unRoleId rid, unPermissionId pid])
encodeRoleEvent (PermissionRevokedFromRole uid rid pid) =
    ("PermissionRevokedFromRole", T.intercalate "|" [unUserId uid, unRoleId rid, unPermissionId pid])

decodeRoleEvent :: RoleEvent -> [RoleEventPayload]
decodeRoleEvent row =
    case (roleEventEventType row, T.splitOn "|" (roleEventPayload row)) of
        ("RoleCreated", [rid, name]) ->
            case (mkRoleId rid, mkRoleName name) of
                (Right r, Right n) -> [RoleCreated r n]
                _ -> []
        ("RoleActivated", [uid, rid]) ->
            case (mkUserId uid, mkRoleId rid) of
                (Right u, Right r) -> [RoleActivated u r]
                _ -> []
        ("RoleDeactivated", [uid, rid]) ->
            case (mkUserId uid, mkRoleId rid) of
                (Right u, Right r) -> [RoleDeactivated u r]
                _ -> []
        ("PermissionAssignedToRole", [uid, rid, pid]) ->
            case (mkUserId uid, mkRoleId rid, mkPermissionId pid) of
                (Right u, Right r, Right p) -> [PermissionAssignedToRole u r p]
                _ -> []
        ("PermissionRevokedFromRole", [uid, rid, pid]) ->
            case (mkUserId uid, mkRoleId rid, mkPermissionId pid) of
                (Right u, Right r, Right p) -> [PermissionRevokedFromRole u r p]
                _ -> []
        _ -> []

-- ─────────────────────────────────────────────────────────────────────────────
-- Permission
-- ─────────────────────────────────────────────────────────────────────────────

encodePermissionEvent :: PermissionEventPayload -> (Text, Text)
encodePermissionEvent (PermissionDefined pid name code) =
    ( "PermissionDefined"
    , T.intercalate "|" [unPermissionId pid, unPermissionName name, unPermissionCode code]
    )
encodePermissionEvent (PermissionActivated uid pid) =
    ("PermissionActivated", T.intercalate "|" [unUserId uid, unPermissionId pid])
encodePermissionEvent (PermissionRetired uid pid) =
    ("PermissionRetired", T.intercalate "|" [unUserId uid, unPermissionId pid])

decodePermissionEvent :: PermissionEvent -> [PermissionEventPayload]
decodePermissionEvent row =
    case (permissionEventEventType row, T.splitOn "|" (permissionEventPayload row)) of
        ("PermissionDefined", [pid, name, code]) ->
            case (mkPermissionId pid, mkPermissionName name, mkPermissionCode code) of
                (Right p, Right n, Right c) -> [PermissionDefined p n c]
                _ -> []
        ("PermissionActivated", [uid, pid]) ->
            case (mkUserId uid, mkPermissionId pid) of
                (Right u, Right p) -> [PermissionActivated u p]
                _ -> []
        ("PermissionRetired", [uid, pid]) ->
            case (mkUserId uid, mkPermissionId pid) of
                (Right u, Right p) -> [PermissionRetired u p]
                _ -> []
        _ -> []
