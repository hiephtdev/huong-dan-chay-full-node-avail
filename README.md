# Hướng dẫn chạy full node Avail - Avail Full Node Setup Guide (Vietnamese - English)

## Phần 1: Sử dụng Binaries trên Ubuntu 22.04

1. Cài đặt môi trường bằng cách sao chép và thực thi các lệnh dưới đây:

    ```bash
    sudo apt-get -y update &&
    sudo apt-get -y install build-essential &&
    sudo apt-get -y install --assume-yes git clang curl libssl-dev protobuf-compiler && 
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh &&
    source ~/.cargo/env &&
    rustup default stable &&
    rustup update &&
    rustup update nightly && 
    rustup target add wasm32-unknown-unknown --toolchain nightly
    ```

2. Xây dựng phiên bản mới nhất của dự án Avail (v1.8.0.0):

    ```bash
    mkdir $HOME/avail-node &&
    git clone https://github.com/availproject/avail.git &&
    cd avail &&
    mkdir -p output &&
    mkdir -p $HOME/avail-node/data &&
    git checkout v1.8.0.0 &&
    cargo run --locked --release -- --chain goldberg -d ./output
    ```
    <img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/build.png">
    Đợi cho đến khi quá trình chạy hoàn tất, sau đó nhấn Ctrl + C.

3. Tạo dịch vụ hệ thống để khởi động ổn định hơn:

    ```bash
    sudo touch /etc/systemd/system/availd.service
    sudo nano /etc/systemd/system/availd.service
    ```

    Sau đó, dán lệnh sau vào tệp:

    ```
    [Unit] 
    Description=Avail Validator
    After=network.target
    StartLimitIntervalSec=0

    [Service] 
    User=root 
    ExecStart= $HOME/avail-node/avail/target/release/data-avail --base-path $HOME/avail-node/data --chain goldberg --port 30333  --rpc-cors=all --rpc-external --rpc-methods=unsafe --rpc-port 9933 --prometheus-port 9615  --validator --name "mysticwho-node"
    Restart=always 
    RestartSec=120

    [Install] 
    WantedBy=multi-user.target
    ```

    Trong lệnh trên, hãy lưu ý các thông tin sau:
    - `--name` là tên của node.
    - Các cổng `30333`, `9933`, `9615` cần phải được mở trong tường lửa. Nếu bạn sử dụng VPS, hãy cấu hình cho phép kết nối TCP/UDP qua các cổng này.

    Sau khi chỉnh sửa xong, nhấn Ctrl + O và sau đó nhấn Enter, sau đó nhấn Ctrl + X để thoát.

4. Kích hoạt và khởi động dịch vụ:

    ```bash
    systemctl enable availd.service && systemctl start availd.service
    ```

5. Kiểm tra trạng thái của dịch vụ:

    ```bash
    systemctl status availd.service
    ```
<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/service-status.png">

6. Xem logs khi chạy bằng lệnh:

    ```bash
    journalctl -f -u availd
    ```

## Phần 2: Sử dụng docker trên Ubuntu 22.04

1. Cài đặt docker chạy câu lệnh dưới đây

```bash
sudo apt-get update &&
sudo apt-get -y install ca-certificates curl gnupg &&
sudo install -m 0755 -d /etc/apt/keyrings &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
sudo chmod a+r /etc/apt/keyrings/docker.gpg &&
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update &&
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
sudo apt-get -y install docker-compose &&
sudo usermod -aG docker $USER &&
newgrp docker
```

2. Run câu lệnh sau để tạo lưu trữ data của node
```bash
mkdir $HOME/avail-node/data/keystore &&
mkdir $HOME/avail-node/data/state
```
3. Chạy container
```bash
docker run -v $(pwd)/state:/da/state:rw -v $(pwd)/keystore:/da/keystore:rw -e DA_CHAIN=goldberg -e DA_NAME=goldberg-docker-avail-Node -p 0.0.0.0:30333:30333 -p 9615:9615 -p 9944:9944 -d --restart unless-stopped availj/avail:v1.8.0.0
```
Trong lệnh trên, hãy lưu ý các thông tin sau:
    - `DA_NAME` là tên của node.
    - Các cổng `30333`, `9933`, `9615` cần phải được mở trong tường lửa. Nếu bạn sử dụng VPS, hãy cấu hình cho phép kết nối TCP/UDP qua các cổng này.


