// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Interfaces
import {IBeefyVaultV6} from "../../contracts/BIFI/interfaces/beefy/IBeefyVaultV6.sol";

interface IERC20Like {
    function balanceOf(address account_) external view returns (uint256 balance_);
}

contract VaultUser {

    function deposit(IBeefyVaultV6 vault_, uint256 amount_) external returns (uint256 mooShares_) {
        vault_.deposit(amount_);
        mooShares_ = vault_.balanceOf(address(this));
    }

    function depositAll(IBeefyVaultV6 vault_) external returns (uint256 mooShares_) {
        vault_.depositAll();
        mooShares_ = vault_.balanceOf(address(this));
    }

    function withdraw(IBeefyVaultV6 vault_, uint256 shares_) external returns (uint256 want_) {
        vault_.withdraw(shares_);
        want_ = IERC20Like(vault_.want()).balanceOf(address(this));
    }

    function withdrawAll(IBeefyVaultV6 vault_) external returns (uint256 want_) {
        vault_.withdrawAll();
        want_ = IERC20Like(vault_.want()).balanceOf(address(this));

    }

}