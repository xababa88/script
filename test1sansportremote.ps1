#region Imports and Preparation
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration variables for remote operations
$Global:RemoteServer = "SERVER-NAME"  # Change to your server name
$Global:LogFilePath = "\\$RemoteServer\Logs\AdminTools.log"
$Global:RemoteComputer = $null  # Will store target computer name

# Function to test remote connectivity
function Test-RemoteAccess {
    param($ComputerName)
    try {
        Test-WSMan -ComputerName $ComputerName -ErrorAction Stop
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur de connexion à $ComputerName`n$_", "Erreur")
        return $false
    }
}

# Modified Log-Action function for network logging
function Log-Action {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    try {
        Add-Content -Path $LogFilePath -Value $logMessage -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur d'écriture des logs: $_", "Erreur")
    }
}

# Add computer selection at startup
function Show-ComputerSelection {
    $selectForm = New-Object System.Windows.Forms.Form
    $selectForm.Text = "Sélection de l'ordinateur distant"
    $selectForm.Size = New-Object System.Drawing.Size(400, 150)
    $selectForm.StartPosition = "CenterScreen"

    $lblComputer = New-Object System.Windows.Forms.Label
    $lblComputer.Text = "Nom de l'ordinateur:"
    $lblComputer.Location = New-Object System.Drawing.Point(10, 20)
    $selectForm.Controls.Add($lblComputer)

    $txtComputer = New-Object System.Windows.Forms.TextBox
    $txtComputer.Location = New-Object System.Drawing.Point(120, 20)
    $txtComputer.Size = New-Object System.Drawing.Size(250, 20)
    $selectForm.Controls.Add($txtComputer)

    $btnConnect = New-Object System.Windows.Forms.Button
    $btnConnect.Text = "Connecter"
    $btnConnect.Location = New-Object System.Drawing.Point(150, 60)
    $btnConnect.Add_Click({
        if (Test-RemoteAccess $txtComputer.Text) {
            $Global:RemoteComputer = $txtComputer.Text
            $selectForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $selectForm.Close()
        }
    })
    $selectForm.Controls.Add($btnConnect)

    return $selectForm.ShowDialog()
}

# Main Form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Outil d'Administration"
$mainForm.Size = New-Object System.Drawing.Size(800, 600)
$mainForm.StartPosition = "CenterScreen"

# Navigation Panel (toujours visible à gauche)
$navPanel = New-Object System.Windows.Forms.Panel
$navPanel.Location = New-Object System.Drawing.Point(0, 0)
$navPanel.Size = New-Object System.Drawing.Size(200, 600)
$navPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Content Panel (à droite, change selon la sélection)
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(200, 0)
$contentPanel.Size = New-Object System.Drawing.Size(600, 600)

# Fonction pour créer les boutons de navigation
function New-NavButton {
    param (
        [string]$text,
        [int]$yPosition,
        [scriptblock]$action
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Location = New-Object System.Drawing.Point(10, $yPosition)
    $button.Size = New-Object System.Drawing.Size(180, 40)
    $button.Add_Click($action)
    return $button
}

# Fonction pour nettoyer le panel de contenu
function Clear-ContentPanel {
    $contentPanel.Controls.Clear()
}

# Ajout des boutons de navigation
$btnUserManagement = New-NavButton -text "Gestion des utilisateurs" -yPosition 20 -action {
    Log-Action "Navigated to User Management"
    Clear-ContentPanel
    Show-UserManagementContent
}
$navPanel.Controls.Add($btnUserManagement)

$btnComputerManagement = New-NavButton -text "Gestion des ordinateurs" -yPosition 70 -action {
    Log-Action "Navigated to Computer Management"
    Clear-ContentPanel
    Show-ComputerManagementContent
}
$navPanel.Controls.Add($btnComputerManagement)

$btnNetwork = New-NavButton -text "Gestion réseau" -yPosition 120 -action {
    Log-Action "Navigated to Network Management"
    Clear-ContentPanel
    Show-NetworkManagementContent
}
$navPanel.Controls.Add($btnNetwork)

$btnLogs = New-NavButton -text "Afficher les logs" -yPosition 170 -action {
    Log-Action "Viewing Logs"
    Clear-ContentPanel
    Show-LogsContent
}
$navPanel.Controls.Add($btnLogs)

$btnExit = New-NavButton -text "Quitter" -yPosition 500 -action {
    Log-Action "Application Exited"
    $mainForm.Close()
}
$navPanel.Controls.Add($btnExit)

# Fonction pour créer un groupe de contrôles
function New-ControlGroup {
    param (
        [string]$title,
        [int]$yPosition
    )
    
    $group = New-Object System.Windows.Forms.GroupBox
    $group.Text = $title
    $group.Location = New-Object System.Drawing.Point(10, $yPosition)
    $group.Size = New-Object System.Drawing.Size(570, 150)
    return $group
}

# Fonction pour tester une connexion réseau
function Test-NetworkConnection {
    param (
        [string]$target
    )
    try {
        $result = Test-Connection -ComputerName $target -Count 1 -Quiet
        return $result
    } catch {
        return $false
    }
}

# Contenu du panel de gestion réseau
function Show-NetworkManagementContent {
    $networkGroup = New-ControlGroup -title "Actions réseau" -yPosition 10
    
    # 1. Test de connexion
    $lblPing = New-Object System.Windows.Forms.Label
    $lblPing.Text = "Adresse à tester:"
    $lblPing.Location = New-Object System.Drawing.Point(10, 30)
    $lblPing.Size = New-Object System.Drawing.Size(100, 20)
    $networkGroup.Controls.Add($lblPing)

    $txtPing = New-Object System.Windows.Forms.TextBox
    $txtPing.Location = New-Object System.Drawing.Point(110, 30)
    $txtPing.Size = New-Object System.Drawing.Size(150, 20)
    $networkGroup.Controls.Add($txtPing)

    $btnPing = New-Object System.Windows.Forms.Button
    $btnPing.Text = "Tester connexion"
    $btnPing.Location = New-Object System.Drawing.Point(270, 28)
    $btnPing.Size = New-Object System.Drawing.Size(120, 25)
    $btnPing.Add_Click({
        if ($txtPing.Text) {
            $result = Test-NetworkConnection -target $txtPing.Text
            if ($result) {
                [System.Windows.Forms.MessageBox]::Show("Connexion réussie à $($txtPing.Text)", "Succès")
            } else {
                [System.Windows.Forms.MessageBox]::Show("Impossible de se connecter à $($txtPing.Text)", "Échec")
            }
        }
    })
    $networkGroup.Controls.Add($btnPing)

    # 2. Informations réseau
    $btnNetInfo = New-Object System.Windows.Forms.Button
    $btnNetInfo.Text = "Informations réseau"
    $btnNetInfo.Location = New-Object System.Drawing.Point(10, 65)
    $btnNetInfo.Size = New-Object System.Drawing.Size(150, 25)
    $btnNetInfo.Add_Click({
        $netInfo = Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway
        $infoText = "Informations réseau:`n`n"
        foreach ($adapter in $netInfo) {
            $infoText += "Interface: $($adapter.InterfaceAlias)`n"
            $infoText += "Adresse IP: $($adapter.IPv4Address.IPAddress)`n"
            $infoText += "Passerelle: $($adapter.IPv4DefaultGateway.NextHop)`n`n"
        }
        [System.Windows.Forms.MessageBox]::Show($infoText, "Informations réseau")
    })
    $networkGroup.Controls.Add($btnNetInfo)

    # 3. Test de bande passante
    $btnSpeedTest = New-Object System.Windows.Forms.Button
    $btnSpeedTest.Text = "Test de débit"
    $btnSpeedTest.Location = New-Object System.Drawing.Point(170, 65)
    $btnSpeedTest.Size = New-Object System.Drawing.Size(150, 25)
    $btnSpeedTest.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Test de débit en cours...", "Patientez")
        try {
            $download = Invoke-WebRequest -Uri "http://speedtest.net" -UseBasicParsing
            $latency = $download.BaseResponse.ResponseUri.Host
            [System.Windows.Forms.MessageBox]::Show("Test terminé`nLatence: $latency ms", "Résultat")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors du test de débit", "Erreur")
        }
    })
    $networkGroup.Controls.Add($btnSpeedTest)

    

    # 4. DNS Flush
    $btnDnsFlush = New-Object System.Windows.Forms.Button
    $btnDnsFlush.Text = "Vider cache DNS"
    $btnDnsFlush.Location = New-Object System.Drawing.Point(10, 100)
    $btnDnsFlush.Size = New-Object System.Drawing.Size(150, 25)
    $btnDnsFlush.Add_Click({
        try {
            Clear-DnsClientCache
            [System.Windows.Forms.MessageBox]::Show("Cache DNS vidé avec succès", "Succès")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors du vidage du cache DNS", "Erreur")
        }
    })
    $networkGroup.Controls.Add($btnDnsFlush)

    $contentPanel.Controls.Add($networkGroup)
}

