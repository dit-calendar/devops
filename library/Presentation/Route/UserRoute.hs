module Presentation.Route.UserRoute
    ( routeUser
    , routeDetailUser
    , routeUsers
    ) where

import           Data.Aeson                                 (decode)
import           Data.Text                                  (pack)
import           Happstack.Server                           (Method (DELETE, GET, POST, PUT),
                                                             Response, look,
                                                             mapServerPartT)

import           Auth.Authorization                         (callIfAuthorized)
import           Data.Domain.Types                          (UserId)
import           Presentation.AcidHelper                    (App)
import           Presentation.HttpServerHelper              (getHttpMethod, getBody)
import           Presentation.ResponseHelper                (badRequest, notImplemented, okResponse)
import           Presentation.Dto.User                      as UserDto (User (..))

import qualified Presentation.Controller.CalendarController as CalendarController
import qualified Presentation.Controller.UserController     as UserController
import qualified Presentation.Dto.CalendarEntry as CalendarDto

routeUsers :: App Response
routeUsers = do
    m <- getHttpMethod
    case m of
        GET -> UserController.usersPage

routeUser :: UserId -> App Response
routeUser userId = do
    m <- getHttpMethod
    case m of
        GET -> UserController.userPage userId

routeDetailUser :: App Response
routeDetailUser = do
    m <- getHttpMethod
    case m of
        PUT -> do
              body <- getBody
              case decode body :: Maybe UserDto.User of
                  Just userDto ->
                        callIfAuthorized (UserController.updateUser userDto)
                  Nothing -> badRequest "Could not parse"
        DELETE -> callIfAuthorized UserController.deleteUser
        -- curl -X POST -d "name=FooBar" http://localhost:8000/user/me
        POST -> do
            body <- getBody
            case decode body :: Maybe CalendarDto.CalendarEntry of
                Just newCalendar -> callIfAuthorized (CalendarController.createCalendarEntry newCalendar)
                Nothing -> badRequest "Could not parse"
        other -> notImplemented other
