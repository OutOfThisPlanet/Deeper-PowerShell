Function Get-Deeper
{
    param ([string]$WalletAddress)
    
    $Staked =  @()
    
    #Endpoints
    $StakedEndpoint = "https://staking.deeper.network/api/wallet/deeperChain/detail?deeperChain=$($WalletAddress)"
    $StatusEndpoint = "https://www.deeperscan.io/api/v1/deeper/staking_delegate_count?addr=$($WalletAddress)"
    $AccountEndpoint = "https://www.deeperscan.io/api/v1/account/$($WalletAddress)"
    
    #Staking Values
    $Values = Invoke-RestMethod -Uri $StakedEndpoint | 
        Select-Object bsc, bscv2, eth, credit

    [decimal]$BSC = $Values.bsc
    [decimal]$DSC = $Values.bscV2
    [decimal]$ETH = $Values.eth
    $StakedDPR = ($BSC + $DSC + $ETH)/[math]::Pow(10,18)
    $Credit = $Values.credit

    $Type = Invoke-RestMethod -Uri $StatusEndpoint | 
        Select-Object staking_status

    $Balance = (Invoke-RestMethod -Uri $AccountEndpoint | 
        Select-Object -ExpandProperty data | 
        Select-Object -ExpandProperty attributes | 
        select balance_total).balance_total/[math]::Pow(10,18)


    #Object Creation
    $GetStaked = New-Object psobject -Property `
    @{
        "Address" = $WalletAddress
        "Balance" = $Balance
        "Staked" = $StakedDPR
        "Credit" = $Credit
        "Type" = $Type.staking_status
    }
    $Staked += $GetStaked
    $Staked
}

Get-Deeper -WalletAddress YOURWALLETADDRESSHERE
