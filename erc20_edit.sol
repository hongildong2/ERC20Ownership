// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}

library SafeMath {
  	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256) {
	    uint256 c = a / b;
		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

abstract contract OwnerHelper {
  	address private _owner;

  	event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);

  	modifier onlyOwner {
		require(msg.sender == _owner, "OwnerHelper: caller is not owner");
		_;
  	}

  	constructor() {
            _owner = msg.sender;
  	}

    uint candidateCount = 0;
    mapping(uint => address) public candidates;
    mapping(address => uint) candidateVote;

    function owner() public view virtual returns (address) {
           return _owner;
       }

  	function transferOwnership(address newOwner) onlyOwner public {
            require(newOwner != _owner);
            require(newOwner != address(0x0));
            address preOwner = _owner;
    	    _owner = newOwner;
    	    emit OwnershipTransferred(preOwner, newOwner);
  	}
    
    function delegation(address candidate) onlyOwner public{
        require(candidate != address(0x0));
        require(candidate != msg.sender);
        require(candidate != _owner);
        require(candidateCount <= 3 && candidateCount >= 0);
        require(candidateVote[candidate] == 0);
        candidates[candidateCount] = candidate;
        candidateVote[candidate] = 0;
        candidateCount++;

    }
    function vote(address voter, address candidate) public {
        require(voter != candidate);
        require(voter == msg.sender);
        require(voter != address(0x0));
        require(candidateCount == 4);
        require(candidateVote[candidate] >= 0);
        candidateVote[candidate]++;
    }

    function result() public returns (address winner_){
        uint winningVoteCount = 0;
        address winner = address(0x0);
        for (uint i = 0; i < 4; i++){
            if( candidateVote[candidates[i]] > winningVoteCount ){
                winningVoteCount = candidateVote[candidates[i]];
                winner = candidates[i];
         }
        }
        require(winner != address(0x0));
        _transferOwnershipByVote(winner);
        return winner;

    }

    function _transferOwnershipByVote (address newOwner) internal {
        require(newOwner != address(0x0));
        address preOwner = _owner;
    	_owner = newOwner;
    	emit OwnershipTransferred(preOwner, newOwner);
    }
}

contract SimpleToken is ERC20Interface, OwnerHelper {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    
    constructor(string memory getName, string memory getSymbol) {
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) external virtual override onlyOwner returns (bool) {
        uint256 currentAllownace = _allowances[msg.sender][spender];
        require(currentAllownace >= amount, "ERC20: Transfer amount exceeds allowance");
        _approve(msg.sender, spender, currentAllownace, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        emit Transfer(msg.sender, sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance - amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
    }
    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, currentAmount, amount);
    }
}
