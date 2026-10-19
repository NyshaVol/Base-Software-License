// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IAuraSoftwareLicenseHub {
    function buySoftwareLicense(uint256 softwareId) external payable;
    function listNewSoftware(uint256 priceWei, bytes32 softwareHash) external returns (uint256);
}
