[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Invoke-Azd {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    & azd @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "azd $($Arguments[0]) failed with exit code $LASTEXITCODE."
    }
}

foreach ($command in @('az', 'azd')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command '$command' was not found."
    }
}

$timeZone = [TimeZoneInfo]::FindSystemTimeZoneById(
    $(if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'Eastern Standard Time' } else { 'America/New_York' })
)
$easternNow = [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $timeZone)
$formattedNow = $easternNow.ToString(
    'yyyy-MM-ddTHH:mm:sszzz',
    [System.Globalization.CultureInfo]::InvariantCulture
)

$createdOn = (& azd env get-value AZURE_CREATED_ON 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($createdOn)) {
    Invoke-Azd -Arguments @('env', 'set', 'AZURE_CREATED_ON', $formattedNow)
}
else {
    $parsedCreatedOn = [DateTimeOffset]::MinValue
    $createdOnIsValid = [DateTimeOffset]::TryParseExact(
        $createdOn.Trim(),
        'yyyy-MM-ddTHH:mm:sszzz',
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref] $parsedCreatedOn
    )
    if (-not $createdOnIsValid) {
        throw 'AZURE_CREATED_ON must be an ISO 8601 timestamp with the Eastern offset in effect at that instant.'
    }
    if ($parsedCreatedOn.Offset -ne $timeZone.GetUtcOffset($parsedCreatedOn.UtcDateTime)) {
        throw 'AZURE_CREATED_ON must be an ISO 8601 timestamp with the Eastern offset in effect at that instant.'
    }
}

Invoke-Azd -Arguments @('env', 'set', 'AZURE_LAST_UPDATED_ON', $formattedNow)

$featureOverridesJson = (& azd env get-value AZURE_FEATURE_OVERRIDES_JSON 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($featureOverridesJson)) {
    $featureOverridesJson = '{}'
    Invoke-Azd -Arguments @('env', 'set', 'AZURE_FEATURE_OVERRIDES_JSON', $featureOverridesJson)
}
$featureOverridesBase64 = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($featureOverridesJson.Trim())
)
Invoke-Azd -Arguments @('env', 'set', 'AZURE_FEATURE_OVERRIDES_BASE64', $featureOverridesBase64)

$operatorPrincipalIds = (& azd env get-value AZURE_OPERATOR_PRINCIPAL_IDS 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($operatorPrincipalIds)) {
    $signedInUserId = (& az ad signed-in-user show --query id --output tsv --only-show-errors 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($signedInUserId)) {
        $operatorPrincipalIds = $signedInUserId.Trim()
    }
    else {
        $operatorPrincipalIds = ''
    }
    Invoke-Azd -Arguments @('env', 'set', 'AZURE_OPERATOR_PRINCIPAL_IDS', $operatorPrincipalIds)
}
