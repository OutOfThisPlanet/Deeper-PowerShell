This script contains some PowerShell functions to query and interact with a Deeper Connect device.

NOTE: public key has changed in the new release, and has broken this script.

Requires PowerShell 7! This will not work on Windows PowerShell (5), and I haven't tested PowerShell 6. 

`Get-EncryptedString` encrypts a string using the deeper.pem public key. This is used to encrypt the login password and the wallet password.  

`Get-LoginPassword` asks for the login password, and sends it to get encrypted

`Get-WalletPassword` asks for the wallet password, and sends it to get encrypted

`Get-LoginToken` gets the authenticated session token, and is needed for all other functions below. Requires Deeper device IP Address, and the encrypted login string 

Example: `$Token = Get-LoginToken -IPAddress "192.168.1.111" -EncryptedLoginPassword (Get-LoginPassword)`

`Send-DPR` can send DPR from your wallet to an on-chain address

Example: `Send-DPR -IPAddress "192.168.1.111" -Recepient "5C5kUhQsECAcr7VovYBn6kEUe87JmdXDX4uwu2XyNomPtAyU" -DPRAmount 100 -Token $Token -EncryptedWalletPassword (Get-WalletPassword)`

`Get-Values` Grabs information about the deeper device

Example: `Get-Values -IPAddress "192.168.1.111" -Token $Token`

`Withdraw-NPOW` Requests that the NPOW rewards are withdrawn

Example: `Withdraw-NPOW -IPAddress "192.168.1.111" -Token $Token`

`Reboot-Device` reboots the device. 

Example: `Reboot-Device -IPAddress "192.168.1.111" -Token $Token`
