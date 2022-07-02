// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event TokenSold(uint256 tokenId);
    event Minted(uint256 tokenId, string tokenURI);
    event Claim(uint256 tokenId, address owner);
    event Pause(bool _paused);

    mapping(uint256 => uint256) private tokenPrices;
    mapping(uint256 => bool) private listed;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => bool) public claimed;

    bool public paused;
    string public pausedReason;

    constructor() ERC721("Non-fungible Token", "NFT") {}

    modifier exists(uint256 _tokenId) {
        require(_exists(_tokenId), "This asset has not been minted yet.");
        _;
    }
    modifier verifyPrice(uint256 _price) {
        require(_price > 0, "Invalid price");
        _;
    }
    modifier verifyOwner(uint256 _tokenId) {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "Caller is not owner of asset"
        );
        _;
    }

    modifier isPaused() {
        require(!paused, "Transactions have been paused");
        _;
    }

    function mint(string memory _uri) public isPaused returns (uint256) {
        require(bytes(_uri).length > 0, "Invalid uri");
        uint256 newId = _tokenIds.current();
        _safeMint(msg.sender, newId);
        _setTokenURI(newId, _uri);
        _tokenIds.increment();
        claimed[newId] = false;
        emit Minted(newId, _uri);
        return newId;
    }

    function buyItem(uint256 _tokenId)
        public
        payable
        isPaused
        exists(_tokenId)
    {
        require(
            msg.sender != tokenOwner[_tokenId],
            "You cannot buy your own asset."
        );
        require(listed[_tokenId], "asset isn't on sale.");
        require(
            msg.value == tokenPrices[_tokenId],
            "Transfer the required price of the asset."
        );
        uint256 amount = tokenPrices[_tokenId];
        tokenPrices[_tokenId] = 0;
        tokenOwner[_tokenId] = msg.sender;
        listed[_tokenId] = false;
        (bool success, ) = payable(tokenOwner[_tokenId]).call{value: amount}(
            ""
        );
        require(success, "Transfer failed");
        _transfer(address(this), msg.sender, _tokenId);

        emit TokenSold(_tokenId);
    }

    //TRADING FUNCTIONS

    function sellItem(uint256 _tokenId, uint256 _price)
        public
        isPaused
        exists(_tokenId)
        verifyPrice(_price)
        verifyOwner(_tokenId)
    {
        require(!listed[_tokenId], "asset is currently listed");
        require(_price > 0, "Invalid price");
        tokenPrices[_tokenId] = _price;
        tokenOwner[_tokenId] = msg.sender;
        _transfer(msg.sender, address(this), _tokenId);
    }

    // allows users to claim asset and burn their token
    function claimNft(uint256 _tokenId)
        external
        isPaused
        exists(_tokenId)
        verifyOwner(_tokenId)
    {
        require(!listed[_tokenId], "asset is on sale");
        require(!claimed[_tokenId], "Already claimed");
        _burn(_tokenId);
        emit Claim(_tokenId, msg.sender);
    }
    //allows deployer to pause transactions during an emergency
    function pause(string memory _pausedReason) external onlyOwner {
        require(!paused && bytes(pausedReason).length == 0, "Already paused");
        require(bytes(_pausedReason).length > 0, "Invalid pause reason");
        paused = true;
        pausedReason = _pausedReason;
        emit Pause(paused);
    }

    // allows deployer to unpause and resume transactions
    function unPause() external onlyOwner {
        require(paused, "Already unpaused");
        paused = false;
        pausedReason = "";
        emit Pause(paused);
    }

    function getItemPrice(uint256 _tokenId)
        public
        view
        isPaused
        exists(_tokenId)
        returns (uint256)
    {
        require(listed[_tokenId], "Not for sale yet.");
        return tokenPrices[_tokenId];
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
