$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:3000/")
$listener.Start()
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Web App Thong Ke Tuyen Sinh Lop 10" -ForegroundColor White
Write-Host "  Server: http://localhost:3000" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Start-Process "http://localhost:3000"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/") { $localPath = "/index.html" }

        $filePath = Join-Path $basePath ($localPath.TrimStart("/").Replace("/", "\"))

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

            $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.StatusCode = 200
            $response.ContentLength64 = $fileBytes.Length
            $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
            $response.OutputStream.Flush()
            $response.OutputStream.Close()
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 200 $localPath" -ForegroundColor Green
        } else {
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $localPath")
            $response.StatusCode = 404
            $response.ContentType = "text/plain; charset=utf-8"
            $response.ContentLength64 = $msg.Length
            $response.OutputStream.Write($msg, 0, $msg.Length)
            $response.OutputStream.Flush()
            $response.OutputStream.Close()
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 404 $localPath" -ForegroundColor Red
        }
    }
} catch {
    if ($_.Exception.Message -notlike "*thread exit*" -and $_.Exception.Message -notlike "*listener was closed*") {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Server stopped." -ForegroundColor Yellow
}
