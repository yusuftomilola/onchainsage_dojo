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
            

            // Emit event
            emit!(world, DepositMade {
                user,
                amount,
                new_balance: payment_data.balance,
                timestamp: get_block_timestamp(),
            });
        }

        fn upgrade_tier(ref world: IWorldDispatcher, user: ContractAddress) {
            let mut payment_data = get!(world, user, (PaymentData));
            assert(!payment_data.user.is_zero(), 'User not found');
            
            let current_tier = payment_data.tier;
            let new_tier = self._calculate_eligible_tier(world, payment_data.balance);
            
            assert(new_tier != current_tier, 'Already at highest eligible tier');
            
            let old_tier = payment_data.tier;
            payment_data.tier = new_tier;
            payment_data.last_payment_timestamp = get_block_timestamp();
            
            set!(world, (payment_data));
            
            // Log event for Torii
            let event_id = self._get_next_event_id(world);
            let payment_event = PaymentEvent {
                id: event_id,
                user,
                event_type: PaymentEventType::TierUpgrade,
                amount: 0,
                timestamp: get_block_timestamp(),
                block_number: get_block_number(),
            };
            set!(world, (payment_event));
            
            // Emit event
            emit!(world, TierUpgraded {
                user,
                old_tier,
                new_tier,
                timestamp: get_block_timestamp(),
            });
        }

        fn pay_for_call(ref world: IWorldDispatcher, user: ContractAddress, amount: u256) {
            let mut payment_data = get!(world, user, (PaymentData));
            assert(!payment_data.user.is_zero(), 'User not found');

       
            let call_fee = self._calculate_call_fee(world, payment_data.tier, amount);
            
            if payment_data.balance < call_fee {
                // Log insufficient balance event
                let event_id = self._get_next_event_id(world);
                let payment_event = PaymentEvent {
                    id: event_id,
                    user,
                    event_type: PaymentEventType::InsufficientBalance,
                    amount: call_fee,
                    timestamp: get_block_timestamp(),
                    block_number: get_block_number(),
                };
                set!(world, (payment_event));
                
                emit!(world, InsufficientBalance {
                    user,
                    required: call_fee,
                    available: payment_data.balance,
                    timestamp: get_block_timestamp(),
                });
                
                panic!("Insufficient balance for call fee");
            }
            
            payment_data.balance -= call_fee;
            payment_data.total_spent += call_fee;
            payment_data.last_payment_timestamp = get_block_timestamp();
            
            // Check if tier should be downgraded due to low balance
            let eligible_tier = self._calculate_eligible_tier(world, payment_data.balance);
            if eligible_tier != payment_data.tier {
                payment_data.tier = eligible_tier;
            }
            
            set!(world, (payment_data));
            
            // Log event for Torii
            let event_id = self._get_next_event_id(world);
            let payment_event = PaymentEvent {
                id: event_id,
                user,
                event_type: PaymentEventType::CallPayment,
                amount: call_fee,
                timestamp: get_block_timestamp(),
                block_number: get_block_number(),
            };
            set!(world, (payment_event));
            
            // Emit event
            emit!(world, CallPaymentMade {
                user,
                amount: call_fee,
                remaining_balance: payment_data.balance,
                timestamp: get_block_timestamp(),
            });
        }
     
     
        fn initialize_config(ref world: IWorldDispatcher) {
            // Set tier requirements
            let basic_req = TierRequirements {
                tier: UserTier::Basic,
                minimum_balance: 0,
                call_fee_discount: 0,
            };
            
            let premium_req = TierRequirements {
                tier: UserTier::Premium,
                minimum_balance: 1000000000000000000, // 1 STRK
                call_fee_discount: 20,
            };
            
            let vip_req = TierRequirements {
                tier: UserTier::VIP,
                minimum_balance: 10000000000000000000, // 10 STRK
                call_fee_discount: 50,
            };
            
            set!(world, (basic_req, premium_req, vip_req));
            
            // Set call fee configuration
            let fee_config = CallFeeConfig {
                id: 1,
                base_fee: 100000000000000000, // 0.1 STRK
                premium_discount: 20,
                vip_discount: 50,
            };
            
            set!(world, (fee_config));
        }

        fn get_user_payment_data(world: @IWorldDispatcher, user: ContractAddress) -> PaymentData {
            get!(world, user, (PaymentData))
        }

        fn get_call_fee(world: @IWorldDispatcher, user: ContractAddress) -> u256 {
            let payment_data = get!(world, user, (PaymentData));
            let fee_config = get!(world, 1_u8, (CallFeeConfig));
            
            self._calculate_call_fee(world, payment_data.tier, fee_config.base_fee)
        }
    }
