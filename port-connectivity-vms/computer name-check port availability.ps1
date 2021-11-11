$Servers = Get-Content 'C:\Temp\Computers.txt'

$Jobs = @()

$MaxWorkers = 30

 

$Queue = New-Object System.Collections.Queue

$Servers | ForEach-Object { $Queue.Enqueue($_) }

$MaxTime = [Datetime]::Now.AddHours(1)

do {

    if (($Jobs | Where-Object { $_.State -eq 'Running' }).Count -lt $MaxWorkers) {

        $Server = $Queue.Dequeue()

        Write-Host "$(Get-Date) Launched job for ${Server}"

        $Jobs += Start-Job -Name $Server -ArgumentList $Server {

            Param($Server)

            return [PSCustomObject] @{

                'Server' = $Server

                '135'    = Test-NetConnection -ComputerName $Server -Port 135  | Select-Object -ExpandProperty 'TcpTestSucceeded'

                '139'    = Test-NetConnection -ComputerName $Server -Port 139  | Select-Object -ExpandProperty 'TcpTestSucceeded'

                '445'   = Test-NetConnection -ComputerName $Server -Port 445 | Select-Object -ExpandProperty 'TcpTestSucceeded'

              

                

            }

        }

    }

    Start-Sleep -Milliseconds 1

} until ($Queue.Count -eq 0 -or [Datetime]::Now -gt $MaxTime)

 

$Jobs | Wait-Job | Receive-Job | Out-GridView