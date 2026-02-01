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
    5: FlexColumnWidth(1.5),
    6: FlexColumnWidth(1.2),
    7: FixedColumnWidth(40),
  };

  final Set<String> _expandedCategories = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Map<String, bool> _initialLocked = {};
  final Map<String, bool> _followUpLocked = {};
  final Set<String> _templatesSynced = {};

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
  final Map<String, TextEditingController> _initialTemplateCtrls = {};
  final Map<String, TextEditingController> _followUpTemplateCtrls = {};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    for (final c in _initialTemplateCtrls.values) {
      c.dispose();
    }
    for (final c in _followUpTemplateCtrls.values) {
      c.dispose();
    }
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
                    : PageView(
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
                                  horizontal: 80, vertical: 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildSearchBar(vm),
                                  const SizedBox(height: 24),
                                  _buildCategorySection(
                                    category,
                                    vm.contributorsByCategory[category]!,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildEmailTemplates(vm, category),
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

  Widget _buildSearchBar(HomeViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (query) {
              vm.setSearchQuery(query);
              if (query.isNotEmpty) {
                final categories =
                    vm.contributorsByCategory.keys.toList();
                for (var i = 0; i < categories.length; i++) {
                  final hasMatch = vm
                      .contributorsByCategory[categories[i]]!
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
              prefixIcon:
                  const Icon(Icons.search, size: 20, color: Colors.grey),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: const Color(0xFFF2A900)
                        .withValues(alpha: 0.3),
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
                  _outboundEmailCell(c, vm),
                  _statusCell(c, vm),
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
                const SizedBox.shrink(),
                const SizedBox.shrink(),
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

  Widget _buildEmailTemplates(HomeViewModel vm, String category) {
    // Lazily create controllers and sync from VM once per category
    _initialTemplateCtrls.putIfAbsent(category, () => TextEditingController());
    _followUpTemplateCtrls.putIfAbsent(category, () => TextEditingController());
    if (!_templatesSynced.contains(category)) {
      final initial = vm.initialTemplate(category);
      final followUp = vm.followUpTemplate(category);
      if (initial.isNotEmpty || followUp.isNotEmpty) {
        _initialTemplateCtrls[category]!.text = initial;
        _followUpTemplateCtrls[category]!.text = followUp;
        _initialLocked[category] = initial.isNotEmpty;
        _followUpLocked[category] = followUp.isNotEmpty;
        _templatesSynced.add(category);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'EMAIL TEMPLATES — $category',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          vm: vm,
          category: category,
          title: 'Initial Email',
          type: 'initial',
          controller: _initialTemplateCtrls[category]!,
          locked: _initialLocked[category] ?? false,
          onToggleLock: () => setState(() =>
              _initialLocked[category] = !(_initialLocked[category] ?? false)),
        ),
        const SizedBox(height: 8),
        _buildTemplateCard(
          vm: vm,
          category: category,
          title: 'Follow-Up Email',
          type: 'followUp',
          controller: _followUpTemplateCtrls[category]!,
          locked: _followUpLocked[category] ?? false,
          onToggleLock: () => setState(() =>
              _followUpLocked[category] = !(_followUpLocked[category] ?? false)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTemplateCard({
    required HomeViewModel vm,
    required String category,
    required String title,
    required String type,
    required TextEditingController controller,
    required bool locked,
    required VoidCallback onToggleLock,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: locked ? onToggleLock : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleLock,
                    child: Icon(
                      locked ? Icons.lock_outline : Icons.lock_open,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!locked) ...[
            Divider(height: 1, color: Colors.grey.shade300),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Paste your template here...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: const Color(0xFFF2A900).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    vm.saveTemplate(category, type, controller.text.trim());
                    setState(() {
                      if (type == 'initial') {
                        _initialLocked[category] = true;
                      } else {
                        _followUpLocked[category] = true;
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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

  Widget _outboundEmailCell(Contributor c, HomeViewModel vm) {
    if (c.outboundEmail.isNotEmpty) {
      return _cell(c.outboundEmail);
    }
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Set email...',
          hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: const Color(0xFFF2A900).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            vm.setOutboundEmail(c, trimmed);
          }
        },
      ),
    );
  }

  Widget _statusCell(Contributor c, HomeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: c.status.isEmpty ? null : c.status,
          hint: Text(
            'Set status',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
          ),
          isDense: true,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
          items: HomeViewModel.statusOptions.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s, style: GoogleFonts.inter(fontSize: 12)),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              vm.setStatus(c, value);
            }
          },
        ),
      ),
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
