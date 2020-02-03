
$ClientId = "695c5127-18bb-4ce5-9774-a4e16051c9f8"
$ClientSecret = ConvertTo-SecureString "uBlNAgc73@sfx[2llmDjZbwEFRi]-yQ3" -AsPlainText -Force

$Credential = New-Object System.Management.Automation.PSCredential($ClientId, $ClientSecret)

Connect-AzAccount -Credential $Credential `
    -Tenant "d32a6fae-4b02-489b-9b07-1b8724ba1e12" `
    -Subscription "0afc0a80-c582-41c8-b9ea-0c52e7ead960" `
    -ServicePrincipal
