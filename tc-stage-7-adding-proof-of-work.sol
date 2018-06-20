pragma solidity ^0.4.17;

contract Admined {
    address public admin;
    event AdminWasChanged(address indexed oldAdmin, address indexed newAdmin);
    
    function Admined(address centralAdmin) public {
        admin = centralAdmin != 0 ? centralAdmin : msg.sender;
    }

    modifier onlyAdmin () {
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address newAdmin) onlyAdmin public {
        address oldAdmin = admin;
        admin = newAdmin;
        
        emit AdminWasChanged(oldAdmin, admin);
    }
}

contract TCoin {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) allowance;

    string public standard = "TCoin v1.0";
    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply;
    event AmountWasTransfered(address indexed from, address indexed to, uint256 indexed amount);

    function TCoin(uint256 initialSupply, string tokenName, 
        string tokenSymbol, uint8 decimalUnits) public 
    {
        balanceOf[msg.sender] = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimal = decimalUnits;
        totalSupply = initialSupply;
    }    

    function transfer (address receiver, uint256 amount) public {        

        rawTransfer(msg.sender, receiver, amount);
    }    

    function aproveTransfer(address authorizedSpenderInBehalfOfMe, uint256 spendLimit) public returns (bool success) {
        
        allowToSpendInBehalfOfMe(authorizedSpenderInBehalfOfMe, spendLimit);
        
        return true;
    }

    function transferInBehalfOf(address spender, address receiver, uint256 amount) public returns (bool success) {
                
        require(amIAllowedToSpendInBehalfOf(spender, amount));        

        rawTransfer(spender, receiver, amount);  
        decrementSpendAuthorization(spender, msg.sender, amount);                    

        return true;
    }

    function allowToSpendInBehalfOfMe(address authorizedSpender, uint256 amount) private {
        authorizeToSpend(msg.sender, authorizedSpender, amount);
    }

    function decrementSpendAuthorization(address principal, address authorizedSpender, uint256 decrement) private {

        require(decrement >= 0);
        
        uint256 previousAuthorizedAmount = authorizedAmountToSpend(principal, authorizedSpender);

        assert(previousAuthorizedAmount >= 0);

        uint256 newSpendLimit = previousAuthorizedAmount - decrement;

        assert(newSpendLimit >= 0);
        
        authorizeToSpend(principal, authorizedSpender, newSpendLimit);        
    }

    function authorizeToSpend(address principal, address authorizedSpender, uint256 amount) private {
        allowance[principal][authorizedSpender] = amount;        
    }

    function authorizedAmountToSpend(address principal, address authorizedSpender) private view returns (uint256 authorizedAmount){
        return allowance[principal][authorizedSpender];        
    }

    function amIAllowedToSpendInBehalfOf(address spender, uint256 amount) private view returns (bool allowed) {
        return allowance[spender][msg.sender] >= amount;
    }    

    function rawTransfer(address sender, address receiver , uint256 amount) private {

        require(balanceOf[sender] >= amount);
        assert(!overflowIsReached(balanceOf[receiver], amount)); 

        uint256 prevAmountSender = balanceOf[sender];
        uint256 prevAmountReceiver = balanceOf[receiver];

        balanceOf[sender] -= amount;
        balanceOf[receiver] += amount;

        assert(balanceOf[sender] >= 0);
        assert(balanceOf[receiver] >= 0);

        assert(balanceOf[sender] == prevAmountSender - amount);
        assert(balanceOf[receiver] == prevAmountReceiver + amount);

        emit AmountWasTransfered(sender, receiver, amount);
    }

    function overflowIsReached(uint256 baseAmount, uint256 increment) 
        private pure returns (bool overflow) 
    {
        return (baseAmount + increment) < baseAmount;
    }
}

