{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}

module Cardano.Wallet.API.V1.Handlers.Accounts where

import           Universum

import           Servant

import qualified Data.IxSet.Typed as IxSet

import           Cardano.Wallet.API.Request
import           Cardano.Wallet.API.Response
import qualified Cardano.Wallet.API.V1.Accounts as Accounts
import           Cardano.Wallet.API.V1.Types
import qualified Cardano.Wallet.Kernel.DB.Util.IxSet as KernelIxSet
import           Cardano.Wallet.WalletLayer (PassiveWalletLayer)
import qualified Cardano.Wallet.WalletLayer as WalletLayer

handlers :: PassiveWalletLayer IO -> ServerT Accounts.API Handler
handlers w =  deleteAccount w
         :<|> getAccount    w
         :<|> listAccounts  w
         :<|> newAccount    w
         :<|> updateAccount w
         :<|> getAccountAddresses w
         :<|> getAccountBalance w

deleteAccount :: PassiveWalletLayer IO
              -> WalletId
              -> AccountIndex
              -> Handler NoContent
deleteAccount layer wId accIdx = do
    res <- liftIO $ WalletLayer.deleteAccount layer wId accIdx
    case res of
         Left e   -> throwM e
         Right () -> return NoContent

-- | Fetches an 'Account' given its parent 'WalletId' and its index.
getAccount :: PassiveWalletLayer IO
           -> WalletId
           -> AccountIndex
           -> Handler (WalletResponse Account)
getAccount layer wId accIdx = do
    res <- liftIO $ WalletLayer.getAccount layer wId accIdx
    case res of
         Left e        -> throwM e
         Right account -> return $ single account

listAccounts :: PassiveWalletLayer IO
             -> WalletId
             -> RequestParams
             -> Handler (WalletResponse [Account])
listAccounts layer wId params = do
    res <- liftIO $ WalletLayer.getAccounts layer wId
    case res of
         Left e         -> throwM e
         Right accounts ->
            respondWith params
                (NoFilters :: FilterOperations Account)
                (NoSorts :: SortOperations Account)
                -- FIXME(adn) [CBR-347] We need to unify these two IxSet
                -- wrappers, but for now let's pay the full conversion price
                -- to get the feature shipped.
                (pure $ IxSet.fromList . KernelIxSet.toList $ accounts)

newAccount :: PassiveWalletLayer IO
           -> WalletId
           -> NewAccount
           -> Handler (WalletResponse Account)
newAccount layer wId newAccountRequest = do
    res <- liftIO $ WalletLayer.createAccount layer wId newAccountRequest
    case res of
         Left e        -> throwM e
         Right account -> return $ single account

updateAccount :: PassiveWalletLayer IO
              -> WalletId
              -> AccountIndex
              -> AccountUpdate
              -> Handler (WalletResponse Account)
updateAccount layer wId accIdx updateRequest = do
    res <- liftIO $ WalletLayer.updateAccount layer wId accIdx updateRequest
    case res of
         Left e -> throwM e
         Right updatedAccount ->
             return $ single updatedAccount

getAccountAddresses
    :: PassiveWalletLayer IO
    -> WalletId
    -> AccountIndex
    -> RequestParams
    -> FilterOperations WalletAddress
    -> Handler (WalletResponse AccountAddresses)
getAccountAddresses _layer _wId _accIdx _pagination _filters =
    error "unimplemented, see [CBR-366]"

getAccountBalance
    :: PassiveWalletLayer IO
    -> WalletId
    -> AccountIndex
    -> Handler (WalletResponse AccountBalance)
getAccountBalance _layer _wId _accIdx =
    error "unimplemented, see [CBR-366]"
