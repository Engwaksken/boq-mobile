part of '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
    required this.onSignedOut,
  });

  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// A bottom-navigation destination. [topSuppliers] adds the Top Suppliers
/// drawer entry directly beneath it.
typedef _HomeDestination = ({
  IconData icon,
  IconData selectedIcon,
  String label,
  Widget page,
  bool topSuppliers,
});

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final destinations = <_HomeDestination>[
      (
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
        label: l10n.dashboard,
        page: DashboardPage(l10n: l10n, api: widget.api),
        topSuppliers: false,
      ),
      (
        icon: Icons.account_tree_outlined,
        selectedIcon: Icons.account_tree,
        label: l10n.projects,
        page: ProjectsPage(l10n: l10n, api: widget.api),
        topSuppliers: false,
      ),
      // Prices and Top Suppliers require hardware-prices.view.
      if (widget.api.can('hardware-prices.view'))
        (
          icon: Icons.price_check_outlined,
          selectedIcon: Icons.price_check,
          label: l10n.getPrices,
          page: HardwarePricesPage(l10n: l10n, api: widget.api),
          topSuppliers: true,
        ),
      // Importing/creating BOQs requires boq.edit (finance stays read-only).
      if (widget.api.can('boq.edit'))
        (
          icon: Icons.document_scanner_outlined,
          selectedIcon: Icons.document_scanner,
          label: l10n.importBoq,
          page: ImportPage(l10n: l10n, api: widget.api),
          topSuppliers: false,
        ),
      (
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.account,
        page: AccountPage(
          l10n: l10n,
          api: widget.api,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
          onSignedOut: widget.onSignedOut,
        ),
        topSuppliers: false,
      ),
    ];

    final selectedIndex = _selectedIndex.clamp(0, destinations.length - 1);
    // Only roles that may see the account owner's billing get the plan entry.
    final canViewBilling = widget.api.can('subscriptions.view');

    Widget drawerTile({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool selected = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        child: ListTile(
          selected: selected,
          selectedColor: scheme.onPrimaryContainer,
          selectedTileColor: scheme.primaryContainer,
          iconColor: scheme.onSurfaceVariant,
          shape: const StadiumBorder(),
          leading: Icon(icon),
          title: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(destinations[selectedIndex].label)),

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.foundation_outlined,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              for (var index = 0; index < destinations.length; index++) ...[
                drawerTile(
                  selected: selectedIndex == index,
                  icon: selectedIndex == index
                      ? destinations[index].selectedIcon
                      : destinations[index].icon,
                  label: destinations[index].label,
                  onTap: () {
                    setState(() => _selectedIndex = index);

                    Navigator.of(context).pop();
                  },
                ),
                // Top Suppliers sits under Get Prices (same permission).
                if (destinations[index].topSuppliers)
                  drawerTile(
                    icon: Icons.emoji_events_outlined,
                    label: l10n.topSuppliers,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TopSuppliersPage(api: widget.api),
                        ),
                      );
                    },
                  ),
              ],

              drawerTile(
                icon: Icons.receipt_long_outlined,
                label: 'BOQs',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BoqsPage(api: widget.api, l10n: l10n),
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                child: Divider(),
              ),

              if (canViewBilling)
                drawerTile(
                  icon: Icons.workspace_premium_outlined,
                  label: l10n.managePlan,
                  onTap: () {
                    Navigator.of(context).pop();

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlansPage(api: widget.api),
                      ),
                    );
                  },
                ),
              drawerTile(
                icon: Icons.payments_outlined,
                label: l10n.orgExpenses,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExpensesPage(api: widget.api),
                    ),
                  );
                },
              ),
              drawerTile(
                icon: Icons.group_add_outlined,
                label: l10n.orgInvitations,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InvitationsPage(api: widget.api),
                    ),
                  );
                },
              ),
              drawerTile(
                icon: Icons.assignment_ind_outlined,
                label: l10n.orgAssignments,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProjectAssignmentsPage(api: widget.api),
                    ),
                  );
                },
              ),
              drawerTile(
                icon: Icons.help_outline,
                label: l10n.orgFaqs,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FaqsPage(api: widget.api),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [for (final destination in destinations) destination.page],
        ),
      ),

      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            for (final item in destinations)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
                tooltip: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
