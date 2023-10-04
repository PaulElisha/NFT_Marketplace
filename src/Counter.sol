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
        require(ownerOf(tokenId) == msg.msg.sender, "Not token owner");
        require(isApprovedForAll());
        require(tokenAddress != address(0), "Must be a valid address");
        require(Address.hasCode(tokenAddress), "Has no code");
        require(price > 0, "Can't set price lower than zero");
        require(deadline >= block.timestamp + 23400, "Deadline is after 1 hour");
        Order storage order = Order(orderCreator, tokenAddress, tokenId, price, signature, deadline);
        order.isActive = true;
        orders[listingId] = order;
    }  

    function executeListing(uint _tokenId, bytes memory _signature) external payable {
        require(msg.value == orders[listingId].price, "Insufficient amount");
        require(block.timestamp <= orders[listingId].deadline, "Order time limit passed");
        require(!orders[listingId].isActive, "Order not active");
        Order storage order = orders[listingId];
        bytes32 messageHash = keccak256(abi.encodePacked(_tokenId, msg.sender)).toEthSignedMessageHash();
        require(messageHash.recover(_signature) == order.orderCreator, "Invalid signature");
        safeTransferFrom(order.orderCreator, msg.sender, order.tokenId);
        payable(order.orderCreator).transfer(msg.value);
        delete orders[listingId];
    }



}
