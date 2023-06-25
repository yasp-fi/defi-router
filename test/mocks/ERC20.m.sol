// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/interfaces/IERC20.sol";

contract ERC20 is IERC20 {
  uint8 public immutable decimals = 18;

  string public name;
  string public symbol;
  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
  {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount) public virtual returns (bool) {
    balanceOf[msg.sender] -= amount;

    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(address from, address to, uint256 amount)
    public
    virtual
    returns (bool)
  {
    uint256 allowed = allowance[from][msg.sender];
    if (allowed != type(uint256).max) {
      allowance[from][msg.sender] = allowed - amount;
    }

    balanceOf[from] -= amount;

    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  function _mint(address to, uint256 amount) internal virtual {
    totalSupply += amount;
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    balanceOf[from] -= amount;
    unchecked {
      totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }
}

contract MockERC20 is ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

  function mint(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }
}
