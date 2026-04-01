// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract OwnerControl is Context {
    address private _admin;
    address private _manager;
    
    constructor() {
        _admin = _msgSender();
        _manager = _msgSender();
    }
    
    modifier onlyAdmin() {
        require(_msgSender() == _admin, "Not admin");
        _;
    }
    
    modifier onlyManager() {
        require(_msgSender() == _admin || _msgSender() == _manager, "Not manager");
        _;
    }
    
    function setManager(address newManager) external onlyAdmin {
        _manager = newManager;
    }
}

contract AntiBotToken is IERC20, OwnerControl {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = supply_ * 10**uint256(decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function blacklist(address account, bool status) external onlyManager {
        _blacklist[account] = status;
    }
    
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "Zero address");
        require(!_blacklist[from] && !_blacklist[to], "Blacklisted");
        require(_balances[from] >= amount, "Insufficient balance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_allowances[from][_msgSender()] >= amount, "Allowance exceeded");
        _allowances[from][_msgSender()] -= amount;
        _transfer(from, to, amount);
        return true;
    }
}
