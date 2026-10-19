// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract AuraSoftwareLicenseHub {
    struct Software {
        address payable developer;
        uint256 priceWei;
        bool isActive;
        bytes32 softwareHash;
    }

    address payable public immutable hubAdmin;
    string public hubDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public softwareCounter;
    uint256 public accumulatedFees;
    bool public isHubHalted;

    mapping(address => bool) public approvedDevelopers;
    mapping(uint256 => Software) public softwares;
    mapping(uint256 => mapping(address => bool)) public hasLicense;

    event DeveloperAdded(address indexed developer);
    event LicensePurchased(uint256 indexed softwareId, address indexed buyer, uint256 price);
    event SoftwareCanceled(uint256 indexed softwareId);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesDrained(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event HubHaltToggled(bool isHalted);
    event SoftwareListed(uint256 indexed softwareId, address indexed developer, uint256 price);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == hubAdmin, "AuraLicense: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isHubHalted, "AuraLicense: Hub is halted");
        _;
    }

    constructor() {
        hubAdmin = payable(msg.sender);
        hubDescriptor = "Aura Base Software License Hub v1";
        platformFeeBps = 250; // 2.5%
        isHubHalted = false;
        approvedDevelopers[msg.sender] = true;
    }

    // 1. addSoftwareDeveloper
    function addSoftwareDeveloper(address developer) external onlyAdmin {
        require(!approvedDevelopers[developer], "AuraLicense: Already approved");
        approvedDevelopers[developer] = true;
        emit DeveloperAdded(developer);
    }

    // 2. buySoftwareLicense
    function buySoftwareLicense(uint256 softwareId) external payable whenNotHalted {
        Software storage s = softwares[softwareId];
        require(softwareId > 0 && softwareId <= softwareCounter, "AuraLicense: Invalid ID");
        require(s.isActive, "AuraLicense: Software inactive");
        require(!hasLicense[softwareId][msg.sender], "AuraLicense: Already own license");
        require(msg.value >= s.priceWei, "AuraLicense: Insufficient payment");

        uint256 fee = (msg.value * platformFeeBps) / 10000;
        uint256 developerShare = msg.value - fee;

        accumulatedFees += fee;
        hasLicense[softwareId][msg.sender] = true;

        if (developerShare > 0) {
            (bool sent, ) = s.developer.call{value: developerShare}("");
            require(sent, "AuraLicense: Payout failed");
        }

        emit LicensePurchased(softwareId, msg.sender, msg.value);
    }

    // 3. cancelSoftwareListing
    function cancelSoftwareListing(uint256 softwareId) external {
        Software storage s = softwares[softwareId];
        require(softwareId > 0 && softwareId <= softwareCounter, "AuraLicense: Invalid ID");
        require(msg.sender == s.developer || msg.sender == hubAdmin, "AuraLicense: Unauthorized");
        require(s.isActive, "AuraLicense: Already inactive");

        s.isActive = false;
        emit SoftwareCanceled(softwareId);
    }

    // 4. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotHalted {
        require(msg.value > 0, "AuraLicense: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. drainPlatformReserves
    function drainPlatformReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "AuraLicense: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: balance}("");
        require(sent, "AuraLicense: Sweep failed");

        emit ReservesDrained(hubAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "AuraLicense: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: amount}("");
        require(sent, "AuraLicense: Harvest failed");

        emit FeesGathered(hubAdmin, amount);
    }

    // 7. haltLicenseHub
    function haltLicenseHub(bool isHalted) external onlyAdmin {
        isHubHalted = isHalted;
        emit HubHaltToggled(isHalted);
    }

    // 8. listNewSoftware
    function listNewSoftware(uint256 priceWei, bytes32 softwareHash) external whenNotHalted returns (uint256) {
        require(approvedDevelopers[msg.sender], "AuraLicense: Not an approved developer");
        require(priceWei > 0, "AuraLicense: Zero price not allowed");

        softwareCounter++;
        softwares[softwareCounter] = Software({
            developer: payable(msg.sender),
            priceWei: priceWei,
            isActive: true,
            softwareHash: softwareHash
        });

        emit SoftwareListed(softwareCounter, msg.sender, priceWei);
        return softwareCounter;
    }

    // 9. updateHubDescriptor
    function updateHubDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "AuraLicense: Empty string");
        hubDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}