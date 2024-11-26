// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@v3-core/interfaces/IUniswapV3Pool.sol";
import "@v3-core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "./interfaces/IWETH9.sol";

contract AutoBuyContract2Pools is Ownable, IUniswapV3SwapCallback {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // (from TickMath) The minimum value that can be returned from getSqrtRatioAtTick
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342; // (from TickMath) The maximum value that can be returned from getSqrtRatioAtTick
    uint256 constant MAX_INT = 2 ** 256 - 1;

    IWETH9 public immutable WETH_CONTRACT;

    IUniswapV3Pool public pool1;
    IUniswapV3Pool public pool2;

    error Pool1NotMadeYet();
    error Pool2NotMadeYet();
    error UnauthorizedPool();

    constructor(IWETH9 weth_contract_, IUniswapV3Pool pool1_, IUniswapV3Pool pool2_) Ownable() {
        WETH_CONTRACT = weth_contract_;
        pool1 = pool1_;
        pool2 = pool2_;
    }

    /**
     * @dev The pool1 that will be traded into.
     */
    function setPool1(IUniswapV3Pool newPool1_) public onlyOwner {
        pool1 = newPool1_;
    }

    /**
     * @dev The pool2 that will be traded into.
     */
    function setPool2(IUniswapV3Pool newPool2_) public onlyOwner {
        pool2 = newPool2_;
    }

    /// credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L323
    /// @notice The Uniswap V3 pool callback where the token transfer is expected to happen.
    /// @param _amount0Delta The amount of token 0 being used for the swap.
    /// @param _amount1Delta The amount of token 1 being used for the swap.
    /// Last param - Data passed in by the swap operation.
    function uniswapV3SwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata) external override {
        // Make sure this call is being made from within the swap execution.
        if (msg.sender != address(pool1) && msg.sender != address(pool2)) revert UnauthorizedPool();

        // Keep a reference to the amount of tokens that should be sent to fulfill the swap (the positive delta)
        uint256 _amountToSendToPool = _amount0Delta < 0 ? uint256(_amount1Delta) : uint256(_amount0Delta);

        // Wrap ETH into WETH
        WETH_CONTRACT.deposit{value: _amountToSendToPool}();

        // Transfer the token to the pool.
        WETH_CONTRACT.transfer(msg.sender, _amountToSendToPool);
    }

    receive() external payable {
        // Make sure the pool exists. credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L485
        try pool1.slot0() returns (uint160, int24, uint16, uint16, uint16, uint8, bool unlocked) {
            // If the pool hasn't been initialized, return an empty quote.
            if (!unlocked) revert Pool1NotMadeYet();
        } catch {
            // If the address is invalid or if the pool has not yet been deployed, return an empty quote.
            revert Pool1NotMadeYet();
        }

        // Make sure the pool exists. credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L485
        try pool2.slot0() returns (uint160, int24, uint16, uint16, uint16, uint8, bool unlocked) {
            // If the pool hasn't been initialized, return an empty quote.
            if (!unlocked) revert Pool2NotMadeYet();
        } catch {
            // If the address is invalid or if the pool has not yet been deployed, return an empty quote.
            revert Pool2NotMadeYet();
        }

        bool isWETHToken0Pool1 = pool1.token0() == address(WETH_CONTRACT);
        uint160 limitToUsePool1 = isWETHToken0Pool1 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;
        bool isWETHToken0Pool2 = pool2.token0() == address(WETH_CONTRACT);
        uint160 limitToUsePool2 = isWETHToken0Pool2 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;

        pool1.swap(tx.origin, isWETHToken0Pool1, int256(msg.value / 2), limitToUsePool1, "");
        pool2.swap(tx.origin, isWETHToken0Pool2, int256(msg.value - (msg.value / 2)), limitToUsePool2, "");
    }
}
