# nftMarketPlace

# This is a unique NFT Market place with two sections.
First Secion.
1. Users can mint an Nft.
2. Users can list their Nft on the marketplace.
3. Other users can then buy these listed NFT after which the NFT will be available for trading.

Second Section(Trading Section) all functions here can only execute if the item is tradable(forTrade == true).
1. Users can sell their NFTs by setting a price and approving it for transfer.
2. Other users can then buy this NFT and they can also choose to sell it too.

note: the buylistedItem function can only be called if the item is listed for sale while the buyItem function can only be called if the item is tradable by setting the forTrade value to true.
