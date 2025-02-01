// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockNFT is ERC721, Ownable {
    constructor(address initialOwner)
        ERC721("SuperMemeNFT", "SPRN")
        Ownable(initialOwner)
    {
        //mint 5 NFTs to the contract creator
        for (uint256 i = 0; i < 5; i++) {
            _safeMint(initialOwner, i);
        }
    }

    function safeMint(address to, uint256 tokenId) public  {
        _safeMint(to, tokenId);
    }
}