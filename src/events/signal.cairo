use starknet::ContractAddress;
use dojo_examples::models::signal_lifecycle::SignalStatus;

#[derive(Drop, Serde, starknet::Event)]
struct SignalGenerated {
    #[key]
    signal_id: u256,
    #[key]
    creator: ContractAddress,
    asset: felt252,
    category: felt252,
    timestamp: u64
}

#[derive(Drop, Serde, starknet::Event)]
struct SignalValidated {
    #[key]
    signal_id: u256,
    #[key]
    validator: ContractAddress,
    timestamp: u64
}

#[derive(Drop, Serde, starknet::Event)]
struct SignalStatusChanged {
    #[key]
    signal_id: u256,
    old_status: SignalStatus,
    new_status: SignalStatus,
    timestamp: u64
}