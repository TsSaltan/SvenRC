Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

<#
 # Название нашего Arduino-устройства, которое мы ищем в ответе команды handshake
 # @var string
 #>
$deviceName = "SvenRC"

<#
 # Найдено ли Arduino-устройство
 # @var bool
 #>
$devFound = $false

<#
 # Поток к Arduino устройству
 # @var Serial
 #>
$arduino = $null

# Ищем устаройства CH340 - так определяется Arduino в диспетчере задач
# Если у вашего устройства другой чип, поменяйте на следующей строке CH340 на другое значение
$query = Get-WmiObject -Query "Select Caption from Win32_PnPEntity WHERE Name like '%CH340%'"
foreach ($port in $query){
    try{
        # Ищем COM порты
        if($port['Caption'] -match 'COM\d+'){
            $com = $Matches[0] 
            $baud = 9600
            $arduino = new-Object System.IO.Ports.SerialPort $com,$baud,None,8,one

            Write-host "Connect to " $arduino.PortName " port..."

            $arduino.ReadTimeout = 5000;
            $arduino.WriteTimeout = 5000;
            $arduino.open()

            # Отправляем приветствие
            Write-host "handshake ..."
            $arduino.WriteLine("handshake")
            Write-host "Read line ..."
            start-sleep -m 50
            
            $hello = $arduino.ReadLine()
            Write-host "Answer:" $hello
            
            # Если вернуло нашу команду - считываем следующую строку
            if($hello -match "handshake"){
                Write-host "Read next"
                start-sleep -m 50
                $hello = $arduino.ReadLine()
                Write-host "Next answer:" $hello
            }

            # Если получили в ответ нужное название, то это наш Arduino
            if($hello -match $deviceName){
                Write-host "Device found"
                $devFound = $true
                break
            }

            # $arduino.close()
        }
       
    } catch {
        Write-host "Error"
        $_
    }


    if($arduino.isOpen){
        $arduino.close()
    }
}

<# 
    Форма с ошибкой в стиле Windows
    https://poshgui.com/editor/5c4b729ac417d926b8555161
#>
$ErrorForm                       = New-Object system.Windows.Forms.Form
$ErrorForm.ClientSize            = '350,170'
$ErrorForm.text                  = "Ошибка"
$ErrorForm.BackColor             = "#ffffff"
$ErrorForm.TopMost               = $false
$ErrorForm.FormBorderStyle       = 'Fixed3D'
$ErrorForm.MaximizeBox           = $false
$ErrorForm.MinimizeBox           = $false

$ErrorIcon                       = New-Object system.Windows.Forms.PictureBox
$ErrorIcon.width                 = 32
$ErrorIcon.height                = 32
$ErrorIcon.location              = New-Object System.Drawing.Point(15,15)
$ErrorIcon.SizeMode              = [System.Windows.Forms.PictureBoxSizeMode]::zoom
# Закодированная в Base64 иконка
$base64ImageString = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAYdEVYdFNvZnR3YXJlAHBhaW50Lm5ldCA0LjEuNWRHWFIAAAEYSURBVEhLtZNNCsIwEEZzlNzccwhuegCXxaUIHqNVJxNakmZ+voEa3sJu+r4XavqGzvtSiJygYMqFyIkIaPstFSIREcGUP/dEhCJgAc9fnoVQBCzg+curEIrABPt8FoQiMEEzv4JHAILD/AocAQiG+RUwwhOI8ytYhCdQ5leQCFMwzK9nf0QiTMEw/ygAInSBdPujwI3QBdLtCwIvQhFI8wlRYEcoAuXjkQVmhCRQ5hOawIiQBPq3rwr0iEGgzycMgRYxCMy/riVQInqBOZ+wBWJELzDnE45AimgE3nyIIaIRePNBDhGbAJvvXlGhj9gE2HxI0Eew4JTbb2kiWHDS7bfsEey5pnVO6+NU5kSvpZezh379iSn/AEa8ZdiowHAjAAAAAElFTkSuQmCC"
$imageBytes = [Convert]::FromBase64String($base64ImageString)
$ms = New-Object IO.MemoryStream($imageBytes, 0, $imageBytes.Length)
$ms.Write($imageBytes, 0, $imageBytes.Length);
$ErrorIcon.Image =  [System.Drawing.Image]::FromStream($ms, $true)

