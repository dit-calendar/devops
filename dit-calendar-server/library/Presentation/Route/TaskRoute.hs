module Presentation.Route.TaskRoute
    ( routeTask
    , routeTaskDetail
    , routeTaskWithUser
    ) where

import           Data.Aeson                             (eitherDecode)
import           Happstack.Server                       (Method (DELETE, GET, POST, PUT),
                                                         Response)

import           AppContext                             (App)
import           Auth.Authorization                     (callIfAuthorized)
import           Data.Domain.Types                      (EntryId, TaskId)
import           Presentation.Dto.Task                  as TaskDto (Task (..),
                                                                    validate)
import           Presentation.Dto.TelegramUserLink      as TelegramDto (TelegramUserLink (..),
                                                                        validate)
import           Server.HttpServerHelper                (getBody, getHttpMethod)
import           Server.ResponseBuilder                 (badRequest,
                                                         handleResponse,
                                                         notImplemented)

import qualified Presentation.Controller.TaskController as TaskController


routeTask :: EntryId -> App Response
routeTask entryId = do
    m <- getHttpMethod
    case m of
        POST -> do
            body <- getBody
            case validate (eitherDecode body :: Either String TaskDto.Task) of
                 Right taskDto -> TaskController.createTask entryId taskDto >>= handleResponse
                 Left errorMessage -> badRequest errorMessage
        GET -> callIfAuthorized (TaskController.calendarTasks entryId)
        other -> notImplemented other

routeTaskDetail :: EntryId ->  TaskId -> App Response
routeTaskDetail entryId taskId = do
    m <- getHttpMethod
    case m of
        GET -> TaskController.taskPage taskId >>= handleResponse
        PUT -> do
            body <- getBody
            case validate (eitherDecode body :: Either String TaskDto.Task) of
                  Right taskDto ->
                       callIfAuthorized (TaskController.updateTask taskId taskDto)
                  Left errorMessage -> badRequest errorMessage
        DELETE -> callIfAuthorized (TaskController.deleteTask entryId taskId)
        other  -> notImplemented other

routeTaskWithUser :: EntryId -> TaskId -> App Response
routeTaskWithUser entryId taskId = do
    m <- getHttpMethod
    case m of
        DELETE -> callIfAuthorized (TaskController.removeUserFromTask taskId)
        PUT    -> do
            body <- getBody
            case TelegramDto.validate (eitherDecode body :: Either String TelegramDto.TelegramUserLink) of
                  Right telegramDto ->
                       callIfAuthorized (TaskController.addUserToTask taskId telegramDto)
                  Left errorMessage -> badRequest errorMessage
        other  -> notImplemented other
