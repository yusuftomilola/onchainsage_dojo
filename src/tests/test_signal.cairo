#[cfg(test)]
mod tests {
    use core::traits::Into;
    use starknet::testing::set_caller_address;
    use starknet::ContractAddress;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use onchainsage_dojo::models::signal::Signal;
    use onchainsage_dojo::systems::signal::{
        signal_system, ISignalDispatcher, ISignalDispatcherTrait
    };

    #[test]
    fn test_signal_generation() {
        // Setup
        let world = spawn_test_world();
        let contract_address = world.deploy_contract('signal_system', signal_system::CONTRACT_CLASS_HASH);
        let signal_system = ISignalDispatcher { contract_address };

        // Set caller
        let caller = starknet::contract_address_const::<0x123>();
        set_caller_address(caller);

        // Test data
        let test_asset: felt252 = 'BTC'.try_into().unwrap();
        let test_category: felt252 = 'LONG'.try_into().unwrap();
        let test_confidence: u8 = 80;
        let test_hash: felt252 = 0x123abc;

        // Generate signal
        signal_system.generate_signal(
            test_asset,
            test_category,
            test_confidence,
            test_hash
        );

        // Verify signal
        let signal = world.get_signal(0);
        assert(signal.asset == test_asset, 'Wrong asset');
        assert(signal.category == test_category, 'Wrong category');
        assert(signal.confidence == test_confidence, 'Wrong confidence');
        assert(signal.hash == test_hash, 'Wrong hash');
        assert(!signal.is_validated, 'Should not be validated');
    }

    #[test]
    fn test_signal_validation() {
        // Setup
        let world = spawn_test_world();
        let contract_address = world.deploy_contract('signal_system', signal_system::CONTRACT_CLASS_HASH);
        let signal_system = ISignalDispatcher { contract_address };

        // Set caller
        let caller = starknet::contract_address_const::<0x123>();
        set_caller_address(caller);

        // Generate initial signal
        let test_hash: felt252 = 0x123abc;
        signal_system.generate_signal(
            'BTC'.try_into().unwrap(),
            'LONG'.try_into().unwrap(),
            80,
            test_hash
        );

        // Validate signal
        signal_system.validate_signal(0, test_hash);
        
        // Verify validation
        let signal = world.get_signal(0);
        assert(signal.is_validated, 'Should be validated');
    }
}