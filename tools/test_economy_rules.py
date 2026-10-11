"""Regression cases for the PRD material safety net and acceleration accounting."""
import unittest

import balance_sim as b


class TutorialMaterials(unittest.TestCase):
    def test_no_materials_still_allows_tutorial_delivery(self):
        q = b.forge_quote(2, 1, 0, 0)
        self.assertEqual((q['ore_after'], q['ore_paid'], q['ore_subsidy']), (0, 0, 6))

    def test_first_rune_shortage_is_consumed_not_granted(self):
        q = b.forge_quote(5, 2, 2, 0, needs_stone=True)
        self.assertEqual((q['ore_after'], q['stones_after'], q['ore_paid']), (0, 0, 2))
        self.assertEqual((q['ore_subsidy'], q['stone_subsidy']), (6, 1))
        self.assertEqual(int(q['ore_paid'] * b.ORE_REFUND), 1)

    def test_assistance_cannot_be_farmed_through_reforges(self):
        for initial_wallet in (0, 1, 5, 20):
            wallet, paid = initial_wallet, 0
            previous = wallet
            for _ in range(50):
                q = b.forge_quote(5, 2, wallet, 0, needs_stone=True, old_ore_paid=paid)
                wallet, paid = q['ore_after'], q['ore_paid']
                liquid_value = wallet + int(paid * b.ORE_REFUND)
                self.assertLessEqual(liquid_value, previous)
                previous = liquid_value

    def test_safety_net_ends_exactly_at_stage_seven(self):
        self.assertIsNotNone(b.forge_quote(6, 2, 0, 0, needs_stone=True))
        self.assertIsNone(b.forge_quote(7, 2, 0, 0, needs_stone=True))

    def test_refund_counts_toward_affordability(self):
        # Furnace 5 costs 18; the previous 15 Ore weapon returns 12.
        q = b.forge_quote(8, 5, 6, 0, old_ore_paid=15)
        self.assertEqual((q['ore_after'], q['ore_paid'], q['ore_subsidy']), (0, 18, 0))
        self.assertIsNone(b.forge_quote(8, 5, 5, 0, old_ore_paid=15))

    def test_existing_rune_can_be_kept_without_inventory_stones(self):
        self.assertIsNotNone(b.forge_quote(8, 5, 6, 0, old_ore_paid=15, needs_stone=False))
        self.assertIsNone(b.forge_quote(8, 5, 6, 0, old_ore_paid=15, needs_stone=True))


class AccelerationAccounting(unittest.TestCase):
    def test_includes_both_full_cart_doubles(self):
        limits = b.acceleration_limits()
        self.assertEqual(limits['welcome'], 960)
        self.assertEqual(limits['ads_total'], 1050)
        self.assertEqual(limits['daily_total'], 1410)

    def test_weekly_purchase_is_not_added_to_daily_limit(self):
        limits = b.acceleration_limits()
        self.assertEqual(limits['supply_weekly'], 240)
        self.assertEqual(limits['daily_total'], limits['welcome'] + limits['ad_quick'] + limits['gems'])


if __name__ == '__main__':
    unittest.main()
