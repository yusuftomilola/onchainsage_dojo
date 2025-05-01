#[cfg(test)]
mod tests {
    use core::traits::Into;
    use starknet::testing::set_caller_address;
    use starknet::ContractAddress;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use onchainsage::models::signal::Signal;
    use onchainsage::systems::signal::{
        signal_system, ISignalDispatcher, ISignalDispatcherTrait
    };
    use starknet::testing;
    use dojo::model::ModelStorage;
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use onchainsage::constants::{GAME_ID};
    use onchainsage::models::signal::{Signal, Signals, SignalCount, SignalValidator};
    use onchainsage::systems::signal::{ISignalDispatcher, ISignalDispatcherTrait, signal_system};
    use onchainsage::tests::test_utils::{setup};

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

    #[test]
    fn test_generate_signal() {
        let caller = starknet::contract_address_const::<0x0>();
        let mut world = setup();

        let (contract_address, _) = world.dns(@"signal_system").unwrap();
        let signal_system = ISignalDispatcher { contract_address };

        let asset = 'BTC';
        let category = 'LONG';
        let confidence = 80;
        let hash = 0x123abc;

        let signal_id = signal_system.generate_signal(asset, category, confidence, hash);

        let signals: Signals = world.read_model(signal_id);
        let signal_count: SignalCount = world.read_model(GAME_ID);

        assert(signal_count.count == 1, 'signal count is wrong');
        assert(signals.signal.creator == caller, 'signal creator is wrong');
        assert(signals.signal.asset == asset, 'wrong asset');
        assert(signals.signal.category == category, 'wrong category');
        assert(signals.signal.confidence == confidence, 'wrong confidence');
        assert(signals.signal.hash == hash, 'wrong hash');
        assert(!signals.signal.is_validated, 'should not be validated');
    }

    #[test]
    fn test_validate_signal() {
        let caller = starknet::contract_address_const::<0x0>();
        let validator = starknet::contract_address_const::<0x1>();
        
        let mut world = setup();

        let (contract_address, _) = world.dns(@"signal_system").unwrap();
        let signal_system = ISignalDispatcher { contract_address };

        // Generate a signal first
        let signal_id = signal_system.generate_signal('BTC', 'LONG', 80, 0x123abc);

        // Validate the signal
        testing::set_contract_address(validator);
        signal_system.validate_signal(signal_id);

        // Check signal is validated
        let signals: Signals = world.read_model(signal_id);
        assert(signals.signal.is_validated, 'signal not validated');

        // Check validator record
        let validator_info: SignalValidator = world.read_model((validator, signal_id));
        assert(validator_info.validated, 'validator record not set');
    }

    #[test]
    #[should_panic(expected: ('Signal already validated', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_validate_twice() {
        let validator = starknet::contract_address_const::<0x1>();
        let mut world = setup();

        let (contract_address, _) = world.dns(@"signal_system").unwrap();
        let signal_system = ISignalDispatcher { contract_address };

        // Generate a signal
        let signal_id = signal_system.generate_signal('BTC', 'LONG', 80, 0x123abc);

        // First validation
        testing::set_contract_address(validator);
        signal_system.validate_signal(signal_id);

        // Try to validate again (should fail)
        signal_system.validate_signal(signal_id);
    }

    #[test]
    fn test_is_signal_validator() {
        let caller = starknet::contract_address_const::<0x0>();
        let validator = starknet::contract_address_const::<0x1>();
        let not_validator = starknet::contract_address_const::<0x2>();
        
        let mut world = setup();

        let (contract_address, _) = world.dns(@"signal_system").unwrap();
        let signal_system = ISignalDispatcher { contract_address };

        // Generate and validate a signal
        let signal_id = signal_system.generate_signal('BTC', 'LONG', 80, 0x123abc);
        
        testing::set_contract_address(validator);
        signal_system.validate_signal(signal_id);

        // Check validator status
        assert(
            signal_system.is_signal_validator(signal_id, validator),
            'should be validator'
        );
        assert(
            !signal_system.is_signal_validator(signal_id, not_validator),
            'should not be validator'
        );
    }
}