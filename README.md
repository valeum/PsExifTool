# PowershellExifTool
A function that uses ExifTool to output meta-data as PSObjects.

## Examples
The function Install-ExifTool downloads and installs the ExifTool binary to the specified or default directory. If the ExifTool binary is already installed in the specified directory, the function returns without doing anything.
```
Install-ExifTool
```

The function Get-ExifData extracts metadata from an image or video file using the ExifTool command-line application and returns it as a PowerShell object. It requires the file path as input and can also accept an optional path to the ExifTool binary.
```
Get-Exif -File 'C:\tmp\'
```
