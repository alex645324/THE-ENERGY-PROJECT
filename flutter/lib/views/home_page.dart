import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _tabLabels = ['CONTRIBUTORS', 'ADVISORS', 'PROGRESS'];

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
            if (vm.selectedTab == 0) ...[
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      children: vm.contributorHeaders
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
                    ...vm.contributorRows.map((row) => TableRow(
                          children: row
                              .map((cell) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    child: Text(
                                      cell,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
