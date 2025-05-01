#[starknet::interface]
trait ISignal<TContractState> {
    fn generate_signal(
        ref self: TContractState,
        asset: felt252,
        category: felt252,
        confidence: u8,
        hash: felt252
    );
    fn validate_signal(
        ref self: TContractState,
        signal_id: u128,
        validation_hash: felt252
    );
}

#[dojo::contract]
mod signal_system {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    
    // Import models
    use onchainsage_dojo::models::signal::Signal;
    
    // Import events
    use onchainsage_dojo::events::signal::{SignalGenerated, SignalValidated};

    #[storage]
    struct Storage {
        world_dispatcher: IWorldDispatcher,
        next_signal_id: u128,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SignalGenerated: SignalGenerated,
        SignalValidated: SignalValidated
    }

    #[constructor]
    fn constructor(ref self: ContractState, world: ContractAddress) {
        self.world_dispatcher.write(IWorldDispatcher { contract_address: world });
        self.next_signal_id.write(0);
    }

    #[abi(embed_v0)]
    impl SignalImpl of super::ISignal<ContractState> {
        fn generate_signal(
            ref self: ContractState,
            asset: felt252,
            category: felt252,
            confidence: u8,
            hash: felt252
        ) {
            // Get caller and current timestamp
            let caller = get_caller_address();
            let timestamp = get_block_timestamp();
            
            // Validate confidence is between 0-100
            assert(confidence <= 100, 'Invalid confidence value');

            // Get next signal ID and increment
            let signal_id = self.next_signal_id.read();
            self.next_signal_id.write(signal_id + 1);

            // Create new signal
            let signal = Signal {
                signal_id,
                creator: caller,
                asset,
                category,
                confidence,
                hash,
                timestamp,
                is_validated: false
            };

            // Set signal in world state
            self.world_dispatcher.read().set_signal(signal);

            // Emit event
            self.emit(Event::SignalGenerated(
                SignalGenerated {
                    signal_id,
                    creator: caller,
                    asset,
                    category,
                    confidence,
                    timestamp
                }
            ));
        }

        fn validate_signal(
            ref self: ContractState,
            signal_id: u128,
            validation_hash: felt252
        ) {
            let caller = get_caller_address();
            let timestamp = get_block_timestamp();
            
            // Get signal from world state
            let signal = self.world_dispatcher.read().get_signal(signal_id);
            
            // Verify signal exists and not already validated
            assert(!signal.is_validated, 'Signal already validated');
            
            // Validate hash matches
            let is_valid = signal.hash == validation_hash;
            
            // Update signal validation status
            let mut updated_signal = signal;
            updated_signal.is_validated = true;
            self.world_dispatcher.read().set_signal(updated_signal);

            // Emit validation event
            self.emit(Event::SignalValidated(
                SignalValidated {
                    signal_id,
                    validator: caller,
                    is_valid,
                    timestamp
                }
            ));
        }
    }
}