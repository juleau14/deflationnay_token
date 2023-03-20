pragma solidity ^0.8.19;


contract chancla {

    string public _name = "CHANCLA";
    string public _symbol = "ISSOU";

    uint8 public _decimals = 18;
    uint256 public _totalSupply = 1000 ** 18;
    
    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) public _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

}