Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{ 

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 272
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(70,70)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Ip Address:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(70,50)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$RadioButton1                    = New-Object system.Windows.Forms.RadioButton
$RadioButton1.text               = "Windows"
$RadioButton1.AutoSize           = $true
$RadioButton1.width              = 104
$RadioButton1.height             = 20
$RadioButton1.location           = New-Object System.Drawing.Point(70,162)
$RadioButton1.Font               = 'Microsoft Sans Serif,10'
$Form.Controls.Add($RadioButton1) 

$RadioButton2                    = New-Object system.Windows.Forms.RadioButton
$RadioButton2.text               = "Linux"
$RadioButton2.AutoSize           = $true
$RadioButton2.width              = 104
$RadioButton2.height             = 20
$RadioButton2.location           = New-Object System.Drawing.Point(70,180)
$RadioButton2.Font               = 'Microsoft Sans Serif,10'
$Form.Controls.Add($RadioButton2) 

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Password:"
$Label2.AutoSize                 = $true
$Label2.width                    = 100
$Label2.height                   = 100
$Label2.location                 = New-Object System.Drawing.Point(70,230)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$TextBox2                  = New-Object system.Windows.Forms.TextBox
$TextBox2.PasswordChar     = "*" 
$TextBox2.multiline        = $false
$TextBox2.width            = 100
$TextBox2.height           = 20
$TextBox2.location         = New-Object System.Drawing.Point(70,250)
$TextBox2.Font             = 'Microsoft Sans Serif,10'

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Connect"
$Button1.width                   = 80
$Button1.height                  = 50
$Button1.location                = New-Object System.Drawing.Point(123,299)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($TextBox1,$Label1,$Label2,$RadioButton1,$RadioButton2,$Button1,$TextBox2))

#region gui events {
    $Button1.Add_Click(
    {
        $ErrorActionPreference = "SilentlyContinue"
        $localport = find-localport
		Write-Host "Found free port: $($localport)"
        if ($RadioButton1.checked) {
            create-tunnel $TextBox1.text  "3389" $localport $TextBox2.text
			$listening = Get-NetTCPConnection -state listen -LocalPort $localport
            while ($listening -eq $False){
				$listening = Get-NetTCPConnection -state listen -LocalPort $localport
				Write-Host "Waiting for $($localport) to be ready"
				Start-Sleep -Seconds 2
            }
			Write-Host "Connecting to $($localport)"
            rdp-connect $localport
        }
        elseif ($RadioButton2.checked) {
            create-tunnel $TextBox1.text  "22"  $localport $TextBox2.text
			$listening = Get-NetTCPConnection -state listen -LocalPort $localport
            while ($listening -eq $False){
				$listening = Get-NetTCPConnection -state listen -LocalPort $localport
				Write-Host "Waiting for $($localport) to be ready"
				Start-Sleep -Seconds 2
            }
			Write-Host "Connecting to $($localport)"
			ssh-connect $localport $TextBox2.text
		}
    }
)
#endregion events }

#endregion GUI }


#Write your logic code here
$domain="Your domain here"
$ssh_bastion="Yur Bastion ip or hostname here"
function create-tunnel {
    param($remote_host,$remote_port,$localport, $password)
	Write-Host "$($domain)\\$($env:UserName)@$($ssh_bastion) -L $($localport):$($remote_host):$($remote_port) -pw $($password)"
    & "putty" $($ssh_bastion) -l "$($env:UserName)" -L "$($localport):$($remote_host):$($remote_port)" -pw "$($password)"
}

function find-localport{
    $localport = 3000
    $portlist = (Get-NetTCPConnection -state Established | group localport -NoElement | sort  -Descending | Out-String)
    while ($True){
        if ($portlist -match $localport){
            $localport = $localport + 1
        }
        else{
            return $localport
        }
    }
}

function ssh-connect {
    param($port,$password)
        & "putty" localhost "$($port)" -l "$($env:UserName)" -pw "$($password)"
}
function rdp-connect {
    param($port)
        & "mstsc" /v localhost:$port
    
}

[void]$Form.ShowDialog()
