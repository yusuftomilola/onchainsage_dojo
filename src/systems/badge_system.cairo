#[dojo::contract]
mod badge_system {
    use starknet::{ContractAddress, get_caller_address};
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
    }
}