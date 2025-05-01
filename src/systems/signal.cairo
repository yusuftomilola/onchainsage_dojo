use onchainsage::models::signal::{Signal, Signals, SignalCount, SignalValidator};
use onchainsage::constants::GAME_ID;
use starknet::ContractAddress;

#[starknet::interface]
pub trait ISignal<TContractState> {
    fn generate_signal(
        ref self: TContractState,
        asset: felt252,
        category: felt252,
        confidence: u8,
        hash: felt252
    ) -> u256;
    fn validate_signal(ref self: TContractState, signal_id: u256);
    fn is_signal_validator(self: @TContractState, signal_id: u256, validator: ContractAddress) -> bool;
}

#[dojo::contract]
pub mod signal_system {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use super::{ISignal, GAME_ID};
    use onchainsage::models::signal::{Signal, Signals, SignalCount, SignalValidator};

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct SignalGenerated {
        #[key]
        pub signal_id: u256,
        pub creator: ContractAddress,
        pub timestamp: u64
    }

    #[derive(Drop, Copy, Serde)]
    #[dojo::event]
    pub struct SignalValidated {
        #[key]
        pub signal_id: u256,
        pub validator: ContractAddress,
        pub timestamp: u64
    }

    #[abi(embed_v0)]
    impl SignalImpl of ISignal<ContractState> {
        fn generate_signal(
            ref self: ContractState,
            asset: felt252,
            category: felt252,
            confidence: u8,
            hash: felt252
        ) -> u256 {
            // Get world dispatcher
            let mut world = self.world_default();
            
            // Get caller
            let caller = get_caller_address();
            
            // Get next signal ID
            let signal_count: SignalCount = world.read_model(GAME_ID);
            let signal_id = signal_count.count + 1;

            // Create signal
            let signal = Signal {
                creator: caller,
                asset,
                category,
                confidence,
                hash,
                timestamp: get_block_timestamp(),
                is_validated: false
            };

            // Update world state
            world.write_model(@SignalCount { id: GAME_ID, count: signal_id });
            world.write_model(@Signals { signal_id, signal });

            // Emit event
            world.emit_event(
                @SignalGenerated { signal_id, creator: caller, timestamp: get_block_timestamp() }
            );

            signal_id
        }

        fn validate_signal(ref self: ContractState, signal_id: u256) {
            let mut world = self.world_default();
            let caller = get_caller_address();
            
            // Get signal
            let signals: Signals = world.read_model(signal_id);
            let mut signal = signals.signal;
            
            // Validate state
            assert(!signal.is_validated, 'Signal already validated');
            
            // Update signal
            signal.is_validated = true;
            world.write_model(@Signals { signal_id, signal });

            // Record validator
            world.write_model(
                @SignalValidator {
                    validator_to_signal_id: (caller, signal_id),
                    validated: true,
                    validation_time: get_block_timestamp()
                }
            );

            // Emit event
            world.emit_event(
                @SignalValidated { 
                    signal_id,
                    validator: caller,
                    timestamp: get_block_timestamp()
                }
            );
        }

        fn is_signal_validator(
            self: @ContractState,
            signal_id: u256,
            validator: ContractAddress
        ) -> bool {
            let world = self.world_default();
            let validator_info: SignalValidator = world.read_model((validator, signal_id));
            validator_info.validated
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"onchainsage")
        }
    }
}