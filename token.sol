pragma solidity ^0.8.19;


contract chancla {

    string public _name = "CHANCLA";
    string public _symbol = "ISSOU";

    uint8 public _decimals = 18;
    uint256 public _totalSupply = 1000 ** 18;
    
    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) public _allowances;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address from, address to, uint256 amount);

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }


    // GETTERS
    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns(uint256) {
        return _allowances[owner][spender];
    }


    // WRITERS 
    function approve(address spender, uint256 amount) external returns(bool) {

        require(msg.sender != address(0));
        require(spender != address(0));

        _allowances[msg.sender][spender] = amount;

        return true;

    }

    function transfer(address to, uint256 amount) external returns(bool) {
        
        require(_balances[msg.sender] >= amount);

        _balances[to] += amount;
        _balances[msg.sender] = amount;

        emit Transfer(msg.sender, to, amount);

        return true;

    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool) {

        require(_balances[from] >= amount);
        require(_allowances[from][msg.sender] >= amount);

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);

        return true;

    }

}