Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
#Hämtar GUI från en mapp
#Hemma
$VS_GUI = "C:\Users\edvin\OneDrive\Dokument\WindowsPowerShell\Aktivitetshanteraren\Projekt_GUI\Projekt_GUI\MainWindow.xaml"

#Skola
#$VS_GUI = "C:\Users\edvin.salminen\Documents\Powershell uppgifter\Projekt\Aktivitetshanteraren-master\Projekt_GUI\Projekt_GUI\MainWindow.xaml"

$inputVS_GUI = Get-Content $VS_GUI -Raw
$inputVS_GUI = $inputVS_GUI -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$xaml = $inputVS_GUI

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )    
} catch {
    Write-Warning $_.Exception
    throw
}

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    #"trying item $($_.Name)"
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
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Enabled = $true
$timer.Start()

#Fyller listboxen med processerna som körs på datorn
function itemlist {
    $var_lstV_Itemlist.Items.Clear()
    $processes = Get-Process
    $processes.Path
    foreach($p in $processes){
        $process = [Process]::new()
        $process.ProcessName = $p.Name
        $process.ProcessStatus = $p.Responding
        $process.PID = $p.Id
        $var_lstV_Itemlist.Items.Add($process)
    }    
    Write-Host "yo"
}
#Laddar listboxen med processerna som körs på datorn
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
    $var_lstV_Itemlist.Items.Clear()
    Start-Sleep -Milliseconds 15
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
    $select = $var_lstV_Itemlist.SelectedItem.PID
    Stop-Process -Id $select
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
$Null = $window.ShowDialog()