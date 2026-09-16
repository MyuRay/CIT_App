import 'package:flutter/material.dart';

/// The fixed destinations exposed by the application's primary navigation.
abstract final class MainNavigation {
  static const homeIndex = 0;
  static const scheduleIndex = 1;
  static const communityIndex = 2;
  static const bulletinIndex = 3;
  static const profileIndex = 4;
  static const destinationCount = 5;

  static int normalizeIndex(int index) {
    return index >= 0 && index < destinationCount ? index : homeIndex;
  }
}

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.hasNewCommunityPosts = false,
    this.hasNewBulletinPosts = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool hasNewCommunityPosts;
  final bool hasNewBulletinPosts;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('main_navigation_bar'),
      // Keep the default compact while allowing larger labels to wrap. This is
      // content height only; the system navigation inset is handled separately.
      height: MediaQuery.textScalerOf(context).scale(64).clamp(64.0, 88.0),
      selectedIndex: MainNavigation.normalizeIndex(selectedIndex),
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'ホーム',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: '時間割',
        ),
        NavigationDestination(
          icon: _DestinationIcon(
            icon: Icons.groups_outlined,
            label: '交流',
            hasNewContent: hasNewCommunityPosts,
          ),
          selectedIcon: _DestinationIcon(
            icon: Icons.groups,
            label: '交流',
            hasNewContent: hasNewCommunityPosts,
          ),
          label: '交流',
        ),
        NavigationDestination(
          icon: _DestinationIcon(
            icon: Icons.campaign_outlined,
            label: '掲示板',
            hasNewContent: hasNewBulletinPosts,
          ),
          selectedIcon: _DestinationIcon(
            icon: Icons.campaign,
            label: '掲示板',
            hasNewContent: hasNewBulletinPosts,
          ),
          label: '掲示板',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'マイページ',
        ),
      ],
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({
    required this.icon,
    required this.label,
    required this.hasNewContent,
  });

  final IconData icon;
  final String label;
  final bool hasNewContent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hasNewContent ? '$labelに新着があります' : label,
      child: Badge(
        key: ValueKey('${label}_new_badge'),
        isLabelVisible: hasNewContent,
        smallSize: 8,
        child: ExcludeSemantics(child: Icon(icon)),
      ),
    );
  }
}
