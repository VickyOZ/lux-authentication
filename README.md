# Luxury Watch Registry Smart Contract (WR-1.0)

A decentralized application built on Stacks blockchain for authenticating, tracking, and trading luxury timepieces. This smart contract provides a secure and transparent platform for watch collectors and dealers to register, transfer, and trade high-end watches while maintaining their provenance and authenticity.

## Features

- **Watch Registration**: Securely register luxury watches with detailed specifications and storage location
- **Ownership Tracking**: Immutable record of ownership history
- **Condition Monitoring**: Track watch condition scores over time
- **Secure Trading**: Built-in marketplace functionality for listing and purchasing watches
- **Location Management**: Update and track watch storage locations
- **Administrative Controls**: Designated admin functionality for platform management

## Smart Contract Functions

### Administrative Functions
- `set-registry-admin`: Transfer admin privileges to a new principal

### Watch Management
- `register-watch`: Register a new watch in the system
- `update-storage-location`: Update the storage location of a registered watch
- `get-watch-details`: Retrieve details of a specific watch

### Marketplace Functions
- `list-watch`: List a watch for sale with a specified price
- `delist-watch`: Remove a watch from the marketplace
- `buy-watch`: Purchase a listed watch
- `get-market-listing`: Get details of a watch's market listing

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized to perform this action |
| u101 | Watch not found in registry |
| u102 | Watch is already listed for sale |
| u103 | Watch is not listed for sale |
| u104 | Invalid price specified |

## Data Structures

### WatchRegistry Map
```clarity
{
    owner: principal,
    specifications: (string-utf8 256),
    storage-location: (string-utf8 100),
    condition-score: uint,
    for-sale: bool
}
```

### WatchMarket Map
```clarity
{
    price: uint,
    seller: principal
}
```

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- [Hiro Wallet](https://wallet.hiro.so/) for contract interaction

### Deployment
1. Clone the repository
2. Deploy the contract to the Stacks blockchain using Clarinet or the Stacks CLI
3. Initialize the contract by setting the registry admin

### Usage Example
```clarity
;; Register a new watch
(contract-call? .watch-registry register-watch 
    "Rolex Submariner 116610LN, Serial: 7XXXXXXX" 
    "Secure Vault 42")

;; List watch for sale
(contract-call? .watch-registry list-watch u1 u5000000)
```

## Security Considerations

- Only the watch owner can modify watch details or list it for sale
- Admin privileges are required for system-level changes
- Built-in checks prevent unauthorized transfers
- All transactions are recorded on-chain for transparency

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request


## Contact

For inquiries and support, please open an issue in the repository.
