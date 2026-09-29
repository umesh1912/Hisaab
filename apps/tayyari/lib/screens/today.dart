import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/test_setup.dart';
import '../sheets/topic_plan.dart';
import '../ui.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onGo});
  final void Function(int tab) onGo;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final t = tones(context);
    final today = todayIso();
    final due = store.due;
    final plan = store.plan;
    final learn = store.learnTarget;
    final testSec = store.testSection;
    final last = store.lastFull;
    final revMin = due.length * 1.5 < 5 ? 5 : (due.length * 1.5).round();

    Widget doneChip() => Pill('Done', bg: t.goodSoft, fg: t.good, icon: Icons.check);
    Widget startChip() => Pill('Start', bg: cs.primary, fg: cs.onPrimary);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _Countdown(key: const Key('countdown'), examDate: d.profile.examDate, exam: d.profile.exam, minutes: d.minutes),
        SectionTitle("Today's plan", trailing: Text('about 75 min', style: TextStyle(color: cs.onSurfaceVariant))),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('plan-rev'),
                leading: const IconBox(Icons.replay),
                title: Text(
                  plan.rev
                      ? "Today's revision"
                      : (due.isEmpty ? 'No revision due today' : 'Revise ${due.length} question${due.length == 1 ? '' : 's'} due today'),
                  style: plan.rev ? TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant) : null,
                ),
                subtitle: Text(plan.rev
                    ? (due.isEmpty ? 'Done. Mistakes come back tomorrow' : 'Done. ${due.length} more due')
                    : (due.isEmpty ? 'All caught up' : '~$revMin min · before you forget them')),
                trailing: plan.rev ? doneChip() : (due.isEmpty ? null : startChip()),
                onTap: () {
                  if (due.isEmpty) {
                    toast(context, 'Nothing due. Come back tomorrow.');
                    return;
                  }
                  store.startSession(due, 'due', 'Revision');
                  onGo(1);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                key: const Key('plan-learn'),
                leading: const IconBox(Icons.add),
                title: Text(
                  'Learn: ${learn.topic} (${sectionShort[learn.sec]})',
                  style: plan.learn ? TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant) : null,
                ),
                subtitle: Text(learn.started ? '~30 min · weakest topic at ${learn.percent}%' : '~30 min · not practised yet'),
                trailing: plan.learn ? doneChip() : null,
                onTap: () => showLearnSheet(context, learn.sec, learn.topic, onGo),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                key: const Key('plan-test'),
                leading: const IconBox(Icons.timer_outlined),
                title: Text(
                  'Sectional test: ${sectionShort[testSec]}, $questionsPerSection questions',
                  style: plan.test ? TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant) : null,
                ),
                subtitle: const Text('~35 min · timed, with negative marking'),
                trailing: plan.test ? doneChip() : null,
                onTap: () => showTestSetup(context, sec: testSec),
              ),
            ],
          ),
        ),
        if (last != null && last.wrong > 0)
          InfoNote(
            child: Text(
              'Your last mock lost ${fmtMarks(last.negative)} marks to wrong answers, and ${last.confidentWrong} of those '
              '${last.wrong} were questions you felt sure about. Practice asks how sure you are, to catch these gaps.',
            ),
          ),
        if (store.confidentMissCount > 0)
          InfoNote(
            icon: Icons.priority_high,
            color: t.badSoft,
            child: Text(
              '${store.confidentMissCount} confident mistake${store.confidentMissCount == 1 ? '' : 's'} in your revision. '
              'These were answered wrong while you felt certain, so they come back first.',
            ),
          ),
        const SectionTitle('Revision coming up', trailing: Text('questions due')),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: _DueChart(counts: store.dueWeek, today: today),
          ),
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({super.key, required this.examDate, required this.exam, required this.minutes});
  final String examDate;
  final String exam;
  final Map<String, int> minutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final left = daysBetween(today, examDate);
    final st = streak(minutes, today);
    final last14 = [for (var i = 13; i >= 0; i--) minutes[addDaysIso(today, -i)] ?? 0];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Column(
              children: [
                FittedBox(
                  child: Text(
                    '${left < 0 ? 0 : left}',
                    style: TextStyle(color: cs.onPrimary, fontSize: 44, fontWeight: FontWeight.w800, height: 1),
                  ),
                ),
                const SizedBox(height: 2),
                Text('DAYS LEFT',
                    style: TextStyle(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$exam · ${longDate(examDate)}',
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  left < 0 ? 'Exam date has passed. Update it in Profile.' : 'Your target date. $st-day study streak.',
                  style: TextStyle(color: cs.onPrimary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final m in last14)
                      Expanded(
                        child: Container(
                          height: 12,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: m > 0 ? accentYellow : Color.lerp(cs.primary, cs.onPrimary, 0.22)!,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueChart extends StatelessWidget {
  const _DueChart({required this.counts, required this.today});
  final List<int> counts;
  final String today;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mx = counts.fold<int>(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 124,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < counts.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${counts[i]}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: counts[i] == 0 ? 4 : 4 + counts[i] / mx * 66,
                    decoration: BoxDecoration(
                      color: i == 0 ? cs.primary : cs.primaryContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(i == 0 ? 'Today' : dayName(addDaysIso(today, i)),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.clip),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
