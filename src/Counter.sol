// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NftMarketplace {
    address public constant owner;

    constructor() {
        owner = msg.sender;
    }

    struct Order {
        address orderCreator;
        address tokenAddress;
        uint tokenId;
        uint price;
        bool isActive;
        bytes signature;
        uint deadline;
    }

    uint public listingId; 

    mapping(uint => Order) orders;

    function createOrder(address orderCreator, address tokenAddress, uint tokenId, uint price, bytes signature, uint deadline) external {
        listingId++;
        require(ERC721(tokenAddress).ownerOf(tokenId) == msg.sender, "Not token owner");
        require(ERC721(tokenAddress) != address(0), "Must be a valid address");
        require(0 < price, "Can't set price lower than zero");
        require(block.timestamp + 1 days <= deadline, "Deadline is after 1 hour");
        Order storage order = Order(orderCreator, tokenAddress, tokenId, price, signature, deadline);
        bytes32 messageHash = keccak256(abi.encodePacked(order));
        bytes32 EthSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        require(messageHash.recover(_signature) == order.orderCreator, "Invalid signature");
        order.isActive = true;
        orders[listingId] = order;
    }  

    function executeListing(uint _tokenId, bytes memory _signature) external payable {
        require(msg.value == orders[listingId].price, "Insufficient amount");
        require(block.timestamp <= orders[listingId].deadline, "Order time limit passed");
        require(!orders[listingId].isActive, "Order not active");
        Order storage order = orders[listingId];
        safeTransferFrom(order.orderCreator, msg.sender, order.tokenId);
        payable(order.orderCreator).transfer(msg.value);
        delete orders[listingId];
    }



}
