use starknet::ContractAddress;

#[starknet::interface]
pub trait IAuth<TContractState> {
    fn grant_admin_role(ref self: TContractState, address: ContractAddress);
    fn revoke_admin_role(ref self: TContractState, address: ContractAddress);
    fn grant_validator_role(ref self: TContractState, address: ContractAddress);
    fn revoke_validator_role(ref self: TContractState, address: ContractAddress);
    fn is_admin(self: @TContractState, address: ContractAddress) -> bool;
    fn is_validator(self: @TContractState, address: ContractAddress) -> bool;
}

#[allow(starknet::colliding_storage_paths)]
#[dojo::contract]
pub mod auth_system {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use onchainsage::models::auth::Auth;
    use super::IAuth;

    #[storage]
    struct Storage {
        world_dispatcher: IWorldDispatcher,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        RoleGranted: RoleGranted,
        RoleRevoked: RoleRevoked,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RoleGranted {
        #[key]
        address: ContractAddress,
        #[key]
        role: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RoleRevoked {
        #[key]
        address: ContractAddress,
        #[key]
        role: felt252,
        timestamp: u64,
    }

    #[abi(embed_v0)]
    impl AuthImpl of IAuth<ContractState> {
        fn grant_admin_role(ref self: ContractState, address: ContractAddress) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            // Only existing admins can grant admin role
            assert(self.is_admin(caller), 'Caller is not admin');
            
            let mut auth = get_or_create_auth(ref world, address);
            auth.is_admin = true;
            auth.roles_timestamp = get_block_timestamp();
            
            world.write_model(@auth);
            
            // Emit event
            world.emit_event(
                RoleGranted { address, role: 'admin', timestamp: get_block_timestamp() }
            );
        }

        fn revoke_admin_role(ref self: ContractState, address: ContractAddress) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            // Only existing admins can revoke admin role
            assert(self.is_admin(caller), 'Caller is not admin');
            assert(caller != address, 'Cannot revoke own admin role');
            
            let mut auth: Auth = world.read_model(address);
            auth.is_admin = false;
            auth.roles_timestamp = get_block_timestamp();
            
            world.write_model(@auth);
            
            // Emit event
            world.emit_event(
                RoleRevoked { address, role: 'admin', timestamp: get_block_timestamp() }
            );
        }

        fn grant_validator_role(ref self: ContractState, address: ContractAddress) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            // Only admins can grant validator role
            assert(self.is_admin(caller), 'Caller is not admin');
            
            let mut auth = get_or_create_auth(ref world, address);
            auth.is_validator = true;
            auth.roles_timestamp = get_block_timestamp();
            
            world.write_model(@auth);
            
            // Emit event
            world.emit_event(
                RoleGranted { address, role: 'validator', timestamp: get_block_timestamp() }
            );
        }

        fn revoke_validator_role(ref self: ContractState, address: ContractAddress) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            // Only admins can revoke validator role
            assert(self.is_admin(caller), 'Caller is not admin');
            
            let mut auth: Auth = world.read_model(address);
            auth.is_validator = false;
            auth.roles_timestamp = get_block_timestamp();
            
            world.write_model(@auth);
            
            // Emit event
            world.emit_event(
                RoleRevoked { address, role: 'validator', timestamp: get_block_timestamp() }
            );
        }

        fn is_admin(self: @ContractState, address: ContractAddress) -> bool {
            let world = self.world_default();
            let auth: Auth = world.read_model(address);
            auth.is_admin
        }

        fn is_validator(self: @ContractState, address: ContractAddress) -> bool {
            let world = self.world_default();
            let auth: Auth = world.read_model(address);
            auth.is_validator
        }

        fn register(ref self: ContractState) {
            let caller = get_caller_address();
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"onchainsage")
        }
    }

    fn get_or_create_auth(ref world: dojo::world::WorldStorage, address: ContractAddress) -> Auth {
        let existing: Auth = world.read_model(address);
        if existing.address.is_zero() {
            Auth {
                address,
                is_admin: false,
                is_validator: false,
                roles_timestamp: get_block_timestamp()
            }
        } else {
            existing
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