$ErrorBottomPanel                = New-Object system.Windows.Forms.Panel
$ErrorBottomPanel.height         = 40
$ErrorBottomPanel.width          = 350
$ErrorBottomPanel.BackColor      = "#f0f0f0"
$ErrorBottomPanel.Anchor         = 'right,bottom,left'
$ErrorBottomPanel.location       = New-Object System.Drawing.Point(0,130)

$ErrorButtonOK                   = New-Object system.Windows.Forms.Button
$ErrorButtonOK.text              = "OK"
$ErrorButtonOK.width             = 60
$ErrorButtonOK.height            = 23
$ErrorButtonOK.Anchor            = 'right,bottom'
$ErrorButtonOK.location          = New-Object System.Drawing.Point(278,9)
$ErrorButtonOK.Font              = 'Microsoft Sans Serif,10'

$ErrorTitleLabel                 = New-Object system.Windows.Forms.Label
$ErrorTitleLabel.text            = "Не найдено устройство"
$ErrorTitleLabel.AutoSize        = $true
$ErrorTitleLabel.width           = 271
$ErrorTitleLabel.height          = 22
$ErrorTitleLabel.Anchor          = 'top,right,left'
$ErrorTitleLabel.location        = New-Object System.Drawing.Point(65,10)
$ErrorTitleLabel.Font            = 'Calibri,16'
$ErrorTitleLabel.ForeColor       = "#003399"

$ErrorLabelDescription           = New-Object system.Windows.Forms.Label
$ErrorLabelDescription.text      = "Проверьте, подключено ли Arduino '$deviceName' и не занят ли COM порт другой программой"
$ErrorLabelDescription.AutoSize  = $false
$ErrorLabelDescription.width     = 270
$ErrorLabelDescription.height    = 70
$ErrorLabelDescription.Anchor    = 'top,right,bottom,left'
$ErrorLabelDescription.location  = New-Object System.Drawing.Point(65,50)
$ErrorLabelDescription.Font      = 'Microsoft Sans Serif,10'

$ErrorForm.controls.AddRange(@($ErrorIcon,$ErrorBottomPanel,$ErrorTitleLabel,$ErrorLabelDescription))
$ErrorBottomPanel.controls.AddRange(@($ErrorButtonOK))

$ErrorButtonOK.Add_Click({ 
    $ErrorForm.close()
})


# Create form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.text ='<Arduino> SvenRC'
$mainForm.width = 160
$mainForm.height = 300
$mainForm.autoSize = $true
$mainForm.FormBorderStyle = 'Fixed3D'
$mainForm.MaximizeBox     = $false
$mainForm.MinimizeBox     = $false

# Sven
#       | StandBy |
# |Sven ON |  | Sven OFF|
# |  Input  | | Sound  |
# |  Mute  |  |  Preset |
# |Volume +|  |Volume -|
# |SW+| | Nobass | |SW-|
# |Central+|  |Central-|
# | Small+ |  | Small- |
# |Middle +|  |Middle -|
#

$afterButtonX = 80;
$afterButtonY = 30;
$afterLabelYUp = -4;
$x = 10;
$y = 10;

# Label Sven
$labelSven = New-Object System.Windows.Forms.Label
$labelSven.Text = "Sven"
$labelSven.Location  = New-Object System.Drawing.Point($x, $y)
$labelSven.AutoSize = $true
$mainForm.Controls.Add($labelSven)

$y += $afterLabelYUp

# Button - Sven Standby
$buttonS = New-Object System.Windows.Forms.Button
$buttonS.Text = 'Standby'
$buttonS.Location = New-Object System.Drawing.Point(($x + $afterButtonX / 2), $y)
$buttonS.AutoSize = $false
$buttonS.BackColor = "#ca2929"
$buttonS.ForeColor = "#ffffff"
$mainForm.Controls.Add($buttonS)
$buttonS.Add_Click({   
    $arduino.writeLine("sven standby")
})

# Next Line
$y += $afterButtonY 

# Button - Sven ON
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Sven ON'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven on")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven OFF
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Sven OFF'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven off")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY * 1.5

# Button - Sven Input
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Input'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven input")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Sound
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Sound'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven sound")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY 

