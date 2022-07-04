// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, ERC721URIStorage  {
    using Counters for Counters.Counter;
    
    event TokenSold(uint256 tokenId);
    event Minted(string tokenURI);
    
    Counters.Counter private _tokenIds;
    
    mapping(uint256 => uint256) internal tokenListPrices;
    mapping(uint256 => address) internal tokenMinters;
    mapping(uint256 => bool) internal listed;
    mapping(uint256 => bool) internal forTrade;
    mapping(uint256 => uint256) internal tokenTradePrices;
    mapping(uint256 => bool) internal canBeListed;

    constructor() ERC721("Non-fungible Token", "NFT") {}

    // mint a new token
    function mint(address _recipient, string memory _uri)
        public
        returns (uint256)
    {
        uint256 newId = _tokenIds.current();
        _safeMint(_recipient, newId);
        _setTokenURI(newId, _uri);
        tokenMinters[newId] = msg.sender; // adding the minter to the list
        canBeListed[newId] = true; // Making the NFT available for listing
        _tokenIds.increment();
        emit Minted(_uri);
        return newId;

    }

    // list an item in the market for sale
    function listItemForSale(uint _id, uint _price) // can be called only by the minter
        public
    {
        require(tokenMinters[_id] == msg.sender, "You are not the minter of this asset.");
        require(_exists(_id), "This asset has not been minted yet.");
        require(canBeListed[_id], "The asset has been listed for sale once already.");
        tokenListPrices[_id] = _price;
        listed[_id] = true; 
        approve(address(this), _id);
    }


    // get price of a market item(returns price of listed item)
    function getListItemPrice(uint _tokenId)
        public
        view
        returns (uint)
    {
        require(_exists(_tokenId), "This asset has not been minted yet.");
        require(listed[_tokenId], "Not listed for sale yet.");
        uint price = tokenListPrices[_tokenId];
        return price;
    }

    // buy a listed item with id _tokenId (buy item that is listed for sale)
    function buyListedItem(uint256 _tokenId)
        public
        payable
    {
        require(msg.sender != ownerOf(_tokenId), "You cannot buy your own asset.");
        require(_exists(_tokenId), "This asset has not been minted yet.");
        require(listed[_tokenId], "Not listed for sale yet.");
        require(msg.value == tokenListPrices[_tokenId], "Transfer the required price of the asset.");
        payable(tokenMinters[_tokenId]).transfer(msg.value);
        _transfer(tokenMinters[_tokenId], msg.sender, _tokenId);
        listed[_tokenId] = false;
        canBeListed[_tokenId] = false;
        forTrade[_tokenId] = true;     // setting the item to be tradable   
        emit TokenSold(_tokenId);
    }
    
    //TRADING FUNCTIONS- this is the trading section. all functions here can only execute if the item is tradable(forTrade == true)

    // sell a market item(sell item that is tradable)
    function sellItem(uint _tokenId, uint _price)
        public
    {
        require(forTrade[_tokenId] == true, "Not for trade yet.");
        require(_exists(_tokenId), "This asset has not been minted yet.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this asset");
        tokenTradePrices[_tokenId] = _price;
        approve(address(this), _tokenId);// approve transfer
    }

    // get price of an item (get tradable item price)
    function getItemPrice(uint _tokenId)
        public
        view
        returns (uint)
    {
        require(_exists(_tokenId), "This asset has not been minted yet.");
        require(forTrade[_tokenId] == true, "Not for trade yet.");
        uint price = tokenTradePrices[_tokenId];
        return price;
    }

    // buy a market item that is tradable.
    function buyforTradeItem(uint _tokenId)
        public
        payable
    {
        require(msg.sender != ownerOf(_tokenId), "You cannot buy your own asset.");
        require(_exists(_tokenId), "This asset has not been minted yet.");
        require(forTrade[_tokenId] == true, "Not for trade yet.");
        require(tokenTradePrices[_tokenId] == msg.value, "Transfer the required price of the asset.");
        payable(ownerOf(_tokenId)).transfer(msg.value);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
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
