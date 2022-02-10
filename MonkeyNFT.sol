//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract MonkeyNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.08 ether;
    uint256 public presaleCost = 0.06 ether;
    uint256 public maxSupply = 10000;
    bool public paused = false;
    bool public inPreSale = true;
    mapping(address => bool) public presaleWallets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        require(!paused);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if(inPreSale == true){
                require(presaleWallets[msg.sender]);
                require(msg.value >= presaleCost * _mintAmount);
            }
            else{
                require(msg.value >= cost * _mintAmount);
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function _price() external view returns (uint) {
        if(inPreSale == true && presaleWallets[msg.sender] == true){
            return presaleCost;
        }
        else{
            return cost;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function changePreSale() public onlyOwner {
        inPreSale = !inPreSale;
    }

    function addPresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = true;
    }

    function addMultiplePresaleUser(address[] memory _user) public onlyOwner {
        for (uint i = 0; i< _user.length; i++){
            presaleWallets[_user[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
