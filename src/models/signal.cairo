use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Signal {
    #[key]
    signal_id: u128,  // Unique identifier for the signal
    #[key]
    creator: ContractAddress,  // Address of signal creator
    asset: felt252,  // Asset identifier (e.g., BTC, ETH)
    category: felt252,  // Signal category (e.g., LONG, SHORT)
    confidence: u8,  // Confidence level (0-100)
    hash: felt252,  // Hash of signal data for validation
    timestamp: u64,  // Timestamp of signal creation
    is_validated: bool,  // Validation status
}