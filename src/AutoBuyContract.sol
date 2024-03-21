// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@v3-core/interfaces/IUniswapV3Pool.sol";

contract AutoBuyContract is Ownable {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // (from TickMath) The minimum value that can be returned from getSqrtRatioAtTick

    IUniswapV3Pool public pool;
    address public proceedsDestination;

    error PoolNotMadeYet();

    constructor(IUniswapV3Pool pool_, address proceedsDestination_) Ownable() {
        pool = pool_;
        proceedsDestination = proceedsDestination_;
    }

    /**
     * @dev This pool needs to have the token this contract should buy as token1, and the native asset to the chain as token0.
     */
    function setPool(IUniswapV3Pool pool_) public onlyOwner {
        pool = pool_;
    }

    /**
     * @dev Set where the proceeds of the swaps should go.
     */
    function setProceedsDestination(address proceedsDestination_) public onlyOwner {
        proceedsDestination = proceedsDestination_;
    }

    receive() external payable {
        // Make sure the pool exists. credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L485
        try pool.slot0() returns (uint160, int24, uint16, uint16, uint16, uint8, bool unlocked) {
            // If the pool hasn't been initialized, return an empty quote.
            if (!unlocked) revert PoolNotMadeYet();
        } catch {
            // If the address is invalid or if the pool has not yet been deployed, return an empty quote.
            revert PoolNotMadeYet();
        }

        pool.swap(proceedsDestination, true, int256(msg.value), MIN_SQRT_RATIO + 1, "");
    }
}
