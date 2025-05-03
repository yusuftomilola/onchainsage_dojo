from starkware.starknet.testing.starknet import Starknet
from utils import assert_event_emitted

# Constants
BADGE_ID = 12345
USER_ADDRESS = 0x123
UPVOTE_PERCENTAGE = 75
PROFITABILITY_PERCENTAGE = 15
NEGATIVE_VOTE_PERCENTAGE = 55

async def test_award_badge():
    starknet = await Starknet.empty()
    badge_system = await starknet.deploy("src/systems/badge_system.cairo")

    # Simulate awarding a badge
    await badge_system.award_badge(
        user=USER_ADDRESS,
        badge=BADGE_ID,
        upvote_percentage=UPVOTE_PERCENTAGE,
        profitability_percentage=PROFITABILITY_PERCENTAGE
    ).invoke()

    # Fetch user data and verify badge assignment
    user_data = await badge_system.get_user(USER_ADDRESS).call()
    assert BADGE_ID in user_data.result.badges

async def test_remove_badge():
    starknet = await Starknet.empty()
    badge_system = await starknet.deploy("src/systems/badge_system.cairo")

    # Simulate removing a badge
    await badge_system.remove_badge(
        user=USER_ADDRESS,
        badge=BADGE_ID,
        negative_vote_percentage=NEGATIVE_VOTE_PERCENTAGE
    ).invoke()

    # Fetch user data and verify badge removal
    user_data = await badge_system.get_user(USER_ADDRESS).call()
    assert BADGE_ID not in user_data.result.badges

async def test_call_restrictions():
    starknet = await Starknet.empty()
    badge_system = await starknet.deploy("src/systems/badge_system.cairo")

    # Simulate a user without a badge making calls
    for i in range(5):
        can_call = await badge_system.can_submit_call(user=USER_ADDRESS).call()
        assert can_call.result == True

    # Sixth call should be denied
    can_call = await badge_system.can_submit_call(user=USER_ADDRESS).call()
    assert can_call.result == False

    # Simulate a user with a badge making calls
    await badge_system.award_badge(
        user=USER_ADDRESS,
        badge=BADGE_ID,
        upvote_percentage=UPVOTE_PERCENTAGE,
        profitability_percentage=PROFITABILITY_PERCENTAGE
    ).invoke()

    can_call = await badge_system.can_submit_call(user=USER_ADDRESS).call()
    assert can_call.result == True  # Unrestricted calls for badge holders