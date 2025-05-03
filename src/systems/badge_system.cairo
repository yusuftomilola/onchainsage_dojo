#[dojo::contract]
mod badge_system {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use onchainsage_dojo::models::user::User;

    #[storage]
    struct Storage {
        world_dispatcher: IWorldDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, world: ContractAddress) {
        self.world_dispatcher.write(IWorldDispatcher { contract_address: world });
    }

    #[abi(embed_v0)]
    impl BadgeSystemImpl {
        /// Awards a badge to a user if conditions are met
        fn award_badge(
            ref self: ContractState,
            user: ContractAddress,
            badge: felt252,
            upvote_percentage: u8,
            profitability_percentage: u8
        ) {
            // Ensure upvote percentage is at least 70%
            assert(upvote_percentage >= 70, 'Insufficient upvote percentage');

            // Ensure profitability percentage is at least 10%
            assert(profitability_percentage >= 10, 'Insufficient profitability percentage');

            // Fetch user data from the world state
            let mut user_data = self.world_dispatcher.read().get_user(user);

            // Add the badge to the user's badge list
            user_data.badges.append(badge);

            // Update the user data in the world state
            self.world_dispatcher.read().set_user(user_data);
        }

        /// Removes a badge from a user if conditions are met
        fn remove_badge(
            ref self: ContractState,
            user: ContractAddress,
            badge: felt252,
            negative_vote_percentage: u8
        ) {
            // Ensure negative vote percentage is at least 50%
            assert(negative_vote_percentage >= 50, 'Insufficient negative vote percentage');

            // Fetch user data from the world state
            let mut user_data = self.world_dispatcher.read().get_user(user);

            // Remove the badge from the user's badge list
            let updated_badges = user_data.badges.filter(|b| *b != badge);
            user_data.badges = updated_badges;

            // Update the user data in the world state
            self.world_dispatcher.read().set_user(user_data);
        }

        /// Checks if a user can submit a trading call
        fn can_submit_call(ref self: ContractState, user: ContractAddress) -> bool {
            // Fetch user data from the world state
            let user_data = self.world_dispatcher.read().get_user(user);

            // Check if the user has any badges
            if user_data.badges.len() > 0 {
                // User has a badge, allow full privileges
                return true;
            }

            // User does not have a badge, enforce call limit
            let current_timestamp = get_block_timestamp();
            let month_start = current_timestamp - (current_timestamp % 2592000); // Start of the current month (30 days in seconds)

            // Check if the user has exceeded the call limit for the current month
            if user_data.call_count < 5 {
                // Increment the call count
                let mut updated_user_data = user_data;
                updated_user_data.call_count += 1;

                // Update the user data in the world state
                self.world_dispatcher.read().set_user(updated_user_data);

                // Allow the call
                return true;
            }

            // Deny the call if the limit is exceeded
            return false;
        }
    }
}