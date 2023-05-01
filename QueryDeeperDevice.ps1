Function QueryDeeperDevice
{
    param([string]$IPAddress)

    # I have a stack exchange post currently up where I am looking to get this key automgically.
    # https://stackoverflow.com/questions/76146132/encrypting-and-encoding-a-password-string-with-a-public-key
    $WorkingPasswordHash = "ADD KEY HERE"

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

    $Scrape = Get-Deeper -WalletAddress $Keys.publicKey
    
    $Collection =  @()

    #Object Creation
    $CreateObject = `
    [ordered]@{
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
        "CPUTemp" = $Hardware.tempInCelsius
        "TotalMem" = $Hardware.totalMem
        "Latest" = $Version.latestVersion
        "Current" = $Version.currentVersion
        "TotalStaked" = $Scrape.Staked
        "StakingType" = $Scrape.Type
        "LastReward" = ($Transactions | Where-Object {$_.type -eq "staking.DelegatorReward"} | Select-Object -Last 1 | Select-Object amount).amount
        "LastRewardDate" = (Get-Date ([System.DateTimeOffset]::FromUnixTimeMilliSeconds(($Transactions | Where-Object {$_.type -eq "staking.DelegatorReward"} | Select-Object -Last 1 | Select-Object timestamp).timestamp).DateTime).ToString("s")).DateTime
    }
    $Collection += $CreateObject
    $Collection
}

QueryDeeperDevice -IPAddress "192.168.1.100" 