contract AdvancedTCoin is TCoin, Admined {

    mapping (address => bool) public frozenAccounts;
    uint256 sellPrice;
    uint256 buyPrice;
    uint256 minimumWei = 5 finney;

    event AccountFreezeStatusHasBeenUpdated(address indexed frozenAccount, bool freezeStatus);
    
    function AdvancedTCoin(address admin, uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) 
        TCoin(initialSupply, tokenName, tokenSymbol, decimalUnits) Admined(admin) public {

        balanceOf[msg.sender] = 0;
        balanceOf[admin] = initialSupply;
    }

    modifier isNotFrozen(address account) {
        require(!frozenAccounts[account]);
        _;
    }

    modifier hasEnoughFunds(address account, uint256 minimunAmount) {
        require(balanceOf[account] >= minimunAmount);
        _;
    }

    function mintToken(address receiver, uint256 mintedAmount) onlyAdmin public {
        
        require(mintedAmount > 0);

        balanceOf[receiver] += mintedAmount;
        totalSupply += mintedAmount;

        emit AmountWasTransfered(this, receiver, mintedAmount);
    }

    function freezeAccount(address account, bool freezeStatus) onlyAdmin public {

        frozenAccounts[account] = freezeStatus;

        emit AccountFreezeStatusHasBeenUpdated(account, freezeStatus);
    }

    function transfer (address receiver, uint256 amount) isNotFrozen(msg.sender) public { 
        
        sellTCoinsIfEtherFundsAreNotEnoughToOperate();
        
        super.transfer(receiver, amount);
    }

    function transferInBehalfOf(address spender, address receiver, uint256 amount) isNotFrozen(spender) public returns (bool success) {
        return super.transferInBehalfOf(spender, receiver, amount);
    }

    function setBuyPrice(uint256 priceInEthers) onlyAdmin public {
        buyPrice = priceInEthers;
    }

    function setSellPrice(uint256 priceInEthers) onlyAdmin public {
        sellPrice = priceInEthers;
    }

    function buy() payable hasEnoughFunds(this, weiToTcoins(msg.value)) public {
        
        uint256 purchasedTCoins = weiToTcoins(msg.value);

        balanceOf[msg.sender] += purchasedTCoins;
        balanceOf[this] -= purchasedTCoins;

        emit AmountWasTransfered(this, msg.sender, purchasedTCoins);
    }

    function sell(uint256 tcoinsAmount) hasEnoughFunds(msg.sender, tcoinsAmount) public {
        require(msg.sender.send(tcoinsToWei(tcoinsAmount)));

        uint256 prevAmountSender = balanceOf[msg.sender];
        uint256 prevAmountContract = balanceOf[this];

        balanceOf[msg.sender] -= tcoinsAmount;
        balanceOf[this] += tcoinsAmount;

        assert(balanceOf[msg.sender] >= 0);
        assert(balanceOf[this] >= 0);
        
        assert(balanceOf[msg.sender] == prevAmountSender - tcoinsAmount);
        assert(balanceOf[this] == prevAmountContract + tcoinsAmount);
    }

    function weiToTcoins(uint256 weiAmount) view public returns (uint256 tcoinAmount) {
        return (weiAmount / (1 ether)) / buyPrice;
    }
    
    function pp() view public returns (string[] result) {
        String[] a = {"uno"};

        return a;
    }


    function tcoinsToWei(uint256 tcoinsAmount) view public returns  (uint256 weiAmount) {
        return tcoinsAmount * sellPrice * (1 ether);
    } 

    function sellTCoinsIfEtherFundsAreNotEnoughToOperate() private {
        if (msg.sender.balance < minimumWei){
            
            uint256 remainingWeiToReachMinimum = minimumWei - msg.sender.balance;
            uint256 neededTCoinsToSell = remainingWeiToReachMinimum / sellPrice;

            sell(neededTCoinsToSell);
        }       
    }

    function giveProofReward() public {
        balanceOf[block.coinbase] += 1;
    }

    bytes32 public currentChallenge;
    uint public timeOfLastProof;
    uint public difficulty = 10**32;

    function proofOfWork(uint nonce) public {

        bytes8 guessedNumber = bytes8(keccak256(nonce,currentChallenge));
        require(guessedNumber >= bytes8(difficulty));

        uint timeSinceLastBlock = now - timeOfLastProof;
        require(timeSinceLastBlock >= 5 seconds);

        balanceOf[msg.sender] += timeSinceLastBlock / 60 seconds;
        
        difficulty = difficulty * 10 minutes / timeOfLastProof + 1;
        currentChallenge = keccak256(nonce, currentChallenge, block.blockhash(block.number - 1));
        timeOfLastProof = now;
    }
}