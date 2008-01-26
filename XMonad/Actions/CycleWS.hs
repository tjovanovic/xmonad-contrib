-----------------------------------------------------------------------------
-- |
-- Module      :  XMonad.Actions.CycleWS
-- Copyright   :  (c) Joachim Breitner <mail@joachim-breitner.de>,
--                    Nelson Elhage <nelhage@mit.edu> (`toggleWS' function)
-- License     :  BSD3-style (see LICENSE)
--
-- Maintainer  :  Joachim Breitner <mail@joachim-breitner.de>
-- Stability   :  unstable
-- Portability :  unportable
--
-- Provides bindings to cycle forward or backward through the list
-- of workspaces, and to move windows there, and to cycle between the screens.
--
-----------------------------------------------------------------------------

module XMonad.Actions.CycleWS (
                              -- * Usage
                              -- $usage
                              nextWS,
                              prevWS,
                              shiftToNext,
                              shiftToPrev,
                              toggleWS,
                              nextScreen,
                              prevScreen,
                              shiftNextScreen,
                              shiftPrevScreen
                             ) where

import Data.List ( findIndex )
import Data.Maybe ( fromMaybe )

import XMonad hiding (workspaces)
import XMonad.StackSet hiding (filter)
import XMonad.Util.WorkspaceCompare

-- $usage
-- You can use this module with the following in your @~\/.xmonad\/xmonad.hs@ file:
--
-- > import XMonad.Actions.CycleWS
--
-- >   , ((modMask x,               xK_Down),  nextWS)
-- >   , ((modMask x,               xK_Up),    prevWS)
-- >   , ((modMask x .|. shiftMask, xK_Down),  shiftToNext)
-- >   , ((modMask x .|. shiftMask, xK_Up),    shiftToPrev)
-- >   , ((modMask x,               xK_Right), nextScreen)
-- >   , ((modMask x,               xK_Left),  prevScreen)
-- >   , ((modMask x .|. shiftMask, xK_Right), shiftNextScreen)
-- >   , ((modMask x .|. shiftMask, xK_Left),  shiftPrevScreen)
-- >   , ((modMask x,               xK_t),     toggleWS)
--
-- If you want to follow the moved window, you can use both actions:
--
-- >   , ((modMask x .|. shiftMask, xK_Down), shiftToNext >> nextWS)
-- >   , ((modMask x .|. shiftMask, xK_Up),   shiftToPrev >> prevWS)
--
-- For detailed instructions on editing your key bindings, see
-- "XMonad.Doc.Extending#Editing_key_bindings".


-- | Switch to next workspace
nextWS :: X ()
nextWS = switchWorkspace 1

-- | Switch to previous workspace
prevWS :: X ()
prevWS = switchWorkspace (-1)

-- | Move focused window to next workspace
shiftToNext :: X ()
shiftToNext = shiftBy 1

-- | Move focused window to previous workspace
shiftToPrev :: X ()
shiftToPrev = shiftBy (-1)

-- | Toggle to the workspace displayed previously
toggleWS :: X ()
toggleWS = windows $ view =<< tag . head . hidden

switchWorkspace :: Int -> X ()
switchWorkspace d = wsBy d >>= windows . greedyView

shiftBy :: Int -> X ()
shiftBy d = wsBy d >>= windows . shift

wsBy :: Int -> X (WorkspaceId)
wsBy d = do
    ws <- gets windowset
    sort' <- getSortByTag
    let orderedWs = sort' (workspaces ws)
    let now = fromMaybe 0 $ findWsIndex (workspace (current ws)) orderedWs
    let next = orderedWs !! ((now + d) `mod` length orderedWs)
    return $ tag next

findWsIndex :: WindowSpace -> [WindowSpace] -> Maybe Int
findWsIndex ws wss = findIndex ((== tag ws) . tag) wss

-- | View next screen
nextScreen :: X ()
nextScreen = switchScreen 1

-- | View prev screen
prevScreen :: X ()
prevScreen = switchScreen (-1)

switchScreen :: Int -> X ()
switchScreen d = do s <- screenBy d
                    mws <- screenWorkspace s
                    case mws of
                         Nothing -> return ()
                         Just ws -> windows (view ws)

screenBy :: Int -> X (ScreenId)
screenBy d = do ws <- gets windowset
                --let ss = sortBy screen (screens ws)
                let now = screen (current ws)
                return $ (now + fromIntegral d) `mod` fromIntegral (length (screens ws))

-- | Move focused window to workspace on next screen
shiftNextScreen :: X ()
shiftNextScreen = shiftScreenBy 1

-- | Move focused window to workspace on prev screen
shiftPrevScreen :: X ()
shiftPrevScreen = shiftScreenBy (-1)

shiftScreenBy :: Int -> X ()
shiftScreenBy d = do s <- screenBy d
                     mws <- screenWorkspace s
                     case mws of
                         Nothing -> return ()
                         Just ws -> windows (shift ws)