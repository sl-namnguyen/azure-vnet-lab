# sử dụng script này ở trên Powershell của portal azure
# lấy list các key của storage account
# key này sẽ sử dụng để mount file share vào VM
$resourceGroup = "<insert resource group>"
$storageAccountName = "<insert storage account name>"
# sau khi chạy xong dòng lệnh bên dưới sẽ có 2 key, lấy key có "permission" = "full"
Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName

# script bên dưới này sẽ chạy ở trên VM
# điền value cho các biến sau:
$storageAccountName = "<insert storage account name>"
$storageAccountKey = "<insert storage account key>"
# thay key vào phần <insert key here>
$connectTestResult = Test-NetConnection -ComputerName sahubeastus01.privatelink.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$storageAccountName.privatelink.file.core.windows.net`" /user:`"localhost\$storageAccountName`" /pass:`"$storageAccountKey`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$storageAccountName.privatelink.file.core.windows.net\test" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}