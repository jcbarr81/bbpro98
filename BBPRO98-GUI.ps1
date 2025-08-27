# GUI front end for Baseball Pro '98 scripts
# Provides simple Windows Forms interface to run repository tools
# Requires PowerShell 5+ and Windows

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDefinitions = @(
    @{ Name='ASN-Extractor-B'; File='ASN-Extractor-B.ps1'; Inputs=@('ASN File') },
    @{ Name='ASN-Importer-A'; File='ASN-Importer-A.ps1'; Inputs=@('ASN File','Roster CSV') },
    @{ Name='Export-pyr-A'; File='Export-pyr-A.ps1'; Inputs=@('PYR File') },
    @{ Name='Import-pyr-A'; File='Import-pyr-A.ps1'; Inputs=@('PYR File','Player CSV') },
    @{ Name='Decrypt-pyr-E'; File='Decrypt-pyr-E.ps1'; Inputs=@('PYR File') },
    @{ Name='Find-asn-Sections'; File='Find-asn-Sections.ps1'; Inputs=@('ASN File') }
)

$form = New-Object Windows.Forms.Form
$form.Text = 'Baseball Pro 98 Tools'
$form.Size = New-Object Drawing.Size(620,410)
$form.StartPosition = 'CenterScreen'

$combo = New-Object Windows.Forms.ComboBox
$combo.Location = New-Object Drawing.Point(10,10)
$combo.Width = 580
$combo.DropDownStyle = 'DropDownList'
$scriptDefinitions.Name | ForEach-Object { [void]$combo.Items.Add($_) }
$form.Controls.Add($combo)

$pnlInputs = New-Object Windows.Forms.Panel
$pnlInputs.Location = New-Object Drawing.Point(10,40)
$pnlInputs.Size = New-Object Drawing.Size(580,130)
$form.Controls.Add($pnlInputs)

$lblOut = New-Object Windows.Forms.Label
$lblOut.Location = New-Object Drawing.Point(10,180)
$lblOut.Text = 'Output folder (optional)'
$form.Controls.Add($lblOut)

$txtOut = New-Object Windows.Forms.TextBox
$txtOut.Location = New-Object Drawing.Point(10,200)
$txtOut.Width = 500
$form.Controls.Add($txtOut)

$btnBrowseOut = New-Object Windows.Forms.Button
$btnBrowseOut.Location = New-Object Drawing.Point(520,198)
$btnBrowseOut.Size = New-Object Drawing.Size(70,23)
$btnBrowseOut.Text = 'Browse'
$form.Controls.Add($btnBrowseOut)

$btnRun = New-Object Windows.Forms.Button
$btnRun.Location = New-Object Drawing.Point(10,230)
$btnRun.Size = New-Object Drawing.Size(100,25)
$btnRun.Text = 'Run Script'
$form.Controls.Add($btnRun)

$txtLog = New-Object Windows.Forms.TextBox
$txtLog.Location = New-Object Drawing.Point(10,260)
$txtLog.Size = New-Object Drawing.Size(580,110)
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$form.Controls.Add($txtLog)

function Set-Inputs {
    $pnlInputs.Controls.Clear()
    $sel = $scriptDefinitions | Where-Object { $_.Name -eq $combo.SelectedItem }
    if (-not $sel) { return }
    for ($i = 0; $i -lt $sel.Inputs.Count; $i++) {
        $prompt = $sel.Inputs[$i]
        $lbl = New-Object Windows.Forms.Label
        $lbl.Location = [Drawing.Point]::new(0, $i * 30)
        $lbl.Size = New-Object Drawing.Size(100,23)
        $lbl.Text = $prompt
        $pnlInputs.Controls.Add($lbl)

        $txt = New-Object Windows.Forms.TextBox
        $txt.Location = [Drawing.Point]::new(110, $i * 30)
        $txt.Size = New-Object Drawing.Size(380,23)
        $pnlInputs.Controls.Add($txt)

        $btn = New-Object Windows.Forms.Button
        $btn.Location = [Drawing.Point]::new(500, ($i * 30) - 1)
        $btn.Size = New-Object Drawing.Size(70,23)
        $btn.Text = 'Browse'
        $btn.Add_Click({
            $dlg = New-Object Windows.Forms.OpenFileDialog
            if ($dlg.ShowDialog() -eq 'OK') { $txt.Text = $dlg.FileName }
        })
        $pnlInputs.Controls.Add($btn)
    }
}

$combo.Add_SelectedIndexChanged({ Set-Inputs })

$btnBrowseOut.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq 'OK') { $txtOut.Text = $dlg.SelectedPath }
})

$btnRun.Add_Click({
    $txtLog.Clear()
    $sel = $scriptDefinitions | Where-Object { $_.Name -eq $combo.SelectedItem }
    if (-not $sel) { return }
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = 'pwsh'
    $psi.Arguments = "-ExecutionPolicy Bypass -File `"$($sel.File)`""
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [Diagnostics.Process]::Start($psi)

    foreach ($c in $pnlInputs.Controls) {
        if ($c -is [Windows.Forms.TextBox]) { $proc.StandardInput.WriteLine($c.Text) }
    }
    $proc.StandardInput.Close()
    $proc.WaitForExit()
    $output = $proc.StandardOutput.ReadToEnd() + $proc.StandardError.ReadToEnd()
    $txtLog.Text = $output
    if ($txtOut.Text -and (Test-Path $txtOut.Text)) {
        $time = Get-Date -Format 'yyyyMMdd-HHmmss'
        $log = Join-Path $txtOut.Text "$($sel.Name)-$time.log"
        $output | Out-File -FilePath $log -Encoding UTF8
    }
})

[void]$form.ShowDialog()
