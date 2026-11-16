import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_config.dart';
import '../theme/app_theme.dart';

class TermsOfServicePage extends StatefulWidget {
  final int initialIndex;

  const TermsOfServicePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _doc3Content;
  String? _doc4Content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadTerms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    try {
      final String fullContent =
          await rootBundle.loadString('assets/legal/terms.md');

      // Markers for consumer legal documents:
      // Document 3: ShopQ Terms of Use
      // Document 4: ShopQ Privacy Policy
      final doc3Start =
          fullContent.indexOf('# DOCUMENT 3 — ShopQ Terms of Use');
      final doc4Start =
          fullContent.indexOf('# DOCUMENT 4 — ShopQ Privacy Policy');
      final appendixStart = fullContent.indexOf('# APPENDIX A —');

      String doc3 = '';
      String doc4 = '';

      if (doc3Start != -1 && doc4Start != -1) {
        doc3 = fullContent.substring(doc3Start, doc4Start).trim();
        if (doc3.endsWith('---')) {
          doc3 = doc3.substring(0, doc3.lastIndexOf('---')).trim();
        }
      } else if (doc3Start != -1) {
        doc3 = fullContent.substring(doc3Start).trim();
      }

      if (doc4Start != -1) {
        if (appendixStart != -1 && appendixStart > doc4Start) {
          doc4 = fullContent.substring(doc4Start, appendixStart).trim();
        } else {
          doc4 = fullContent.substring(doc4Start).trim();
        }
        if (doc4.endsWith('---')) {
          doc4 = doc4.substring(0, doc4.lastIndexOf('---')).trim();
        }
      }

      // Clean up internal draft headers and placeholder labels for production display
      doc3 = doc3
          .replaceAll('# DOCUMENT 3 — ShopQ Terms of Use', '# ShopiQ Terms of Use')
          .replaceAll('[SHOPPER APP NAME]', 'ShopiQ')
          .replaceAll('[DATE]', 'November 2026');

      doc4 = doc4
          .replaceAll('# DOCUMENT 4 — ShopQ Privacy Policy', '# ShopiQ Privacy Policy')
          .replaceAll('[SHOPPER APP NAME]', 'ShopiQ')
          .replaceAll('[DATE]', 'November 2026');

      if (mounted) {
        setState(() {
          _doc3Content = doc3.isNotEmpty ? doc3 : fullContent;
          _doc4Content = doc4.isNotEmpty ? doc4 : fullContent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _doc3Content = 'Failed to load ShopiQ Terms of Use.';
          _doc4Content = 'Failed to load ShopiQ Privacy Policy.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchExternalLegal() async {
    final isPrivacy = _tabController.index == 1;
    final url = isPrivacy ? ApiConfig.privacyPolicyUrl : ApiConfig.termsOfServiceUrl;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // In case device has no web browser installed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tabController.index == 1 ? 'Privacy Policy' : 'Terms of Service',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.externalLink, color: AppTheme.primaryBlue, size: 20),
            tooltip: 'Open in browser',
            onPressed: _launchExternalLegal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.shadowSmall,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Terms of Use'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMarkdownView(_doc3Content ?? ''),
                _buildMarkdownView(_doc4Content ?? ''),
              ],
            ),
    );
  }

  Widget _buildMarkdownView(String markdownData) {
    return Markdown(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      data: markdownData,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.55,
        ),
        h1: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
        h2: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          height: 1.8,
        ),
        h3: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          height: 1.6,
        ),
        strong: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
        listBullet: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
        tableBorder: TableBorder.all(
          color: AppTheme.veryLightGray,
          width: 1,
        ),
        tableHead: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
        tableBody: const TextStyle(
          fontFamily: 'Outfit',
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
        tableCellsPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        blockquoteDecoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppTheme.primaryBlue, width: 4),
          ),
        ),
      ),
    );
  }
}
