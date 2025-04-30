use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Auth {
    #[key]
    player: ContractAddress,
    is_active: bool,
    created_at: u64,  // Timestamp of registration
    last_login: u64,  // Timestamp of last login
}