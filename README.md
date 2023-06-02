![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/d4f51b04-5dee-4962-b1b6-ed6b884f5728)

This script queries a Deeper Connect device, and some web apis to grab some details. 
It also attempts to withdraw any NPOW rewards that have accrued.

Usage: 

`QueryDeeperDevice -IPAddress '192.168.1.111' -WithdrawLimit 50 -Password 'password'`

If you are using PowerShell Core (Version 7) on Windows, Linux, or whatever, you only need to pass the admin password to login.

If you are using Windows PowerShell (Version 5), this script requires a working password hash to login. 

You can get the working password hash from your browser developer tools. 

1) Open your dev tools in your browser (F12)
2) Navigate to the "Network" tab
3) Login to the deeper device
4) In the network trace, find the entry with the "File" called "login"
5) In the developer tools "Network" tab's the right pane, copy the password hash
6) Add the password hash to the script

![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/252afe6c-089f-4866-a01d-51f47185d849)
This is the hash for "password". 

