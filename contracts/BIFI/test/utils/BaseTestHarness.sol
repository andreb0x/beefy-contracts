// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {DSTest} from "../forge/test.sol";
import {Vm} from "../forge/Vm.sol";
import {console} from "../forge/console.sol";

import {IERC20Like} from "../interfaces/IERC20Like.sol";

contract BaseTestHarness is DSTest {
    // Api to modify test vm state.
    Vm internal constant FORGE_VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /*             */
    /* Forge Hacks */
    /*             */

    function modifyBalance(address token_, uint256 amount_, address user_) internal {
        IERC20Like erc20 = IERC20Like(token_);
        uint256 slotToTest;
        while (true) {
            // Get before value in case the slot is wrong, so can restore the value.
            bytes32 beforeValue = FORGE_VM.load(address(token_), keccak256(abi.encode(user_, slotToTest)));
            
            // Modify storage slot.
            FORGE_VM.store(address(token_), keccak256(abi.encode(user_, amount_)), bytes32(amount_));
            
            if (erc20.balanceOf(user_) == amount_) {
                console.log("SLOT FOUND", slotToTest);
                break;
            }

            // Restore value.
            FORGE_VM.store(address(token_), keccak256(abi.encode(user_, amount_)), beforeValue);
            slotToTest += 1;
        }
    }

    function erc20MintHack(
        IERC20Like token_,
        address account_,
        uint256 slot_,
        uint256 amountToMint_
    ) public {
        uint256 currentBalance = token_.balanceOf(account_);
        uint256 newBalance = currentBalance + amountToMint_;
        FORGE_VM.store(address(token_), keccak256(abi.encode(account_, slot_)), bytes32(newBalance));
    }

    /**
     * @dev Shifts block.timestamp and block.number ahead.
     * @param seconds_ to shift block.timestamp and block.number ahead.
     */
    function shift(uint256 seconds_) public {
        console.log("Shifting forward seconds", seconds_);
        FORGE_VM.warp(block.timestamp + seconds_);
        FORGE_VM.roll(block.number + getApproximateBlocksFromSeconds(seconds_));
    }

    /**
     * @dev Shifts block.timestamp and block.number ahead.
     * @param seconds_ to shift block.timestamp and block.number ahead.
     */
    function getApproximateBlocksFromSeconds(uint256 seconds_) public pure returns (uint256 blocks_) {
        uint256 secondsPerBlock = 14;
        return seconds_ / secondsPerBlock;
    }

    /*               */
    /* General Utils */
    /*               */

    function compareStrings(string memory a_, string memory b_) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a_))) == keccak256(abi.encodePacked((b_))));
    }
}
