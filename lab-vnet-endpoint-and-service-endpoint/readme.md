# Lab: làm quen với endpoint và service endpoint
## Mục tiêu: 
- Hiểu được cách tạo và cấu hình endpoint, service endpoint
- Hiểu được vnet peering: "traffic to remote virtual network" hoạt động như thế nào
- Hiểu 1 phần cách hoạt động phần networking của storage account
- Hiểu 1 phần cách cấu hình private dns zone

---
## A. Chuẩn bị trước bài lab:
 Bài lab sẽ có bước liên quan đến sử dụng Azure Powershell (trên portal Azure hoặc Powershell module local trong máy đều được nhưng prefre là sử dụng trên portal Azure)

---
## B. Chuẩn bị môi trường lab
**1. tạo ra 2 vnet:**
  - vnet 1:
      - name: `vnet-hub-01`
      - region: `eastus`
      - ip address range: `192.168.0.0/16`
      - subnet:
        - name: `subnet01`
        - ip address range: `192.168.0.0/24`
  - vnet 2:
      - name: `vnet-spoke-01`
      - region: `eastus`
      - ip addres range: `192.169.0.0/16`
      - subnet:
        - name: subnet01
        - ip address range: `192.169.0.0/24`

**2. tạo VM trong spoke vnet:**
  - vm
    - name: `vm-spoke-eastus-01`
    - region: `eastus`
    - image: `windows data center 2019`
    - size: `B2s`
    - username: `lab`
    - password: `1234567890a@`
    - Public inboud port: `3389`
    - OS disk type: `standard ssd`
    - vnet:
      - name: `vnet-spoke-01`
      - subnet: `subnet01`
      - public ip: create new

> NOTE: trong quá trình tạo storage account nếu bị lỗi do trùng tên thì đổi số 01 02 thành các số khác tùy thích
**3. tạo storage account với endpoint và service endpoint trong hub vnet:**
  - storage account 1:
    - name: `sahubeastus01`
    - region: `eastus`
    - performance: `standard`
    - Redundancy: `LRS`
    - Networking:
      - Network connectivity:
        - Network access: `disable public access and use private access`
      - Private endpoint:
        - location: `eastus`
        - name: `pv-`sahubeastus01`-hub-eastus-01`
        - storage sub-resource: `file`
        - vnet: `vnet-hub-01`
        - subnet: `subnet01`
        - private dns integration: `yes`
    - Data protection: untick everything for easy cleanup after finish

  - storage account 2:
    - name: `sahubeastus01`
    - region: `eastus`
    - performance: `standard`
    - Redundancy: `LRS`
    - Networking:
      - Network connectivity:
        - Network access: `enable public access from selected virtual network and ip address`
      - Virutal networks:
        - vnet: `vnet-hub-01`
        - subnet: `subnet01`
    - Data protection: untick everything for easy cleanup after finish

**4. tạo file share trong các storage account:**
  - storage account list:
    - `sahubeastus01`
    - `sahubeastus01`
  - storage account > file share:
    - name: `test`
    - tier: `hot`

=> Môi trường lab đã chuẩn bị xong, giờ bắt đầu bài lab

---
## C. Bài lab:
### Mục tiêu:
- Tìm cách để VM `vm-spoke-eastus-01` có thể mount được file share `test` bên trong các storage account `sahubeastus01`, `sahubeastus01`
- Tìm cách access vào file share `test` của storage account `sahubeastus01` ở trên portal azure

### Steps:
**1. Test mount thử file share test của storage account `sahubeastus01`, `sahubeastus01`**
  - thay các biến trong script
  - Sử dụng 3 scripts để test xem có kết nối tới file share test được không
  >**Kết quả:** không thể kết nối tới file share test ở các storage account

  > **EXPLAIN:**
    Do `vnet-spoke-01` và `vnet-hub-01` chưa peering đến nhau nên VM `vm-spoke-eastus-01` không thể kết nối đến file share `test` trong các storage account `sahubeastus01`, `sahubeastus01`

**2. tạo vnet peering giữa spoke và hub vnet, test lại 3 scripts:**
  - trong vnet spoke > peering:
    - This virtual network:
      - peering link name: `vnet-spoke-01-to-vnet-hub-01`
      - Traffic to remote virtual network: `Allow`
      - Traffic forward from remote virtual network: `Allow`
    - Remote virtual network:
      - peering link name: `vnet-hub-01-to-vnet-spoke-01`
      - vnet: `vnet-hub-01`
      - Traffic to remote virtual network: `Allow`
      - Traffic forward from remote virtual network: `Allow`
  - mở `vnet-hub-01` > connected devices > note lại ip address của device `pv-sahubeastus01-hub-eastus.nic.<random>` (trong phần device của vnet này chỉ có 1 device thôi)
  - ở trong VM `vm-spoke-eastus-01`, test lại 3 scripts
  >**Kết quả:**thấy script `mount-fileshare-sahubeastus01-privateip.ps1`, `mount-fileshare-sahubeastus01.ps1` hoạt động được

  > **EXPLAIN:**
    Do `vnet-spoke-01` và `vnet-hub-01` đã peering đến nhau và allow traffic to remote virtual network nên VM `vm-spoke-eastus-01` có thể kết nối đến file share `test` của các storage account
    Đối với script `mount-fileshare-sahubeastus01-privatednszone.ps1` không hoạt động được là vì, VM `vm-spoke-eastus-01` không thể phân giải được ip address của `sahubeastus01.privatelink.file.core.windows.net`
    nên không thể kết nối được

**3.tạo virtual network links cho vnet vnet-spoke-01:**
  - Tìm private dns zone `privatelink.file.core.windows.net` ở trong resource group nơi `sahubeastus01` đang nằm ở bên trong private dns zone > virtual network links > add:
      - name: `pvl-to-vnet-spoke-01`
      - vnet: `vnet-spoke-01`
  - ở trong VM `vm-spoke-eastus-01`, test lại script `mount-fileshare-sahubeastus01-privatednszone.ps1`
  >**Kết quả:** thấy script chạy thành công

  > **EXPLAIN:**
    Do private dns zone đã link tới `vnet-spoke-01`, nên vm `vm-spoke-eastus-01` có thể sử dụng private dns zone này để phân ip address của `sahubeastus01.privatelink.file.core.windows.net`

**4. access vào file share test của storage account `sahubeastus01` ở trên portal azure:**
  - trong portal azure > `sahubeastus01` > file share > test:
  >**Kết quả:** sẽ thấy báo lỗi **this machine doesn't seem to have access**

  > **EXPLAIN:**
    Do ip address của con máy tính hiện chưa được add vào whitelist của firewall nên không thể access được vào file share test của `sahubeastus01`
  - quay lại `sahubeastus01` > networking > firewall and virtual networks > firewall > tick `Add your client IP address ('public ip address của bạn')`
    đợi 2-3' rồi access lại file share `test`
  >**Kết quả:** sẽ thấy access được vào file share `test` của storage account `sahubeastus01`
  
  > **EXPLAIN:**
    Do ip address của bạn đã được whitelist nên có thể access được vào file share `test` của storage account `sahubeastus01`
