Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
#Hämtar GUI från en mapp
$VS_GUI = "C:\Users\edvin\OneDrive\Dokument\WindowsPowerShell\Aktivitetshanteraren\Projekt_GUI\Projekt_GUI\MainWindow.xaml"

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

class Process
{
    [string]$ProcessName
    [bool]$ProcessStatus
    [int]$PID
}

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
}
#Laddar listboxen med processerna som körs på daotrn
itemlist

function startup {
    $var_lstV_Itemlist.Items.Clear()

    $startup_appar = Get-CimInstance -ClassName Win32_startupCommand 
    foreach($a in $startup_appar){
        $process = [Process]::new()
        $process.ProcessName = $a | Select-Object -Property name
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

    $name = $var_lstV_Itemlist.SelectedItem
    Stop-Process -Name $name

    
}

$var_btnProcesser.Add_Click({

    itemlist     
    disablebutton    
})

$var_btnAvsluta.Add_Click({

    stopProcess
    refreshlist
    

})

$var_btnAutostart.Add_Click({

    startup
    disablebutton
})

$Null = $window.ShowDialog()
