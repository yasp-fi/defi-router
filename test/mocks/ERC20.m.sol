pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
