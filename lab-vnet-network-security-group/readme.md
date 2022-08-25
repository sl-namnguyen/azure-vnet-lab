# Lab: làm quen với endpoint và service endpoint
## Mục tiêu: 
- Hiểu được cách tạo và cấu hình network security group để filter traffic
- Tạo Virtual Machine và cấu hình Application Security Group

---
## A. Chuẩn bị trước bài lab:
N/A

---
## B. Chuẩn bị môi trường lab
**1. tạo ra 1 vnet:**
  - vnet 1:
    - name: `vnet-02`
    - region: `eastus`
    - ip address range: `192.171.0.0/16`
    - subnets:
        - subnet 1:
            - name: `subnet01`
            - ip address range: `192.171.0.0/24`

**2. tạo 2 VM cho subnet:**
  - vm 1:
    - name: `vmmgmt`
    - region: `eastus`
    - image: `windows data center 2019`
    - size: `B2s`
    - username: `lab`
    - password: `1234567890a@`
    - Public inboud port: `none`
    - OS disk type: `standard ssd`
    - vnet:
      - name: `vnet-01`
      - subnet: `subnet01`
      - nic network security group: `none`
      - public ip: create new
    - vm 2
    - name: `vmweb`
    - region: `eastus`
    - image: `windows data center 2019`
    - size: `B2s`
    - username: `lab`
    - password: `1234567890a@`
    - Public inboud port: `none`
    - OS disk type: `standard ssd`
    - vnet:
      - name: `vnet-01`
      - subnet: `public-subnet`
      - nic network security group: `none`
      - public ip: create new

**3. Tạo Network Security Group :**
  - Network security group:
    - name: `nsgsubnet`
    - region `eastus`

**4. tạo 2 Application Security Group :**
  - Application Security Group:
    - Application Security Group 1:
        - name: `asgmgmtserver`
        - region: `eastus`
    - Application Security Group 2:
        - name: `asgwebserver`
        - region: `eastus`

=> Môi trường lab đã chuẩn bị xong, giờ bắt đầu bài lab

---
## C. Bài lab:
### Mục tiêu:
- Tìm cách để Remote Desktop (RDP) vào VM `vmmgmt`
- Cài đặt IIS web server trên VM `vmweb`
- Access vào web của VM `vmweb` từ browser của máy tính

### Steps:
**1. Test remote desktop từ máy tính tới VM `vmmgmt` và VM `vmweb`:**
  - Download file RDP từ portal Azure của 2 VMs `vmmgmt` `vmweb` và RDP thử
  >**Kết quả:** không thể remote được

  > **EXPLAIN:**
  Do các VM hiện tại không có network security group => không có rule allow RDP đến nên không thể RDP được

**2. Gán Application Security Group cho các VMs:**
  - ở trên portal Azure mở VM `vmmgmt` > Networking > Application Security Group > Configure the application security groups > chọn `asgmgmtserver`
  - ở trên portal Azure mở VM `vmweb` > Networking > Application Security Group > Configure the application security groups > chọn `asgwebserver`

**3. Cấu hình Network Security Group cho subnet:**
  - ở trên portal Azure mở vnet `vnet-02` > subnet > chọn `subnet01` > Network Security Group > chọn `nsgsubnet` > chọn OK
  - Mở Network Security Group `nsgsubnet` > Inbound security rules:
    - Tạo ra 2 rules mới:
      - rule 1:
        - source: `Any`
        - Source port range: để default `*`
        - Destination: `Application Security Group`
          - Destination application security groups: `asgmgmtserver`
        - Service: `RDP`
        - Action: `Allow`
        - Name: `allow-rdp-all`
      - rule 12
        - source: `Any`
        - Source port range: để default `*`
        - Destination: `Application Security Group`
          - Destination application security groups: `asgwebserver`
        - Service: `Custom`
        - Destination port ranges: `80,443`
        - Action: `Allow`
        -Name: `allow-http-https-all`

**4. Test remote desktop từ máy tính tới VM `vmmgmt` và VM `vmweb` lần nữa:**
  - Download file RDP từ portal Azure của 2 VMs `vmmgmt` `vmweb` và RDP thử
  >**Kết quả:** có thể remote tới VM `vmmgmt` nhưng không thể remote tới VM `vmweb`

  > **EXPLAIN:**
  >- Do Network Security Group gán ở subnet có rule cho phép RDP đến Application security group `asgmgmtserver`, và `asgmgmtserver` hiện đang gán cho VM `vmmgmt`. Nên có thể remote đến VM `vmmgmt` được.
  >- Đối với VM `vmweb` cũng có rule allow đến **Application security group** `asgwebserver` nhưng do **Destination port ranges** là **80,443** nên không thể RDP được

**5. remote vào VM `vmweb` thông qua vm `vmmgmt` và cài đặt web server :**
 - RDP vào VM `vmmgmt`
 - bên trong VM `vmmgmt` RDP vào VM `vmweb` và mở Powershell run command bên dưới để cài đặt IIS (web server):
 >``Install-WindowsFeature -name Web-Server -IncludeManagementTools``

**6. Truy cập vào web bằng cách sử dụng public ip của VM `vmweb` :**
  - Ở trên portal Azure tìm VM `vmweb` > copy public ip address
  - mở trình duyệt web và điền `http://<public ip address>`
  >**Kết quả:** có thể truy cập vào trang web mặc định của IIS của VM `vmweb`

  > **EXPLAIN:**
  >- Do Network Security Group gán ở subnet có rule cho phép truy cập vào port 80,443 (http và htttps) đến Application security group `asgwebserver`, và `asgmgmtserver` hiện đang gán cho VM `vmweb` nên ta có thể access được website