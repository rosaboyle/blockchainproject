// =========================== ERC20 Token Contract =================
// 000000000000000000
// Contract 0xC7cb0291e6B19188EEF93e03d08442D15783cE16
/* MyAdvancedToken.sol

   Modified from https://ethereum.org/token.

   This contract has instructional documentation.

   Within 2_deploy_migration.js we deploy and call the constructor
   with 1300 tokens for Alice.

   var aliceToken = artifacts.require("./MyAdvancedToken.sol");
   module.exports = function(deployer) {
     deployer.deploy(aliceToken, 1300, "Alice Coin","AC");
   };


   Deploy the contract with Truffle.
   truffle migrate --reset

   Run truffle console:

   truffle console


   Within the console, get access to this contract deployed on Ganache:

   var Web3 = require('web3');
   var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
   web3.isConnected()
   MyAdvancedToken.deployed().then(function(x){ app = x; });
   app

   To use accounts on Ganache:

   accounts = web3.eth.accounts
   Alice = accounts[0];
   Bob = accounts[1];
   Charlie = accounts[2];
   Donna = accounts[3];

   etc.


   To get the address of the contract into a convenient variable.
   contract = '0x address from Ganache in quotes'

   To access the balance of account[0] - by default the output is in Wei
   web3.eth.getBalance(web3.eth.accounts[0]).toNumber();

   To transform this into Ether, use the following:

   web3._extend.utils.fromWei(web3.eth.getBalance(web3.eth.accounts[0]).toNumber(), 'ether')

   An optional note on debugging:

       establish an event

       event Debug(string text, uint value);

       code that works

       Debug('Note this ', uint(addr));
       return;  // You may not want to continue.
                // On throw all is reverted and no events are logged.
       problem code here
*/



pragma solidity 0.5.17;

contract Task {

    address payable creator;
    uint256 minBid;
    uint256 CurValue;
    address payable selectedBidder;
    bool finalized; // Bidder selected
    bool accepted;
    
    constructor(uint256 _minBid, address payable _creator) public {
        creator = _creator;
        minBid = _minBid;
        finalized = false;
        accepted = false;
        
    }
}


