{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE TemplateHaskell    #-}

module Data.Domain.User
    ( User(..)
    ) where

import           Data.Data         (Data, Typeable)
import           Data.SafeCopy     (base, deriveSafeCopy)
import           Data.Text         (Text)

import           Data.Domain.Types (Entry (..), EntryId, TaskId, UserId)

data User = User
    { name            :: Text
    , userId          :: UserId
    , calendarEntries :: [EntryId]
    , belongingTasks  :: [TaskId]
    } deriving (Eq, Ord, Read, Show, Data, Typeable)

$(deriveSafeCopy 0 'base ''User)

instance Entry User where
    setId user newId = user {userId = newId}
    getId = userId
