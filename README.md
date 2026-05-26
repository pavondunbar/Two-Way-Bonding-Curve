## Two-Way Bonding Curve Smart Contracts
Three two-way bonding curve token contracts that enable automated market making between BOND tokens and a stablecoin (USDT/USDC). Each contract implements a different pricing curve and provides predictable token pricing.

Prices go up for each purchase and down for each sell. You can rename this token to anything you like and pair it with any ERC-20 stablecoin by passing its address to the constructor at deployment.

The owner of each contract can withdraw the funds in reserve to set up a liquidity pool on a DEX.

# Bonding Curve Variants

**LinBondcoin.sol — Linear Bonding Curve**

- Price formula: `price = 1 + (0.05 * supply)`
- Price increases at a constant rate per token minted
- Predictable, steady growth

**ExpBondcoin.sol — Exponential Bonding Curve**

- Price formula: `price = 1 * 1.01^supply`
- Price compounds multiplicatively with each token in supply
- Steep, accelerating price growth with strong early-adopter advantage

**LogBondcoin.sol — Logarithmic Bonding Curve**

- Price formula: `price = 1 + (0.5 * ln(supply + 1))`
- Price grows quickly at first, then flattens over time
- Most stable long-term pricing

# Features

- ERC20 compliant token (BOND)
- Two-way bonding curve mechanism (buy and sell)
- Three curve options: linear, exponential, logarithmic
- Stablecoin-denominated (USDT, USDC, or any ERC-20 stablecoin)
- Automatic decimal normalization (works with 6-decimal and 18-decimal tokens)
- Automated market making
- Reentrancy protection
- Safe ERC-20 transfers (compatible with USDT's non-standard return values)
- Owner-controlled liquidity withdrawal

# Deployment

Each contract takes the stablecoin address as a constructor argument:

```solidity
// Deploy with USDT
BondCoin bondCoin = new BondCoin(0xdAC17F958D2ee523a2206206994597C13D831ec7);

// Deploy with USDC
BondCoin bondCoin = new BondCoin(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
```

The contract reads the stablecoin's decimals at deployment and handles all scaling internally.

# Core Functions

**Pricing and Calculations**

`getCurrentPrice()`

- Returns the current price of BOND in stablecoin (18-decimal internal precision)
- First purchase is always 1:1 (1 stablecoin = 1 BOND)
- Price changes depend on the curve variant used

`calculatePurchaseReturn(uint256 stablecoinAmount)`

- Calculates how many BOND tokens you'll receive for a given stablecoin amount
- Input is in the stablecoin's native decimals (e.g., 6 decimals for USDT/USDC)
- First buyer gets 1:1 ratio
- Subsequent purchases use current price for calculation

`calculateSaleReturn(uint256 bondAmount)`

- Calculates how much stablecoin you'll receive for selling BOND tokens
- Returns amount in the stablecoin's native decimals
- Uses current price to determine return amount
- Special handling for complete supply liquidation

**Trading Functions**

`buy(uint256 stablecoinAmount)`

- Purchase BOND tokens with stablecoin
- Caller must first `approve` the contract to spend their stablecoin
- Automatically calculates token amount based on current price
- Emits price update event

`sell(uint256 amount)`

- Sell BOND tokens back to the contract
- Receive stablecoin based on current price
- Requires sufficient contract reserves
- Updates reserve balance after sale

**View Functions**

`getStablecoinBalance()`

Check contract's stablecoin reserve balance

`getBONDBalance()`

Check total BOND supply

`getBONDBalanceOf(address account)`

Check BOND balance of any address

**Admin Functions**

`withdrawForLiquidity(uint256 bondAmount, uint256 stablecoinAmount)`

- Owner can withdraw stablecoin and mint BOND for DEX liquidity
- Requires sufficient balances
- Updates reserve tracking

# Benefits for Users

**Predictable Pricing**

- Know exact price before trading
- Choose the curve that fits your tokenomics
- No sudden price jumps

**Guaranteed Liquidity**

- Always able to buy tokens
- Always able to sell (if reserves available)
- No need to find counterparty

**Stablecoin-Denominated**

- Reserve holds its value (no volatility risk)
- Price on the curve always means dollars
- No oracle dependency

**Early Adopter Advantage**

- Better prices for early buyers
- Price appreciates with supply
- Natural token value growth

**Transparency**

- All calculations visible on-chain
- Clear price formula
- Real-time price updates

**Security**

- Reentrancy protection
- SafeERC20 for all token transfers (handles non-standard tokens like USDT)
- Balance checks and reserve tracking

# Technical Details

- Solidity Version: 0.8.24
- Initial Price: 1 stablecoin
- BOND Decimal Places: 18
- Stablecoin Support: Any ERC-20 with <= 18 decimals
- Dependencies: OpenZeppelin Contracts (ERC20, Ownable, ReentrancyGuard, SafeERC20)

# Usage Example (JavaScript)

```javascript
// Approve the contract to spend your USDC
const amount = ethers.utils.parseUnits("100", 6); // 100 USDC (6 decimals)
await usdc.approve(bondCoinAddress, amount);

// Buy BOND tokens
await bondCoin.buy(amount);

// Check current price
const price = await bondCoin.getCurrentPrice();

// Sell BOND tokens
const bondAmount = ethers.utils.parseEther("1.0"); // 1 BOND (18 decimals)
await bondCoin.sell(bondAmount);
```

# Important Notes

**Approval Required**

- You must call `approve` on the stablecoin contract before buying
- The contract uses `transferFrom` to pull stablecoins from your wallet

**Reserve Limitations**

- Sells require sufficient stablecoin reserves
- Large sells might be limited by available reserves
- Consider reserve levels when trading

**Price Movement**

- Price increases with every purchase
- No price decrease from sales
- Consider timing of trades

**Gas Considerations**

- Buy/sell transactions require gas
- Linear curve is most gas-efficient
- Logarithmic curve uses the most gas (ln/exp calculations)
- Exponential curve gas cost scales with supply (iterative loop)

# License
MIT