contract owned {
    // This state variable holds the address of the owner
    // In truffle:  app.owner().then( n => {c = n})
    // c.toString()

    address public owner;
    // The original creator is the first owner.

    // The constructor is called once on first deployment.
    constructor() public {
        owner = msg.sender;
    }


    // Add this modifier to restrict function execution
    // to only the current owner.

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    // Establish a new owner.
    // The owner calls with the address of the new owner.
    // Suppose deployer Alice gives ownership to Bob.
    // In truffle app.transferOwnership(Bob).then( n => {c = n})
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


// This interface may be implemented by another contract on the blockchain.
// We can call this function in the other contract.
// We are telling the other contract that it has been approved to
// withdraw from a particular address up to a particular value.
// We include the address of this token contract.

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    Task[] public tasks;

    /* We can read these data from truffle with command such as
     app.name().then( n => {c = n})
     c
    */

    // totalSupply established by constructor and increased
    // by mintToken calls

    uint256 public totalSupply;

    /* To access totalSupply in truffle
    app.totalSupply().then( n => {c = n})
    c.toString();
    */

    // This creates an array with all balances.
    // Users (Alice, Bob, Charlie) may have balances.
    // So may the contract itself have a balance.
    // 0 or more addresses and each has a balance.

    mapping (address => uint256) public balanceOf;

    // The token balances are kept with 10^decimal units.
    // If the number of tokens is 1 and we are using 2 decimals
    // then 100 is stored.

    /* To access balanceOf
    app.balanceOf(Alice).then( n => {c = n})
    c.toString();
    */

    // 0 or more addresses and each has 0 or more addresses each with
    // an allowance.
    // The allowance balances are kept with 10^decimal units.

    mapping (address => mapping (address => uint256)) public allowance;

    // access with truffle. How much has Alice allowed Bob to use?

    /*
     app.allowance(Alice,Bob).then( n => {c = n})
     c.toString();
    */

    // This generates a public event on the blockchain that can be
    // used to notify clients.
    // In truffle, upon receipt of response c, examine c.logs[0].args

    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that can be
    // used to notify clients.

    event CreateTask(address indexed from, uint256 value);
    event BidTask(address indexed from, uint256 value);
    event AcceptBid(address indexed from, uint256 value);


    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This can be used to notify clients of the amount of tokens burned.

    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function executes once upon deployment.
     *
     * Initializes the contract with an initial supply of
     * tokens and gives them all to the creator of the
     * contract.
     */

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        // In traditional money, if the initialSupply is 1 dollar then
        // the value stored would be 1 x 10 ^ 2 = 100 cents.
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }



    /**
     * Internal transfer, only can be called by this contract.
     * Move tokens from one account to another.
     * Preconditions are specified in the require statements.
     */

     

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        // Check if from has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the from address
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        balanceOf[_to] += _value;

        // Make notification of the transfer
        emit Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code.
        // They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function _createTask(address _from, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead

        // Check if from has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows

        

        // Subtract from the from address
        balanceOf[_from] -= _value;

        // TODO: Create a new account or subcontract on with for this Task.

        // Add the same to the recipient

        // Make notification of the transfer

        emit CreateTask(_from, _value);

        // Asserts are used to use static analysis to find bugs in your code.
        // They should never fail
        // assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


     /* Public transfer of tokens.
        Calls the internal transfer with the message sender as 'from'.
        The caller transfers its own tokens to the specified address.
        precondition: The caller has enough tokens to transfer.
        postcondition: The caller's token count is lowered by the passed value.
                       The specified address gains tokens.
        Called from truffle with:
        Alice (sending transaction) transfers 50 tokens to Bob
        app.transfer(Bob,'50000000000000000000').then( n => {c = n})
        c
        c is a receipt
        c.logs shows the Transfer event
        c.logs[0]
        c.logs[0].logIndex
        v = c.logs[0].args.value
        v.toString()   shows '50000000000000000000'

        Bob transfers 50 tokens to Charlie.
        Bob's address included in the transaction.
        Bob pays for this in ether.
        app.transfer(Charlie,'50000000000000000000',{from:Bob}).then( n => {c = n})

    */

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function createTaskFunc(uint256 _value) public returns (bool success) {
        _createTask(msg.sender, _value);
        return true;
    }



     /* This is a public approve function.
        The message sender approves the included address to
        spend from the sender's account. The upper limit of this approval
        is also specified.
        It only modifies the allowance mapping.
        sender --> spender ---> amount.
        This generates an Approval event in the receipt log.
        The approve call occurs prior to a transferFrom.

        truffle: Bob approves Charlie to spend 25 tokens.
        app.approve(Charlie,'25000000000000000000',{from:Bob}).then( n => {c = n})
     */

    function approve(address _spender, uint256 _value) public
        returns (bool success) {

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }


     /* This is a public transferFrom function.
        It allows an approved sender to spend from another account.
        Preconditions: The message sender has been approved by the specified
        from address. The approval is of enough value.

        Postcondition: Reduce how much more may be spent by this sender.
        Perform the actual transfer from the 'from' account to the 'to' account.
        Bob pays Charlie from Alice's account. Alice issued a prior approval
        for Bob to spend. Bob initiates the transfer request.


        In truffle:
            Charlie sends 10 of Bob's tokens to Donna.
            app.transferFrom(Bob,Donna, '10000000000000000000',{from:Charlie}).then( n => {c = n})
    */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }



     /* This is a public approve and call function.
        It provides an allowance for another contract and informs
        that contract of the allowance.
        The message sender approves the included address (a contract) to
        spend from the sender's account. The upper limit of this approval
        is also specified.

        It only modifies the allowance mapping.
        sender --> contract spender ---> amount.
        Because of the approve call, this generates an Approval event in
        the receipt log.

        The approve and call call occurs prior to a transferFrom.

        truffle: Requires another deployed contract and the second deployed
        contract must have a receiveApproval function.

        Suppose Bob approves a contract to spend 25 tokens.
        app.approveAndCall(contract,'25000000000000000000',"0x00",{from:Bob}).then( n => {c = n})
     */

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }



     /* This is a public burn function.
        The sender loses tokens and the totalSupply is reduced.

        precondition: The sender must have enough tokens to burn.

        postcondition: The sender loses tokens and so does totalSupply.
                       A burn event is published.

        truffle: Suppose Bob wants to burn a 1 token

        app.burn('1000000000000000000',{from:Bob}).then( n => {c = n
        and view the burn event in the logs.
        c.logs[0].event
        'Burn'
    */

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }


     /* This is a public function to burn some tokens that the sender (Bob)
        has been approved to spend from the approver's (Alice) account.

        Suppose Alice has allowed Bob to spend her tokens.
        Bob is allowed to burn them if he wants.
        Suppose he wants to burn 3 of the tokens that Alice has provided.
        Bob calls burnFrom(Alice,3)

        Precondition:
                      Alice must have the required number of tokens.
                      Alice must have approved Bob to use at least that number.

        Postcondition: Deduct tokens from Alice.
                       Decrease the number of tokens Bob has been approved to spend.
                       Decrease the totalSuppy of tokens.
                       Publish a Burn event.

        Truffle: Bob wants to burn 3 token of those tokens that he may spend
        from Alice's account.

        app.burnFrom(Alice,'3000000000000000000', {from:Bob}).then( n => {c = n})
     */

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

}



// MyAdvancedToken inherits from owned and TokenERC20

