// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.18;


contract taxed_token {

    // BASIC ATTRIBUTES

    string public _name = "TOKEN";          // The name of the token
    string public _symbol = "TOK";          // The symbol of the token

    uint256 public _totalSupply = 1000;     // The total supply of the token
    uint256 public _decimals = 18;          // The decimals of the token

    mapping(address => uint256) public _balances;   // The mapping of all balances : user_account => balance
    mapping(address => mapping(address => uint256)) public _allowances;     // The mapping of all allowances : user_account => (a_spender => amount)
    mapping(address => bool) public _excludedFromTax;       // The mapping that inform if an account is exluded from tax (address => true in this case)

    address public _owner;                  // The address who own the contract

    address public _taxWallet;              // The address of the wallet where all the taxes go
    bool public _taxEnabled = true;                // If true autoBurn enabled (default = true)
    uint256 public _tax = 5;                       // Amount of the taxes
    uint256 public _maximumTax = 20;                  // Maximum tax that can be set up
    uint256 public _minimumTax = 0;                   // Minimum ----------------------

    // EVENTS 

    event Transfer(address from, address to, uint256 amount);   // Event emitted on every token transfer (required ERC20 event)
    event Approval(address user, address spender, uint256 amount);    // Event emitted when 'user' allow 'spender' to spend 'amount' tokens for him (required ERC20 event)


    // CONSTRUCTOR

    constructor () {
        _owner = msg.sender;                // The person who deploy the contract is set as the owner
        _balances[_owner] = _totalSupply;   // give the total supply to the owner
        _taxWallet = address(0);            // set the tax wallet
        _excludedFromTax[_owner] = true;    // The owner is excluded from taxes
        _excludedFromTax[address(this)] = true;     // The contract itself is excluded from taxes
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
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool) {
        _transfer(from, to, amount);
        emit Transfer(from, to, amount);
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
        _excludedFromTax[account] = true;
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


    function taxValueCalculation(uint256 amount, uint256 taxPercentage) private pure returns(uint256) {       // return the tax value
        return (amount * taxPercentage) / 100;
    }


    function _makeTransfer(address from, address to, uint256 amount, uint256 taxPercentage) private returns(bool) {         // make a transfer and apply the tax percentage in arg
        uint256 taxValue = taxValueCalculation(amount, taxPercentage);
        _balances[from] -= amount;
        amount -= taxValue;
        _balances[to] += amount;
        _balances[_taxWallet] += taxValue;
        emit Transfer(from, to, amount);
        return true;
    }


    function _transfer(address from, address to, uint256 amount) private returns(bool) {

        require(_balances[from] >= amount, "Not enough tokens in balance");         // 'From' must have enough tokens 

        if (msg.sender != from) {           // if the transfer is not made by the 'from'
            require(_allowances[from][msg.sender] >= amount, "Allowance too low");      // The contract caller must be allowed to use 'amount' tokens for the from
        }
        
        uint256 taxPercentage;

        if (!_taxEnabled) {
            taxPercentage = 0;
        }

        else if (from == msg.sender) {      // if it is a simple token transfer 
           
            if (_excludedFromTax[from] == true || _excludedFromTax[to] == true) {       // if sender or receiver is excluded from tax
                taxPercentage = 0;                                  // no tax
            }

            else { 
                taxPercentage = _tax;                   // else tax
            }
        }

        else {                      // else if its a transferFrom
        
            if (_excludedFromTax[to] == true) {         // if 'to' is excluded from taxes (for example the contract or the owner during a buy)
                taxPercentage = 0;                      // no tax
            }
            else {
                taxPercentage = _tax;
            }
        }

        _makeTransfer(from, to, amount, taxPercentage);

        return true;

    }
}
