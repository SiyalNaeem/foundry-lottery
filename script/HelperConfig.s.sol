//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_GOERLI_CHAIN_ID = 5;
    uint256 public constant ETH_MUMBAI_CHAIN_ID = 80001;
    uint256 public constant ETH_POLYGON_CHAIN_ID = 137;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    /** VRF Mock Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; // 0.25 LINK
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; // 1 Gwei
    //LINK/ETH price in wei
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15; // 4.15 LINK
}

contract HelperConfig is CodeConstants, Script {

    error HelperConfig__InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilEthConfig();
        }else{
            revert HelperConfig__InvalidChainId(chainId);
        }

    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e, // Sepolia VRF Coordinator
            gasLane: 0x8472ba59cf7134dfe321f4d61a430c4857e8b19cdd5230b09952a92671c24409, // Sepolia gas lane - 30 gwei
            subscriptionId: 0, // Sepolia subscription ID
            callbackGasLimit: 500000, // 100,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789 // LINK token address
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        // Deploy mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorMock), // Anvil VRF Coordinator
            //doesn't matter
            gasLane: 0x8472ba59cf7134dfe321f4d61a430c4857e8b19cdd5230b09952a92671c24409, // Anvil gas lane - 30 gwei
            subscriptionId: 0, // Anvil subscription ID - might have to fix this
            callbackGasLimit: 500000, // 100,000 gas
            link: address(linkToken) // LINK token address
        });

        return localNetworkConfig;
        
    }

}