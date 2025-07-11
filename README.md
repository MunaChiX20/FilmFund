# FilmFund Crowdfunding Platform 🎬

A decentralized crowdfunding platform built on Stacks blockchain for film and creative projects, enabling transparent and secure funding mechanisms.

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://www.stacks.co/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/your-repo/filmfund)

## 🎯 Overview

FilmFund is a decentralized crowdfunding platform that allows creators to raise funds for their film projects while providing contributors with transparent investment opportunities. Built on the Stacks blockchain, it ensures security, transparency, and immutability of all transactions.

### Key Features

- **🎭 Campaign Creation**: Film creators can launch funding campaigns with customizable goals and deadlines
- **💰 Secure Contributions**: Contributors can safely invest in projects with automatic refund mechanisms
- **🔒 Transparent Funding**: All transactions are recorded on the blockchain for complete transparency
- **⚡ Automatic Execution**: Smart contracts handle fund distribution and refunds automatically
- **📊 Real-time Analytics**: Track campaign progress and statistics in real-time
- **🛡️ Security First**: Built-in security validations and authorization checks

## 🏗️ Architecture

```
FilmFund Platform
├── Campaign Management
│   ├── Create Campaign
│   ├── Fund Campaign
│   └── Finalize Campaign
├── Contribution System
│   ├── Contribute to Campaign
│   ├── Track Contributions
│   └── Process Refunds
├── Analytics & Reporting
│   ├── Campaign Statistics
│   ├── Progress Tracking
│   └── Success Metrics
└── Platform Administration
    ├── Fee Management
    ├── Fund Withdrawal
    └── Contract Governance
```

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v0.31.1 or later
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/cli-wallet-quickstart)
- Node.js v16+ (for frontend integration)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/filmfund-platform.git
   cd filmfund-platform
   ```

2. **Initialize Clarinet project**
   ```bash
   clarinet new filmfund
   cd filmfund
   ```

3. **Add the contract**
   ```bash
   # Copy the contract file to contracts/
   cp ../filmfund-crowdfunding.clar contracts/
   ```

4. **Check contract syntax**
   ```bash
   clarinet check
   ```

5. **Run tests**
   ```bash
   clarinet test
   ```

## 📋 Smart Contract API

### Public Functions

#### `create-campaign`
Creates a new crowdfunding campaign.

```clarity
(create-campaign (title (string-ascii 100)) (description (string-ascii 500)) (goal uint) (duration uint))
```

**Parameters:**
- `title`: Campaign title (max 100 characters)
- `description`: Campaign description (max 500 characters)
- `goal`: Funding goal in microSTX
- `duration`: Campaign duration in blocks

**Returns:** Campaign ID on success

**Example:**
```clarity
(contract-call? .filmfund-crowdfunding create-campaign 
  "My Film Project" 
  "An independent film about..." 
  u1000000000 
  u1000)
