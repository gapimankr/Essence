NONE='\033[00m'
RED='\033[01;91m'
GREEN='\033[01;32m'

echo "${RED}Installing required packages, done in 3 steps. ${NONE}";

echo "${RED}1. Installing swap file. ${NONE}";
#setup swap to make sure there's enough memory for compiling the daemon 
dd if=/dev/zero of=/mnt/myswap.swap bs=1M count=4000
mkswap /mnt/myswap.swap
chmod 0600 /mnt/myswap.swap
swapon /mnt/myswap.swap

echo "${RED}2. Installing dependencies. ${NONE}";
#download and install required packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install software-properties-common -y
sudo apt-get install git -y
sudo apt-get install wget -y
sudo apt-get install curl -y
sudo apt-get install nano -y
sudo apt-get install htop -y

sudo apt-get install build-essential libtool automake autoconf -y
sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -y
sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libminiupnpc-dev -y

sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

#get essence client from github, compile the client
echo "${RED}3. Installing Essence client. ${NONE}";
cd $HOME
sudo mkdir $HOME/essence
git clone https://github.com/essencecoin/essence.git essence
cd $HOME/essence
chmod +x autogen.sh
./autogen.sh
./configure --disable-tests
chmod +x share/genbuild.sh
sudo make
sudo make install

#setup config file for the masternode
sudo apt-get install pwgen -y

echo "${RED}Installation completed. ${NONE}";

#get masternode key from user
echo "${RED}Paste here your masternode key (right mouse click) and confirm with Enter ${NONE}";
read KEYM

sudo mkdir $HOME/.essencecore
PASSWORD=`pwgen -1 20 -n`
EXTIP=`wget -qO- ident.me`
printf "rpcuser=essenceuser\nrpcpassword=$PASSWORD\nrpcallowip=127.0.0.1\nrpcport=3554\nexternalip=$EXTIP:3553\nserver=1\ndaemon=1\nlisten=1\nmaxconnections=512\nmasternode=1\nmasternodeprivkey=$KEYM\naddnode=82.223.83.67:3553\naddnode=82.223.70.105:3553\naddnode=82.223.66.67:3553\naddnode=82.223.49.215:3553\naddnode=82.223.49.135:3553\naddnode=82.223.81.224:3553\naddnode=206.189.159.126:3553\naddnode=91.241.59.243:3553\naddnode=185.234.15.87:3553\naddnode=85.217.170.152:3553\naddnode=173.249.17.201:3553\naddnode=66.172.11.157:3553\naddnode=188.130.251.215:3553" > /$HOME/.essencecore/essence.conf


#start the client and make sure it's synced before confirming completion
essenced --daemon
sleep 3

echo "${RED}Waiting for your Essence client to fully sync with the network, this can take a while. ${NONE}";
block=1
while true
do
	realblock=`essence-cli getblockcount` 
	echo "Block: $realblock" #write block
	if [ $realblock -eq $block ] #check block if is done
	then 
		sleep 60
		realblock=$((`essence-cli getblockcount`))
		if [ $realblock -eq $block ] #second check block if is done
		then 
			echo "${RED}Synced will be done in 4 steps. ${NONE}"
			break
		fi
	fi
	block=$((realblock))
	sleep 5	
done

echo "${RED}1. Blockchain sync start.${NONE}"
until essence-cli mnsync status | grep -m 1 '"IsBlockchainSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}BlockchainSynced done. ${NONE}"

echo "${RED}2. Masternode List sync start.${NONE}"
until essence-cli mnsync status | grep -m 1 '"IsMasternodeListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}MasternodeListSynced done. ${NONE}"

echo "${RED}3. Winners List sync start.${NONE}"
until essence-cli mnsync status | grep -m 1 '"IsWinnersListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}WinnersListSynced done. ${NONE}"

echo "${RED}4. Sync start.${NONE}"
until essence-cli mnsync status | grep -m 1 '"IsSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}Sync done. ${NONE}"

echo "${RED}Setting up your VPS is finish. You can now start MasterNode in your wallet. ${NONE}"; 

echo "${RED}Waiting that MasterNode start.${NONE}"
until essence-cli masternode status | grep -m 1 '"status": "Masternode successfully started"'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}Done! Masternode successfully started, now you can close connection and wait until in your wallet will write ENABLED.${NONE}"

echo ""
echo "If this guild help you, then you can sent me some tips ;) ESS ER5fnEkiVoufF7b28WgkPMMR78ac44RHU6 BTC 12nxh3nUTJHve3XGaXrh692xQZMVLJLFJm DOGE DJbHoCkzwzqjyrJxT1hGwN1rzZdJFzBseG"
