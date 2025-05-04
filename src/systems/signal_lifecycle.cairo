#[dojo::contract]
mod signal_lifecycle_system {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_examples::models::signal_lifecycle::{SignalLifecycle, SignalStatus};
    use dojo_examples::models::signal::{Signal, Signals};
    use dojo_examples::events::signal::{SignalStatusChanged};

    const SIGNAL_EXPIRY_DURATION: u64 = 86400; // 24 hours in seconds

    // Constructor
    #[constructor]
    fn constructor(self: @ContractState) {}

    #[external(v0)]
    impl SignalLifecycleImpl of ISignalLifecycle<ContractState> {
        // Initialize a new signal lifecycle
        fn initialize_lifecycle(
            self: @ContractState, 
            signal_id: u256
        ) -> SignalLifecycle {
            let world = self.world_dispatcher.read();
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Create new lifecycle with Open status
            let lifecycle = SignalLifecycle {
                signal_id,
                status: SignalStatus::Open,
                created_at: current_time,
                updated_at: current_time,
                expires_at: current_time + SIGNAL_EXPIRY_DURATION,
            };

            // Set the lifecycle in the world state
            set!(world, (lifecycle));

            lifecycle
        }

        // Update signal status
        fn update_status(
            self: @ContractState,
            signal_id: u256,
            new_status: SignalStatus
        ) -> SignalLifecycle {
            let world = self.world_dispatcher.read();
            let current_time = get_block_timestamp();

            // Get existing lifecycle
            let mut lifecycle = get!(world, signal_id, SignalLifecycle);
            
            // Don't allow updates to non-Open signals (except for expiry)
            if lifecycle.status != SignalStatus::Open && new_status != SignalStatus::Expired {
                panic!("Cannot update status of non-open signal");
            }

            // Check if signal has expired
            if current_time >= lifecycle.expires_at {
                lifecycle.status = SignalStatus::Expired;
            } else {
                // Store old status for event
                let old_status = lifecycle.status;
                
                // Update status
                lifecycle.status = new_status;
                lifecycle.updated_at = current_time;

                // Emit status change event
                emit!(world, SignalStatusChanged { 
                    signal_id,
                    old_status,
                    new_status,
                    timestamp: current_time
                });
            }

            // Update the lifecycle in world state
            set!(world, (lifecycle));

            lifecycle
        }

        // Check if a signal is open
        fn is_signal_open(self: @ContractState, signal_id: u256) -> bool {
            let world = self.world_dispatcher.read();
            let lifecycle = get!(world, signal_id, SignalLifecycle);
            
            // Check expiry first
            if get_block_timestamp() >= lifecycle.expires_at {
                return false;
            }

            lifecycle.status == SignalStatus::Open
        }

        // Get signal lifecycle
        fn get_lifecycle(self: @ContractState, signal_id: u256) -> SignalLifecycle {
            let world = self.world_dispatcher.read();
            get!(world, signal_id, SignalLifecycle)
        }
    }
}
