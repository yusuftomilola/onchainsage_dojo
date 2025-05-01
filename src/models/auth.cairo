use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Auth {
    #[key]
    pub address: ContractAddress,
    pub is_admin: bool,
    pub is_validator: bool,
    pub roles_timestamp: u64,
}