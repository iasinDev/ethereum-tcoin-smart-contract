# ethereum-tcoin-smart-contract
Block chain council "Certified Blockchain Developer" TCoin Smart contract for Ethereum. This is the contract that is being developed at the course provided by the BlockChain Council.

## Deploy & test the smart contract

One possibility is to use a Ehereum test network (Ropsten, by instance). In this case, you will need to obtain some ethers from a faucet and deploy your contract... nevertheless I think this is not a very agile method when you are developing and testing your smart contract.

A more versatile option is to set up an Ethereum development network on your local machine:

1. Install Geth for your os, and make it available in the execution path
2. Install Mist
3. Run **`geth(.exe) --dev --ipcpath geth.ipc console`**
4. In the Geth RPEL console, type: **`personal.newAccount()`** (this will create the main account in yout development wallet)
5. Optionally, add new accounts to the development wallet
6. Start mining: Run **`miner.stop()`** , and after that  **`miner.start()`**
7. Without closing the Geth RPEL console, open Mist. It should be in *private network* mode
8. From the mist GUI you should have a lot of ethers available in the main wallet account. Just check it
9. Go to the *contracts* section, deploy new contract option. Select the main wallet account and copy & paste the source code for your smart contract
10. After the deploy, a new transaction should be started. When the new block is mined, the contract should be avilable in the *contracts* section
11. Selecting the deployed contract, you should be able to:
* Check the smart contract state (inspect the public variables)
* Invoke the smart contract operations

[Obtain Geth](URL "http://geth.ethereum.org/downloads/")

[Obtain Mist](URL "http://github.com/ethereum/mist/releases") 

More detailed info about how to set up an ethereum local development network can be found [here](URL "https://gist.github.com/evertonfraga/9d65a9f3ea399ac138b3e40641accf23") 
