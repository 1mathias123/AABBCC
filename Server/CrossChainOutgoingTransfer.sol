pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

contract Automated {
  address payable public ceoAddress;
  mapping (address => bool) public bot;

  function isAutomated (address _adr) public view returns (bool) {
    return bot[_adr];
  }

  function addBot (address _adr) external botOnly {
    bot[_adr] = true;
  }

  function removeBot (address _adr) external botOnly {
    require(_adr != msg.sender, "Action not allowed");
    bot[_adr] = false;
  }

  modifier botOnly () {
    require(bot[msg.sender] == true, "Unauthorized");
    _;
  }

  constructor (address _bot) public {
    ceoAddress = msg.sender;
    bot[msg.sender] = true;
    bot[_bot] = true;
  }

  function getCEOAddress () public view returns (address payable) {
    return ceoAddress;
  }
}

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function percentageOf(uint256 total, uint256 percentage) internal pure returns (uint256) {
    return div(mul(total, percentage), 100);
  }

  function getPercentage(uint256 total, uint256 piece) internal pure returns (uint256) {
    return div(piece, total);
  }
}

interface TRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address tokenOwner) external view returns (uint256 balance);
  function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
  function transfer(address to, uint256 tokens) external returns (bool success);
  function approve(address spender, uint256 tokens) external returns (bool success);
  function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract CrossChainOutgoingTransfer is Automated {
  using SafeMath for uint256;

  struct TransferGroup {
    uint256 id;
    uint256 tokens;
    address receiver;
    bool completed;
  }

  uint256 public lastId = 0;
  TRC20 public HEX;

  mapping (uint256 => TransferGroup) public transferGroups;

  event OutgoingTransfer(TransferGroup transferGroup);

  constructor (address _hex, address _bot) Automated(_bot) public {
    HEX = TRC20(_hex);
  }

  function readyForTransfer (uint256 id) internal view returns (bool ready) {
    return !transferGroups[id].completed;
  }

  function tokenBalance () public view returns (uint256) {
    return HEX.balanceOf(address(this));
  }

  // Assuming that the amount has already been approved for both tokens
  function triggerOutgoingTransfer (uint256 id, uint256 amount, address receiver) external botOnly {
    require (readyForTransfer(id), "Transfer already completed");
    require (id == SafeMath.add(lastId, 1), "Invalid id, must be lastId plus one");
    require (tokenBalance() >= amount, "Insufficient funds, seed me!");

    HEX.transfer(receiver, amount);

    TransferGroup memory transferGroup = TransferGroup(
      {
        id: id,
        tokens: amount,
        receiver: receiver,
        completed: true
      }
    );

    transferGroups[id] = transferGroup;
    lastId = id;

    emit OutgoingTransfer(transferGroup);
  }
}