```

#### `contribute`
Contribute STX to a campaign.

```clarity
(contribute (campaign-id uint) (amount uint))
```

**Parameters:**
- `campaign-id`: ID of the campaign to contribute to
- `amount`: Amount to contribute in microSTX

**Returns:** `true` on successful contribution

#### `finalize-campaign`
Finalize a campaign after deadline (creator only).

```clarity
(finalize-campaign (campaign-id uint))
```

**Parameters:**
- `campaign-id`: ID of the campaign to finalize

**Returns:** `true` if funded, `false` if not funded

#### `refund`
Claim refund from an unfunded campaign.

```clarity
(refund (campaign-id uint))
```

**Parameters:**
- `campaign-id`: ID of the campaign to refund from

**Returns:** `true` on successful refund

#### `withdraw-funds`
Withdraw funds from a successful campaign (creator only).

```clarity
(withdraw-funds (campaign-id uint))
```

**Parameters:**
- `campaign-id`: ID of the funded campaign

**Returns:** `true` on successful withdrawal

#### `update-platform-fee`
Update platform fee (contract owner only).

```clarity
(update-platform-fee (new-fee uint))
```

**Parameters:**
- `new-fee`: New fee in basis points (max 1000 = 10%)

**Returns:** `true` on successful update

### Read-Only Functions

#### `get-campaign`
Retrieve campaign details.

```clarity
(get-campaign (campaign-id uint))
```

**Returns:** Campaign data map or `none`

#### `get-contribution`
Get contribution amount for a specific contributor.

```clarity
(get-contribution (campaign-id uint) (contributor principal))
```

**Returns:** Contribution amount or `none`

#### `get-campaign-stats`
Get campaign statistics and progress.

```clarity
(get-campaign-stats (campaign-id uint))
```

**Returns:** Statistics map with progress, time-left, and success status

#### `get-platform-fee`
Get current platform fee.

```clarity
(get-platform-fee)
```

**Returns:** Current platform fee in basis points

## 🏦 Data Structures

### Campaign Structure
```clarity
{
  creator: principal,        ; Campaign creator
  title: (string-ascii 100), ; Campaign title
  description: (string-ascii 500), ; Campaign description
  goal: uint,               ; Funding goal in microSTX
  raised: uint,             ; Amount raised so far
  deadline: uint,           ; Campaign deadline (block height)
  active: bool,             ; Campaign status
  funded: bool              ; Whether goal was reached
}
```

### Contribution Structure
```clarity
{
  campaign-id: uint,        ; Campaign identifier
  contributor: principal    ; Contributor's principal
}
```

## 🔧 Configuration

### Platform Settings

- **Platform Fee**: 3% (300 basis points) - adjustable by contract owner
- **Maximum Fee**: 10% (1000 basis points)
- **Campaign Duration**: Specified in blocks (approximately 10 minutes per block)

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 400 | `err-invalid-amount` | Invalid amount or parameter |
| 401 | `err-not-authorized` | Unauthorized access |
| 404 | `err-not-found` | Campaign or contribution not found |
| 409 | `err-campaign-active` | Campaign is still active |
| 410 | `err-campaign-ended` | Campaign has ended |
| 411 | `err-already-funded` | Campaign already funded |

## 🧪 Testing

### Unit Tests

Create test files in the `tests/` directory:

```typescript
// tests/filmfund-crowdfunding_test.ts
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.1/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new campaign",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;

        let block = chain.mineBlock([
            Tx.contractCall('filmfund-crowdfunding', 'create-campaign', [
                types.ascii("Test Film"),
                types.ascii("A test film project"),
                types.uint(1000000),
                types.uint(100)
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(ok u1)`);
    }
});
```

### Running Tests

```bash
clarinet test
```

## 🔐 Security Considerations

### Input Validation
- All string inputs are validated for non-empty content
- Numerical parameters are checked for positive values
- Campaign deadlines are validated against current block height

### Authorization
- Only campaign creators can finalize their campaigns
- Only campaign creators can withdraw funds from successful campaigns
- Only contract owner can update platform fees

### Fund Security
- Contributions are held in contract escrow until campaign finalization
- Automatic refunds for failed campaigns
- Platform fee is deducted only from successful campaigns

## 📈 Usage Examples

### Creating a Campaign

```clarity
;; Create a film campaign with 1 STX goal for 1000 blocks
(contract-call? .filmfund-crowdfunding create-campaign 
  "Independent Film Project" 
  "A groundbreaking independent film exploring..." 
  u1000000 
  u1000)
```

### Contributing to a Campaign

```clarity
;; Contribute 0.1 STX to campaign #1
(contract-call? .filmfund-crowdfunding contribute u1 u100000)
```

### Checking Campaign Status

```clarity
;; Get campaign details
(contract-call? .filmfund-crowdfunding get-campaign u1)

;; Get campaign statistics
(contract-call? .filmfund-crowdfunding get-campaign-stats u1)
```

## 🛣️ Roadmap

### Phase 1 (Current)
- [x] Basic crowdfunding functionality
- [x] Campaign creation and management
- [x] Contribution and refund system
- [x] Platform fee management

### Phase 2 (Planned)
- [ ] Milestone-based funding
- [ ] Campaign categories and tags
- [ ] Governance token rewards
- [ ] Campaign updates and amendments

### Phase 3 (Future)
- [ ] Multi-token support
- [ ] NFT rewards for contributors
- [ ] Decentralized governance
- [ ] Cross-chain compatibility

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Stacks Foundation](https://stacks.org/) for the blockchain infrastructure
- [Clarity Language](https://clarity-lang.org/) for the smart contract language
- [Clarinet](https://github.com/hirosystems/clarinet) for development tools

## 📞 Support

- **Documentation**: [Wiki](https://github.com/your-repo/filmfund/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-repo/filmfund/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/filmfund/discussions)
- **Discord**: [Join our Discord](https://discord.gg/filmfund)

## 🔗 Links

- **Website**: [https://filmfund.platform](https://filmfund.platform)
- **Documentation**: [https://docs.filmfund.platform](https://docs.filmfund.platform)
- **Explorer**: [https://explorer.stacks.co](https://explorer.stacks.co)

---

Made with ❤️ by the FilmFund team