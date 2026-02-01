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
  static const _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.2),
    1: FlexColumnWidth(1.5),
    2: FlexColumnWidth(1.2),
    3: FlexColumnWidth(1.5),
    4: FlexColumnWidth(1.5),
    5: FixedColumnWidth(40),
  };

  final Set<String> _expandedCategories = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (query) {
                                      vm.setSearchQuery(query);
                                      if (query.isNotEmpty) {
                                        final categories = vm
                                            .contributorsByCategory.keys
                                            .toList();
                                        for (var i = 0;
                                            i < categories.length;
                                            i++) {
                                          final hasMatch = vm
                                              .contributorsByCategory[
                                                  categories[i]]!
                                              .any((c) => vm.isMatch(c));
                                          if (hasMatch) {
                                            _goToPage(i);
                                            break;
                                          }
                                        }
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search by name...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey.shade400,
                                      ),
                                      prefixIcon: const Icon(Icons.search,
                                          size: 20, color: Colors.grey),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: const Color(0xFFF2A900).withValues(alpha: 0.3),
                                            width: 2),
                                      ),
                                    ),
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                                if (vm.searchQuery.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '${vm.contributorsByCategory.values.expand((list) => list).where((c) => vm.isMatch(c)).length} matches',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (context.read<HomeViewModel>().contributorsByCategory.length > 1)
              Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: () => _goToPage(_currentPage - 1),
                      child: Icon(Icons.chevron_left,
                          size: 24, color: Colors.black54),
                    ),
                  if (_currentPage <
                      context
                              .read<HomeViewModel>()
                              .contributorsByCategory
                              .length -
                          1)
                    GestureDetector(
                      onTap: () => _goToPage(_currentPage + 1),
                      child: Icon(Icons.chevron_right,
                          size: 24, color: Colors.black54),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: _columnWidths,
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                ...HomeViewModel.contributorHeaders
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
                        )),
                const SizedBox.shrink(),
              ],
            ),
            ...visibleContributors.map((c) {
              final vm = context.read<HomeViewModel>();
              final highlighted = vm.isMatch(c);
              return TableRow(
                decoration: highlighted
                    ? const BoxDecoration(color: Color(0xFFFFF9C4))
                    : null,
                children: [
                  _cell(c.fullName),
                  _cell(c.title),
                  _cell(c.company),
                  _cell(c.email),
                  _cell(c.linkedinUrl),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          title: Text(
                            'Delete contributor?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          content: Text(
                            'Remove ${c.fullName}?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade400,
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF2A900),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        vm.deleteContributor(c);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        Table(
          border: TableBorder(
            left: BorderSide(color: Colors.grey.shade300, width: 1),
            right: BorderSide(color: Colors.grey.shade300, width: 1),
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            verticalInside:
                BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: _columnWidths,
          children: [
            TableRow(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _inputCell(_firstNameCtrl, 'First')),
                    Expanded(
                        child: _inputCell(_lastNameCtrl, 'Last')),
                  ],
                ),
                _inputCell(_titleCtrl, 'Title'),
                _inputCell(_companyCtrl, 'Company'),
                _inputCell(_emailCtrl, 'Email'),
                _inputCell(_linkedinCtrl, 'LinkedIn URL'),
                GestureDetector(
                  onTap: () => _handleAdd(
                      context.read<HomeViewModel>(), category),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add,
                        size: 20, color: Colors.black54),
                  ),
                ),
              ],
            ),
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

  Widget _inputCell(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: InputBorder.none,
        ),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _handleAdd(HomeViewModel vm, String category) {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;

    final contributor = Contributor(
      firstName: firstName,
      lastName: lastName,
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      linkedinUrl: _linkedinCtrl.text.trim(),
      category: category,
    );

    vm.addContributor(contributor);

    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _titleCtrl.clear();
    _companyCtrl.clear();
    _emailCtrl.clear();
    _linkedinCtrl.clear();
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
