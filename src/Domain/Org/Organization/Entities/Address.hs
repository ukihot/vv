module Domain.Org.Organization.Entities.Address
    ( Address (..)
    )
where

import Data.Text (Text)

data Address = Address
    { addressCountry :: Text,
      addressPostalCode :: Text,
      addressState :: Maybe Text,
      addressCity :: Text,
      addressStreet :: Text,
      addressBuilding :: Maybe Text
    }
    deriving (Show, Eq)
