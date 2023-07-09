This script contains some PowerShell functions to query and interact with a Deeper Connect device.

It also gathers some info from online resources. 

I have also added the ability to turn sharing on or off.

NOTE: Deeper Network have changed their public and private keys (which is good, and I applaud them for doing so). 

Requires PowerShell 7! This will not work on Windows PowerShell (5), and I haven't tested PowerShell 6. 

After loading the functions, you can use them as shown in the picture below. 

![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/2177feaa-d007-4cf5-bca9-f95b7f3e3727)

If you do not supply a password when you run the "Deeper-Session" function, you will be asked to type it in. 
Same goes for when you run the "Send-DPR" function. 

![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/78d5bafa-654e-47c5-a640-7fb8f9e3bced)

The values from the powershell script can be exported to JSON, and consumed by HomeAssistant (out of scope for this repo, but worth mentioning).

For fun, I calculated how much DPR would need to cost per token for you to be a millionaire (based from your staked amount).

I also calculated how many many DPR tokens you need at today's price for you to be a millionaire.

![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/06b713c0-8cdb-4e63-a1c0-12a1ccbdb22a)

I like Home Assistant :)

![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/36ff3fe0-8257-42db-a8e0-3bda4f0efeae)
![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/578798ac-bf0d-47b0-826f-f23e8525d3e1)
![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/d272c585-f6fd-4717-af91-84e57bb593c9)
![image](https://github.com/OutOfThisPlanet/Deeper-PowerShell/assets/42836083/d93e51ef-5cdc-4ab3-8a12-fede68414267)


