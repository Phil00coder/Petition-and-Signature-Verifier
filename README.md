# 📝 Petition and Signature Verifier

A decentralized petition platform built on the Stacks blockchain using Clarity smart contracts. Create, sign, and verify petitions with cryptographic signatures in a transparent and tamper-proof manner.

## ✨ Features

- 🏗️ **Create Petitions**: Deploy petitions with custom titles, descriptions, and signature targets
- ✍️ **Digital Signatures**: Sign petitions with cryptographic hashes for verification
- ⏰ **Deadline Management**: Set petition deadlines and reopen closed petitions
- 🔒 **Access Control**: Owner and creator permissions for petition management
- 📊 **Progress Tracking**: Real-time signature count and progress monitoring
- ✅ **Verification System**: Verify petition completion and signature validity

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Petition-and-Signature-Verifier
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
npm install
npm test
```

## 🎯 Usage

### Creating a Petition

```clarity
(contract-call? .petition-and-signature-verifier create-petition 
    "Save the Environment" 
    "A petition to implement green energy policies" 
    u1000 
    u500000)
```

### Signing a Petition

```clarity
(contract-call? .petition-and-signature-verifier sign-petition 
    u1 
    0x1234567890abcdef...)
```

### Verifying a Petition

```clarity
(contract-call? .petition-and-signature-verifier verify-petition u1)
```

## 📚 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-petition` | Create a new petition | title, description, target-signatures, deadline |
| `sign-petition` | Sign an existing petition | petition-id, signature-hash |
| `verify-petition` | Verify a completed petition | petition-id |
| `close-petition` | Close an active petition | petition-id |
| `reopen-petition` | Reopen a closed petition | petition-id, new-deadline |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|--|
| `get-petition` | Get petition details | Petition data |
| `get-petition-status` | Get petition status info | Status object |
| `get-petition-progress` | Get signature progress | Progress data |
| `can-sign-petition` | Check if user can sign | Boolean |
| `is-signature-valid` | Validate a signature | Boolean |

## 🏗️ Data Structures

### Petition Object
```clarity
{
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    target-signatures: uint,
    created-at: uint,
    deadline: uint,
    is-active: bool,
    signature-count: uint,
    is-verified: bool
}
```

### Signature Object
```clarity
{
    signed-at: uint,
    signature-hash: (buff 32)
}
```

## 🔐 Access Control

- **Contract Owner**: Can verify any petition and manage all petitions
- **Petition Creator**: Can close/reopen their own petitions and verify when target is reached
- **Signers**: Can sign active petitions (once per petition per user)

## ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Owner-only operation |
| u101 | `err-not-found` | Petition not found |
| u102 | `err-unauthorized` | Unauthorized access |
| u103 | `err-already-signed` | User already signed |
| u104 | `err-petition-closed` | Petition is closed |
| u105 | `err-invalid-threshold` | Invalid parameters |
| u106 | `err-insufficient-signatures` | Not enough signatures |
| u107 | `err-petition-active` | Petition is still active |

## 🧪 Testing

The contract includes comprehensive tests covering:

- Petition creation and validation
- Signature functionality
- Access control mechanisms
- Edge cases and error handling

Run tests with:
```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🛠️ Technical Details

- **Blockchain**: Stacks
- **Language**: Clarity
- **Contract Size**: 264 lines
- **Max Signatures per Petition**: 1,000
- **Max Petitions per Signer**: 100

## 🌟 Use Cases

- **Community Initiatives**: Organize local community petitions
- **Corporate Governance**: Employee feedback and proposal systems
- **Academic Research**: Survey and data collection with verification
- **Political Campaigns**: Transparent signature collection for ballot measures
- **Non-Profit Organizations**: Supporter mobilization and engagement

## 📞 Support

For questions, issues, or contributions, please open an issue on GitHub.

---

Built with ❤️ on Stacks blockchain
