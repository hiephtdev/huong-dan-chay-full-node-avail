# How to upgrade avail full node

## 1. Stop service
```bash
sudo systemctl stop availd.service
```

## 2. Pull new tag from github
```bash
read -p "Enter tag name: " AVAIL_TAG &&
cd $HOME/avail-node &&
git fetch &&
git pull && 
git checkout $AVAIL_TAG &&
cargo run --locked --release -- --chain goldberg --validator -d ./output
```

<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/build.png">

**Wait for the process to complete, then press Ctrl + C.**

## 3. Remove old data and get snapshot

```bash
sudo apt update -y &&
sudo apt install snapd -y &&
sudo snap install lz4 &&
```

Remove old data
```bash
rm -r [HOME_PATH]/avail-node/data/chains/avail_goldberg_testnet/db
```

**In the above command, please note the following information:**

-  `[HOME_PATH]` type the command $HOME and copy the path to replace in `[HOME_PATH]` above as shown in the example below. Replace `[HOME_PATH]` with `/home/tuan` like this: `[HOME_PATH]/avail-node/avail/target/release/data-avail` will become `/home/tuan/avail-node/avail/target/release/data-avail`, `[HOME_PATH]/avail-node/data` will become `/home/tuan/avail-node/data`.  
<img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/home.png">

Copy snapshot data
```bash
curl -o - -L http://snapshots.staking4all.org/snapshots/avail/latest/avail.tar.lz4 | lz4 -c -d - | tar -x -C [HOME_PATH]/avail-node/data/chains/avail_goldberg_testnet/
```

**In the above command, please note the following information:**

-  `[HOME_PATH]` type the command $HOME and copy the path to replace in `[HOME_PATH]` above as shown in the example below. Replace `[HOME_PATH]` with `/home/tuan` like this: `[HOME_PATH]/avail-node/avail/target/release/data-avail` will become `/home/tuan/avail-node/avail/target/release/data-avail`, `[HOME_PATH]/avail-node/data` will become `/home/tuan/avail-node/data`.
 <img src="https://github.com/hiephtdev/huong-dan-chay-full-node-avail/blob/main/home.png">

## 4. Start the service

```bash
sudo systemctl start availd.service &&
systemctl status availd.service
```
