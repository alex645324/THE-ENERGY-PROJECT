import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/contributor.dart';
import '../view_models/home_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabLabels = ['CONTRIBUTORS', 'ADVISORS', 'PROGRESS'];
  static const _collapsedRowCount = 10;

  final Set<String> _expandedCategories = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'THE ELECTRIFICATION INDEX OS',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Row(
                children: List.generate(_tabLabels.length * 2 - 1, (i) {
                  if (i.isOdd) return const SizedBox(width: 12);
                  final tabIndex = i ~/ 2;
                  final isActive = vm.selectedTab == tabIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => vm.setTab(tabIndex),
                      child: Column(
                        children: [
                          Text(
                            _tabLabels[tabIndex],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.black
                                  : Colors.grey.shade400,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: isActive ? 2.5 : 1,
                            color: isActive
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (vm.selectedTab == 0)
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              children: [
                                for (final category
                                    in vm.contributorsByCategory.keys)
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 80, vertical: 40),
                                    child: _buildCategorySection(
                                      category,
                                      vm.contributorsByCategory[category]!,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (vm.contributorsByCategory.length > 1)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16, top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  vm.contributorsByCategory.length,
                                  (i) => GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        i,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i == _currentPage
                                            ? Colors.black54
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String category, List<Contributor> contributors) {
    final isExpanded = _expandedCategories.contains(category);
    final showToggle = contributors.length > _collapsedRowCount;
    final visibleContributors = showToggle && !isExpanded
        ? contributors.sublist(0, _collapsedRowCount)
        : contributors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$category (${contributors.length})',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: HomeViewModel.contributorHeaders
                  .map((h) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          h,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            ...visibleContributors.map((c) => TableRow(
                  children: [
                    _cell(c.fullName),
                    _cell(c.title),
                    _cell(c.company),
                    _cell(c.email),
                    _cell(c.linkedinUrl),
                  ],
                )),
          ],
        ),
        if (showToggle) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category);
                } else {
                  _expandedCategories.add(category);
                }
              });
            },
            child: Text(
              isExpanded ? 'See less' : 'See more',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
