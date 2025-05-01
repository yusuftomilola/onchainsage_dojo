use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct User {
    address: ContractAddress,
    badges: Array<felt252>,
    call_count: u8,
}