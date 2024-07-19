#!/bin/bash

function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}

# Function to install Node.js if not installed
function install_node {
    if ! command -v node &> /dev/null
    then
        echo_blue_bold "Node.js not found. Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
}

# Function to install npm if not installed
function install_npm {
    if ! command -v npm &> /dev/null
    then
        echo_blue_bold "npm not found. Installing npm..."
        sudo apt install -y npm
    fi
}

# Ensure Node.js and npm are installed
install_node
install_npm

echo
echo_blue_bold "Enter RPC URL of the network:"
read providerURL
echo
echo_blue_bold "Enter private key:"
read privateKeys
echo
echo_blue_bold "Enter contract address:"
read contractAddress
echo
echo_blue_bold "Enter transaction data (in hex):"
read transactionData
echo
echo_blue_bold "Enter gas limit:"
read gasLimit
echo
echo_blue_bold "Enter base fee (in gwei):"
read baseFee
echo
echo_blue_bold "Enter max fee (in gwei):"
read maxFee
echo
echo_blue_bold "Enter priority fee (in gwei):"
read priorityFee
echo
echo_blue_bold "Enter number of transactions to send:"
read numberOfTransactions
echo

if ! npm list ethers@5.5.4 >/dev/null 2>&1; then
  echo_blue_bold "Installing ethers..."
  npm install ethers@5.5.4
  echo
else
  echo_blue_bold "Ethers is already installed."
fi
echo

temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "${providerURL}";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

const privateKeys = "${privateKeys}";

const contractAddress = "${contractAddress}";

const transactionData = "${transactionData}";

const numberOfTransactions = ${numberOfTransactions};

async function sendTransaction(wallet) {
    const tx = {
        to: contractAddress,
        value: 0,
        gasLimit: ethers.BigNumber.from(${gasLimit}),
        maxFeePerGas: ethers.utils.parseUnits("${maxFee}", 'gwei'),
        maxPriorityFeePerGas: ethers.utils.parseUnits("${priorityFee}", 'gwei'),
        data: transactionData,
    };

    try {
        const transactionResponse = await wallet.sendTransaction(tx);
        console.log("\033[1;35mTx Hash:\033[0m", transactionResponse.hash);
        const receipt = await transactionResponse.wait();
        if (receipt.status === 0) {
            throw new Error('Transaction failed with status 0');
        }
        console.log("Transaction successful with receipt:", receipt);
        console.log("");
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

async function main() {
    const wallet = new ethers.Wallet(privateKeys, provider);

    for (let i = 0; i < numberOfTransactions; i++) {
        console.log("Sending transaction", i + 1, "of", numberOfTransactions);
        await sendTransaction(wallet);
    }
}

main().catch(console.error);
EOF

NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

rm $temp_node_file
echo
echo_blue_bold "Stay Frosty DEGEN"
echo
