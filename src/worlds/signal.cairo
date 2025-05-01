use dojo::world;
use onchainsage_dojo::models::signal::Signal;

#[starknet::interface]
trait ISignalWorld<TContractState> {
    fn get_signal(self: @TContractState, signal_id: u128) -> Signal;
    fn set_signal(ref self: TContractState, signal: Signal);
}

#[dojo::contract]
mod signal_world {
    use super::Signal;

    #[storage]
    struct Storage {
        signals: LegacyMap::<u128, Signal>,
    }

    #[abi(embed_v0)]
    impl SignalWorldImpl of super::ISignalWorld<ContractState> {
        fn get_signal(self: @ContractState, signal_id: u128) -> Signal {
            self.signals.read(signal_id)
        }

        fn set_signal(ref self: ContractState, signal: Signal) {
            self.signals.write(signal.signal_id, signal);
        }
    }
}