# Button - Sven Mute
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Mute'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven mute")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Preset
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Preset'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven preset")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY * 1.5

# Button - Sven Vol+
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Volume -'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven -")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Vol-
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Volume +'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven +")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY 

# Button - Sven SW+
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Sw-'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Width = 40
$buttonA.Add_Click({   
    $arduino.writeLine("sven sw-")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Nobass
$buttonN = New-Object System.Windows.Forms.Button
$buttonN.Text = 'No Bass'
$buttonN.Width = 55
$buttonN.Location = New-Object System.Drawing.Point(($x + 50), $y)
$buttonN.Add_Click({    
    $arduino.writeLine("sven nobass")
})
$mainForm.Controls.Add($buttonN)

# Button - Sven SW-
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Sw+'
$buttonB.Width = 40
$buttonB.Location = New-Object System.Drawing.Point(($x + 50 + 65), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven sw+")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY 

# Button - Sven Central+
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Central -'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven c-")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Central-
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Central +'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven c+")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY 

# Button - Sven Small+
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Small -'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven s-")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Small-
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Small +'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven s+")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY 

# Button - Sven Middle+
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'Middle -'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("sven m-")
})
$mainForm.Controls.Add($buttonA);

# Button - Sven Middle-
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'Middle +'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("sven m+")
})
$mainForm.Controls.Add($buttonB)


<#
# Goto right column
$x += $afterButtonX * 2.3
$y = 10;

# Bluetooth
# | ON | | OFF |

# Label Bluetooth
$label = New-Object System.Windows.Forms.Label
$label.Text = "Bluetooth"
$label.Location  = New-Object System.Drawing.Point($x, $y)
$label.AutoSize = $true
$mainForm.Controls.Add($label)

# Next Line
$y += $afterButtonY + $afterLabelYUp

# Button - Bluetooth ON
$buttonA = New-Object System.Windows.Forms.Button
$buttonA.Text = 'ON'
$buttonA.Location = New-Object System.Drawing.Point($x, $y)
$buttonA.Add_Click({   
    $arduino.writeLine("bluetooth 1")
})
$mainForm.Controls.Add($buttonA);

# Button - Bluetooth OFF
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'OFF'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("bluetooth 0")
})
$mainForm.Controls.Add($buttonB)

# Next Line
$y += $afterButtonY * 1.5 - $afterLabelYUp

# Servo
# | ... |  | Set |

# Label Servo
$label = New-Object System.Windows.Forms.Label
$label.Text = "Servo"
$label.Location  = New-Object System.Drawing.Point($x, $y)
$label.AutoSize = $true
$mainForm.Controls.Add($label)

$y += $afterButtonY + $afterLabelYUp
$servoInput = New-Object System.Windows.Forms.TextBox
$servoInput.Location  = New-Object System.Drawing.Point($x, $y)
$servoInput.Text = '0'
$servoInput.Width = 80
$mainForm.Controls.Add($servoInput)

# Button - Servo set OFF
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'SET'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine("servo set" + $servoInput.Text)
})
$mainForm.Controls.Add($buttonB)

$y += $afterButtonY * 1.5

# Command
# | ... |  | Send |
$label = New-Object System.Windows.Forms.Label
$label.Text = "Send command"
$label.Location  = New-Object System.Drawing.Point($x, $y)
$label.AutoSize = $true
$mainForm.Controls.Add($label)

$y += $afterButtonY + $afterLabelYUp
$cmdInput = New-Object System.Windows.Forms.TextBox
$cmdInput.Location  = New-Object System.Drawing.Point($x, $y)
$cmdInput.Text = 'hello'
$cmdInput.Width = 80
$mainForm.Controls.Add($cmdInput)

# Button - Servo set OFF
$buttonB = New-Object System.Windows.Forms.Button
$buttonB.Text = 'SEND'
$buttonB.Location = New-Object System.Drawing.Point(($x + $afterButtonX), $y)
$buttonB.Add_Click({    
    $arduino.writeLine($cmdInput.Text)
})
$mainForm.Controls.Add($buttonB)
#>

if ($devFound) {
    $mainForm.text = $mainForm.text + ' (' + $arduino.PortName + ')'
    $mainForm.showDialog()
} else {
    $ErrorForm.showDialog()
}

$arduino.close()
Write-Host "Good bye!"