Để kiểm tra node của bạn, truy cập [https://telemetry.avail.tools/](https://telemetry.avail.tools/). Node của bạn sẽ được hiển thị sau khi hoàn tất quá trình đồng bộ và bắt đầu chạy.
<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/check-tool.png">

## Part 1: Using Binaries on Ubuntu 22.04

1. Set up the environment by copying and executing the following commands:

    ```bash
    sudo apt-get -y update &&
    sudo apt-get -y install build-essential &&
    sudo apt-get -y install --assume-yes git clang curl libssl-dev protobuf-compiler && 
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh &&
    source ~/.cargo/env &&
    rustup default stable &&
    rustup update &&
    rustup update nightly && 
    rustup target add wasm32-unknown-unknown --toolchain nightly
    ```

2. Build the latest version of the Avail project (v1.8.0.0):

    ```bash
    mkdir $HOME/avail-node &&
    git clone https://github.com/availproject/avail.git &&
    cd avail &&
    mkdir -p output &&
    mkdir -p $HOME/avail-node/data &&
    git checkout v1.8.0.0 &&
    cargo run --locked --release -- --chain goldberg -d ./output
    ```
     <img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/build.png">
    Wait for the process to complete, then press Ctrl + C.

3. Create a system service for more stable startup:

    ```bash
    sudo touch /etc/systemd/system/availd.service
    sudo nano /etc/systemd/system/availd.service
    ```

    Then, paste the following command into the file:

    ```
    [Unit] 
    Description=Avail Validator
    After=network.target
    StartLimitIntervalSec=0

    [Service] 
    User=root 
    ExecStart= $HOME/avail-node/avail/target/release/data-avail --base-path $HOME/avail-node/data --chain goldberg --port 30333  --rpc-cors=all --rpc-external --rpc-methods=unsafe --rpc-port 9933 --prometheus-port 9615  --validator --name "mysticwho-node"
    Restart=always 
    RestartSec=120

    [Install] 
    WantedBy=multi-user.target
    ```

    In the above command, please note the following information:

--name is the name of the node.
Ports 30333, 9933, 9615 must be opened in the firewall. If you are using a VPS, configure it to allow TCP/UDP connections through these ports.
After editing, press Ctrl + O and then Enter, then press Ctrl + X to exit.

4. Enable and start the service:

    ```bash
    systemctl enable availd.service && systemctl start availd.service
    ```

5. Check the service status:

    ```bash
    systemctl status availd.service
    ```
<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/service-status.png">

6. View logs while running with the following command:

    ```bash
    journalctl -f -u availd
    ```

## Part 2: Using Docker on Ubuntu 22.04

1. Install Docker by running the following commands:

```bash
sudo apt-get update &&
sudo apt-get -y install ca-certificates curl gnupg &&
sudo install -m 0755 -d /etc/apt/keyrings &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&
sudo chmod a+r /etc/apt/keyrings/docker.gpg &&
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update &&
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
sudo apt-get -y install docker-compose &&
sudo usermod -aG docker $USER &&
newgrp docker
```

2. Run the following command to create data storage for the node:
```bash
mkdir $HOME/avail-node/data/keystore &&
mkdir $HOME/avail-node/data/state
```
3. Run the Docker container:
```bash
docker run -v $(pwd)/state:/da/state:rw -v $(pwd)/keystore:/da/keystore:rw -e DA_CHAIN=goldberg -e DA_NAME=goldberg-docker-avail-Node -p 0.0.0.0:30333:30333 -p 9615:9615 -p 9944:9944 -d --restart unless-stopped availj/avail:v1.8.0.0
```
In this step, make sure to replace `DA_NAME=goldberg-docker-avail-Node` with your node's name. Also, ensure that ports `30333, 9933, 9615` are opened in the firewall. If you are using a VPS, configure it to allow TCP/UDP connections through these ports.


To check your node, visit [https://telemetry.avail.tools/](https://telemetry.avail.tools/). Your node will be displayed after the synchronization process is complete and the node starts running.
<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/check-tool.png">


