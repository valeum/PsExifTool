function Install-ExifTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$InstallPath = $PSScriptRoot, # The installation path for ExifTool. Defaults to the directory where the script is located.
        [Parameter(Mandatory=$false)]
        [string]$DownloadUrl # The URL from which to download ExifTool. If not provided, the script will attempt to retrieve the latest download URL from the ExifTool RSS feed.
    )

    # The path to the downloaded ExifTool ZIP file.
    $ZipPath = Join-Path -Path $env:TEMP -ChildPath 'exiftool.zip'
    # The path where ExifTool will be installed.
    $ExifToolPath = Join-Path -Path $InstallPath -ChildPath 'exiftool.exe'

    # Check if ExifTool is already installed.
    if (Test-Path $ExifToolPath) {
        Write-Output "ExifTool already installed at $ExifToolPath."
        return
    }

    # Check if the specified installation path exists.
    if (-not (Test-Path $InstallPath)) {
        Write-Error -Message "The specified path '$InstallPath' does not exist or is not accessible." -ErrorAction Stop
    }

    # If no download URL is specified, attempt to retrieve the latest URL from the ExifTool RSS feed.
    if(-not ($DownloadUrl)) {
        Write-Output "Get newest ExifTool download url."
        [xml]$Rss = Invoke-WebRequest -Uri 'https://exiftool.org/rss.xml' -UseBasicParsing
        $DownloadUrl = ($Rss.rss.channel.item.enclosure | Where-Object {$_.type -eq 'application/zip'} | Select-Object -First 1).url
    }

    # Download ExifTool ZIP file.
    Write-Output "Downloading ExifTool from $DownloadUrl."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

    # Extract the contents of the ZIP file to the installation directory.
    Write-Output "Extracting ExifTool archive to $InstallPath."
    Expand-Archive -Path $ZipPath -DestinationPath $InstallPath -Force | Out-Null

    # Remove the downloaded ZIP file.
    Write-Output "Cleaning up temporary files."
    Remove-Item $ZipPath

    # Rename the ExifTool binary file to its proper name.
    Write-Host "Renaming ExifTool binary to exiftool.exe..."
    Rename-Item -Path (Join-Path -Path $InstallPath -ChildPath 'exiftool(-k).exe') -NewName $ExifToolPath

    Write-Output "ExifTool installed successfully at $ExifToolPath."
}

function Get-ExifData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$File, # Path to the file for which to retrieve exif data
        [Parameter(Mandatory=$false)]
        [string]$ExifToolBinary = (Join-Path -Path $PSScriptRoot -ChildPath 'exiftool.exe') # Path to the exiftool binary
    )

    Begin {
        # Check if the specified file exists
        if(-not (Test-Path $File)) {
            Write-Error -Message "The specified file '$File' does not exist or is not accessible." -ErrorAction Stop
        }

        # Check if the specified exiftool binary exists
        if(-not (Test-Path $ExifToolBinary)) {
            Write-Error -Message "The specified exiftool binary '$ExifToolBin' does not exist or is not accessible." -ErrorAction Stop
        }
    }

    Process {
        # Set up process info for exiftool command
        $ProcessStartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = $ExifToolBinary
        $ProcessStartInfo.Arguments = "$File -json"
        $ProcessStartInfo.RedirectStandardOutput = $true
        $ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
        $ProcessStartInfo.CreateNoWindow = $true

        # Create new process and execute exiftool command
        $Process = New-Object -TypeName System.Diagnostics.Process
        $Process.StartInfo = $ProcessStartInfo
        $Process.Start() | Out-Null

        # Read output and error streams
        $StandardOutput = $Process.StandardOutput.ReadToEnd()
        $StandardErrorOutput = $Process.StandardError.ReadToEnd()
        $Process.WaitForExit()
    }

    End {
        # Check for errors and throw exception if necessary
        if($Process.ExitCode -ne 0) {
            if(-not [string]::IsNullOrWhiteSpace($StandardErrorOutput)) {
                Write-Error -Exception $StandardErrorOutput -ErrorAction Stop
            }
            else {
                Write-Error -Message "An unknown error occurred while executing the exiftool command." -ErrorAction Stop
            }
        }

        # Return exif data as a PowerShell object
        $StandardOutput | ConvertFrom-Json
    }
}
