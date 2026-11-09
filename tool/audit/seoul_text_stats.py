"""Seoul Case 02-12 displayed English text: per-case, per-level statistics + text dump.

Source of displayed lines: content_pipeline/seasons/s5_seoul/cases/s5_epNN/levels.json
(`lines[]` = every player-visible Rookie line with its Junior/Master version; the
plan's base text is Rookie). Each unique line is classified by the first plan path
where it appears (case.plan.json), ignoring learning.* / clueInputs.* (not shown).

Word = [A-Za-z]+ with inner ' or - (numbers, Hangul excluded).
Sentence = split on . ! ? (followed by space, quote, or end) and on newlines;
fragments without a word are dropped.  Each unique line counted once per case.
"""
import json, re, sys, collections, statistics
from wordfreq import zipf_frequency

ROOT = sys.argv[1]
OUT = sys.argv[2]
LEVELS = ('rookie', 'junior', 'master')

STORY = ('story', 'intro', 'transition', 'synopsis', 'caseSummary', 'hook', 'ending.text', 'letter',
         'talk.before.lines.text', 'talk.after.lines.text', 'interview.opening.text',
         'interview.questions.lines.text', 'interview.presents.lines.text', 'interview.presents.tell',
         'witnesses.answers', 'witnesses.greeting', 'discovery.detail', 'search.arrival')
CATS = [
    ('hint', ('hints',)),
    ('feedback', ('feedback', 'orderFeedback', 'missLine', '.miss', 'retryLine', 'offTopicLine',
                  'lockedLine', 'unreadLine', 'notPlaceLine', 'differentLine', 'anotherLine')),
    ('success', ('successMessage', 'doneLine', 'foundLine', 'matchLine', 'readyLine', 'checkLine')),
    ('instruction', ('question', 'task', 'Task', 'prompt', 'goal', 'Goal', 'guide', 'Guide', 'how', 'How',
                     'startLabel', 'objectives', 'finishLabel', 'askLine', 'notesLine', 'checkLabel')),
    ('option', ('options.label', 'options.altText', 'cards.', 'finds.name', 'spots.label', 'spots.title',
                'choices.description', 'others.label', 'witnesses.name', 'witnesses.title',
                'witnesses.description', 'records.', 'clues.label', 'questions.text', 'choiceTitle')),
]


def category(path):
    if any(path.endswith(s) or ('.' + s) in path or path.startswith(s) for s in STORY):
        return 'story'
    for name, keys in CATS:
        if any(k in path for k in keys):
            return name
    if any(k in path for k in ('.line', 'reportLine', 'relations', 'blocks.line', 'inscription', 'clue.note',
                               'evidence.description')):
        return 'clue_text'
    return 'label'


WORD = re.compile(r"[A-Za-z]+(?:['’\-][A-Za-z]+)*")
SENT = re.compile(r'(?<=[.!?])["”’)]*\s+|\n')


def sentences(text):
    out = []
    for s in SENT.split(text):
        w = WORD.findall(s)
        if w:
            out.append((s.strip(), w))
    return out


def walk(o, path, acc):
    if isinstance(o, dict):
        for k, v in o.items():
            walk(v, path + [k], acc)
    elif isinstance(o, list):
        for v in o:
            walk(v, path, acc)
    elif isinstance(o, str):
        acc.append(('.'.join(path), o))


def load(n):
    d = f'{ROOT}/content_pipeline/seasons/s5_seoul/cases/s5_ep{n:02d}/'
    plan = json.load(open(d + 'case.plan.json'))
    lv = json.load(open(d + 'levels.json'))
    trip = {x['rookie']: x for x in lv['lines']}
    acc = []
    walk(plan, [], acc)
    seen, rows = set(), []
    for path, s in acc:
        if s not in trip or s in seen or path.split('.')[-2:-1] == ['learning'] or 'learning.' in path \
                or 'clueInputs' in path or path.endswith('.notes'):
            continue
        seen.add(s)
        m = re.match(r'(missions|final)', path)
        rows.append({'path': path, 'cat': category(path), **trip[s]})
    # mission tagging: walk again per mission
    mission_of = {}
    for i, mi in enumerate(plan['missions'] + [plan['final']]):
        a = []
        walk(mi, [], a)
        for _, s in a:
            mission_of.setdefault(s, mi['slot'])
    for r in rows:
        r['slot'] = mission_of.get(r['rookie'], 'case')
    gl = plan.get('play', {}).get('glossary', {})
    return plan, rows, gl, lv.get('glossary', {})


def stats(texts):
    sents = [s for t in texts for s in sentences(t)]
    words = [w for _, ws in sents for w in ws]
    lens = [len(ws) for _, ws in sents]
    longest = max(sents, key=lambda x: len(x[1])) if sents else ('', [])
    return {
        'words': len(words), 'sentences': len(sents),
        'avg_sent': round(statistics.mean(lens), 1) if lens else 0,
        'longest_len': len(longest[1]), 'longest': longest[0],
        'gt15': sum(1 for x in lens if x > 15), 'gt20': sum(1 for x in lens if x > 20),
        'unique': len({w.lower() for w in words}),
        'avg_wlen': round(statistics.mean(len(w) for w in words), 2) if words else 0,
        '_words': words,
    }


