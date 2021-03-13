Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
#Hämtar GUI från en mapp
$VS_GUI = "Projekt_GUI\Projekt_GUI\MainWindow.xaml"

$inputVS_GUI = Get-Content $VS_GUI -Raw
$inputVS_GUI = $inputVS_GUI -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$xaml = $inputVS_GUI

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )    
} catch {
    Write-Warning "Fel: " + $_.Exception
    throw
}

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try {
        Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    } catch {
        throw
    }
}

class Process{    
    [string]$ProcessName
    [bool]$ProcessStatus    
    [int]$PID
    [int]$ProcessCPU
    [int]$TestCPU
    [string]$Path
    [string]$Ikon
    [string]$IconFile
}   

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10000
$timer.Enabled = $true
$timer.Start()

$processes = [System.Collections.ArrayList]::new()

#Fyller listboxen med processerna som körs på datorn
function itemlist {
    $SelectedItem = $var_lstV_Itemlist.SelectedIndex
    Set-Variable $SelectedItem -Option ReadOnly
    $var_lstV_Itemlist.SelectedIndex = $SelectedItem
    $var_lstV_Itemlist.Items.Clear()

    [string]$currentPath = Get-Location

    foreach($p in Get-Process){
            $process = [Process]::new()     
        
            if($p.Path.length -gt 0) {
                $fullFileName = $p.Path.split("\")[-1]
                $fileName = $fullFileName -replace(".exe", "")
                $process.IconFile = $currentPath + $fileName + ".bmp"
            }

            if($processes.Contains($p.Id) -eq $false) {
                if($p.Path.length -gt 0) {
                    if($fileName.length -gt 0) {
                        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($p.Path)
                        $icon.ToBitmap().Save($currentPath + $fileName + ".bmp")
                    }
                }
            }

            $process.Path = $p.path
            $process.ProcessName = $p.Name
            $process.PID = $p.Id
            $process.ProcessStatus = $p.Responding
            $process.ProcessCPU = $p.cpupercentage
            $process.TestCPU = $p.TotalPercentage
            $var_lstV_Itemlist.Items.Add($process) > null

            $processes.Add($p.Id) > null
    }
}

#Laddar listboxen med processerna som körs på daotrn
itemlist

$timer.add_tick{(itemlist)}

function startup {
    $var_lstV_Itemlist.Items.Clear()

    $startup_appar = Get-Ciminstance -Classname Win32_startupCommand
    foreach($a in $startup_appar){
        $process = [Process]::new()
        $process.ProcessName = $a | Select-Object -Property Caption
        $process.ProcessStatus = $a | Select-Object -Property Command
        $var_lstV_Itemlist.items.Add($process)
    }
}

#Updaterar listan efter du har stoppat en process
function refreshlist {
    itemlist
}

#Sätta på stänga av knappen
function buttonenable {
    $var_btnAvsluta.IsEnabled = $false
        $var_lstV_Itemlist.add_SelectionChanged({
        $var_btnAvsluta.IsEnabled = $true

    })                                   
}
buttonenable

function disablebutton {
    $var_btnAvsluta.IsEnabled = $false        
}

function stopProcess {
    $yo = $var_lstV_Itemlist.SelectedItem.PID
    Stop-Process -Id $yo
}

$var_btnProcesser.Add_Click({
    itemlist     
    disablebutton
    $timer.Start()    
})

$var_btnAvsluta.Add_Click{        
    stopProcess
    refreshlist
}

$var_btnAutostart.Add_Click({
    startup
    disablebutton
    $timer.Stop()
})

#Stoppar timern och tömmer dens resurser
$window.Add_Closing({
    $timer.Stop()
    $timer.Dispose()
})

[void]$window.ShowDialog()