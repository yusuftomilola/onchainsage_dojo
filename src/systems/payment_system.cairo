use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_payment_system::models::{
    PaymentData, UserTier, PaymentEvent, PaymentEventType, TierRequirements, CallFeeConfig
};

#[dojo::interface]
trait IPaymentSystem {
    fn deposit(ref world: IWorldDispatcher, user: ContractAddress, amount: u256);
    fn upgrade_tier(ref world: IWorldDispatcher, user: ContractAddress);
    fn pay_for_call(ref world: IWorldDispatcher, user: ContractAddress, amount: u256);
    fn initialize_config(ref world: IWorldDispatcher);
    fn get_user_payment_data(world: @IWorldDispatcher, user: ContractAddress) -> PaymentData;
    fn get_call_fee(world: @IWorldDispatcher, user: ContractAddress) -> u256;
}

#[dojo::contract]
mod payment_system {
    use super::{IPaymentSystem, PaymentData, UserTier, PaymentEvent, PaymentEventType, TierRequirements, CallFeeConfig};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_block_number};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DepositMade: DepositMade,
        TierUpgraded: TierUpgraded,
        CallPaymentMade: CallPaymentMade,
        InsufficientBalance: InsufficientBalance,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositMade {
        user: ContractAddress,
        amount: u256,
        new_balance: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TierUpgraded {
        user: ContractAddress,
        old_tier: UserTier,
        new_tier: UserTier,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct CallPaymentMade {
        user: ContractAddress,
        amount: u256,
        remaining_balance: u256,
        timestamp: u64,
    }


    #[derive(Drop, starknet::Event)]
    struct InsufficientBalance {
        user: ContractAddress,
        required: u256,
        available: u256,
        timestamp: u64,
    }

    #[abi(embed_v0)]
    impl PaymentSystemImpl of IPaymentSystem<ContractState> {
        fn deposit(ref world: IWorldDispatcher, user: ContractAddress, amount: u256) {
            assert(amount > 0, 'Amount must be greater than 0');
            
            let mut payment_data = get!(world, user, (PaymentData));
            
            // Initialize if first deposit
            if payment_data.user.is_zero() {
                payment_data = PaymentData {
                    user,
                    balance: 0,
                    tier: UserTier::Basic,
                    total_deposited: 0,
                    total_spent: 0,
                    last_payment_timestamp: 0,
                };
            }
            
            payment_data.balance += amount;
            payment_data.total_deposited += amount;
            payment_data.last_payment_timestamp = get_block_timestamp();
            
            set!(world, (payment_data));
            
            // Log event for Torii
            let event_id = self._get_next_event_id(world);
            let payment_event = PaymentEvent {
                id: event_id,
                user,
                event_type: PaymentEventType::Deposit,
                amount,
                timestamp: get_block_timestamp(),
                block_number: get_block_number(),
            };
            set!(world, (payment_event));
            
