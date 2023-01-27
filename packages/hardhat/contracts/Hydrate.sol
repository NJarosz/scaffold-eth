// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hydrate is ERC20Burnable, Ownable {
    uint256 hit = 420_000_000_000_000_000_000;
    uint256 hydrated = 6969_000_000_000_000_000_000;

    mapping(address => bool) public minters;

    constructor() ERC20("Hydrate", "HYDR") {}

    function setMinter(address _minter) public onlyOwner {
        minters[_minter] = !minters[_minter];
    }

    function mint(address _recipient) public {
        require(minters[msg.sender], "only minters can mint");
        _mint(_recipient, hit);
    }

    function isHydrated(address sipper) public view returns (bool) {
        return balanceOf(sipper) >= hydrated;
    }
}
