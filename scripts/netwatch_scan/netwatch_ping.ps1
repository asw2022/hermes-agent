$pingR = Test-Connection 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue
if ($pingR -and ($pingR | Measure-Object).Count -gt 0) {
    $avg = [math]::Round(($pingR | Measure-Object ResponseTime -Average).Average, 1)
    Write-Output "ROUTER=$avg"
} else {
    Write-Output "ROUTER=FAIL"
}

$pingD = Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue
if ($pingD -and ($pingD | Measure-Object).Count -gt 0) {
    $avg = [math]::Round(($pingD | Measure-Object ResponseTime -Average).Average, 1)
    Write-Output "DNS=$avg"
} else {
    Write-Output "DNS=FAIL"
}
