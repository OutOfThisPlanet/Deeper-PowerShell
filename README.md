This script contains some PowerShell functions to query and interact with a Deeper Connect device.

Requires PowerShell 7! This will not work on Windows PowerShell (5). 

`Get-EncryptedString` encrypts a string using the deeper.pem public key. This is used to encrypt the login password and the wallet password.  

`Get-LoginPassword` asks for the login password, and sends it to get encrypted

`Get-WalletPassword` asks for the wallet password, and sends it to get encrypted

`Get-LoginToken` holds the authenticated session token, and is needed for all other functions below. Requires Deeper device IP Address, and the encrypted login string 

`Send-DPR` can send DPR from your wallet to an on-chain address

`Get-Values` Grabs information about the deeper device

`Withdraw-NPOW` Requests that the NPOW rewards are withdrawn

`Reboot-Device` reboots the device. 
