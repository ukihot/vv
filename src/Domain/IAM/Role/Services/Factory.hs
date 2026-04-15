module Domain.IAM.Role.Services.Factory
  ( createRole,
  )
where

import Domain.IAM.Role (Role (RoleD))
import Domain.IAM.Role.Entities.Profile (RoleProfile (..))
import Domain.IAM.Role.Events (RoleEventPayload (..))
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.Role.ValueObjects.RoleName (RoleName)
import Domain.IAM.Role.ValueObjects.RoleState (RoleState (Draft))
import Domain.IAM.Role.ValueObjects.Version (initialVersion)

createRole :: RoleId -> RoleName -> (Role 'Draft, RoleEventPayload)
createRole roleId roleName =
  let profile = RoleProfile roleName []
      role = RoleD roleId profile initialVersion
   in (role, RoleCreated roleId roleName)
