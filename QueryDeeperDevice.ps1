Function QueryDeeperDevice
{
    param([string]$IPAddress)
    
    $ErrorActionPreference = "SilentlyContinue"
    
    # I have a stack exchange post currently up where I am looking to get this automagically.
    # https://stackoverflow.com/questions/76146132/encrypting-and-encoding-a-password-string-with-a-public-key
    $WorkingPasswordHash = "ADD Password Encoded String HERE"

    $Token = ((Invoke-WebRequest -UseBasicParsing -Uri "http://$($IPAddress)/api/admin/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body "{`"username`":`"admin`",`"password`":`"$WorkingPasswordHash`"}"  |
        Select-Object -ExpandProperty Content) | ConvertFrom-Json | Select-Object token).token

    #Local Endpoints
    $URI = "http://$($IPAddress)/api"
    $BalanceAndCredit = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getBalanceAndCredit" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Traffic = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/microPayment/getDailyTraffic" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Channel = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getChannelBalance" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Hardware = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/hardware-info" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Version = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/system-info/get-latestversion" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $Transactions = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/betanet/getTransactionList" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty list
    $Keys = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/wallet/getKeyPair" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    $DEPWorkProof = Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/workProof" -Headers @{"Authorization" = $Token} | Select-Object -ExpandProperty Content | ConvertFrom-Json
    
    if ($DEPWorkProof.estimatedDprReward -gt 0)
    {
        $NPOWWithdraw = (Invoke-WebRequest -UseBasicParsing -Uri "$($URI)/dep/withdraw" -Headers @{"Authorization" = $Token} -Method POST | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select Success).Success
    }
    elseif ($DEPWorkProof.estimatedDprReward -eq $null)
    {
        $NPOWWithdraw = "Unavailable"
    }
    else
    {
        $NPOWWithdraw = "Nothing to withdraw yet"
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


    $Collection =  @()

    #Object Creation
    $CreateObject = `
    [ordered]@{
        "LocalIP" = $IPAddress
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
        "WithdrawNPOWReward" = $NPOWWithdraw
        "LastReward" = $LastReward 
        "LastRewardDate" = $LastRewardDate
        "ThisSnapshotUTC" = (Get-Date).DateTime 
    }
    $Collection += $CreateObject
    $Collection
}

QueryDeeperDevice -IPAddress "192.168.1.100" 