contract MyAdvancedToken is owned, TokenERC20 {

    // This contract will buy and sell tokens at these prices
    uint256 public sellPrice;
    uint256 public buyPrice;

    /* In truffle we can view these prices:
    app.sellPrice({from:Bob}).then(n => { c = n})
    c.toString()
    */

    // We can freeze and unfreeze accounts
    mapping (address => bool) public frozenAccount;

    /* In truffle we can view the mapping. Is Donna frozen?
    app.frozenAccount(Donna,{from:Bob}).then(n => { c = n})
    c.toString()
    false
    */


    /* The function freezeAccounts publishes an event on the blockchain
       that will notify clients of frozen accounts.
    */

    event FrozenFunds(address target, bool frozen);


    // This is a public constructor.
    // It initializes the contract with an initial supply of tokens
    // and assigns those tokens to the deployer of the contract.
    // It also assigns a name and a symbol.
    // This constructor calls the parent constructor (TokenERC20).
    // It does nothing else after the call to the TokenERC20 constructor.

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* This is an internal function. It can only be called by this contract.
       It does not use an implied sender. It simply transfers tokens from
       one account to another and both accounts are supplied as arguments.

       Preconditions: The recipient may not be the zero address. Use burn instead.
                      The source must have sufficient funds.
                      No overflow is permited.
                      Neither account may be frozen.

       Postconditions: Tokens are transferred.
                       An event is published.
    */

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }


    // This function is public but may only be called by the owner
    // of the contract.
    // It adds tokens to the supplied address.

    /* Suppose Alice wants to add 5 tokens to Bob's account.

       In truffle:
       app.mintToken(Bob,'5000000000000000000',{from:Alice}).then(n => { c = n})
       c

       c is a receipt
       c.logs shows two Transfer events
       c.logs[0]  shows zero address to contract address of 5 tokens
       c.logs[1]  shows contract address to Bob's address of 5 tokens

       v = c.logs[1].args.value
       v.toString() shows '5000000000000000000'
    */

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {

        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;

        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    // This function is public but may only be called by the owner
    // of the contract.
    // The owner may freeze or unfreeze the specified address.
    // Precondition: Only the owner may call.
    // Postcondition: The specified account is frozen or unfrozen.
    //                A FrozenFunds event is published.

    /* Suppose Alice wants to freeze the account of Donna.
       In truffle:
       app.freezeAccount(Donna,true,{from:Alice}).then(n => { c = n})

       c is a receipt
       c.logs shows one FrozenFunds event.
       c.logs[0]  shows the specified address and frozen is true.

       v = c.logs[0].args.frozen
       true
    */

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


    // This function is public but may only be called by the owner
    // of the contract.
    // It allows the owner to set a sell price and a buy price in eth.

    /* Suppose Alice wants to set the sell price at 2 eth and the buy price at 1 eth.
       In truffle:

       app.setPrices('2','1',{from:Alice}).then(n => { c = n})
    */

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }



    // Function buy is public and since it is 'payable' it may be passed ether.
    // The idea is to send ether to the contract's ether account in
    // exchange for tokens going into the sender's token account.
    // The contract will need to have some tokens in its token account
    // before any buys can succeed.
    // The ether account (the contract's balance) is maintained by
    // Ethereum and is not the same as the contract's token account.
    // The buyPrice is expressed in ether and was established by the owner.
    // The buyer sends along a value that is expressed in wei.
    // The contract needs tokens to sell. So, lets assume that prior
    // to a buy call by Charlie, Alice performed the following two steps.
    // First, she assigns the variable 'contract' to the address
    // of the contract.
    // contract = '0xDDec5bf035cEf613dc3cb130B0aED7172e04a35d'
    // Second, she might mint 5 tokens for the contract.
    // app.mintToken(contract,'5000000000000000000',{from:Alice}).then(n => { c = n})
    // Precondition: The contract must have tokens in its token account.
    //               The caller must have an account with sufficient funds to
    //               cover the cost of gas and the cost of tokens.
    // Postcondition: Tokens are transferred to the caller's token account.
    //                Ether is placed into the contract's Ether account.
    //                Miners take some ether based on gas used and the
    //                price of gas.
    //                A transfer event is published.
    //

    /* Suppose Charlie would like to buy 2 ether worth of tokens from the
     * contract. Suppose the buy price is 4 eth per token.
     * Truffle:
     * app.buy({from:Charlie, value:2000000000000000000}).then(n => { c = n})
     * The function will compute amount = 2000000000000000000 / 4 producing the
     * correct amount in the correct format.
    */

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        _transfer(address(this), msg.sender, amount);
    }

    // This is a public function but does not take in ether.
    // It is not marked as 'payable'. There needs to be ether
    // in the contract's account for it to be able to buy these
    // tokens from the caller.

    // Suppose the caller wants to sell 1 token.
    // The token's ether balance must be >= 1 * 2 = 2.
    // How do we check the contract's ether balance?

    // In truffle:
    // bal = web3._extend.utils.fromWei(web3.eth.getBalance(contract), 'ether')
    // bal.toNumber()
    // Precondition:  The contract has enough ether to buy these tokens
    //                at the sell price.
    // Postconditions:The tokens are added to the contract's account.
    //                Tokens are deducted from sender's account.
    //                Ether is transferred from contract's ether account
    //                to sender's ether account.

    function sell(uint256 amount) public {
        address myAddress = address(this);
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, address(this), amount);

        // It's important to do this transfer last to avoid recursion attacks.
        msg.sender.transfer(amount * sellPrice);
    }
}
