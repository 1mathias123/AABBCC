pragma solidity ^0.5.8;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

interface TRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract HXYT is TRC20, Ownable {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint256 public decimals = 8;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => bool) public blacklist;

  event Transfer (address indexed from, address indexed to, uint256 value);
  event Approval (address indexed owner, address indexed spender, uint256 value);
  event Burn (address indexed from, uint256 value);
  event DestroyBlacklistFunds(address _blackListedUser, uint256 _balance);
  event BlacklistUser(address user);
  event WhitelistUser(address user);

  uint256 initialSupply = 66000000;
  string tokenName = "HOT";
  string tokenSymbol = "HXYT";

  constructor () public {
    totalSupply = initialSupply*10**uint256(decimals);
    name = tokenName;
    symbol = tokenSymbol;
    balanceOf[msg.sender] = totalSupply;
  }

  modifier isWhitelisted(address _from, address _to) {
    require(_isWhitelisted(_from, _to), "Sender or receiver is blacklisted");
    _;
  }

  function isBlacklisted(address user) public view returns (bool) {
    return blacklist[user];
  }

  function blacklistUser(address user) public onlyOwner {
    blacklist[user] = true;
    emit BlacklistUser(user);
  }

  function whitelistUser(address user) public onlyOwner {
    blacklist[user] = false;
    emit WhitelistUser(user);
  }

  function destroyBlacklistFunds(address user) public onlyOwner {
    require(blacklist[user], "User isn't blacklisted");
    uint256 funds = balanceOf[user];
    _burn(user, funds);
    emit DestroyBlacklistFunds(user, funds);
  }

  function _isWhitelisted(address _from, address _to) internal view returns (bool) {
    return !isBlacklisted(_from) && !isBlacklisted(_to);
  }

  function _transfer (address _from, address _to, uint256 _value) internal {
    require (balanceOf[_from] >= _value, "Insufficient funds");
    require (balanceOf[_to].add(_value) >= balanceOf[_to], "Invalid amount");

    uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    assert (balanceOf[_from].add(balanceOf[_to]) == previousBalances);

    emit Transfer (_from, _to, _value);
  }

  function transfer (address _to, uint256 _value) public isWhitelisted(msg.sender, _to) returns (bool) {
    _transfer (msg.sender, _to, _value);
    return true;
  }

  function transferFrom (address _from, address _to, uint256 _value) public isWhitelisted(msg.sender, _to) returns (bool) {
    require (_value <= allowance[_from][msg.sender], "Insufficient allowance");
    allowance[_from][msg.sender] -= _value;
    _transfer (_from, _to, _value);
    return true;
  }

  function approve (address _spender, uint256 _value) public isWhitelisted(msg.sender, _spender) returns (bool) {
    require (_value > 0, "Invalid amount");
    allowance[msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);

    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes calldata data) external isWhitelisted(msg.sender, _spender) returns (bool) {
    require (_value > 0, "Invalid amount");
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, address(this), data);
    return true;
  }

  function _burn(address _burner, uint256 _value) internal {
    require(_value > 0, "Invalid value");
    require(_value <= balanceOf[_burner], "Insufficient funds");

    totalSupply = totalSupply.sub(_value);
    balanceOf[_burner] = balanceOf[_burner].sub(_value);
    emit Burn (_burner, _value);
  }

  function burn (uint256 _value) public isWhitelisted(msg.sender, address(0)) returns (bool) {
    require (balanceOf[msg.sender] >= _value, "Insufficient funds");

    _burn(msg.sender, _value);

    return true;
  }

  function burnFrom (address _from, uint256 _value) public isWhitelisted(msg.sender, address(0)) returns (bool) {
    require (balanceOf[_from] >= _value, "Insufficient funds");
    require (_value <= allowance[_from][msg.sender], "Insufficient allowance");
    require (totalSupply >= _value, "Invalid amount");


    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _burn(_from, _value);

    return true;
  }
}
