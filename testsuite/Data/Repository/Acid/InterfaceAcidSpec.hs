module Data.Repository.Acid.InterfaceAcidSpec (spec) where

import Test.Hspec
import Data.Maybe                 ( isJust, fromJust, isNothing)
import Data.Acid                  ( AcidState, query, update )

import Data.Repository.Acid.DataBaseHelper   ( initDatabase )
import Data.Repository.Acid.CalendarAcid  as CalendarAcid
import Data.Domain.CalendarEntry          as CalendarEntry
import qualified Data.Repository.Acid.InterfaceAcid      as   InterfaceAcid


withDatabaseConnection :: (AcidState CalendarAcid.EntryList -> IO ()) -> IO ()
withDatabaseConnection = initDatabase CalendarEntry{ CalendarEntry.description="Foo", CalendarEntry.entryId=0, userId=0, calendarTasks=[] }

spec :: Spec
spec =
    around withDatabaseConnection $
        context "CalendarEntry" $ do
          describe "create" $ do
              it "new and check existence" $
                \c -> do
                  entryList   <- query c GetEntryList
                  let calendarEntry = CalendarEntry { CalendarEntry.description="Zahnarzt", CalendarEntry.entryId=0, userId=0, calendarTasks=[] }
                  _           <- update c (NewEntry calendarEntry)
                  entryState  <- query c $ CalendarAcid.EntryById $ InterfaceAcid.nextEntryId entryList
                  entryState `shouldSatisfy` isJust
                  fromJust entryState `shouldBe` CalendarEntry{ description="Zahnarzt", entryId=InterfaceAcid.nextEntryId entryList, userId=0, calendarTasks=[]}

              it "new and check nextEntryId" $
                \c -> do
                  entryList    <- query c GetEntryList
                  let oldId    = InterfaceAcid.nextEntryId entryList
                  let calendarEntry = CalendarEntry { CalendarEntry.description="Zahnarzt", CalendarEntry.entryId=0, userId=1, calendarTasks=[] }
                  _            <- update c (NewEntry calendarEntry)
                  entryList    <- query c GetEntryList
                  InterfaceAcid.nextEntryId entryList `shouldBe` oldId + 1
                  let calendarEntry = CalendarEntry { CalendarEntry.description="Zahnarzt2", CalendarEntry.entryId=0, userId=1, calendarTasks=[] }
                  _            <- update c (NewEntry calendarEntry)
                  entryState  <- query c $ CalendarAcid.EntryById (oldId + 1)
                  entryState `shouldSatisfy` isJust
                  fromJust entryState `shouldBe` CalendarEntry{ description="Zahnarzt2", entryId=oldId + 1, userId=1, calendarTasks=[]}

          describe "find" $
              it "by EntryId" $
                \c -> do
                  entryState   <- query c $ CalendarAcid.EntryById 0
                  entryState `shouldSatisfy` isJust
                  fromJust entryState `shouldBe` CalendarEntry{ description="Foo", entryId=0, userId=0, calendarTasks=[] }

          describe "delete" $
              it "create/delete Entry and check existence" $
                \ c -> do 
                  entryList <- query c GetEntryList
                  let calendarEntry = CalendarEntry { CalendarEntry.description="Zahnarzt", CalendarEntry.entryId=0, userId=1, calendarTasks=[] }
                  _ <- update c (NewEntry calendarEntry)
                  entryState <- update c $ CalendarAcid.DeleteEntry $ InterfaceAcid.nextEntryId entryList
                  entryList <- query c GetEntryList
                  entryState <- query c $ CalendarAcid.EntryById $ InterfaceAcid.nextEntryId entryList
                  entryState `shouldSatisfy` isNothing

          describe "update" $
              it "change attributes and check changes" $
                \c -> do
                  entryList   <- query c GetEntryList
                  let eId = InterfaceAcid.nextEntryId entryList
                  let calendarEntry = CalendarEntry { CalendarEntry.description="Termin 1", CalendarEntry.entryId=0, userId=2, calendarTasks=[] }
                  _           <- update c (NewEntry calendarEntry)
                  entryState  <- query c $ CalendarAcid.EntryById eId
                  let updatedEntry = (fromJust entryState) {description = "Termin 2"}
                  _           <- update c $ CalendarAcid.UpdateEntry updatedEntry
                  entryState  <- query c $ CalendarAcid.EntryById eId
                  entryState `shouldSatisfy` isJust
                  fromJust entryState `shouldBe` CalendarEntry{ description="Termin 2", entryId=eId, userId=2, calendarTasks=[]}
