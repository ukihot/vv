module Domain.IFRS.Provision.ValueObjects.ProvisionId
    ( ProvisionId (..)
    , mkProvisionId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Provision.Errors (ProvisionError (..))

newtype ProvisionId = ProvisionId {unProvisionId :: Text}
    deriving (Show, Eq, Ord)

mkProvisionId :: Text -> Either ProvisionError ProvisionId
mkProvisionId t
    | T.null t = Left InvalidProvisionId
    | otherwise = Right (ProvisionId t)
