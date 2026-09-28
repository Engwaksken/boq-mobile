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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = <Widget>[
      DashboardPage(l10n: l10n, api: widget.api),
      ProjectsPage(l10n: l10n, api: widget.api),
      HardwarePricesPage(l10n: l10n, api: widget.api),
      ImportPage(l10n: l10n, api: widget.api),
      AccountPage(
        l10n: l10n,
        api: widget.api,
        locale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
        onSignedOut: widget.onSignedOut,
      ),
    ];

    final destinations = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard, l10n.dashboard),
      (Icons.account_tree_outlined, Icons.account_tree, l10n.projects),
      (Icons.price_check_outlined, Icons.price_check, l10n.hardwarePrices),
      (Icons.document_scanner_outlined, Icons.document_scanner, l10n.importBoq),
      (Icons.person_outline, Icons.person, l10n.account),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(destinations[_selectedIndex].$3)),

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF102A43)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              for (var index = 0; index < destinations.length; index++)
                ListTile(
                  selected: _selectedIndex == index,
                  leading: Icon(destinations[index].$2),
                  title: Text(destinations[index].$3),
                  onTap: () {
                    setState(() => _selectedIndex = index);

                    Navigator.of(context).pop();
                  },
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.managePlan),
                onTap: () {
                  Navigator.of(context).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlansPage(api: widget.api),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$2),
              label: item.$3,
            ),
        ],
      ),
    );
  }
}
