// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BondCoin is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant INITIAL_PRICE = 1e18; // 1 stablecoin (18-decimal internal precision)
    uint256 public constant SLOPE = 5e16; // 0.05 stablecoin price change per token

    IERC20 public immutable stablecoin;
    uint256 private immutable _scalingFactor; // 10^(18 - stablecoinDecimals)

    uint256 public reserveBalance; // tracked in stablecoin native decimals
    bool private firstBuyExecuted;

    event PriceUpdate(uint256 newPrice);

    constructor(
        address stablecoinAddress
    ) ERC20("BondCoin", "BOND") Ownable(msg.sender) {
        require(
            stablecoinAddress != address(0),
            "Invalid stablecoin address"
        );
        stablecoin = IERC20(stablecoinAddress);
        uint8 stablecoinDecimals = IERC20Metadata(
            stablecoinAddress
        ).decimals();
        require(stablecoinDecimals <= 18, "Decimals too high");
        _scalingFactor = 10 ** (18 - stablecoinDecimals);
        firstBuyExecuted = false;
    }

    function getStablecoinBalance() public view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }

    function getBONDBalance() public view returns (uint256) {
        return totalSupply();
    }

    function getBONDBalanceOf(
        address account
    ) public view returns (uint256) {
        return balanceOf(account);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (!firstBuyExecuted || totalSupply() == 0) {
            return INITIAL_PRICE;
        }
        uint256 supply = totalSupply();
        return INITIAL_PRICE + (supply * SLOPE / PRECISION);
    }

    function calculatePurchaseReturn(
        uint256 stablecoinAmount
    ) public view returns (uint256) {
        require(stablecoinAmount > 0, "Amount must be greater than 0");
        uint256 scaled = stablecoinAmount * _scalingFactor;
        if (!firstBuyExecuted) {
            return scaled;
        }
        uint256 currentPrice = getCurrentPrice();
        return (scaled * PRECISION) / currentPrice;
    }

    function calculateSaleReturn(
        uint256 bondAmount
    ) public view returns (uint256) {
        require(bondAmount > 0, "Amount must be greater than 0");
        uint256 supply = totalSupply();
        require(bondAmount <= supply, "Exceeds supply");

        uint256 scaledReturn;
        if (bondAmount == supply) {
            scaledReturn = bondAmount;
        } else {
            uint256 currentPrice = getCurrentPrice();
            scaledReturn = (bondAmount * currentPrice) / PRECISION;
        }
        return scaledReturn / _scalingFactor;
    }

    function buy(uint256 stablecoinAmount) external nonReentrant {
        require(stablecoinAmount > 0, "Must send stablecoin");

        uint256 scaled = stablecoinAmount * _scalingFactor;
        uint256 tokensToMint;
        if (!firstBuyExecuted) {
            tokensToMint = scaled;
        } else {
            uint256 currentPrice = getCurrentPrice();
            tokensToMint = (scaled * PRECISION) / currentPrice;
        }
        require(tokensToMint > 0, "Cannot purchase 0 tokens");

        stablecoin.safeTransferFrom(
            msg.sender,
            address(this),
            stablecoinAmount
        );
        reserveBalance += stablecoinAmount;
        _mint(msg.sender, tokensToMint);

        if (!firstBuyExecuted) {
            firstBuyExecuted = true;
        }

        emit PriceUpdate(getCurrentPrice());
    }

    function sell(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );

        uint256 supply = totalSupply();
        uint256 scaledReturn;
        if (amount == supply) {
            scaledReturn = amount;
        } else {
            uint256 currentPrice = getCurrentPrice();
            scaledReturn = (amount * currentPrice) / PRECISION;
        }
        uint256 stablecoinReturn = scaledReturn / _scalingFactor;

        require(
            stablecoinReturn <= stablecoin.balanceOf(address(this)),
            "Insufficient reserve balance"
        );

        _burn(msg.sender, amount);
        stablecoin.safeTransfer(msg.sender, stablecoinReturn);

        reserveBalance = stablecoin.balanceOf(address(this));

        emit PriceUpdate(getCurrentPrice());
    }

    function withdrawForLiquidity(
        uint256 bondAmount,
        uint256 stablecoinAmount
    ) external onlyOwner {
        require(
            bondAmount <= totalSupply(),
            "Insufficient BOND balance"
        );
        require(
            stablecoinAmount <= stablecoin.balanceOf(address(this)),
            "Insufficient stablecoin balance"
        );
        require(
            stablecoinAmount <= reserveBalance,
            "Exceeds reserve balance"
        );

        reserveBalance -= stablecoinAmount;
        _mint(msg.sender, bondAmount);
        stablecoin.safeTransfer(msg.sender, stablecoinAmount);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }
}
