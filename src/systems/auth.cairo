#[starknet::interface]
trait IAuth<TContractState> {
    fn register(ref self: TContractState);
}

#[allow(starknet::colliding_storage_paths)]
#[dojo::contract]
mod auth_system {
    use starknet::{ContractAddress, get_caller_address};
    use dojo::world::IWorldDispatcher;
    use super::IAuth;

    #[storage]
    struct Storage {
        world_dispatcher: IWorldDispatcher,
    }

    #[abi(embed_v0)]
    impl AuthImpl of IAuth<ContractState> {
        fn register(ref self: ContractState) {
            let caller = get_caller_address();
        }
    }
}

#[cfg(test)]
mod tests {
    use starknet::testing::set_caller_address;
    use dojo::test_utils::spawn_test_world;
    use super::{auth_system, IAuth};

    #[test]
    fn test_auth_flow() {
        let caller = starknet::contract_address_const::<0x123>();
        set_caller_address(caller);

        // Spawn world
        let world = spawn_test_world();

        // Create auth contract
        let contract = auth_system::Contract { world: world };
        
        // Test registration
        contract.register();
        let auth = contract.get_auth(caller);
        assert(auth.user_address == caller, 'Wrong user address');
        assert(!auth.is_active, 'Should not be active');

        // Test login
        contract.login();
        let auth = contract.get_auth(caller);
        assert(auth.is_active, 'Should be active');

        // Test logout
        contract.logout();
        let auth = contract.get_auth(caller);
        assert(!auth.is_active, 'Should not be active');
    }
} 