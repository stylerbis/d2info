$filepath = $PSScriptRoot

$base_url = 'https://www.bungie.net'
$api_base_url = "$($base_url)/Platform"
$user_agent = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0'

Function Get-D2Manifest {
    $url = "$($api_base_url)/Destiny2/Manifest/"

    $res = Invoke-RestMethod -Method Get -Uri $url -UserAgent $user_agent
    return $res.Response
}

$manifest = Get-D2Manifest

$manifest.jsonWorldComponentContentPaths.en |
    Get-Member -MemberType NoteProperty |
    Select-Object -ExpandProperty Name |
    ForEach-Object -Parallel {
        Set-Location -Path $using:filepath
        $relative_path = ($using:manifest.jsonWorldComponentContentPaths.en).$_
        $url = "$($using:base_url)$($relative_path)"

        $req = Invoke-RestMethod -Method Get -Uri $url -UserAgent $using:user_agent
        $json = $req | ConvertTo-Json -Depth 100
        $hashes = $json | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        $old_hashes = Get-Content -Path "$($using:filepath)/../data/cache/$($_).hashes"
        $new_hashes = $hashes | Where-Object {$_ -notin $old_hashes}

        $output = @()
        $new_hashes | ForEach-Object {
            $output += $json.$_
            Write-Output $_ | Out-File -FilePath "$($using:filepath)/../data/cache/$($_).hashes" -Append
        }
        $raw_output = $output | ConvertTo-Json -Depth 100
        if (-not [System.String]::IsNullOrEmpty($raw_output)) {
            Write-Output @"
``````
$($raw_output)
``````
"@ | Out-File -FilePath "$($using:filepath)/../docs/$($_)_$(Get-Date -Format 'yyyyMMdd').md"
        }
    } -ThrottleLimit 3