part of 'package:rutio/screens/home/home_screen.dart';

class HomePinnedHeaderSliver extends StatelessWidget {
  final double height;
  final Widget weekStrip;
  final Widget dayProgress;

  const HomePinnedHeaderSliver({
    super.key,
    required this.height,
    required this.weekStrip,
    required this.dayProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedTopAreaDelegate(
        height: height,
        weekStrip: weekStrip,
        dayProgress: dayProgress,
      ),
    );
  }
}

class _PinnedTopAreaDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget weekStrip;
  final Widget dayProgress;

  _PinnedTopAreaDelegate({
    required this.height,
    required this.weekStrip,
    required this.dayProgress,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // IOS-FIRST IMPROVEMENT START
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(
        IosSpacing.lg,
        IosSpacing.xs,
        IosSpacing.lg,
        IosSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          weekStrip,
          const SizedBox(height: IosSpacing.xs),
          dayProgress,
        ],
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }

  @override
  bool shouldRebuild(covariant _PinnedTopAreaDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.weekStrip != weekStrip ||
        oldDelegate.dayProgress != dayProgress;
  }
}
