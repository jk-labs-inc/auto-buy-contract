// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@v3-core/interfaces/IUniswapV3Pool.sol";
import "@v3-core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "./interfaces/IWETH9.sol";

contract AutoLiquidateNoWrapContract is Ownable, IUniswapV3SwapCallback {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // (from TickMath) The minimum value that can be returned from getSqrtRatioAtTick
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342; // (from TickMath) The maximum value that can be returned from getSqrtRatioAtTick
    uint256 constant MAX_INT = 2 ** 256 - 1;

    IWETH9 public immutable WETH_CONTRACT;

    IUniswapV3Pool public pool;
    address public proceedsRecipient;

    error PoolNotMadeYet();
    error UnauthorizedPool();

    constructor(IWETH9 weth_contract_, IUniswapV3Pool pool_, address proceedsRecipient_) Ownable() {
        WETH_CONTRACT = weth_contract_;
        pool = pool_;
        proceedsRecipient = proceedsRecipient_; 
    }

    /**
     * @dev The pool that will be traded into.
     */
    function setPool(IUniswapV3Pool pool_) public onlyOwner {
        pool = pool_;
    }

    /**
     * @dev The address that will recieve the liquidation proceeds.
     */
    function setProceedsRecipient(address proceedsRecipient_) public onlyOwner {
        proceedsRecipient = proceedsRecipient_; 
    }

    /// credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L323
    /// @notice The Uniswap V3 pool callback where the token transfer is expected to happen.
    /// @param _amount0Delta The amount of token 0 being used for the swap.
    /// @param _amount1Delta The amount of token 1 being used for the swap.
    /// Last param - Data passed in by the swap operation.
    function uniswapV3SwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata) external override {
        // Make sure this call is being made from within the swap execution.
        if (msg.sender != address(pool)) revert UnauthorizedPool();

        // Keep a reference to the amount of tokens that should be sent to fulfill the swap (the positive delta)
        uint256 _amountToSendToPool = _amount0Delta < 0 ? uint256(_amount1Delta) : uint256(_amount0Delta);

        // Transfer the token to the pool.
        WETH_CONTRACT.transfer(msg.sender, _amountToSendToPool);
    }

    receive() external payable {
        bool isWETHToken0 = pool.token0() == address(WETH_CONTRACT);
        uint160 limitToUse = isWETHToken0 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;

        pool.swap(proceedsRecipient, isWETHToken0, int256(msg.value), limitToUse, "");
    }
}
