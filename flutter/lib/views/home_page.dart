import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/advisor.dart';
import '../models/contributor.dart';
import '../view_models/advisor_view_model.dart';
import '../view_models/home_view_model.dart';
import 'body_editor.dart' if (dart.library.html) 'body_editor_web.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabLabels = ['CONTRIBUTORS', 'ADVISORS', 'REPORT'];
  static const _collapsedRowCount = 10;

  Map<int, TableColumnWidth> _columnWidths(bool showLinkedIn) {
    if (showLinkedIn) {
      return const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
        6: FlexColumnWidth(1.2),
        7: FixedColumnWidth(40),
      };
    }
    return const {
      0: FlexColumnWidth(1.2),
      1: FlexColumnWidth(1.5),
      2: FlexColumnWidth(1.2),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(1.5),
      5: FlexColumnWidth(1.2),
      6: FixedColumnWidth(40),
    };
  }

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
  final _advFirstNameCtrl = TextEditingController();
  final _advLastNameCtrl = TextEditingController();
  final _advUniversityCtrl = TextEditingController();
  final _advEmailCtrl = TextEditingController();
  final Map<String, TextEditingController> _initialSubjectCtrls = {};
  final Map<String, GlobalKey<BodyEditorState>> _initialBodyKeys = {};
  final Map<String, TextEditingController> _followUpSubjectCtrls = {};
  final Map<String, GlobalKey<BodyEditorState>> _followUpBodyKeys = {};
  final Map<String, TextEditingController> _initialFooterCtrls = {};
  final Map<String, TextEditingController> _followUpFooterCtrls = {};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    _advFirstNameCtrl.dispose();
    _advLastNameCtrl.dispose();
    _advUniversityCtrl.dispose();
    _advEmailCtrl.dispose();
    for (final c in _initialSubjectCtrls.values) { c.dispose(); }
    for (final c in _followUpSubjectCtrls.values) { c.dispose(); }
    for (final c in _initialFooterCtrls.values) { c.dispose(); }
    for (final c in _followUpFooterCtrls.values) { c.dispose(); }
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
            const SizedBox(height: 24),
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
                                  _buildSearchBar(vm, category),
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
            if (vm.selectedTab == 1)
              Expanded(
                child: _buildAdvisorsTab(),
              ),
            if (vm.selectedTab == 2)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Reports',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate summaries and insights from your contributor and advisor data.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Generate Report with Claude',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(HomeViewModel vm, String category) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (query) => vm.setSearchQuery(query),
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
            '${(vm.contributorsByCategory[category] ?? []).where((c) => vm.isMatch(c)).length} matches',
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
            Row(
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
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _checkDuplicates(context.read<HomeViewModel>(), category, contributors),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Check Duplicates',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
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
          columnWidths: _columnWidths(context.read<HomeViewModel>().showLinkedIn),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                ...HomeViewModel.contributorHeaders
                    .where((h) => h != 'LINKEDIN' || context.read<HomeViewModel>().showLinkedIn)
                    .map((h) {
                      if (h == 'LINKEDIN') {
                        return GestureDetector(
                          onTap: () => context.read<HomeViewModel>().toggleLinkedIn(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Text(h, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.5)),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_left, size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        );
                      }
                      if (h == 'EMAIL' && !context.read<HomeViewModel>().showLinkedIn) {
                        return GestureDetector(
                          onTap: () => context.read<HomeViewModel>().toggleLinkedIn(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Text(h, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.5)),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(h, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.5)),
                      );
                    }),
                const SizedBox.shrink(),
              ],
            ),
            ...visibleContributors.map((c) {
              final vm = context.read<HomeViewModel>();
              final highlighted = vm.isMatch(c);
              Color? rowColor;
              if (highlighted) {
                rowColor = const Color(0xFFE1BEE7);
              } else {
                switch (c.status) {
                  case 'Initial Email Sent':
                    rowColor = const Color(0xFFE3F2FD); // light blue
                  case 'No Response':
                    rowColor = const Color(0xFFFFF3E0); // light orange
                  case 'Follow-Up Sent':
                    rowColor = const Color(0xFFFFF9C4); // light yellow
                  case 'Responded':
                    rowColor = const Color(0xFFE8F5E9); // light green
                  case 'No Response After Follow-Up':
                    rowColor = const Color(0xFFFFCDD2); // light red
                }
              }
              return TableRow(
                decoration: rowColor != null
                    ? BoxDecoration(color: rowColor)
                    : null,
                children: [
                  _cell(c.fullName),
                  _cell(c.title),
                  _cell(c.company),
                  _cell(c.email),
                  if (vm.showLinkedIn) _cell(c.linkedinUrl),
                  _outboundEmailCell(c, vm),
                  _cell(c.status.isEmpty ? '—' : c.status),
                  GestureDetector(
                    onTap: () async {
                      if (await _confirmAction('Delete contributor?', 'Remove ${c.fullName}?')) {
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
          columnWidths: _columnWidths(context.read<HomeViewModel>().showLinkedIn),
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
                if (context.read<HomeViewModel>().showLinkedIn)
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
    _initialSubjectCtrls.putIfAbsent(category, () => TextEditingController());
    _initialBodyKeys.putIfAbsent(category, () => GlobalKey<BodyEditorState>());
    _followUpSubjectCtrls.putIfAbsent(category, () => TextEditingController());
    _followUpBodyKeys.putIfAbsent(category, () => GlobalKey<BodyEditorState>());
    _initialFooterCtrls.putIfAbsent(category, () => TextEditingController());
    _followUpFooterCtrls.putIfAbsent(category, () => TextEditingController());
    if (!_templatesSynced.contains(category)) {
      final hasInitial = vm.initialSubject(category).isNotEmpty || vm.initialBody(category).isNotEmpty;
      final hasFollowUp = vm.followUpSubject(category).isNotEmpty || vm.followUpBody(category).isNotEmpty;
      if (hasInitial || hasFollowUp) {
        _initialSubjectCtrls[category]!.text = vm.initialSubject(category);
        _followUpSubjectCtrls[category]!.text = vm.followUpSubject(category);
        _initialFooterCtrls[category]!.text = vm.initialFooter(category);
        _followUpFooterCtrls[category]!.text = vm.followUpFooter(category);
        _initialLocked[category] = hasInitial;
        _followUpLocked[category] = hasFollowUp;
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
          subjectCtrl: _initialSubjectCtrls[category]!,
          bodyKey: _initialBodyKeys[category]!,
          bodyInitialHtml: vm.initialBody(category),
          footerCtrl: _initialFooterCtrls[category]!,
          locked: _initialLocked[category] ?? false,
          onToggleLock: () {
            if (!(_initialLocked[category] ?? false)) {
              vm.saveTemplate(
                category,
                'initial',
                _initialSubjectCtrls[category]!.text.trim(),
                _initialBodyKeys[category]!.currentState?.html ?? '',
                _initialFooterCtrls[category]!.text.trim(),
              );
            }
            setState(() =>
                _initialLocked[category] = !(_initialLocked[category] ?? false));
          },
        ),
        const SizedBox(height: 8),
        _buildTemplateCard(
          vm: vm,
          category: category,
          title: 'Follow-Up Email',
          type: 'followUp',
          subjectCtrl: _followUpSubjectCtrls[category]!,
          bodyKey: _followUpBodyKeys[category]!,
          bodyInitialHtml: vm.followUpBody(category),
          footerCtrl: _followUpFooterCtrls[category]!,
          locked: _followUpLocked[category] ?? false,
          onToggleLock: () {
            if (!(_followUpLocked[category] ?? false)) {
              vm.saveTemplate(
                category,
                'followUp',
                _followUpSubjectCtrls[category]!.text.trim(),
                _followUpBodyKeys[category]!.currentState?.html ?? '',
                _followUpFooterCtrls[category]!.text.trim(),
              );
            }
            setState(() =>
                _followUpLocked[category] = !(_followUpLocked[category] ?? false));
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _sendButton(vm, category, 'Send Initial Emails', 'initial'),
            const SizedBox(width: 12),
            _sendButton(vm, category, 'Send Follow-Up Emails', 'followUp'),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: vm.checkingReplies ? null : () => vm.checkReplies(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vm.checkingReplies ? 'Checking...' : 'Check Replies',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: vm.checkingReplies
                        ? Colors.grey.shade400
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            if (vm.sending) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  if (vm.paused) {
                    vm.resumeJob();
                  } else {
                    if (await _confirmAction('Pause job?', 'Pause sending emails? You can resume later.')) {
                      vm.pauseJob();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vm.paused ? 'Resume' : 'Pause',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  if (await _confirmAction('Stop job?', 'Stop sending emails? This cannot be undone.')) {
                    vm.stopJob();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Stop',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ),
            ],
            if (vm.sendResult.isNotEmpty && !vm.sending) ...[
              const SizedBox(width: 12),
              Text(
                vm.sendResult,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (vm.checkResult.isNotEmpty && !vm.checkingReplies) ...[
              const SizedBox(width: 12),
              Text(
                vm.checkResult,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
        _buildRespondedSection(vm, category),
        _buildSendDashboard(vm),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRespondedSection(HomeViewModel vm, String category) {
    final responded = (vm.contributorsByCategory[category] ?? [])
        .where((c) => c.status == 'Responded')
        .toList();
    if (responded.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFA5D6A7)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFE8F5E9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESPONDED (${responded.length})',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...responded.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      c.fullName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: Text(
                      c.email,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'via ${c.outboundEmail.replaceAll('@gmail.com', '')}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required HomeViewModel vm,
    required String category,
    required String title,
    required String type,
    required TextEditingController subjectCtrl,
    required GlobalKey<BodyEditorState> bodyKey,
    required String bodyInitialHtml,
    required TextEditingController footerCtrl,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _templateLabel('Subject'),
                  const SizedBox(height: 4),
                  _templateField(subjectCtrl, 'Email subject line...'),
                  const SizedBox(height: 12),
                  _templateLabel('Body'),
                  const SizedBox(height: 4),
                  BodyEditor(
                    key: bodyKey,
                    initialHtml: bodyInitialHtml,
                    hint: 'Paste from Google Docs to keep formatting...',
                    minHeight: 200,
                  ),
                  const SizedBox(height: 12),
                  _templateLabel('Footer'),
                  const SizedBox(height: 4),
                  _templateField(footerCtrl, 'Email footer text...', maxLines: 3),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    vm.saveTemplate(
                      category,
                      type,
                      subjectCtrl.text.trim(),
                      bodyKey.currentState?.html ?? '',
                      footerCtrl.text.trim(),
                    );
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

  Widget _templateLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _templateField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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


  Widget _buildSendDashboard(HomeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SEND PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${vm.overallSent} / ${vm.overallTotal}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: vm.overallTotal > 0
                  ? vm.overallSent / vm.overallTotal
                  : 0,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF2A900)),
            ),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const ['ACCOUNT', 'STATUS', 'TIMER', 'SENT'].map((h) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.5)),
                  );
                }).toList(),
              ),
              ...vm.accountStatuses.map((a) => _buildAccountRow(a)),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildAccountRow(Map<String, dynamic> account) {
    final email = (account['email'] as String).replaceAll('@gmail.com', '');
    final status = account['status'] as String;
    final sent = account['sent'] as int;
    final total = account['total'] as int;
    final cooldownUntil = account['cooldownUntil'] as double;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'sending':
        statusColor = const Color(0xFFF2A900);
        statusText = 'Sending';
      case 'cooldown':
        statusColor = Colors.blue;
        statusText = 'Cooldown';
      case 'break':
        statusColor = Colors.orange;
        statusText = '5-min Break';
      case 'pending':
        statusColor = Colors.grey;
        statusText = 'Starting';
      case 'idle':
        statusColor = Colors.grey.shade400;
        statusText = 'Idle';
      case 'error':
        statusColor = Colors.red;
        statusText = 'Error';
      case 'paused':
        statusColor = Colors.purple;
        statusText = 'Paused';
      case 'stopped':
        statusColor = Colors.red.shade300;
        statusText = 'Stopped';
      case 'done':
        statusColor = Colors.green;
        statusText = 'Done';
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    String countdown = '';
    if ((status == 'cooldown' || status == 'break') && cooldownUntil > 0) {
      final remaining =
          (cooldownUntil - DateTime.now().millisecondsSinceEpoch / 1000)
              .ceil();
      if (remaining > 0) {
        if (remaining >= 60) {
          countdown =
              '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
        } else {
          countdown = '${remaining}s';
        }
      }
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            email,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            countdown,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$sent / $total',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _sendButton(HomeViewModel vm, String category, String label, String type) {
    return GestureDetector(
      onTap: vm.sending ? null : () async {
        if (await _confirmAction('$label?', 'Send ${type == 'initial' ? 'initial' : 'follow-up'} emails to all eligible $category recipients?')) {
          vm.sendEmails(category, type);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: vm.sending
                ? Colors.grey.shade400
                : Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmAction(String title, String message) async {
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
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF2A900)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _checkDuplicates(HomeViewModel vm, String category, List<Contributor> contributors) {
    // Group by lowercase email
    final groups = <String, List<Contributor>>{};
    for (final c in contributors) {
      if (c.email.isEmpty) continue;
      final key = c.email.toLowerCase();
      groups.putIfAbsent(key, () => []).add(c);
    }
    final duplicates = groups.entries.where((e) => e.value.length > 1).toList();

    if (duplicates.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          title: Text('No duplicates', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7), letterSpacing: 0.5)),
          content: Text('No duplicate emails found in $category.', style: GoogleFonts.inter(fontSize: 13, color: Colors.black.withValues(alpha: 0.55))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.7))),
            ),
          ],
        ),
      );
      return;
    }

    // Track which contributor to keep per duplicate group
    final selected = <String, Contributor>{};
    for (final entry in duplicates) {
      selected[entry.key] = entry.value.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          title: Text(
            'Duplicate emails found',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7), letterSpacing: 0.5),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select which record to keep for each duplicate email:',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in duplicates) ...[
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    for (final c in entry.value)
                      GestureDetector(
                        onTap: () => setDialogState(() => selected[entry.key] = c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                selected[entry.key] == c ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                size: 16,
                                color: selected[entry.key] == c ? const Color(0xFFF2A900) : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${c.fullName} — ${c.title.isNotEmpty ? c.title : "No title"}, ${c.company.isNotEmpty ? c.company : "No company"}',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                for (final entry in duplicates) {
                  final keep = selected[entry.key]!;
                  for (final c in entry.value) {
                    if (c != keep) {
                      vm.deleteContributor(c);
                    }
                  }
                }
              },
              child: Text('Remove duplicates', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.7))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorsTab() {
    final avm = context.watch<AdvisorViewModel>();
    if (avm.loading) return const Center(child: CircularProgressIndicator());

    final advisors = avm.advisors;
    final isExpanded = _expandedCategories.contains('advisors');
    final showToggle = advisors.length > _collapsedRowCount;
    final visible = showToggle && !isExpanded
        ? advisors.sublist(0, _collapsedRowCount)
        : advisors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advisory Board (${advisors.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => _showStatusManager(avm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Manage Statuses',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
              4: FixedColumnWidth(40),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: <Widget>[
                  ...const ['NAME', 'UNIVERSITY', 'EMAIL', 'STATUS'].map((h) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(h, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 0.5)),
                    );
                  }),
                  const SizedBox.shrink(),
                ],
              ),
              ...visible.map((a) {
                final statusColor = _parseHex(avm.statusTypes[a.status]);
                return TableRow(
                  decoration: statusColor != null
                      ? BoxDecoration(color: statusColor.withValues(alpha: 0.55))
                      : null,
                  children: [
                    _cell(a.fullName),
                    _cell(a.university),
                    _cell(a.email),
                    _advisorStatusCell(a, avm),
                    GestureDetector(
                      onTap: () async {
                        if (await _confirmAction('Delete advisor?', 'Remove ${a.fullName}?')) {
                          avm.deleteAdvisor(a);
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
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
              4: FixedColumnWidth(40),
            },
            children: [
              TableRow(
                children: [
                  Row(
                    children: [
                      Expanded(child: _inputCell(_advFirstNameCtrl, 'First')),
                      Expanded(child: _inputCell(_advLastNameCtrl, 'Last')),
                    ],
                  ),
                  _inputCell(_advUniversityCtrl, 'University'),
                  _inputCell(_advEmailCtrl, 'Email'),
                  const SizedBox.shrink(),
                  GestureDetector(
                    onTap: () => _handleAddAdvisor(avm),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 20, color: Colors.black54),
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
                    _expandedCategories.remove('advisors');
                  } else {
                    _expandedCategories.add('advisors');
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
      ),
    );
  }

  Widget _advisorStatusCell(Advisor a, AdvisorViewModel avm) {
    final statuses = avm.statusTypes.keys.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: PopupMenuButton<String>(
        onSelected: (value) => avm.setStatus(a, value),
        tooltip: 'Set status',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: '',
            child: Text('— None —', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ),
          ...statuses.map((s) {
            final color = _parseHex(avm.statusTypes[s]);
            return PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color ?? Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(s, style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            );
          }),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  a.status.isEmpty ? '—' : a.status,
                  style: GoogleFonts.inter(fontSize: 12, color: a.status.isEmpty ? Colors.grey : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAddAdvisor(AdvisorViewModel avm) {
    final firstName = _advFirstNameCtrl.text.trim();
    final lastName = _advLastNameCtrl.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;

    avm.addAdvisor(Advisor(
      firstName: firstName,
      lastName: lastName,
      university: _advUniversityCtrl.text.trim(),
      email: _advEmailCtrl.text.trim(),
    ));

    _advFirstNameCtrl.clear();
    _advLastNameCtrl.clear();
    _advUniversityCtrl.clear();
    _advEmailCtrl.clear();
  }

  void _showStatusManager(AdvisorViewModel avm) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final types = avm.statusTypes;
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            title: Text(
              'Manage Status Types',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7), letterSpacing: 0.5),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...types.entries.map((e) {
                      final color = _parseHex(e.value) ?? Colors.grey;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showColorPicker(avm, e.key, e.value, setDialogState),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.key,
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (await _confirmAction('Delete status?', 'Remove "${e.key}"? Advisors with this status will be cleared.')) {
                                  await avm.deleteStatusType(e.key);
                                  setDialogState(() {});
                                }
                              },
                              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showAddStatusDialog(avm, setDialogState),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            'Add status type',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.7))),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _presetColors = [
    '#E3F2FD', '#E8F5E9', '#FFF3E0', '#FFF9C4', '#FFCDD2',
    '#E1BEE7', '#B2DFDB', '#F0F4C3', '#FFECB3', '#D1C4E9',
    '#B3E5FC', '#C8E6C9', '#FFE0B2', '#FFCCBC', '#F8BBD0',
  ];

  void _showColorPicker(AdvisorViewModel avm, String name, String currentHex, StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        title: Text('Pick color for "$name"', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7))),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors.map((hex) {
              final color = _parseHex(hex) ?? Colors.grey;
              final isSelected = hex.toUpperCase() == currentHex.toUpperCase();
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  avm.editStatusType(name, name, hex);
                  parentSetState(() {});
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.black54 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddStatusDialog(AdvisorViewModel avm, StateSetter parentSetState) {
    final nameCtrl = TextEditingController();
    String selectedHex = '#E3F2FD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          title: Text('New Status Type', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7))),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Status name...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((hex) {
                    final color = _parseHex(hex) ?? Colors.grey;
                    final isSelected = hex == selectedHex;
                    return GestureDetector(
                      onTap: () => setInnerState(() => selectedHex = hex),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.black54 : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                avm.addStatusType(name, selectedHex);
                parentSetState(() {});
              },
              child: Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.7))),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return null;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
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
