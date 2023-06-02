![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/d4f51b04-5dee-4962-b1b6-ed6b884f5728)

This script queries a Deeper Connect device, and some web apis to grab some details. 
It also attempts to withdraw any NPOW rewards that have accrued.

Usage (PowerShell 7 and up): 

`QueryDeeperDevice -IPAddress '192.168.1.111' -WithdrawLimit 50 -Password 'password'`


Usage (PowerShell 5): 

`QueryDeeperDevice -IPAddress '192.168.1.111' -WithdrawLimit 50 # you need to add the password hash to the file`

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
This is an example hash for "password", and is included in the script :
 . `hQ3qipNI2qgdoq5pfxi5ezjG2WqXQxrVi0B4CUcAcTEsIYAZ3hpNHm2a28gHcMKH3UcLBDIrEIiU0R5udHxfLrAEW/UPmrC73NfRfEq8TUVDhFWNja4xuyrDFH2Cfyg2cpKKP5lYBZAjj6eU16K6d9DTzo++XMQ/1M0o+V78GkK7R4TPQiWpncGmCAEe3NIq5Indc8EbBvJLEk7YBAG1tBofFfwlpYMKawAWYVo2RfIEbUkUgDpIgS7u3k2YBlchFjaTeMs7/xnHJjkJD2+YMLp/uoPDgzjiijb+GQPnBzOmQNw5JKCxTmVv45iwvYcMV7aLXFGwvxOBrJsHr1U/FAMe8Eyh2k0j54GSlOk2IV7Y/1BJSPdN3A1/Wb/kkS0QW2ns+8PN2Q3QDTNDBvK1w0AGIs2RiT/4fS/VAdRxtdvXbhRl+MUKYnzmzJBJ75QDtqdpcxtHh7FlQFyfoEO+IyIeJhtIopOeAolHUMiUyQqFrDFelMh5Tj5PS2kTxMOO7B5xTvOMcfMxdQok5PUMcJ7X/AqQFYhXleTZev7otl943y2acZBY48VITi98t+aPLSttsDAhSfqvdgdwFt6UgokeCJhye/cd60MMyxcrtp6HnJyVhql1eXSaPXhIxm4Bgd4nf/wJXP4LPetlnzZCp0JCPVV7qA7NdIW8lRow0p8=`

