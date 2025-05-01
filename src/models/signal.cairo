use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SignalCount {
    #[key]
    pub id: felt252, // represents GAME_ID
    pub count: u256,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Signals {
    #[key]
    pub signal_id: u256,
    pub signal: Signal,
}

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
pub struct Signal {
    pub creator: ContractAddress,
    pub asset: felt252,
    pub category: felt252,
    pub confidence: u8,
    pub hash: felt252,
    pub timestamp: u64,
    pub is_validated: bool,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SignalValidator {
    #[key]
    pub validator_to_signal_id: (ContractAddress, u256),
    pub validated: bool,
    pub validation_time: u64,
}