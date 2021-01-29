Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
#Hämtar GUI från en mapp
$VS_GUI = "C:\Users\edvin\source\repos\Projekt_GUI\Projekt_GUI\MainWindow.xaml"

$inputVS_GUI = Get-Content $VS_GUI -Raw
$inputVS_GUI = $inputVS_GUI -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$xaml = $inputVS_GUI

#Laddar listboxen med processerna som körs på daotrn
itemlist

function startup {
    $var_listView.Items.Clear()
    $startup_app = Get-CimInstance -ClassName Win32_startupCommand | Select-Object -Property name, User, status
    foreach($app in $startup_app){
        $var_listView.Items.Add($app)
        
    }
}

#Updaterar listan efter du har stoppat en process
function refreshlist {
    $var_listView.Items.Clear()
    Start-Sleep -Milliseconds 15
    itemlist

}

#Sätta på stänga av knappen
function buttonenable {
    $var_btn2.IsEnabled = $false

        $var_listView.add_SelectionChanged({
        $var_btn2.IsEnabled = $true

    })                                   
}
buttonenable

function disablebutton {
    $var_btn2.IsEnabled = $false        

}




function stopProcess {

    $name = $var_listView.SelectedItem
    Stop-Process -Name $name

    
}

$var_btn1.Add_Click({

    itemlist     
    disablebutton    
})

$var_btn2.Add_Click({

    stopProcess
    refreshlist
    

})

$var_btn3.Add_Click({

    startup
    disablebutton
})

$Null = $window.ShowDialog()
