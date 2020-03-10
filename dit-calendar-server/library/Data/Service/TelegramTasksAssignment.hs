{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE MonoLocalBinds       #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Data.Service.TelegramTasksAssignment (deleteTaskFromAllTelegramLinksImpl, addTelegramLinkToTaskImpl, removeTelegramLinkFromTaskImpl, TelegramTasksAssignmentService(..) ) where

import           Control.Monad.IO.Class
import           Data.Generics.Aliases    (orElse)
import           Data.List                (delete)
import           Data.Maybe               (fromJust)

import           AppContext               (App)
import           Data.Domain.Task         as Task
import           Data.Domain.TelegramLink as TelegramLink
import           Data.Domain.Types        (EitherResult)

import           Data.Repository.TelegramLinkRepo (MonadDBTelegramRepo)
import           Data.Repository.TaskRepo (MonadDBTaskRepo)
import qualified Data.Repository.TaskRepo as TaskRepo
import qualified Data.Repository.TelegramLinkRepo as TelegramRepo



deleteTaskFromAllTelegramLinksImpl :: (MonadIO m, MonadDBTelegramRepo m) =>
                        Task -> m ()
deleteTaskFromAllTelegramLinksImpl task =
    foldr (\ x ->
      (>>) (do
        telegramLink <- TelegramRepo.findTelegramLinkById x
        TelegramRepo.deleteTaskFromTelegramLink (fromJust telegramLink) task ))
    (return ()) $ Task.assignedTelegramLinks task

addTelegramLinkToTaskImpl :: (MonadDBTaskRepo m, MonadDBTelegramRepo m, MonadIO m) =>
                Task -> TelegramLink -> m (EitherResult Task)
addTelegramLinkToTaskImpl task telegramLink =
    if taskId task `elem` assignedTelegramLinks task
    then return (Right task) -- do nothing and return same task
    else do
        TelegramRepo.addTaskToTelegramLinkImpl telegramLink task
        TaskRepo.updateTask task {assignedTelegramLinks = TelegramLink.chatId telegramLink : assignedTelegramLinks task}

removeTelegramLinkFromTaskImpl :: (MonadDBTaskRepo m) =>
                    Task -> TelegramLink -> m (EitherResult Task)
removeTelegramLinkFromTaskImpl task user = undefined
    --do
    --  MonadDBUserRepo.deleteTaskFromUser user task
    --  TaskRepo.updateTask task {assignedUsers = delete (User.userId user) (assignedUsers task)}

class Monad m => TelegramTasksAssignmentService m where
    deleteTaskFromAllTelegramLinks :: Task -> m ()
    addTelegramLinkToTask :: Task -> TelegramLink -> m (EitherResult Task)
    removeTelegramLinkFromTask :: Task -> TelegramLink -> m (EitherResult Task)

instance (MonadDBTaskRepo App, MonadDBTelegramRepo App)
            => TelegramTasksAssignmentService App where
    deleteTaskFromAllTelegramLinks = deleteTaskFromAllTelegramLinksImpl
    addTelegramLinkToTask = addTelegramLinkToTaskImpl
    removeTelegramLinkFromTask = removeTelegramLinkFromTaskImpl
