use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Event)]
struct SignalGenerated {
    #[key]
    signal_id: u128,
    #[key]
    creator: ContractAddress,
    asset: felt252,
    category: felt252,
    confidence: u8,
    timestamp: u64
}

#[derive(Drop, Serde, starknet::Event)]
struct SignalValidated {
    #[key]
    signal_id: u128,
    #[key]
    validator: ContractAddress,
    is_valid: bool,
    timestamp: u64
}