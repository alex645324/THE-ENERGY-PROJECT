import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/contributor.dart';
import '../view_models/home_view_model.dart';
import 'body_editor.dart' if (dart.library.html) 'body_editor_web.dart';

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
  final Map<String, TextEditingController> _initialSubjectCtrls = {};
  final Map<String, GlobalKey<BodyEditorState>> _initialBodyKeys = {};
  final Map<String, TextEditingController> _initialFooterCtrls = {};
  final Map<String, TextEditingController> _followUpSubjectCtrls = {};
  final Map<String, GlobalKey<BodyEditorState>> _followUpBodyKeys = {};
  final Map<String, TextEditingController> _followUpFooterCtrls = {};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    for (final c in _initialSubjectCtrls.values) { c.dispose(); }
    for (final c in _initialFooterCtrls.values) { c.dispose(); }
    for (final c in _followUpSubjectCtrls.values) { c.dispose(); }
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
                  _cell(c.status.isEmpty ? '—' : c.status),
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
    const defaultFooter = 'Alex Pozo\nChief of Staff\nThe Electrification Index';
    _initialSubjectCtrls.putIfAbsent(category, () => TextEditingController());
    _initialBodyKeys.putIfAbsent(category, () => GlobalKey<BodyEditorState>());
    _initialFooterCtrls.putIfAbsent(category, () => TextEditingController(text: defaultFooter));
    _followUpSubjectCtrls.putIfAbsent(category, () => TextEditingController());
    _followUpBodyKeys.putIfAbsent(category, () => GlobalKey<BodyEditorState>());
    _followUpFooterCtrls.putIfAbsent(category, () => TextEditingController(text: defaultFooter));
    if (!_templatesSynced.contains(category)) {
      final hasInitial = vm.initialSubject(category).isNotEmpty || vm.initialBody(category).isNotEmpty;
      final hasFollowUp = vm.followUpSubject(category).isNotEmpty || vm.followUpBody(category).isNotEmpty;
      if (hasInitial || hasFollowUp) {
        _initialSubjectCtrls[category]!.text = vm.initialSubject(category);
        if (vm.initialFooter(category).isNotEmpty) {
          _initialFooterCtrls[category]!.text = vm.initialFooter(category);
        }
        _followUpSubjectCtrls[category]!.text = vm.followUpSubject(category);
        if (vm.followUpFooter(category).isNotEmpty) {
          _followUpFooterCtrls[category]!.text = vm.followUpFooter(category);
        }
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
            if (vm.sendResult.isNotEmpty && !vm.sending) ...[
              const SizedBox(width: 12),
              Text(
                vm.sendResult,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
        _buildSendDashboard(vm),
        const SizedBox(height: 12),
      ],
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
                  _templateField(footerCtrl, 'Signature...', maxLines: 3),
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
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sent ${vm.overallSent} / ${vm.overallTotal}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: vm.overallTotal > 0
                    ? vm.overallSent / vm.overallTotal
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF2A900)),
              ),
            ),
            const SizedBox(height: 12),
            ...vm.accountStatuses.map((a) => _buildAccountRow(a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> account) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              countdown,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            '$sent/$total',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendButton(HomeViewModel vm, String category, String label, String type) {
    return GestureDetector(
      onTap: vm.sending ? null : () => vm.sendEmails(category, type),
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