# Contenu du panel de gestion des utilisateurs
function Show-UserManagementContent {
    $userActionGroup = New-Object System.Windows.Forms.GroupBox
    $userActionGroup.Text = "Actions Utilisateur"
    $userActionGroup.Location = New-Object System.Drawing.Point(10, 10)
    $userActionGroup.Size = New-Object System.Drawing.Size(480, 80)

    $contentPanel.Controls.Add($userActionGroup)

      
    # Bouton : Ajouter un utilisateur
    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Text = "Ajouter un utilisateur"
    $btnAdd.Location = New-Object System.Drawing.Point(10, 30)
    $btnAdd.Size = New-Object System.Drawing.Size(150, 30)
    $btnAdd.Add_Click({
        $addForm = New-Object System.Windows.Forms.Form
        $addForm.Text = "Ajouter un utilisateur"
        $addForm.Size = New-Object System.Drawing.Size(300, 200)
        $addForm.StartPosition = "CenterScreen"

        $lblUser = New-Object System.Windows.Forms.Label
        $lblUser.Text = "Nom de l'utilisateur :"
        $lblUser.Location = New-Object System.Drawing.Point(10, 20)

        $txtUser = New-Object System.Windows.Forms.TextBox
        $txtUser.Location = New-Object System.Drawing.Point(130, 20)

        $lblPwd = New-Object System.Windows.Forms.Label
        $lblPwd.Text = "Mot de passe :"
        $lblPwd.Location = New-Object System.Drawing.Point(10, 50)

        $txtPwd = New-Object System.Windows.Forms.TextBox
        $txtPwd.Location = New-Object System.Drawing.Point(130, 50)
        $txtPwd.PasswordChar = '*'

        $btnConfirmAdd = New-Object System.Windows.Forms.Button
        $btnConfirmAdd.Text = "Ajouter"
        $btnConfirmAdd.Location = New-Object System.Drawing.Point(80, 90)
        $btnConfirmAdd.Add_Click({
            $userName = $txtUser.Text
            $password = $txtPwd.Text
            if ($userName -and $password) {
                try {
                    New-LocalUser -Name $userName -Password (ConvertTo-SecureString $password -AsPlainText -Force) -FullName $userName -Description "Créé via script" -ErrorAction Stop
                    [System.Windows.Forms.MessageBox]::Show("Utilisateur ajouté", "Succès")
                    Log-Action "Added user: $userName"
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'ajout: $_", "Erreur")
                    Log-Action "Failed to add user: $userName"
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Veuillez remplir tous les champs.", "Information")
            }
            $addForm.Close()
        })

        $addForm.Controls.AddRange(@($lblUser, $txtUser, $lblPwd, $txtPwd, $btnConfirmAdd))
        $addForm.ShowDialog()
    })
    $userActionGroup.Controls.Add($btnAdd)

    # Bouton : Modifier un utilisateur
    $btnModify = New-Object System.Windows.Forms.Button
    $btnModify.Text = "Modifier un utilisateur"
    $btnModify.Location = New-Object System.Drawing.Point(170, 30)
    $btnModify.Size = New-Object System.Drawing.Size(150, 30)
    $btnModify.Add_Click({
        $modifyForm = New-Object System.Windows.Forms.Form
        $modifyForm.Text = "Modifier un utilisateur"
        $modifyForm.Size = New-Object System.Drawing.Size(300, 200)
        $modifyForm.StartPosition = "CenterScreen"

        $lblUserToMod = New-Object System.Windows.Forms.Label
        $lblUserToMod.Text = "Nom de l'utilisateur :"
        $lblUserToMod.Location = New-Object System.Drawing.Point(10, 20)

        $txtUserToMod = New-Object System.Windows.Forms.TextBox
        $txtUserToMod.Location = New-Object System.Drawing.Point(130, 20)

        $lblNewPwd = New-Object System.Windows.Forms.Label
        $lblNewPwd.Text = "Nouveau mot de passe :"
        $lblNewPwd.Location = New-Object System.Drawing.Point(10, 50)

        $txtNewPwd = New-Object System.Windows.Forms.TextBox
        $txtNewPwd.Location = New-Object System.Drawing.Point(130, 50)
        $txtNewPwd.PasswordChar = '*'

        $btnConfirmMod = New-Object System.Windows.Forms.Button
        $btnConfirmMod.Text = "Modifier"
        $btnConfirmMod.Location = New-Object System.Drawing.Point(80, 90)
        $btnConfirmMod.Add_Click({
            $selectedUser = $txtUserToMod.Text
            $newPassword = $txtNewPwd.Text
            if ($selectedUser -and $newPassword) {
                try {
                    Set-LocalUser -Name $selectedUser -Password (ConvertTo-SecureString $newPassword -AsPlainText -Force)
                    [System.Windows.Forms.MessageBox]::Show("Utilisateur modifié avec succès", "Succès")
                    Log-Action "Modified user: $selectedUser"
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Erreur lors de la modification: $_", "Erreur")
                    Log-Action "Failed to modify user: $selectedUser"
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Veuillez compléter les champs.", "Information")
            }
            $modifyForm.Close()
        })

        $modifyForm.Controls.AddRange(@($lblUserToMod, $txtUserToMod, $lblNewPwd, $txtNewPwd, $btnConfirmMod))
        $modifyForm.ShowDialog()
    })
    $userActionGroup.Controls.Add($btnModify) 

    $btnDelete = New-Object System.Windows.Forms.Button
    $btnDelete.Text = "Supprimer un utilisateur"
    $btnDelete.Location = New-Object System.Drawing.Point(330, 30)
    $btnDelete.Size = New-Object System.Drawing.Size(150, 30)
    $btnDelete.Add_Click({
        $deleteForm = New-Object System.Windows.Forms.Form
        $deleteForm.Text = "Supprimer un utilisateur"
        $deleteForm.Size = New-Object System.Drawing.Size(300, 200)
        $deleteForm.StartPosition = "CenterScreen"

        # Champ nom d'utilisateur
        $lblUser = New-Object System.Windows.Forms.Label
        $lblUser.Text = "Nom d'utilisateur:"
        $lblUser.Location = New-Object System.Drawing.Point(10, 20)
        $lblUser.Size = New-Object System.Drawing.Size(100, 20)
        $deleteForm.Controls.Add($lblUser)

        $txtUser = New-Object System.Windows.Forms.TextBox
        $txtUser.Location = New-Object System.Drawing.Point(120, 20)
        $txtUser.Size = New-Object System.Drawing.Size(150, 20)
        $deleteForm.Controls.Add($txtUser)

        # Champ mot de passe pour confirmation
        $lblPassword = New-Object System.Windows.Forms.Label
        $lblPassword.Text = "Mot de passe:"
        $lblPassword.Location = New-Object System.Drawing.Point(10, 50)
        $lblPassword.Size = New-Object System.Drawing.Size(100, 20)
        $deleteForm.Controls.Add($lblPassword)

        $txtPassword = New-Object System.Windows.Forms.TextBox
        $txtPassword.Location = New-Object System.Drawing.Point(120, 50)
        $txtPassword.Size = New-Object System.Drawing.Size(150, 20)
        $txtPassword.PasswordChar = '*'
        $deleteForm.Controls.Add($txtPassword)

        # Bouton de confirmation
        $btnConfirm = New-Object System.Windows.Forms.Button
        $btnConfirm.Text = "Supprimer"
        $btnConfirm.Location = New-Object System.Drawing.Point(100, 90)
        $btnConfirm.Add_Click({
            if ($txtUser.Text -and $txtPassword.Text) {
                try {
                    Remove-LocalUser -Name $txtUser.Text -ErrorAction Stop
                    [System.Windows.Forms.MessageBox]::Show("Utilisateur supprimé avec succès", "Succès")
                    Log-Action "Deleted user: $($txtUser.Text)"
                    $deleteForm.Close()
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Erreur lors de la suppression: $_", "Erreur")
                    Log-Action "Failed to delete user: $($txtUser.Text)"
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Veuillez remplir tous les champs", "Erreur")
            }
        })
        $deleteForm.Controls.Add($btnConfirm)

        # Bouton Annuler
        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Annuler"
        $btnCancel.Location = New-Object System.Drawing.Point(190, 90)
        $btnCancel.Add_Click({ $deleteForm.Close() })
        $deleteForm.Controls.Add($btnCancel)

        $deleteForm.ShowDialog()
    })
    $userActionGroup.Controls.Add($btnDelete)
    $contentPanel.Controls.Add($userActionGroup)

    # Groupe Informations utilisateurs
    $userInfoGroup = New-ControlGroup -title "Informations utilisateurs" -yPosition 170
   # Fonction pour rafraîchir la liste des utilisateurs
function Script:Update-UsersList {
    param(
        [System.Windows.Forms.ComboBox]$combo
    )
    if ($null -eq $combo) { return }
    try {
        $combo.Items.Clear()
        $users = Get-LocalUser -ErrorAction Stop
        foreach($user in $users) {
            [void]$combo.Items.Add($user.Name)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur lors du chargement des utilisateurs: $_", "Erreur")
    }
}

# Groupe Informations utilisateurs
$userInfoGroup = New-ControlGroup -title "Informations utilisateurs" -yPosition 170

# Combobox pour sélectionner l'utilisateur
$lblSelectUser = New-Object System.Windows.Forms.Label
$lblSelectUser.Text = "Sélectionner un utilisateur:"
$lblSelectUser.Location = New-Object System.Drawing.Point(10, 30)
$lblSelectUser.Size = New-Object System.Drawing.Size(150, 20)
$userInfoGroup.Controls.Add($lblSelectUser)

$script:comboUsers = New-Object System.Windows.Forms.ComboBox
$comboUsers.Location = New-Object System.Drawing.Point(180, 30)
$comboUsers.Size = New-Object System.Drawing.Size(200, 20)
$comboUsers.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$userInfoGroup.Controls.Add($comboUsers)

# Bouton Rafraîchir
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "↺ rafraichir"
$btnRefresh.Location = New-Object System.Drawing.Point(380, 1)
$btnRefresh.Size = New-Object System.Drawing.Size(60, 40)
$btnRefresh.Add_Click({ 
    Script:Update-UsersList -combo $script:comboUsers 
})
$userInfoGroup.Controls.Add($btnRefresh)

# Chargement initial des utilisateurs
Script:Update-UsersList -combo $script:comboUsers

    # 1. Informations de base
    $btnBasicInfo = New-Object System.Windows.Forms.Button
    $btnBasicInfo.Text = "Infos de base"
    $btnBasicInfo.Location = New-Object System.Drawing.Point(10, 70)
    $btnBasicInfo.Size = New-Object System.Drawing.Size(150, 30)
    $btnBasicInfo.Add_Click({
        if ($comboUsers.SelectedItem) {
            $user = Get-LocalUser -Name $comboUsers.SelectedItem
            $info = @"
Nom d'utilisateur: $($user.Name)
Nom complet: $($user.FullName)
Description: $($user.Description)
Activé: $($user.Enabled)
"@
            [System.Windows.Forms.MessageBox]::Show($info, "Informations de base")
        }
    })
    $userInfoGroup.Controls.Add($btnBasicInfo)

    # 2. État du compte
    $btnAccountStatus = New-Object System.Windows.Forms.Button
    $btnAccountStatus.Text = "État du compte"
    $btnAccountStatus.Location = New-Object System.Drawing.Point(170, 70)
    $btnAccountStatus.Size = New-Object System.Drawing.Size(150, 30)
    $btnAccountStatus.Add_Click({
        if ($comboUsers.SelectedItem) {
            $user = Get-LocalUser -Name $comboUsers.SelectedItem
            $info = @"
Compte expiré: $($user.AccountExpires)
Mot de passe expiré: $($user.PasswordExpires)
Dernière connexion: $($user.LastLogon)
"@
            [System.Windows.Forms.MessageBox]::Show($info, "État du compte")
        }
    })
    $userInfoGroup.Controls.Add($btnAccountStatus)

    # 3. Appartenance aux groupes
    $btnGroups = New-Object System.Windows.Forms.Button
    $btnGroups.Text = "Groupes"
    $btnGroups.Location = New-Object System.Drawing.Point(330, 70)
    $btnGroups.Size = New-Object System.Drawing.Size(150, 30)
    $btnGroups.Add_Click({
        if ($comboUsers.SelectedItem) {
            $groups = Get-LocalGroup | Where-Object { 
                Get-LocalGroupMember -Group $_ -Member $comboUsers.SelectedItem -ErrorAction SilentlyContinue 
            }
            $groupList = $groups | ForEach-Object { $_.Name }
            [System.Windows.Forms.MessageBox]::Show(($groupList -join "`n"), "Groupes")
        }
    })
    $userInfoGroup.Controls.Add($btnGroups)

    # 4. Historique des connexions
    $btnLoginHistory = New-Object System.Windows.Forms.Button
    $btnLoginHistory.Text = "Historique connexions"
    $btnLoginHistory.Location = New-Object System.Drawing.Point(10, 110)
    $btnLoginHistory.Size = New-Object System.Drawing.Size(150, 30)
    $btnLoginHistory.Add_Click({
        if ($comboUsers.SelectedItem) {
            $events = Get-EventLog -LogName Security -InstanceId 4624 -Newest 5 -ErrorAction SilentlyContinue |
                     Where-Object { $_.Message -like "*$($comboUsers.SelectedItem)*" }
            $loginInfo = $events | ForEach-Object { $_.TimeGenerated }
            [System.Windows.Forms.MessageBox]::Show(($loginInfo -join "`n"), "Historique des connexions")
        }
    })
    $userInfoGroup.Controls.Add($btnLoginHistory)

    # 5. Droits et permissions
    $btnPermissions = New-Object System.Windows.Forms.Button
    $btnPermissions.Text = "Droits et permissions"
    $btnPermissions.Location = New-Object System.Drawing.Point(170, 110)
    $btnPermissions.Size = New-Object System.Drawing.Size(150, 30)
    $btnPermissions.Add_Click({
        if ($comboUsers.SelectedItem) {
            $user = Get-LocalUser -Name $comboUsers.SelectedItem
            $isAdmin = Get-LocalGroupMember -Group "Administrators" -Member $user.Name -ErrorAction SilentlyContinue
            $permissions = @"
Administrateur: $(if($isAdmin){'Oui'}else{'Non'})
Peut changer mot de passe: $($user.UserMayChangePassword)
Mot de passe requis: $($user.PasswordRequired)
"@
            [System.Windows.Forms.MessageBox]::Show($permissions, "Droits et permissions")
        }
    })
    $userInfoGroup.Controls.Add($btnPermissions)

    $contentPanel.Controls.Add($userInfoGroup)
}

# Contenu du panel de gestion des ordinateurs
#panneau action
function Show-ComputerManagementContent {
    $computerGroup = New-ControlGroup -title "Actions ordinateur" -yPosition 10

    # Bouton Arrêt
    $btnShutdown = New-Object System.Windows.Forms.Button 
    $btnShutdown.Text = "Arrêter le système"
    $btnShutdown.Location = New-Object System.Drawing.Point(10, 30)
    $btnShutdown.Size = New-Object System.Drawing.Size(150, 30)
    $btnShutdown.Add_Click({
        if (Test-RemoteAccess $Global:RemoteComputer) {
            Stop-Computer -ComputerName $Global:RemoteComputer -Force
            Log-Action "Shutdown initiated on $Global:RemoteComputer"
        }
    })
    $computerGroup.Controls.Add($btnShutdown)

    # Bouton Redémarrage
    $btnRestart = New-Object System.Windows.Forms.Button
    $btnRestart.Text = "Redémarrer"
    $btnRestart.Location = New-Object System.Drawing.Point(330, 30)
    $btnRestart.Size = New-Object System.Drawing.Size(150, 30)
    $btnRestart.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Voulez-vous redémarrer le système?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo) -eq 'Yes') {
            Restart-Computer -Force
        }
    })
    $computerGroup.Controls.Add($btnRestart)

    # Bouton Windows Update
    $btnUpdate = New-Object System.Windows.Forms.Button
    $btnUpdate.Text = "Windows Update"
    $btnUpdate.Location = New-Object System.Drawing.Point(10, 70)
    $btnUpdate.Size = New-Object System.Drawing.Size(150, 30)
    $btnUpdate.Add_Click({
        try {
            Install-Module PSWindowsUpdate -Force -Confirm:$false
            Get-WindowsUpdate
            Install-WindowsUpdate -AcceptAll -AutoReboot:$false
            [System.Windows.Forms.MessageBox]::Show("Mise à jour Windows lancée")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur: $_")
        }
    })
    $computerGroup.Controls.Add($btnUpdate)

    # Bouton Antivirus
    $btnAntivirus = New-Object System.Windows.Forms.Button
    $btnAntivirus.Text = "Analyse Antivirus"
    $btnAntivirus.Location = New-Object System.Drawing.Point(170, 70)
    $btnAntivirus.Size = New-Object System.Drawing.Size(150, 30)
    $btnAntivirus.Add_Click({
        try {
            Start-MpScan -ScanType QuickScan
            [System.Windows.Forms.MessageBox]::Show("Analyse antivirus rapide lancée")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur: $_")
        }
    })
    $computerGroup.Controls.Add($btnAntivirus)

    # Bouton Ajouter Répertoire
    $btnAddDir = New-Object System.Windows.Forms.Button
    $btnAddDir.Text = "Ajouter Répertoire"
    $btnAddDir.Location = New-Object System.Drawing.Point(10, 110)
    $btnAddDir.Size = New-Object System.Drawing.Size(150, 30)
    $btnAddDir.Add_Click({
        $addDirForm = New-Object System.Windows.Forms.Form
        $addDirForm.Text = "Ajouter un répertoire"
        $addDirForm.Size = New-Object System.Drawing.Size(400, 150)
        $addDirForm.StartPosition = "CenterScreen"

        $lblPath = New-Object System.Windows.Forms.Label
        $lblPath.Text = "Chemin:"
        $lblPath.Location = New-Object System.Drawing.Point(10, 20)
        $lblPath.Size = New-Object System.Drawing.Size(60, 20)
        $addDirForm.Controls.Add($lblPath)

        $txtPath = New-Object System.Windows.Forms.TextBox
        $txtPath.Location = New-Object System.Drawing.Point(80, 20)
        $txtPath.Size = New-Object System.Drawing.Size(200, 20)
        $addDirForm.Controls.Add($txtPath)

        $btnBrowse = New-Object System.Windows.Forms.Button
        $btnBrowse.Text = "..."
        $btnBrowse.Location = New-Object System.Drawing.Point(290, 20)
        $btnBrowse.Size = New-Object System.Drawing.Size(30, 20)
        $btnBrowse.Add_Click({
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($folderBrowser.ShowDialog() -eq 'OK') {
                $txtPath.Text = $folderBrowser.SelectedPath
            }
        })
        $addDirForm.Controls.Add($btnBrowse)

        $btnCreate = New-Object System.Windows.Forms.Button
        $btnCreate.Text = "Créer"
        $btnCreate.Location = New-Object System.Drawing.Point(150, 70)
        $btnCreate.Add_Click({
            if ($txtPath.Text) {
                try {
                    New-Item -Path $txtPath.Text -ItemType Directory -ErrorAction Stop
                    [System.Windows.Forms.MessageBox]::Show("Répertoire créé avec succès", "Succès")
                    $addDirForm.Close()
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Erreur: $_", "Erreur")
                }
            }
        })
        $addDirForm.Controls.Add($btnCreate)
        $addDirForm.ShowDialog()
    })
    $computerGroup.Controls.Add($btnAddDir)

    # Bouton Supprimer Répertoire
    $btnDelDir = New-Object System.Windows.Forms.Button
    $btnDelDir.Text = "Supprimer Répertoire"
    $btnDelDir.Location = New-Object System.Drawing.Point(330, 110)
    $btnDelDir.Size = New-Object System.Drawing.Size(150, 30)
    $btnDelDir.Add_Click({
        $delDirForm = New-Object System.Windows.Forms.Form
        $delDirForm.Text = "Supprimer un répertoire"
        $delDirForm.Size = New-Object System.Drawing.Size(400, 200)
        $delDirForm.StartPosition = "CenterScreen"

        $lblPath = New-Object System.Windows.Forms.Label
        $lblPath.Text = "Chemin:"
        $lblPath.Location = New-Object System.Drawing.Point(10, 20)
        $lblPath.Size = New-Object System.Drawing.Size(60, 20)
        $delDirForm.Controls.Add($lblPath)

        $txtPath = New-Object System.Windows.Forms.TextBox
        $txtPath.Location = New-Object System.Drawing.Point(80, 20)
        $txtPath.Size = New-Object System.Drawing.Size(200, 20)
        $delDirForm.Controls.Add($txtPath)

        $btnBrowse = New-Object System.Windows.Forms.Button
        $btnBrowse.Text = "..."
        $btnBrowse.Location = New-Object System.Drawing.Point(290, 20)
        $btnBrowse.Size = New-Object System.Drawing.Size(30, 20)
        $btnBrowse.Add_Click({
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($folderBrowser.ShowDialog() -eq 'OK') {
                $txtPath.Text = $folderBrowser.SelectedPath
            }
        })
        $delDirForm.Controls.Add($btnBrowse)

        $lblPassword = New-Object System.Windows.Forms.Label
        $lblPassword.Text = "Mot de passe:"
        $lblPassword.Location = New-Object System.Drawing.Point(10, 50)
        $lblPassword.Size = New-Object System.Drawing.Size(100, 20)
        $delDirForm.Controls.Add($lblPassword)

        $txtPassword = New-Object System.Windows.Forms.TextBox
        $txtPassword.Location = New-Object System.Drawing.Point(80, 50)
        $txtPassword.Size = New-Object System.Drawing.Size(200, 20)
        $txtPassword.PasswordChar = '*'
        $delDirForm.Controls.Add($txtPassword)

        $btnDelete = New-Object System.Windows.Forms.Button
        $btnDelete.Text = "Supprimer"
        $btnDelete.Location = New-Object System.Drawing.Point(150, 90)
        $btnDelete.Add_Click({
            if ($txtPath.Text -and $txtPassword.Text) {
                if ([System.Windows.Forms.MessageBox]::Show("Êtes-vous sûr de vouloir supprimer ce répertoire?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo) -eq 'Yes') {
                    try {
                        Remove-Item -Path $txtPath.Text -Recurse -Force -ErrorAction Stop
                        [System.Windows.Forms.MessageBox]::Show("Répertoire supprimé avec succès", "Succès")
                        $delDirForm.Close()
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Erreur: $_", "Erreur")
                    }
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Veuillez remplir tous les champs", "Erreur")
            }
        })
        $delDirForm.Controls.Add($btnDelete)
        $delDirForm.ShowDialog()
    })
    $computerGroup.Controls.Add($btnDelDir)

    $contentPanel.Controls.Add($computerGroup)

    # New System Information group
    $sysInfoGroup = New-ControlGroup -title "Information système" -yPosition 200
    $sysInfoGroup.Size = New-Object System.Drawing.Size(480, 300)  # Increase height

    # OS Info
    $lblOS = New-Object System.Windows.Forms.Label
    $lblOS.Text = "Système d'exploitation:"
    $lblOS.Location = New-Object System.Drawing.Point(10, 30)
    $lblOS.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblOS)

    $txtOS = New-Object System.Windows.Forms.TextBox
    $txtOS.Location = New-Object System.Drawing.Point(170, 30)
    $txtOS.Size = New-Object System.Drawing.Size(250, 20)
    $txtOS.ReadOnly = $true
    $txtOS.Text = (Get-WmiObject Win32_OperatingSystem).Caption
    $sysInfoGroup.Controls.Add($txtOS)

    # CPU Info
    $lblCPU = New-Object System.Windows.Forms.Label
    $lblCPU.Text = "Processeur:"
    $lblCPU.Location = New-Object System.Drawing.Point(10, 70)
    $lblCPU.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblCPU)

    $txtCPU = New-Object System.Windows.Forms.TextBox
    $txtCPU.Location = New-Object System.Drawing.Point(170, 70)
    $txtCPU.Size = New-Object System.Drawing.Size(250, 20)
    $txtCPU.ReadOnly = $true
    $txtCPU.Text = (Get-WmiObject Win32_Processor).Name
    $sysInfoGroup.Controls.Add($txtCPU)

    # RAM Info
    $lblRAM = New-Object System.Windows.Forms.Label
    $lblRAM.Text = "Mémoire RAM:"
    $lblRAM.Location = New-Object System.Drawing.Point(10, 110)
    $lblRAM.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblRAM)

    $txtRAM = New-Object System.Windows.Forms.TextBox
    $txtRAM.Location = New-Object System.Drawing.Point(170, 110)
    $txtRAM.Size = New-Object System.Drawing.Size(250, 20)
    $txtRAM.ReadOnly = $true
    $totalRAM = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $txtRAM.Text = "$totalRAM GB"
    $sysInfoGroup.Controls.Add($txtRAM)

    # Disk Space Info
    $lblDisk = New-Object System.Windows.Forms.Label
    $lblDisk.Text = "Espace disque:"
    $lblDisk.Location = New-Object System.Drawing.Point(10, 230)
    $lblDisk.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblDisk)

    $txtDisk = New-Object System.Windows.Forms.TextBox
    $txtDisk.Location = New-Object System.Drawing.Point(170, 230)
    $txtDisk.Size = New-Object System.Drawing.Size(250, 20)
    $txtDisk.ReadOnly = $true
    $diskInfo = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | 
                ForEach-Object { "$($_.DeviceID) $(([math]::Round($_.FreeSpace/1GB, 2))) GB libre / $(([math]::Round($_.Size/1GB, 2))) GB total" }
    $txtDisk.Text = $diskInfo -join " | "
    $sysInfoGroup.Controls.Add($txtDisk)

    # Network Adapter Info
    $lblNetwork = New-Object System.Windows.Forms.Label
    $lblNetwork.Text = "Carte réseau:"
    $lblNetwork.Location = New-Object System.Drawing.Point(10, 150)
    $lblNetwork.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblNetwork)

    $txtNetwork = New-Object System.Windows.Forms.TextBox
    $txtNetwork.Location = New-Object System.Drawing.Point(170, 150)
    $txtNetwork.Size = New-Object System.Drawing.Size(250, 20)
    $txtNetwork.ReadOnly = $true
    $txtNetwork.Text = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1 Name).Name
    $sysInfoGroup.Controls.Add($txtNetwork)

    # System Uptime
    $lblUptime = New-Object System.Windows.Forms.Label
    $lblUptime.Text = "Temps activité:"
    $lblUptime.Location = New-Object System.Drawing.Point(10, 190)
    $lblUptime.Size = New-Object System.Drawing.Size(150, 20)
    $sysInfoGroup.Controls.Add($lblUptime)

    $txtUptime = New-Object System.Windows.Forms.TextBox
    $txtUptime.Location = New-Object System.Drawing.Point(170, 190)
    $txtUptime.Size = New-Object System.Drawing.Size(250, 20)
    $txtUptime.ReadOnly = $true
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    $txtUptime.Text = "{0} jours {1} heures {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    $sysInfoGroup.Controls.Add($txtUptime)

    # Refresh Button with updated functionality
    $btnRefreshSysInfo = New-Object System.Windows.Forms.Button
    $btnRefreshSysInfo.Text = "Actualiser"
    $btnRefreshSysInfo.Location = New-Object System.Drawing.Point(170, 260)
    $btnRefreshSysInfo.Size = New-Object System.Drawing.Size(100, 25)
    $btnRefreshSysInfo.Add_Click({
        $txtOS.Text = (Get-WmiObject Win32_OperatingSystem).Caption
        $txtCPU.Text = (Get-WmiObject Win32_Processor).Name
        $totalRAM = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        $txtRAM.Text = "$totalRAM GB"
        
        $diskInfo = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | 
                    ForEach-Object { "$($_.DeviceID) $(([math]::Round($_.FreeSpace/1GB, 2))) GB libre / $(([math]::Round($_.Size/1GB, 2))) GB total" }
        $txtDisk.Text = $diskInfo -join " | "
        
        $txtNetwork.Text = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1 Name).Name
        
        $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        $txtUptime.Text = "{0} jours {1} heures {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    })
    $sysInfoGroup.Controls.Add($btnRefreshSysInfo)

    $contentPanel.Controls.Add($sysInfoGroup)
}

# Contenu du panel des logs
function Show-LogsContent {
    $logsTextBox = New-Object System.Windows.Forms.TextBox
    $logsTextBox.Multiline = $true
    $logsTextBox.ScrollBars = "Vertical"
    $logsTextBox.Location = New-Object System.Drawing.Point(10, 10)
    $logsTextBox.Size = New-Object System.Drawing.Size(570, 500)
    
    if (Test-Path -Path $LogFilePath) {
        $logsTextBox.Text = Get-Content -Path $LogFilePath -Tail 100 | Out-String
    } else {
        $logsTextBox.Text = "Aucun log disponible."
    }
    
    $contentPanel.Controls.Add($logsTextBox)
}

# Ajout des panels principaux au formulaire
$mainForm.Controls.Add($navPanel)
$mainForm.Controls.Add($contentPanel)

# Point d'entrée principal
if ((Show-ComputerSelection) -eq [System.Windows.Forms.DialogResult]::OK) {
    Log-Action "Application Started - Connected to $Global:RemoteComputer"
    Show-UserManagementContent
    $mainForm.ShowDialog()
}