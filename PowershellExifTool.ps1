function Get-ExifData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$File,
        [string]$ExifToolBinary = '.\exiftool.exe'
    )

    Begin {
        if(-not (Test-Path $File)) {
            Write-Error -Message "The specified file '$File' does not exist or is not accessible." -ErrorAction Stop
        }

        if(-not (Test-Path $ExifToolBinary)) {
            Write-Error -Message "The specified exiftool binary '$ExifToolBin' does not exist or is not accessible." -ErrorAction Stop
        }
    }

    Process {
        $ProcessStartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = $ExifToolBinary
        $ProcessStartInfo.Arguments = "$File -json"
        $ProcessStartInfo.RedirectStandardOutput = $true
        $ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
        $ProcessStartInfo.CreateNoWindow = $true

        $Process = New-Object -TypeName System.Diagnostics.Process
        $Process.StartInfo = $ProcessStartInfo
        $Process.Start() | Out-Null

        $StandardOutput = $Process.StandardOutput.ReadToEnd()
        $StandardErrorOutput = $Process.StandardError.ReadToEnd()
        $Process.WaitForExit()
    }

    End {
        if($Process.ExitCode -ne 0) {
            if(-not [string]::IsNullOrWhiteSpace($StandardErrorOutput)) {
                Write-Error -Exception $StandardErrorOutput -ErrorAction Stop
            }
            else {
                Write-Error -Message "An unknown error occurred while executing the exiftool command." -ErrorAction Stop
            }
        }
        $StandardOutput | ConvertFrom-Json
    }
}
