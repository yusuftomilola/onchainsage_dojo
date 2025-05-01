use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Event)]
struct UserRegistered {
    #[key]
    player: ContractAddress,
    created_at: u64
}

#[derive(Drop, Serde, starknet::Event)]
struct UserAuthenticated {
    #[key]
    player: ContractAddress,
    timestamp: u64,
    action: bool  // true for login, false for logout
}

#[derive(Drop, Serde, starknet::Event)]
struct RoleGranted {
    #[key]
    address: ContractAddress,
    #[key]
    role: felt252,
    timestamp: u64
}

#[derive(Drop, Serde, starknet::Event)]
struct RoleRevoked {
    #[key]
    address: ContractAddress,
    #[key]
    role: felt252,
    timestamp: u64
}