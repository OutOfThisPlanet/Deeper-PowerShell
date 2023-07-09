Function Deeper-Session
{
    param([string]$Password, [string]$IPAddress)
    $ErrorActionPreference = "Stop"

    Function Get-EncryptedString #inputstring
    {
        param([string]$String)
    
        if (($PSVersionTable.PSVersion).Major -le 6)
        {
            Write-Host "This will only work on PowerShell 7." -ForegroundColor Red
            break
        }
        else
        {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
            $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
            $publicKeyFile = "deeper-new.pem"
            $rsa.ImportFromPem([string](Get-Content $publicKeyFile))
            $encryptedData = $rsa.Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA1)
            $encryptedPassword = [System.Convert]::ToBase64String($encryptedData)
            $encryptedPassword
        }
    }

    Function Get-LoginPassword #password
    {
        param([string]$LoginPassword)
        if (!($LoginPassword))
        {
            $PlaintextPassword = Read-Host "Please enter your Deeper login Password" -AsSecureString | ConvertFrom-SecureString -AsPlaintext
            Get-EncryptedString -String $PlaintextPassword
        }
        else
        {
            $PlaintextPassword = $LoginPassword
            Get-EncryptedString -String $PlaintextPassword
        }
    }

    Function Get-LoginToken #IPAddress EncryptedLoginPassword (String that has been through the above 2 functions)
    {
        param([string]$IPAddress, [string]$EncryptedLoginPassword)
        ((Invoke-WebRequest -UseBasicParsing -Uri "http://$($IPAddress)/api/admin/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body "{`"username`":`"admin`",`"password`":`"$EncryptedLoginPassword`"}"  |
                Select-Object -ExpandProperty Content) | ConvertFrom-Json | Select-Object token).token
    }

    $EncryptedPassword = Get-LoginPassword -LoginPassword $Password
    $Token = Get-LoginToken -IPAddress $IPAddress -EncryptedLoginPassword $EncryptedPassword
    $Token
}   

Function Send-DPR
{
    param([string]$IPAddress, [string]$Recepient, [int]$DPRAmount, $Token, [string]$WalletPassword)
        
    Function Deeper-Wallet
    {
        param([string]$WalletPassword)

        Function Get-EncryptedString 
        {
            param([string]$String)
    
            if (($PSVersionTable.PSVersion).Major -le 6)
            {
                Write-Host "This will only work on PowerShell 7." -ForegroundColor Red
                break
            }
            else
            {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
                $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
                $publicKeyFile = "deeper-new.pem"
                $rsa.ImportFromPem([string](Get-Content $publicKeyFile))
                $encryptedData = $rsa.Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA1)
                $encryptedPassword = [System.Convert]::ToBase64String($encryptedData)
                $encryptedPassword
            }
        }

        Function Get-WalletPassword
        {
            param([string]$WalletPassword)

            if (!($WalletPassword))
            {
                $WalletPassword = Read-Host "Please enter your Deeper Wallet Password" -AsSecureString | ConvertFrom-SecureString -AsPlaintext
                Get-EncryptedString -String $WalletPassword
            }
            else
            {
                Get-EncryptedString -String $WalletPassword
            }
        }

        $EncryptedPassword = Get-WalletPassword -WalletPassword $WalletPassword
        $EncryptedPassword
    }     

    $EncryptedWalletPassword = Deeper-Wallet -IPAddress $IPAddress -WalletPassword $WalletPassword
    
    Write-Host "Sending $DPRAmount DPR to $Recepient" -ForegroundColor Yellow

    (Invoke-WebRequest -UseBasicParsing -Uri "http://$IPAddress/api/betanet/transfer" `
        -Method POST `
        -Headers @{"Authorization" = $Token} `
        -ContentType "application/json" `
        -Body "{`"recipient`":`"$Recipient`",`"amount`":$DPRAmount,`"password`":`"$EncryptedWalletPassword`"}"  |
            Select-Object -ExpandProperty Content) | ConvertFrom-Json
}

