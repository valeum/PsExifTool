function Install-ExifTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$InstallPath = $PSScriptRoot,
        [Parameter(Mandatory=$false)]
        [string]$DownloadUrl
    )

    $ZipPath = Join-Path -Path $env:TEMP -ChildPath 'exiftool.zip'
    $ExifToolPath = Join-Path -Path $InstallPath -ChildPath 'exiftool.exe'

    if (Test-Path $ExifToolPath) {
        Write-Output "ExifTool already installed at $ExifToolPath."
        return
    }

    if (-not (Test-Path $InstallPath)) {
        Write-Error -Message "The specified path '$InstallPath' does not exist or is not accessible." -ErrorAction Stop
    }

    if(-not ($DownloadUrl)) {
        Write-Output "Get newest ExifTool download url."
        [xml]$Rss = Invoke-WebRequest -Uri 'https://exiftool.org/rss.xml' -UseBasicParsing
        $DownloadUrl = ($Rss.rss.channel.item.enclosure | Where-Object {$_.type -eq 'application/zip'} | Select-Object -First 1).url
    }

    Write-Output "Downloading ExifTool from $DownloadUrl."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

    Write-Output "Extracting ExifTool archive to $InstallPath."
    Expand-Archive -Path $ZipPath -DestinationPath $InstallPath -Force | Out-Null

    Write-Output "Cleaning up temporary files."
    Remove-Item $ZipPath

    Write-Host "Renaming ExifTool binary to exiftool.exe..."
    Rename-Item -Path (Join-Path -Path $InstallPath -ChildPath 'exiftool(-k).exe') -NewName $ExifToolPath

    Write-Output "ExifTool installed successfully at $ExifToolPath."
}

function Get-ExifData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [string]$ExifToolBinary = '.\exiftool.exe'
    )

    Begin {
        if (-not ($PSVersionTable.PSVersion.Major -ge 5)) {
            Write-Error "This script requires Powershell version 5 or higher to run." -ErrorAction Stop
        }
        
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
