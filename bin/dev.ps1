if ((gem list foreman -i) -ne "true")
{
    Write-Host "Installing foreman..."
    gem install foreman
}

# Default to port 3000 if not specified
if ($env:PORT -eq $null)
{
    $env:PORT = "3000"
}

# Let the debug gem allow remote connections,
# but avoid loading until `debugger` is called
$env:RUBY_DEBUG_OPEN = "true"
$env:RUBY_DEBUG_LAZY = "true"

foreman start -f Procfile.windows.dev $args
