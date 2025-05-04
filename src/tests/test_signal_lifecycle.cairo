#[cfg(test)]
mod tests {
    use core::traits::Into;
    use dojo::test_utils::spawn_test_world;
    use dojo_examples::models::signal_lifecycle::{SignalLifecycle, SignalStatus};
    use dojo_examples::systems::signal_lifecycle::signal_lifecycle_system;

    // Helper function to create a test world
    fn setup_world() -> IWorldDispatcher {
        spawn_test_world()
    }

    #[test]
    fn test_initialize_lifecycle() {
        let world = setup_world();
        let contract = signal_lifecycle_system::contract_state_for_testing();
        let signal_id: u256 = 1;

        let lifecycle = contract.initialize_lifecycle(signal_id);
        
        assert(lifecycle.signal_id == signal_id, 'Wrong signal_id');
        assert(lifecycle.status == SignalStatus::Open, 'Wrong initial status');
        assert(lifecycle.created_at > 0, 'Invalid created_at');
        assert(lifecycle.expires_at > lifecycle.created_at, 'Invalid expires_at');
    }

    #[test]
    fn test_update_status() {
        let world = setup_world();
        let contract = signal_lifecycle_system::contract_state_for_testing();
        let signal_id: u256 = 1;

        // Initialize lifecycle
        contract.initialize_lifecycle(signal_id);

        // Update to validated
        let updated = contract.update_status(signal_id, SignalStatus::Validated);
        assert(updated.status == SignalStatus::Validated, 'Status not updated');
    }

    #[test]
    #[should_panic]
    fn test_update_expired_signal() {
        let world = setup_world();
        let contract = signal_lifecycle_system::contract_state_for_testing();
        let signal_id: u256 = 1;

        // Initialize and expire lifecycle
        let lifecycle = contract.initialize_lifecycle(signal_id);
        contract.update_status(signal_id, SignalStatus::Expired);

        // Try to update expired signal (should panic)
        contract.update_status(signal_id, SignalStatus::Validated);
    }

    #[test]
    fn test_is_signal_open() {
        let world = setup_world();
        let contract = signal_lifecycle_system::contract_state_for_testing();
        let signal_id: u256 = 1;

        // Initialize lifecycle
        contract.initialize_lifecycle(signal_id);
        
        // Check if signal is open
        assert(contract.is_signal_open(signal_id), 'Signal should be open');

        // Update to validated
        contract.update_status(signal_id, SignalStatus::Validated);
        
        // Check if signal is no longer open
        assert(!contract.is_signal_open(signal_id), 'Signal should not be open');
    }
}
