# Lab: làm quen với endpoint và service endpoint
## Mục tiêu: 
- Hiểu được cách tạo và cấu hình network virtual appliance để route traffic
- Hiểu được cách tạo và cấu hình route table
- Route traffic thông qua network virtual appliance

---
## A. Chuẩn bị trước bài lab:
N/A

---
## B. Chuẩn bị môi trường lab
**1. tạo ra 1 vnet:**
  - vnet 1:
    - name: `vnet-01`
    - region: `eastus`
    - ip address range: `192.170.0.0/16`
    - subnets:
        - subnet 1:
            - name: `public-subnet`
            - ip address range: `192.170.0.0/24`
        - subnet 2:
            - name: `private-subnet`
            - ip address range: `192.170.1.0/24`
        - subnet 3:
            - name: `dmz-subnet`
            - ip address range: `192.170.2.0/24`
    - bastion:
        - name: `bastion-eastus-01`
        - AzureBastionSubnet address range: `192.170.3.0/24`
        - Public IP address:

**2. tạo VM cho các subnet:**
  - vm 1:
    - name: `vmnva`
    - region: `eastus`
    - image: `windows data center 2019`
    - size: `B2s`
    - username: `lab`
    - password: `1234567890a@`
    - Public inboud port: `none`
    - OS disk type: `standard ssd`
    - vnet:
      - name: `vnet-01`
      - subnet: `dmz-subnet`
      - nic network security group: `basic`
      - public ip: `none`
    - vm 2
    - name: `vmpublic`
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
      - nic network security group: `basic`
      - public ip: `none`
    - vm 3:
    - name: `vmprivate`
    - region: `eastus`
    - image: `windows data center 2019`
    - size: `B2s`
    - username: `lab`
    - password: `1234567890a@`
    - Public inboud port: `none`
    - OS disk type: `standard ssd`
    - vnet:
      - name: `vnet-01`
      - subnet: `private-subnet`
      - nic network security group: `basic`
      - public ip: `none`

**3. Cấu hình Allow IMCP trên Windows Firewall của VM :**
  - Sử dụng Bastion Host để connect đến các VM
  - Mở powershell và run command bên dưới:
  > ``New-NetFirewallRule –DisplayName "Allow ICMPv4-In" –Protocol ICMPv4``

**4. tạo route table cho `public-subnet` :**
  - route table :
    - name: `rt-publicsubnet-eastus-01`
    - region: `eastus`
  - Sau khi tạo xong route table, tạo 1 đường route:
    - `rt-publicsubnet-eastus-01` > Route > Add:
      - Destination IP addresses/CIDR ranges: `192.170.1.0/24` (CIDR range của `private-subnet`)
      - Next hop type: `Virtual Appliance`
      - Next hop address: Private IP Address của VM `vmnva`

=> Môi trường lab đã chuẩn bị xong, giờ bắt đầu bài lab

---
## C. Bài lab:
### Mục tiêu:
- Tìm cách để VM `vmpublic` connect đến VM `vmprivate` thông qua VM `vmnva`

### Steps:
**1. Test remote desktop và tracert từ VM `vmpublic` đến VM `vmprivate`:**
  - Sử dụng bastion host để connect đến VM `vmpublic`
  - Bên trong VM `vmpublic` remote thử đến VM `vmprivate`
  >**Kết quả:** Có thể remote bình thường
  - Mở Powershell
    - Ở trong VM `vmpublic` run command:
    > ``tracert vmprivate``
    - Ở trong VM `vmprivate` run command:
    > ``tracert vmpublic``

    >**Kết quả:** Sẽ thấy chỉ có duy nhất 1 hop để đến destination ở cả 2 host

  > **EXPLAIN:**
    >- Do network security group hiện tại có rule allow `any` protocol với source là `Virtual Network`
    >- Hiện tại chưa có route table nào associate với `public-subnet` nên VM `vmpublic` có thể remote và tracert chỉ có 1 hop trực tiếp đến `vmprivate`


**2. Cấu hình route table:**
  - ở trên portal Azure tìm vnet `vnet-01` > subnet > `public-subnet` > Route table > chọn rt-publicsubnet-eastus-01
  - sử dụng bastion host để connect đến VM `vmnva` và dùng Powershell run command bên dưới để bật IP Forwarding
  > ``Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name IpEnableRouter -Value 1``
  - ở trên portal Azure tìm VM `vmnva` > Networking > chọn Network Interface > IP configuration > Enable IP Forwarding
  - Restart VM `vmnva`

**3. Test remote desktop và tracert từ VM `vmpublic` đến VM `vmprivate` lại:**
  - Sử dụng bastion host để connect đến VM `vmpublic`
  - Bên trong VM `vmpublic` remote thử đến VM `vmprivate`
  >**Kết quả:** không thể remote
  - Mở Powershell
    - Ở trong VM `vmpublic` run command:
    > ``tracert vmprivate``

    >**Kết quả:** Sẽ thấy có 2 hop để đến destination
    - Ở trong VM `vmprivate` run command:
    > ``tracert vmpublic``

    >**Kết quả:** Sẽ thấy chỉ có duy nhất 1 hop để đến destination

  > **EXPLAIN:**
    >- Do network security group hiện tại có rule allow `any` protocol với source là `Virtual Network`
    >- Do hiện tại dã có route table associate với `public-subnet` nên VM `vmpublic` không thể remote và tracert 2 hops để đến `vmprivate`
    >- Đối với VM `vmprivate` tracert chỉ có 1 hop để đến VM `vmpublic`, do không có route table gán với subnet `private-subnet`
