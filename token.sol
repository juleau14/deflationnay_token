// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.18;


contract taxed_token {

    /*
    This ERC20 token contract will apply : 
        - a 5% burn on every sell
        - a 5% tax on every buy
        - a 5% tax on every transfer
    */

    // BASIC ATTRIBUTES

    string public name = "TOKEN";          // The name of the token
    string public symbol = "TOK";          // The symbol of the token
    uint8 public decimals = 18;          // The decimals of the token

    uint256 public _totalSupply = 1000;     // The total supply of the token

    mapping(address => uint256) public _balances;   // The mapping of all balances : user_account => balance
    mapping(address => mapping(address => uint256)) public _allowances;     // The mapping of all allowances : user_account => (a_spender => amount)
    mapping(address => bool) public _excludedFromFees;       // The mapping that inform if an account is exluded from tax (address => true in this case)

    address public _owner;                  // The address who own the contract

    address public _taxWallet;              // The address of the wallet where all the taxes go
    address public _burnWallet;             // The address of the burn wallet
    bool public _taxEnabled = true;         // If true tax enabled (default = true)
    bool public _burnEnabled = true;        // If true burn enabled (default = true)           
    uint256 public _tax = 5;                // Amount of the taxes
    uint256 public _burn = 5;               // Amount of the burn
    uint256 public _maximumTax = 20;        // Maximum tax that can be set up
    uint256 public _minimumTax = 0;         // Minimum tax that can be set up
    uint256 public _maximumBurn = 20;       // Maximum burn that can be set up
    uint256 public _minimumBurn = 0;        // Maximum burn that can be set up

    // EVENTS 

    event Transfer(address indexed from, address indexed to, uint256 amount);   // Event emitted on every token transfer (required ERC20 event)
    event Approval(address indexed user, address indexed spender, uint256 amount);    // Event emitted when 'user' allow 'spender' to spend 'amount' tokens for him (required ERC20 event)


    // CONSTRUCTOR

    constructor () {
        _owner = msg.sender;                // The person who deploy the contract is set as the owner
        _balances[_owner] = _totalSupply * 10 ** decimals;   // give the total supply to the owner
        _taxWallet = 0x75C2B6c96A7B63407e9098fc09fa725693e7Ce14;            // set the tax wallet
        _burnWallet = address(0);           // set the burn wallet
        _excludedFromFees[_owner] = true;    // The owner is excluded from fees
        _excludedFromFees[_taxWallet] = true;   // The tax wallet is excluded from fees
    }


    // GETTERS

    // ERC20 REQUIRED FUNCTIONS
    function balanceOf(address account) external view returns(uint256) {        // return the balance of 'account'
        return _balances[account];
    }

    function totalSupply() external view returns(uint256) {                     // return the total supply
        return _totalSupply;
    }

    function allowance(address account, address spender) external view returns(uint256) {       // return the amount of tokens owned by 'account' 'spender' is allowed to use for him
        return _allowances[account][spender];
    }
    //--------------------------------------------------



    // FUNCTIONS

    // ERC20 REQUIRED FUNCTIONS 
    function approve(address spender, uint256 amount) external returns(bool) {      // the contract caller allow 'spender' to use 'amount' token for him
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns(bool) {          // make a transfer from the contract caller's balance to 'to'
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool) {
        _transfer(from, to, amount);
        _allowances[from][msg.sender] -= amount;
        return true;
    }
    //--------------------------------------------------


    function isOwner(address account) public view returns(bool) {       // return true if 'account' is the owner of the contract
        if (account == _owner) {
            return true;
        } else {
            return false;
        }
    }


    function _giveOwnership(address newOwner) external returns(bool) {      // allow owner to give his ownership
        require(isOwner(msg.sender), "You are not the current owner");
        _owner = newOwner;
        return true;
    }


    function _renounceOwnership() external returns(bool) {                  // allow owner to renounce ownership
        require(isOwner(msg.sender), "You are not the current owner");
        _owner = address(0);
        return true;
    }


    function _excludeFromTax(address account) external returns(bool) {    // allow the owner to exclude an account from taxes
        require(isOwner(msg.sender), "Only the owner can exclude from tax");        // THE CONTRACT CALLER MUST BE THE OWNER
        _excludedFromFees[account] = true;
        return true;
    }


    function _disableTax() external returns(bool) {                      // allow the owner to disable taxes
        require(isOwner(msg.sender));
        _taxEnabled = false;
        return true;
    }


    function _enableTax() external returns(bool) {                      // allow the owner to enable taxes
        require(isOwner(msg.sender));
        _taxEnabled = true;
        return true;
    }


    function _changeTax(uint256 newTax) external returns(bool) {        // allow the owner to set a new tax amount
        require(newTax <= _maximumTax && newTax >= _minimumTax);        // new tax must be between min tax and max tax 
        require(isOwner(msg.sender));                                   // contract caller must be the owner
        _tax = newTax;
        return true;
    }

    function _disableBurn() external returns(bool) {                      // allow the owner to disable burn
        require(isOwner(msg.sender));
        _burnEnabled = false;
        return true;
    }


    function _enableBurn() external returns(bool) {                      // allow the owner to enable Burn
        require(isOwner(msg.sender));
        _burnEnabled = true;
        return true;
    }


    function _changeBurn(uint256 newBurn) external returns(bool) {        // allow the owner to set a new Burn amount
        require(newBurn <= _maximumBurn && newBurn >= _minimumBurn);        // new Burn must be between min Burn and max Burn 
        require(isOwner(msg.sender));                                   // contract caller must be the owner
        _burn = newBurn;
        return true;
    }


    function valueCalculation(uint256 amount, uint256 taxPercentage) private pure returns(uint256) {       // return the tax value
        return (amount * taxPercentage) / 100;
    }


    function _manualBurn(uint256 amount) public returns(bool) {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _burnTokens(amount);
        return true;
    }


    function _burnTokens(uint256 amount) private returns(bool) {
        _balances[_burnWallet] += amount;
        return true;
    }


    function _takeTax(uint256 amount) private returns(bool) {
        _balances[_taxWallet] += amount;
        return true;
    }


    function _makeTransfer(address from, address to, uint256 amount, uint256 taxPercentage, uint256 burnPercentage) private returns(bool) {         // make a transfer and apply the tax percentage in arg
        
        uint256 taxValue = valueCalculation(amount, taxPercentage);
        uint256 burnValue = valueCalculation(amount, burnPercentage);
        uint256 transferedTokens = amount - taxValue - burnValue;

        _balances[from] -= amount;
        _balances[to] += transferedTokens;

        _takeTax(taxValue);
        _burnTokens(burnValue);

        emit Transfer(from, to, transferedTokens);
        
        return true;
    }


    function _transfer(address from, address to, uint256 amount) private returns(bool) {

        require(_balances[from] >= amount, "Not enough tokens in balance");         // 'From' must have enough tokens 
        require(from != address(0) && to != address(0));                            // can't send to or from address 0   
        if (from != msg.sender) {
            require(_allowances[from][msg.sender] >= amount);
        }

        uint256 taxPercentage;
        uint256 burnPercentage;

        if (_excludedFromFees[from] == true || _excludedFromFees[to] == true) {
            taxPercentage = 0;
            burnPercentage = 0;
        } else {
            taxPercentage = _tax;
            burnPercentage = _burn;
        }

        if (!_taxEnabled) {
            taxPercentage = 0;
        }

        if (!_burnEnabled) {
            burnPercentage = 0;
        }

        _makeTransfer(from, to, amount, taxPercentage, burnPercentage);

        return true;

    }

}