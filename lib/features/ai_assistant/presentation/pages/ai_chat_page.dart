import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/user_provider.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg> _msgs = [
    _Msg("Hello! I'm your MaatriCare AI assistant. How can I help you today?", false),
  ];
  final _tips = ['Best foods for iron?', 'Is this symptom normal?', 'Exercise tips', 'Danger signs'];

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _send(String t) {
    if (t.trim().isEmpty) return;
    setState(() { _msgs.add(_Msg(t, true)); _msgCtrl.clear(); });
    final week = Provider.of<UserProvider>(context, listen: false).pregnancyWeek;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) { setState(() { _msgs.add(_Msg(_reply(t, week), false)); }); _scroll(); }
    });
    _scroll();
  }

  String _reply(String q, int week) {
    if (q.toLowerCase().contains('iron')) return "Iron-rich foods for Week $week:\n\n🥬 Spinach & greens\n🫘 Lentils & chickpeas\n🥩 Lean red meat\n🥜 Pumpkin seeds\n\n💡 Pair with vitamin C!\n\n⚠️ Consult your doctor for personalized advice.";
    if (q.toLowerCase().contains('danger')) return "🚨 Danger signs:\n\n• Severe headache/vision changes\n• Sudden swelling\n• Vaginal bleeding\n• Severe abdominal pain\n• Reduced fetal movement\n\nContact your doctor IMMEDIATELY if you experience these.";
    return "During Week $week, your baby is growing rapidly! I'd recommend discussing this with your healthcare provider.\n\n⚠️ I provide general guidance, not medical diagnoses.";
  }

  void _scroll() { Future.delayed(const Duration(milliseconds: 100), () { if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  @override
  Widget build(BuildContext context) {
    final week = Provider.of<UserProvider>(context).pregnancyWeek;
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(MaatriTheme.spacingMd),
            decoration: BoxDecoration(color: MaatriColors.lavenderLight, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: MaatriColors.lavender.withOpacity( 0.5), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: MaatriColors.lavenderDark, size: 24)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Assistant', style: MaatriTypography.headlineSmall.copyWith(color: MaatriColors.lavenderDark)),
                Text('Week $week · Always here to help', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.lavenderDark)),
              ]),
            ]),
          ),
          // Disclaimer
          Container(
            margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: MaatriColors.goldenLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: MaatriColors.warningDark, size: 16), const SizedBox(width: 6),
              Expanded(child: Text('AI provides general guidance, not medical advice.', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.warningDark))),
            ]),
          ),
          // Messages
          Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: _msgs.length, itemBuilder: (c, i) {
            final m = _msgs[i];
            return Align(
              alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: m.isUser ? MaatriColors.coral : MaatriColors.pureWhite,
                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(m.isUser ? 16 : 4), bottomRight: Radius.circular(m.isUser ? 4 : 16)),
                  border: m.isUser ? null : Border.all(color: MaatriColors.tealLight),
                  boxShadow: MaatriTheme.shadowSm,
                ),
                child: Text(m.text, style: MaatriTypography.bodyMedium.copyWith(color: m.isUser ? Colors.white : MaatriColors.charcoal, height: 1.5)),
              ),
            );
          })),
          // Suggestions
          if (_msgs.length <= 2) SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _tips.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (c, i) => GestureDetector(onTap: () => _send(_tips[i]), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: MaatriColors.pureWhite, borderRadius: BorderRadius.circular(999), border: Border.all(color: MaatriColors.lightGray)), child: Text(_tips[i], style: MaatriTypography.chipText.copyWith(color: MaatriColors.coral)))))),
          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: MaatriColors.pureWhite, boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: SafeArea(top: false, child: Row(children: [
              Expanded(child: TextField(controller: _msgCtrl, style: MaatriTypography.bodyMedium, decoration: InputDecoration(hintText: 'Ask me anything...', filled: true, fillColor: MaatriColors.cloudGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), onSubmitted: _send)),
              const SizedBox(width: 8),
              Container(decoration: BoxDecoration(color: MaatriColors.coral, shape: BoxShape.circle), child: IconButton(onPressed: () => _send(_msgCtrl.text), icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
            ])),
          ),
        ]),
      ),
    );
  }
}

class _Msg { final String text; final bool isUser; _Msg(this.text, this.isUser); }
