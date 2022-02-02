// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {LockedJewelOffer} from "./LockedJewelOffer.sol";
import {IJewelToken} from "./interfaces/Interfaces.sol";

contract OfferFactory is Ownable {
    uint256 public fee = 80; // in bps
    LockedJewelOffer[] public offers;
    address public jewelAddress;
    IJewelToken JEWEL;

    struct OfferData {
        address  offerAddresses;
        uint256  jewelBalances;
        address  tokenWanted;
        uint256  amountWanted;
        uint256  createdAt;
        uint256  completedAt;
        uint256  jewelSellAmount;
    }

    constructor(address _jewelAddress) {
        jewelAddress = _jewelAddress;
        JEWEL = IJewelToken(jewelAddress);
    }

    event OfferCreated(address offerAddress, address tokenWanted, uint256 amountWanted, uint256 jewelSellAmount);

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function createOffer(address _tokenWanted, uint256 _amountWanted, uint256 _jewelSellAmount) public returns (LockedJewelOffer) {
        LockedJewelOffer offer = new LockedJewelOffer(msg.sender, _tokenWanted, _amountWanted, fee, jewelAddress, _jewelSellAmount);
        offers.push(offer);
        emit OfferCreated(address(offer), _tokenWanted, _amountWanted, _jewelSellAmount);
        return offer;
    }

    function getActiveOffersByAccount() public view returns (OfferData[] memory) {
        OfferData[] memory myOffers = new OfferData[](offers.length);

        for (uint256 i; i < offers.length; i++) {
            LockedJewelOffer offer = LockedJewelOffer(offers[i]);

            if (offer.hasEnoughJewel() && offer.seller() == msg.sender && !offer.hasEnded()) {
                myOffers[i].offerAddresses = address(offer);
                myOffers[i].jewelBalances = JEWEL.totalBalanceOf(address(offer));
                myOffers[i].tokenWanted = offer.tokenWanted();
                myOffers[i].amountWanted = offer.amountWanted();
                myOffers[i].createdAt = offer.createdAt();
            }
        }
        return myOffers;
    }

    function getCompletedOffers() public view returns (OfferData[] memory) {
        OfferData[] memory completedOffers = new OfferData[](offers.length);

        for (uint256 i; i < offers.length; i++) {
            LockedJewelOffer offer = LockedJewelOffer(offers[i]);

            if (offer.hasCompleted()) {
                completedOffers[i].offerAddresses = address(offer);
                completedOffers[i].tokenWanted = offer.tokenWanted();
                completedOffers[i].amountWanted = offer.amountWanted();
                completedOffers[i].createdAt = offer.createdAt();
                completedOffers[i].completedAt = offer.completedAt();
            }
        }
        return completedOffers;
    }

    // function getPendingOffersByAccount() public view returns (OfferData[] memory) {

    // }

    function getActiveOffers() public view returns (OfferData[] memory) {
        OfferData[] memory activeOffers = new OfferData[](offers.length);
        
        for (uint256 i; i < offers.length; i++) {
            LockedJewelOffer offer = LockedJewelOffer(offers[i]);
            if (offer.hasEnoughJewel() && !offer.hasEnded()) {
                activeOffers[i].offerAddresses = address(offer);
                activeOffers[i].jewelBalances = JEWEL.totalBalanceOf(address(offer));
                activeOffers[i].tokenWanted = offer.tokenWanted();
                activeOffers[i].amountWanted = offer.amountWanted();
                activeOffers[i].createdAt = offer.createdAt();
                activeOffers[i].jewelSellAmount = offer.jewelSellAmount();
            }
        }

        return activeOffers;
    }

    function getActiveOffersByRange(uint256 start, uint256 end) public view returns (LockedJewelOffer[] memory) {
        LockedJewelOffer[] memory activeOffers = new LockedJewelOffer[](end - start);

        uint256 count;
        for (uint256 i = start; i < end; i++) {
            if (offers[i].hasJewel() && !offers[i].hasEnded()) {
                activeOffers[count++] = offers[i];
            }
        }

        return activeOffers;
    }
}
