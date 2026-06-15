$CredentialParams = @{
    UseDefaultCredentials = $true
    UseBasicParsing       = $true
}

try {

    Invoke-WebRequest `
        -Uri "https://localhost:8081/OrgK1/1" `
        -Method POST `
        -Body @{
            OrgK1 = "plat"
            OrgNum = "1"
        } `
        @CredentialParams

    Invoke-WebRequest `
        -Uri "https://localhost:8081/OrgK2/1" `
        -Method POST `
        -Body @{
            OrgK2 = "corecard"
            OrgNum = "1"
        } `
        @CredentialParams

    Invoke-WebRequest `
        -Uri "https://localhost:8081/OrgK1/2" `
        -Method POST `
        -Body @{
            OrgK1 = "plat"
            OrgNum = "2"
        } `
        @CredentialParams

    Invoke-WebRequest `
        -Uri "https://localhost:8081/OrgK2/2" `
        -Method POST `
        -Body @{
            OrgK2 = "corecard"
            OrgNum = "2"
        } `
        @CredentialParams

    Write-Host "KMS Activation Completed Successfully"
}
catch {
    Write-Host "KMS Activation Failed"
    Write-Host $_.Exception.Message
}