def proper_nouns(all_words):
    caps = collections.Counter(); low = collections.Counter()
    for w in all_words:
        (caps if w[0].isupper() else low)[w.lower()] += 1
    return {w for w in caps if low[w] == 0}


def main():
    report = {}
    dump = []
    for n in range(2, 13):
        plan, rows, gl, lgl = load(n)
        cs = {}
        all_case_words = [w for r in rows for lv in LEVELS for _, ws in sentences(r[lv]) for w in ws]
        pn = proper_nouns(all_case_words)
        for lv in LEVELS:
            s_all = stats([r[lv] for r in rows])
            s_story = stats([r[lv] for r in rows if r['cat'] == 'story'])
            rare = collections.Counter(w.lower() for w in s_all['_words']
                                       if w.lower() not in pn and zipf_frequency(w.lower(), 'en') < 3.2
                                       and not re.search(r'[’\']', w))
            for s in (s_all, s_story):
                s.pop('_words')
            cs[lv] = {'all': s_all, 'story': s_story, 'rare': rare.most_common(40)}
        same3 = sum(1 for r in rows if r['rookie'] == r['junior'] == r['master'])
        rj = sum(1 for r in rows if r['rookie'] == r['junior'])
        jm = sum(1 for r in rows if r['junior'] == r['master'])
        cat_counts = collections.Counter(r['cat'] for r in rows)
        per_cat_same = {c: f"{sum(1 for r in rows if r['cat']==c and r['rookie']==r['junior']==r['master'])}/{k}"
                        for c, k in cat_counts.items()}
        cs['lines'] = len(rows)
        cs['same3'] = same3; cs['same_rj'] = rj; cs['same_jm'] = jm
        cs['same_by_cat'] = per_cat_same
        cs['glossary_base'] = gl; cs['glossary_levels'] = lgl
        cs['title'] = plan['title']
        report[n] = cs
        # dump
        dump.append(f'\n\n# CASE {n:02d} — {plan["title"]}\n')
        cur = None
        for r in rows:
            if r['slot'] != cur:
                cur = r['slot']; dump.append(f'\n## [{cur}]\n')
            same = r['rookie'] == r['junior'] == r['master']
            dump.append(f"- ({r['cat']}) {r['path']}\n  R: {r['rookie']!r}")
            if not same:
                dump.append(f"  J: {r['junior']!r}\n  M: {r['master']!r}")
    json.dump(report, open(f'{OUT}/seoul_stats.json', 'w'), ensure_ascii=False, indent=1)
    open(f'{OUT}/seoul_text_dump.md', 'w').write('\n'.join(dump))
    # summary table
    lines = ['| Case | Level | 줄 | 단어 | 문장 | 평균 문장 | 최장 | >15 | >20 | 고유어 | 평균 단어길이 | 스토리 단어 | 스토리 평균 | 스토리 최장 |',
             '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for n, cs in report.items():
        for lv in LEVELS:
            a, s = cs[lv]['all'], cs[lv]['story']
            lines.append(f"| {n:02d} | {lv[0].upper()} | {cs['lines']} | {a['words']} | {a['sentences']} | {a['avg_sent']} | {a['longest_len']} | {a['gt15']} | {a['gt20']} | {a['unique']} | {a['avg_wlen']} | {s['words']} | {s['avg_sent']} | {s['longest_len']} |")
    lines += ['', '| Case | 표시 줄 | R=J=M 동일 | R=J | J=M | 범주별 동일(동일/전체) |', '|---|---|---|---|---|---|']
    for n, cs in report.items():
        L = cs['lines']
        lines.append(f"| {n:02d} | {L} | {cs['same3']} ({cs['same3']*100//L}%) | {cs['same_rj']} ({cs['same_rj']*100//L}%) | {cs['same_jm']} ({cs['same_jm']*100//L}%) | {cs['same_by_cat']} |")
    lines += ['', '## 최장 문장']
    for n, cs in report.items():
        for lv in LEVELS:
            lines.append(f"- C{n:02d} {lv[0].upper()} ({cs[lv]['all']['longest_len']}어): {cs[lv]['all']['longest']}")
    lines += ['', '## 희귀어(wordfreq Zipf<3.2, 고유명사 제외) 상위']
    for n, cs in report.items():
        for lv in LEVELS:
            lines.append(f"- C{n:02d} {lv[0].upper()}: " + ', '.join(f'{w}×{c}' for w, c in cs[lv]['rare'][:25]))
    open(f'{OUT}/seoul_stats.md', 'w').write('\n'.join(lines))
    print('\n'.join(lines[:40]))


main()
