Function EncryptString 
{
    param([string]$String)
    
    if (($PSVersionTable.PSVersion).Major -le 6)
    {
        Write-Host "This will only work on PowerShell 7." -ForegroundColor Red
        break
    }
    else
    {
        $publicKeyFile = "deeper.pem"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
        $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
        $rsa.ImportFromPem([string](Get-Content $publicKeyFile))
        $encryptedData = $rsa.Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA1)
        $encryptedPassword = [System.Convert]::ToBase64String($encryptedData)
        $encryptedPassword
    }
}

Function Get-LoginPassword
{
    param([string]$LoginPassword)
    if (!($LoginPassword))
    {
        $PlaintextPassword = Read-Host "Please enter your Deeper login Password" -AsSecureString | ConvertFrom-SecureString -AsPlaintext
    }
    EncryptString -String $PlaintextPassword
}

Function Get-WalletPassword
{
    param([string]$WalletPassword)
    if (!($WalletPassword))
    {
        $PlaintextPassword = Read-Host "Please enter your Deeper wallet Password" -AsSecureString | ConvertFrom-SecureString -AsPlaintext
    }
    EncryptString -String $PlaintextPassword
}

Function Get-LoginToken
{
    param([string]$IPAddress, [string]$EncryptedLoginPassword)
    ((Invoke-WebRequest -UseBasicParsing -Uri "http://$($IPAddress)/api/admin/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body "{`"username`":`"admin`",`"password`":`"$EncryptedLoginPassword`"}"  |
            Select-Object -ExpandProperty Content) | ConvertFrom-Json | Select-Object token).token
}

#Session Variables
$IPAddress = "192.168.22.199"
$LoginPassword = Get-LoginPassword
$Token = Get-LoginToken -IPAddress $IPAddress -EncryptedLoginPassword $LoginPassword

Function Send-DPR
{
    param([string]$IPAddress, [string]$Recepient, [string]$EncryptedWalletPassword, [int]$DPRAmount, $Token)
    Write-Host "Sending $DPRAmount DPR to $Recepient" -ForegroundColor Green

    (Invoke-WebRequest -UseBasicParsing -Uri "http://$IPAddress/api/betanet/transfer" `
        -Method POST `
        -Headers @{"Authorization" = $Token} `
        -ContentType "application/json" `
        -Body "{`"recipient`":`"$Recipient`",`"amount`":$DPRAmount,`"password`":`"$EncryptedWalletPassword`"}"  |
            Select-Object -ExpandProperty Content) | ConvertFrom-Json
}

#Sending
$Recipient = "5C5kUhQsECAcr7VovYBn6kEUe87JmdXDX4uwu2XyNomPtAyU"
$DPRAmount = 10
$WalletPassword = Get-WalletPassword
#Send-DPR -IPAddress $IPAddress -Recepient $Recipient -DPRAmount $DPRAmount -Token $Token -EncryptedWalletPassword $WalletPassword

Function Get-Values
{
    param ([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    $Uptime = (Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/info" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json)[0]
    $BalanceAndCredit = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getBalanceAndCredit" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Traffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/microPayment/getDailyTraffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Network = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/network-address" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Channel = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getChannelBalance" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Hardware = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/hardware-info" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Version = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/get-latestversion" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Transactions = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getTransactionList" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty list
    $Keys = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/wallet/getKeyPair" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $DEPWorkProof = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/workProof" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    
    $Now = (Get-Date).ToUniversalTime()

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

    #NPOW Proof
    $NPOWProof = $DEPWorkProof.workProof

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

    #Output
    $Collection =  @()

    #Object Creation
    $CreateObject = `
    [ordered]@{
        "LocalIP" = $IPAddress
        "PublicIP" = $Network.pubIp
        "Address" = $Keys.publicKey
        "Balance" = $BalanceAndCredit.balance
        "Credit" = $BalanceAndCredit.credit
        "CampaignID" = $BalanceAndCredit.campaignId
        "Shared" = $Traffic.shared
        "Consumed" = $Traffic.consumed
        "ChannelBalance" = $Channel.channelBalance
        "SN" = $Hardware.SN
        "DeviceID" = $Hardware.deviceId
        "CPUCount" = $Hardware.cpuCount
        "CPUModel" = $Hardware.totalMem
        "CPUTemp" = $CPUTemp
        "TotalMem" = $Hardware.totalMem
        "Latest" = $Version.latestVersion
        "Current" = $Version.currentVersion
        "TotalStaked" = $Staked
        "StakingType" = $Type
        "WorkProof" = $NPOWProof
        "RewardEstimate" = $NPOWReward
        "LastNPOWReward" = $LastNPOWReward 
        "LastNPOWRewardDate" = $LastNPOWRewardDate
        "LastReward" = $LastReward 
        "LastRewardDate" = $LastRewardDate
        "ThisSnapshotUTC" = $Now.DateTime
        "Uptime" = $Uptime
    }
    $Collection += $CreateObject
    $Collection
}

#Get-Values -IPAddress $IPAddress -Token $Token

Function Withdraw-NPOW
{
    param([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    (Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/withdraw" -Headers @{"Authorization" = $Token} -Method POST | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select Success).Success
}

#Withdraw-NPOW -IPAddress $IPAddress -Token $Token

Function Reboot-Device
{
    param([string]$IPAddress, $Token)
    $URI = "http://$($IPAddress)/api"
    Write-Host "Rebooting Device" -ForegroundColor Red
    Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/admin/reboot" -Headers @{"Authorization" = $Token} -Method POST | Out-Null
}

#Reboot-Device -IPAddress $IPAddress -Token $Token


