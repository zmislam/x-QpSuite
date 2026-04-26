/// ============================================================
/// Ads Manager Shell — Tab container for the module
/// ============================================================
/// Uses bottom NavigationBar for mobile tab switching.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ads_manager_provider.dart';
import '../utils/ads_helpers.dart';
import 'ads_overview_screen.dart';
import 'campaigns_screen.dart';
import 'ad_sets_screen.dart';
import 'ads_list_screen.dart';
import 'billing_screen.dart';

class AdsManagerShell extends StatefulWidget {
  final int initialTab;
  const AdsManagerShell({super.key, this.initialTab = 0});

  @override
  State<AdsManagerShell> createState() => AdsManagerShellState();
}

class AdsManagerShellState extends State<AdsManagerShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsManagerProvider>().initDashboard();
    });
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/more');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kTealBrand, kTealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.ads_click, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Ads Manager'),
          ],
        ),
        actions: [
          Consumer<AdsManagerProvider>(
            builder: (_, provider, __) {
              final isLoading = provider.campaignsLoading ||
                  provider.costBreakdownLoading;
              return IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kTealBrand,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 22),
                onPressed: isLoading
                    ? null
                    : () => context.read<AdsManagerProvider>().refreshAll(),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdsOverviewScreen(),
          CampaignsScreen(),
          AdSetsScreen(),
          AdsListScreen(),
          BillingScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        indicatorColor: kTealBrand.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 22),
            selectedIcon: Icon(Icons.dashboard, color: kTealBrand, size: 22),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, size: 22),
            selectedIcon: Icon(Icons.campaign, color: kTealBrand, size: 22),
            label: 'Campaigns',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined, size: 22),
            selectedIcon: Icon(Icons.layers, color: kTealBrand, size: 22),
            label: 'Ad Sets',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined, size: 22),
            selectedIcon: Icon(Icons.image, color: kTealBrand, size: 22),
            label: 'Ads',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined, size: 22),
            selectedIcon: Icon(Icons.credit_card, color: kTealBrand, size: 22),
            label: 'Billing',
          ),
        ],
      ),
    );
  }
}
