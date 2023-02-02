pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./HexStrings.sol";
import "./Hydrate.sol";
import "./ToColor.sol";

contract Falgene is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using HexStrings for uint160;
    using ToColor for bytes3;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public immutable limit;
    uint256 public immutable curve;
    uint256 public price;
    uint256 public refillPrice;
    uint256 public powderPrice;
    uint256 public sipsPerBottle = 4;

    mapping(uint256 => bytes3) public color;
    mapping(uint256 => uint256) public sips;
    mapping(uint256 => bool) public powder;

    event Drink(
        uint256 indexed id,
        address indexed sender,
        address indexed drinker
    );
    event Refill(
        uint256 indexed id,
        uint256 indexed amount,
        address indexed sender
    );
    event Powder(
        uint256 indexed id,
        address indexed sender,
        bool indexed powder
    );
    event Receive(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed tokenId
    );

    address hydrate;

    constructor(
        uint256 _limit,
        uint256 _curve,
        uint256 _price
    ) ERC721("Falgene", "FG") {
        limit = _limit;
        curve = _curve;
        price = _price;
    }

    function setHydrate(address _hydrate) public onlyOwner {
        hydrate = _hydrate;
    }

    function mintItem() public payable returns (uint256) {
        require(_tokenIds.current() < limit, "DONE MINTING");
        require(msg.value >= price, "NOT ENOUGH");

        price = (price * curve) / 1000;
        refillPrice = price / 5;
        powderPrice = price / 10;

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                id
            )
        );
        color[id] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);

        emit Receive(msg.sender, msg.value, id);

        return id;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(
            _amount <= address(this).balance,
            "Not Enough Funds To Withdraw"
        );
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function sip(uint256 id) public {
        require(ownerOf(id) == msg.sender, "only owner can sip!");
        require(sips[id] < sipsPerBottle, "this drink is done!");
        sips[id] += 1;
        if (powder[id]) {
            Hydrate(hydrate).mintPlus(msg.sender);
        } else {
            Hydrate(hydrate).mint(msg.sender);
        }
        emit Drink(id, msg.sender, msg.sender);
    }

    function addPowder(uint256 id) public payable {
        require(ownerOf(id) == msg.sender, "only owner can add powder!");
        require(msg.value >= powderPrice, "not enough to add powder!");
        require(sips[id] < sipsPerBottle, "this drink is done!");
        powder[id] = true;
        emit Powder(id, msg.sender, powder[id]);
    }

    function refill(uint256 id) public payable {
        require(ownerOf(id) == msg.sender, "only owner can refill!");
        require(msg.value >= refillPrice, "not enough for a refill!");
        powder[id] = false;
        sips[id] = 0;
        emit Refill(id, msg.value, msg.sender);
    }

    function pour(uint256 id, address drinker) public {
        require(ownerOf(id) == msg.sender, "only owner can pour!");
        require(sips[id] < sipsPerBottle, "this drink is done!");
        sips[id] += 1;
        if (powder[id]) {
            Hydrate(hydrate).mintPlus(drinker);
        } else {
            Hydrate(hydrate).mint(drinker);
        }
        emit Drink(id, msg.sender, drinker);
    }

    receive() external payable {
        require(_tokenIds.current() < limit, "no bottles left!");
        emit Receive(msg.sender, msg.value, 0);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "not exist");
        string memory name = string(
            abi.encodePacked("Bottle #", id.toString())
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"Staying Hydrated", "external_url":"https://vagabond-crib.surge.sh/", "attributes":',
                                getAttributesForToken(id),
                                '"owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getAttributesForToken(uint256 id)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "sips", "value": ',
                    uint2str(sips[id]),
                    '}, {"trait_type": "state", "value": "',
                    powder[id] ? "Powdered" : "Un-powdered",
                    '"}],'
                )
            );
    }

    function generateSVGofTokenById(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 326.11 594.97">',
                renderTokenById(id),
                "</svg>"
            )
        );

        return svg;
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        string memory drinkcolorlight = "DEE9EA";
        string memory drinkcolordark = "C9DDDF";

        if (powder[id]) {
            drinkcolorlight = "FB415E";
            drinkcolordark = "F0455F";
        }

        string memory fluid = string(
            abi.encodePacked(
                '<path class="cls-5" d="m268.79,139.14v350.59c0,24.02-19.48,43.5-43.5,43.5H72.69c-24.03,0-43.5-19.48-43.5-43.5V139.14c0-.68.02-1.36.05-2.03.04.13.1.26.2.38,3.54,5.07,47.43,9.17,103.56,9.84,5.23.06,10.57.09,15.99.09s10.76-.03,15.99-.09c56.12-.67,99.97-4.77,103.56-9.83.1-.13.17-.26.2-.39.03.67.05,1.35.05,2.03Z"/>',
                '<path class="cls-5" d="m164.98,147.33c-5.23.06-10.57.09-15.99.09s-10.76-.03-15.99-.09c5.23-.07,10.57-.1,15.99-.1s10.76.03,15.99.1Z"/>',
                '<path class="cls-4" d="m268.74,137.11c-.03.13-.1.26-.2.39-3.59,5.06-47.44,9.16-103.56,9.83-5.23-.07-10.57-.1-15.99-.1s-10.76.03-15.99.1c-56.13-.67-100.02-4.77-103.56-9.84-.1-.12-.16-.25-.2-.38.01-.23.02-.45.04-.68.03-.65.09-1.3.16-1.94.05-.53.12-1.06.2-1.58,2.02-14.13,10.84-26.07,23.04-32.4v-.13c0-.65.04-1.29.12-1.91.32-2.71,1.34-5.21,2.87-7.32,1.17-1.63,2.64-3.02,4.34-4.09,2.44-1.56,5.33-2.46,8.44-2.46h161.07c2.98,0,5.77.83,8.15,2.27,4.57,2.76,7.63,7.78,7.63,13.51v.13c12.2,6.33,21.02,18.27,23.04,32.4.08.53.15,1.06.2,1.59.07.64.13,1.28.16,1.93.02.22.03.45.04.68Z"/>',
                '<path class="cls-2" d="m268.79,136.82c0,.1-.01.19-.05.29-.03.13-.1.26-.2.39-3.59,5.06-47.44,9.16-103.56,9.83-5.23.06-10.57.09-15.99.09s-10.76-.03-15.99-.09c-56.13-.67-100.02-4.77-103.56-9.84-.1-.12-.16-.25-.2-.38-.03-.1-.05-.19-.05-.29,0-.13.03-.26.09-.39.06-.18.19-.35.36-.52,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.17.17.3.34.36.52.06.13.09.26.09.39Z"/>'
            )
        );

        if (sips[id] == 1) {
            fluid = '<path class="cls-5" d="m268.78,217.82v271.91c0,24.02-19.48,43.5-43.5,43.5H72.68c-24.03,0-43.5-19.48-43.5-43.5V217.82c0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/><path class="cls-4" d="m268.78,139.14v78.68c0-.31-.15-.62-.45-.91-5.3-5.43-56.71-9.68-119.35-9.68s-114.05,4.25-119.35,9.68c-.3.29-.45.6-.45.91v-78.68c0-1.57.08-3.12.25-4.65.05-.53.12-1.06.2-1.58,2.02-14.13,10.84-26.07,23.04-32.4v-.13c0-8.71,7.06-15.78,15.77-15.78h161.07c8.72,0,15.78,7.07,15.78,15.78v.13c12.2,6.33,21.02,18.27,23.04,32.4.08.53.15,1.06.2,1.59.17,1.52.25,3.07.25,4.64Z"/><path class="cls-2" d="m268.78,217.82c0,.23-.08.45-.25.68-3.93,5.53-55.96,9.92-119.55,9.92s-115.68-4.39-119.55-9.93c-.17-.22-.25-.45-.25-.67,0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/>';
        }
        if (sips[id] == 2) {
            fluid = '<path class="cls-5" d="m268.78,307.82v181.91c0,24.02-19.48,43.5-43.5,43.5H72.68c-24.03,0-43.5-19.48-43.5-43.5v-181.91c0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/><path class="cls-4" d="m268.78,139.14v168.68c0-.31-.15-.62-.45-.91-5.3-5.43-56.71-9.68-119.35-9.68s-114.05,4.25-119.35,9.68c-.3.29-.45.6-.45.91v-168.68c0-1.57.08-3.12.25-4.65.05-.53.12-1.06.2-1.58,2.02-14.13,10.84-26.07,23.04-32.4v-.13c0-8.71,7.06-15.78,15.77-15.78h161.07c8.72,0,15.78,7.07,15.78,15.78v.13c12.2,6.33,21.02,18.27,23.04,32.4.08.53.15,1.06.2,1.59.17,1.52.25,3.07.25,4.64Z"/><path class="cls-2" d="m268.78,307.82c0,.23-.08.45-.25.68-3.93,5.53-55.96,9.92-119.55,9.92s-115.68-4.39-119.55-9.93c-.17-.22-.25-.45-.25-.67,0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/>';
        }
        if (sips[id] == 3) {
            fluid = '<path class="cls-5" d="m268.79,397.82v91.91c0,24.02-19.48,43.5-43.5,43.5H72.69c-24.03,0-43.5-19.48-43.5-43.5v-91.91c0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/><path class="cls-4" d="m268.79,139.14v258.68c0-.31-.15-.62-.45-.91-5.3-5.43-56.71-9.68-119.35-9.68s-114.05,4.25-119.35,9.68c-.3.29-.45.6-.45.91V139.14c0-1.57.08-3.12.25-4.65.05-.53.12-1.06.2-1.58,2.02-14.13,10.84-26.07,23.04-32.4v-.13c0-.65.04-1.29.12-1.92l1.26.15,6.59.79,11.85.03c15.34,8.61,42.67,14.41,74,14.69.77.01,1.53.01,2.31.01s1.54,0,2.31-.01c35.66-.31,66.15-7.8,79.66-18.42,3.51-2.75,5.88-5.72,6.89-8.83,4.57,2.76,7.63,7.78,7.63,13.51v.13c12.2,6.33,21.02,18.27,23.04,32.4.08.53.15,1.06.2,1.59.17,1.52.25,3.07.25,4.64Z"/><path class="cls-4" d="m237.67,86.87c-1.01,3.11-3.38,6.08-6.89,8.83-13.51,10.62-44,18.11-79.66,18.42-.77.01-1.54.01-2.31.01s-1.54,0-2.31-.01c-31.33-.28-58.66-6.08-74-14.69l-11.85-.03-6.59-.79-1.26-.15c.33-2.71,1.34-5.21,2.87-7.31,1.17-1.63,2.64-3.02,4.34-4.09,2.44-1.56,5.33-2.46,8.44-2.46h161.07c2.98,0,5.77.83,8.15,2.27Z"/><path class="cls-2" d="m268.79,397.82c0,.23-.08.45-.25.68-3.93,5.53-55.96,9.92-119.55,9.92s-115.68-4.39-119.55-9.93c-.17-.22-.25-.45-.25-.67,0-.31.15-.62.45-.91,5.3-5.43,56.71-9.68,119.35-9.68s114.05,4.25,119.35,9.68c.3.29.45.6.45.91Z"/>';
        }
        if (sips[id] == 4) {
            fluid = '<path class="cls-4" d="m268.79,139.14v350.59c0,.9-.03,1.8-.09,2.69,0,.31-.03.62-.06.93-1.84,22.33-20.55,39.88-43.35,39.88H72.69c-22.81,0-41.52-17.56-43.35-39.89-.03-.31-.05-.61-.06-.92-.06-.89-.09-1.79-.09-2.69V139.14c0-1.57.08-3.12.25-4.65.05-.53.12-1.06.2-1.58,2.02-14.13,10.84-26.07,23.04-32.4v-.13c0-.65.04-1.29.12-1.92l1.26.15,6.59.79,11.85.03c15.34,8.61,42.67,14.41,74,14.69.77.01,1.53.01,2.31.01s1.54,0,2.31-.01c35.66-.31,66.15-7.8,79.66-18.42,3.51-2.75,5.88-5.72,6.89-8.83,4.57,2.76,7.63,7.78,7.63,13.51v.13c12.2,6.33,21.02,18.27,23.04,32.4.08.53.15,1.06.2,1.59.17,1.52.25,3.07.25,4.64Z"/><path class="cls-4" d="m237.67,86.87c-1.01,3.11-3.38,6.08-6.89,8.83-13.51,10.62-44,18.11-79.66,18.42-.77.01-1.54.01-2.31.01s-1.54,0-2.31-.01c-31.33-.28-58.66-6.08-74-14.69l-11.85-.03-6.59-.79-1.26-.15c.33-2.71,1.34-5.21,2.87-7.31,1.17-1.63,2.64-3.02,4.34-4.09,2.44-1.56,5.33-2.46,8.44-2.46h161.07c2.98,0,5.77.83,8.15,2.27Z"/>';
        }

        string memory render = string(
            abi.encodePacked(
                "<defs>",
                "<style>.cls-1{fill:#",
                color[id].toColor(),
                ";}.cls-1,.cls-2,.cls-3,.cls-4,.cls-5{stroke:#231f20;stroke-miterlimit:10;}.cls-2{fill:#",
                drinkcolordark,
                ";}.cls-3{fill:none;stroke-width:2px;}.cls-4{fill:#e8e8e8;}.cls-5{fill:#",
                drinkcolorlight,
                ";}</style>",
                "</defs>",
                fluid,
                '<path class="cls-1" d="m238.23,51v32.4c0,4.37-2.66,8.54-7.46,12.3-13.51,10.62-44,18.11-79.66,18.42-.77,0-1.53,0-2.31,0s-1.54,0-2.31,0c-31.33-.28-58.66-6.08-74-14.69-2.12-1.19-4.02-2.43-5.66-3.73-1.5-1.18-2.8-2.4-3.86-3.65-2.34-2.74-3.6-5.64-3.6-8.64v-32.4c0,5.94,4.92,11.5,13.44,16.21,1.23.68,2.54,1.34,3.93,1.98,16.27,7.6,42.49,12.52,72.06,12.52s55.78-4.92,72.05-12.52c1.39-.64,2.71-1.3,3.94-1.98,8.52-4.7,13.44-10.27,13.44-16.21Z"/>',
                '<path class="cls-1" d="m238.23,51c0,5.94-4.92,11.5-13.44,16.21-1.23.68-2.55,1.34-3.94,1.98-16.27,7.6-42.49,12.52-72.05,12.52s-55.79-4.92-72.06-12.52c-1.39-.64-2.7-1.3-3.93-1.98-8.51-4.7-13.44-10.27-13.44-16.21,0-8.95,11.15-17.02,28.95-22.63l10.24,11.27,22.21,12.87c-.77-1.38-1.17-2.83-1.17-4.34,0-2.18.86-4.25,2.4-6.12l-17.03-11.25-5.11-5.5c14.06-3.17,30.88-5.01,48.94-5.01,49.39,0,89.43,13.75,89.43,30.72Z"/>',
                '<path class="cls-1" d="m178,48.17c0,8.52-13.08,15.43-29.2,15.43-13.27,0-24.48-4.68-28.02-11.09-.77-1.38-1.17-2.83-1.17-4.34,0-2.18.86-4.25,2.4-6.12,4.48-5.47,14.8-9.29,26.8-9.29,16.12,0,29.2,6.91,29.2,15.42Z"/>',
                '<path class="cls-1" d="m119.61,48.17c0,1.51.41,2.96,1.17,4.34l-22.21-12.87-10.24-11.27-2.38-2.62-17.25-14.73-17.25-2.95-22.31,5.06-18.52,14.73-2.05,4.9-5.53,13.19-2.53,14.31,1.69-18.21,7.15-20.77,9.68-13.2L39.24.5h21.41l21.51,7.57,13.05,12.21,4.66,5.01,5.11,5.5,17.03,11.25c-1.54,1.88-2.4,3.95-2.4,6.12Z"/>',
                '<path class="cls-1" d="m72.5,99.43l-11.85-.03-6.6-.78-7.53-.9-10.07-3.8-4.43-1.67-14.25-9.68-13.89-14.31-3.37-8,2.53-14.31,5.53-13.19-2.58,15.42,2.58,15.43,11.31,9.29c2.56,1.79,5.85,4.08,9.68,6.73,5.86,4.06,7.65,5.24,10.31,6.52,1.61.77,3.18,1.37,4.73,1.88,1.39.46,2.76.86,4.11,1.28,2.89.87,5.35,1.48,7.16,1.89l7.11.86c1.07,1.26,2.36,2.47,3.86,3.65,1.64,1.3,3.54,2.54,5.66,3.73Z"/>',
                '<line class="cls-3" x1="112.12" y1="142.23" x2="112.12" y2="493.18"/><line class="cls-3" x1="91.78" y1="197.53" x2="135.1" y2="197.53"/><line class="cls-3" x1="85.16" y1="167.53" x2="141.72" y2="167.53"/><line class="cls-3" x1="85.16" y1="227.53" x2="141.72" y2="227.53"/><line class="cls-3" x1="91.78" y1="257.53" x2="135.1" y2="257.53"/><line class="cls-3" x1="85.16" y1="287.53" x2="141.72" y2="287.53"/><line class="cls-3" x1="91.78" y1="317.53" x2="135.1" y2="317.53"/><line class="cls-3" x1="85.16" y1="347.53" x2="141.72" y2="347.53"/><line class="cls-3" x1="85.16" y1="407.53" x2="141.72" y2="407.53"/><line class="cls-3" x1="91.78" y1="377.53" x2="135.1" y2="377.53"/><line class="cls-3" x1="91.78" y1="437.53" x2="135.1" y2="437.53"/><line class="cls-3" x1="84.02" y1="467.53" x2="140.59" y2="467.53"/>'
            )
        );

        return render;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