Function Get-Values
{
    param ([string]$IPAddress, $Token)
    $ErrorActionPreference = "SilentlyContinue"
    $URI = "http://$($IPAddress)/api"
    $Uptime = (Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/info" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json)[0]
    $BalanceAndCredit = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getBalanceAndCredit" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Traffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/microPayment/getDailyTraffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Network = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/network-address" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Hardware = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/hardware-info" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Version = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/get-latestversion" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Transactions = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getTransactionList" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty list
    $Keys = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/wallet/getKeyPair" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $DPRPrice = ((Invoke-WebRequest -UseBasicParsing -Uri "https://www.kucoin.com/_api/currency/v2/prices?base=USD&lang=en_US&targets=" | Select-Object Content).content | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object DPR).DPR
    $SharingEnabled = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/sharing/getSharingConfig" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty SharingEnabled 
    $WorkingMode = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/wifi/workingInfo" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty workingInfo | Select-Object -ExpandProperty mode
    $LocalTraffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/traffic/total-traffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty localTraffic
    $ClientTraffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/traffic/total-traffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty clientTraffic
    $ServerTraffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/traffic/total-traffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty serverTraffic

    $Now = (Get-Date).ToUniversalTime() | Get-Date -Format "dd/MM/yyyy hh:mm:ss"

    if ($Version.currentVersion -like "*dep*")
    {
        $DEPWorkProof = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/workProof" -Headers @{"Authorization" = $Token} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Content | ConvertFrom-Json
    }
    else
    {
        $DEPWorkProof = $Null
    }

    Function Get-Deeper
    {
        param ([string]$WalletAddress)
    
        $Staked =  @()
    
        #Endpoints
        $StakedEndpoint = "https://staking.deeper.network/api/wallet/deeperChain/detail?deeperChain=$($WalletAddress)"
        $StatusEndpoint = "https://www.deeperscan.io/api/v1/deeper/staking_delegate_count?addr=$($WalletAddress)"
       
        #Staking Values
        $Values = Invoke-RestMethod -Uri $StakedEndpoint | 
            Select-Object bsc, bscv2, eth, credit

        [decimal]$BSC = $Values.bsc
        [decimal]$DSC = $Values.bscV2
        [decimal]$ETH = $Values.eth
        $StakedDPR = ($BSC + $DSC + $ETH)/[math]::Pow(10,18)
        
        $Type = Invoke-RestMethod -Uri $StatusEndpoint | 
            Select-Object staking_status 

        #Object Creation
        $GetStaked = `
        [ordered]@{
            "Staked" = $StakedDPR
            "Type" = $Type.staking_status
        }
        $Staked += $GetStaked
        $Staked
    }

    try
    {
        $Scrape = Get-Deeper -WalletAddress $Keys.publicKey
        $Staked = $Scrape.Staked
        $Type = $Scrape.Type
    }
    catch
    {
        $Staked = "Unavailable"
        $Type = "Unavailable"
    }

    #Last Reward Date
    $LastRewardDate = (Get-Date ([System.DateTimeOffset]::FromUnixTimeMilliSeconds(($Transactions | 
            Where-Object {$_.type -eq "staking.DelegatorReward"} | 
            Select-Object -Last 1 | 
            Select-Object timestamp).timestamp).DateTime).ToString("s")).DateTime

    if ($LastRewardDate -like "*1970*" -or (!($LastRewardDate)))
    {
        $LastRewardDate = "Unavailable"
    }

    #Last Reward
    $LastReward = ($Transactions | 
                    Where-Object {$_.type -eq "staking.DelegatorReward"} | 
                    Select-Object -Last 1 | 
                    Select-Object amount).amount

    if (!($LastReward))
    {
        $LastReward = "Unavailable"
    }

    #Last NPOW Reward
    $LastNPOWReward = ($Transactions | 
                    Where-Object {$_.type -eq "staking.NpowMint"} | 
                    Select-Object -Last 1 | 
                    Select-Object amount).amount

    if (!($LastNPOWReward))
    {
        $LastNPOWReward = "Unavailable"
    }

    #Last NPOW Reward Date
    $LastNPOWRewardDate = (Get-Date ([System.DateTimeOffset]::FromUnixTimeMilliSeconds(($Transactions | 
        Where-Object {$_.type -eq "staking.NpowMint"} | 
        Select-Object -Last 1 | 
        Select-Object timestamp).timestamp).DateTime).ToString("s")).DateTime

    if ($LastNPOWRewardDate -like "*1970*" -or (!($LastNPOWRewardDate)))
    {
        $LastNPOWRewardDate = "Unavailable"
    }

    if ($NPOWProof -eq $null)
    {
        $NPOWProof = "Unavailable"

    }

    #NPOW Reward
    $NPOWReward = $DEPWorkProof.estimatedDprReward

    if ($NPOWReward -eq $null)
    {
        $NPOWReward = "Unavailable"
    }

    #CPU
    $CPUTemp = $Hardware.tempInCelsius
    if (!($CPUTemp))
    {
        $CPUTemp = "Unavailable"
    }

    $BytesRemaining = ($($Traffic.shared) - 10000000)

    #Output
    $Collection =  @()

    #Object Creation
    $CreateObject = `
    [ordered]@{
        "LocalIP" = $IPAddress
        "PublicIP" = $Network.pubIp
        "Address" = $Keys.publicKey
        "TokenTracking" = $Token.substring($Token.length - 9, 9)
        "Balance" = $BalanceAndCredit.balance
        "Credit" = $BalanceAndCredit.credit
        "CampaignID" = $BalanceAndCredit.campaignId
        "SharingEnabled" = $SharingEnabled
        "BytesRemaining" = $BytesRemaining
        "Shared" = $Traffic.shared
        "Consumed" = $Traffic.consumed
        "LocalTrafficUpload" = $LocalTraffic.Upload
        "LocalTrafficDownload" = $LocalTraffic.Download
        "ClientTrafficUpload" = $ClientTraffic.Upload
        "ClientTrafficDownload" = $ClientTraffic.Download
        "ServerTrafficUpload" = $ServerTraffic.Upload
        "ServerTrafficDownload" = $ServerTraffic.Download
        "WorkingMode" = $WorkingMode
        "SN" = $Hardware.SN
        "DeviceID" = $Hardware.deviceId
        "CPUCount" = $Hardware.cpuCount
        #"CPUModel" = $Hardware.cpuModel
        "CPUTemp" = $CPUTemp
        "TotalMem" = $Hardware.totalMem
        "Latest" = $Version.latestVersion
        "Current" = $Version.currentVersion
        "TotalStaked" = $Staked
        "StakingType" = $Type
        "RewardEstimate" = $NPOWReward
        "LastNPOWReward" = $LastNPOWReward 
        "LastNPOWRewardDate" = $LastNPOWRewardDate
        "LastReward" = $LastReward 
        "LastRewardDate" = $LastRewardDate
        "DPRPriceUSD" = [float]$DPRPrice
        "StakeValueUSD" = ($Staked * $DPRPrice)
        "DPRMillionaire" = (1000000 / $DPRPrice)
        "ThisSnapshotUTC" = $Now
        "Uptime" = $Uptime
        "UptimeDays" = [int]($Uptime.Split("d")[0])
        "UptimeHours" = [int](($Uptime).Split("d")[1].Split("h")[0])
        "UptimeMinutes" = [int](($Uptime).Split("d")[1].Split("h")[1].Split("m")[0])
    }
    $Collection += $CreateObject
    $Collection
}

Function Withdraw-NPOW
{
    param([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    Write-Host "Attempting to Withdraw NPOW Reward" -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/withdraw" -Headers @{"Authorization" = $Token} -Method POST -ErrorAction Stop | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object Success
}

Function Reboot-Device
{
    param([string]$IPAddress, $Token, [int]$Timeout)
    $URI = "http://$($IPAddress)/api"
    Write-Host "Rebooting Device" -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/admin/reboot" -Headers @{"Authorization" = $Token} -Method POST -TimeoutSec $Timeout | Out-Null
}

Function Turn-SharingOn
{
    param ([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    Write-Host "Turning Sharing On" -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/sharing/setSharingState"  -ContentType "application/json" -Headers @{"Authorization" = $Token} -Method POST -Body "{`"sharingEnabled`":true}" | Select-Object -ExpandProperty Content | ConvertFrom-Json 
}

Function Turn-SharingOff
{
    param ([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    Write-Host "Turning Sharing Off" -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/sharing/setSharingState"  -ContentType "application/json" -Headers @{"Authorization" = $Token} -Method POST -Body "{`"sharingEnabled`":false}" | Select-Object -ExpandProperty Content | ConvertFrom-Json 
}

$IPAddress = "192.168.22.199"
$Token = Deeper-Session -IPAddress $IPAddress

Get-Values -IPAddress $IPAddress -Token $Token

#Send DPR
$Recipient = "5C5kUhQsECAcr7VovYBn6kEUe87JmdXDX4uwu2XyNomPtAyU" #thank you :)
Send-DPR -IPAddress $IPAddress -Recepient $Recepient -DPRAmount 10 -Token $Token

#Withdrawl NPOW
Withdraw-NPOW -IPAddress $IPAddress -Token $Token

#Reboot Device
Reboot-Device -IPAddress $IPAddress -Token $Token

#Turn Sharing On
Turn-SharingOn -IPAddress $IPAddress -Token $Token

#Turn Sharing Off
Turn-SharingOff -IPAddress $IPAddress -Token $Token
