[String]$ExifToolBin = Join-Path -Path $PSScriptRoot -ChildPath 'exiftool.exe'

function Get-ExifData($File) {
    $TempFileOutput = New-TemporaryFile
    $TempFileError = New-TemporaryFile

    $ArgumentList = "$File -json"
    Start-Process -FilePath $ExifToolBin -ArgumentList $ArgumentList -Wait -RedirectStandardOutput $TempFileOutput -RedirectStandardError $TempFileError

    $StandardOutput = Get-Content $TempFileOutput
    $StandardErrorOutput = Get-Content $TempFileError

    Remove-Item $TempFileOutput -Force
    Remove-Item $TempFileError -Force 

    if($StandardOutput.Length -eq 0) {
        Write-Host $StandardErrorOutput
        break
    }

    $StandardOutput | ConvertFrom-Json
}

Get-ExifData -File 'C:\tmp\exiftools\'
