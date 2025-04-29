import 'package:equatable/equatable.dart';

class Localization extends Equatable {
  const Localization({
    this.en,
    this.de,
    this.es,
    this.fr,
    this.it,
    this.pl,
    this.ro,
    this.hu,
    this.nl,
    this.pt,
    this.sv,
    this.vi,
    this.tr,
    this.ru,
    this.ja,
    this.zh,
    this.zhTw,
    this.ko,
    this.ar,
    this.th,
    this.id,
    this.cs,
    this.da,
    this.el,
    this.hi,
    this.no,
    this.sk,
    this.uk,
    this.he,
    this.fi,
    this.bg,
    this.hr,
    this.lt,
    this.sl,
  });

  factory Localization.fromJson(Map<String, dynamic> json) => Localization(
        en: json['en'] as String?,
        de: json['de'] as String?,
        es: json['es'] as String?,
        fr: json['fr'] as String?,
        it: json['it'] as String?,
        pl: json['pl'] as String?,
        ro: json['ro'] as String?,
        hu: json['hu'] as String?,
        nl: json['nl'] as String?,
        pt: json['pt'] as String?,
        sv: json['sv'] as String?,
        vi: json['vi'] as String?,
        tr: json['tr'] as String?,
        ru: json['ru'] as String?,
        ja: json['ja'] as String?,
        zh: json['zh'] as String?,
        zhTw: json['zh-tw'] as String?,
        ko: json['ko'] as String?,
        ar: json['ar'] as String?,
        th: json['th'] as String?,
        id: json['id'] as String?,
        cs: json['cs'] as String?,
        da: json['da'] as String?,
        el: json['el'] as String?,
        hi: json['hi'] as String?,
        no: json['no'] as String?,
        sk: json['sk'] as String?,
        uk: json['uk'] as String?,
        he: json['he'] as String?,
        fi: json['fi'] as String?,
        bg: json['bg'] as String?,
        hr: json['hr'] as String?,
        lt: json['lt'] as String?,
        sl: json['sl'] as String?,
      );
  final String? en;
  final String? de;
  final String? es;
  final String? fr;
  final String? it;
  final String? pl;
  final String? ro;
  final String? hu;
  final String? nl;
  final String? pt;
  final String? sv;
  final String? vi;
  final String? tr;
  final String? ru;
  final String? ja;
  final String? zh;
  final String? zhTw;
  final String? ko;
  final String? ar;
  final String? th;
  final String? id;
  final String? cs;
  final String? da;
  final String? el;
  final String? hi;
  final String? no;
  final String? sk;
  final String? uk;
  final String? he;
  final String? fi;
  final String? bg;
  final String? hr;
  final String? lt;
  final String? sl;

  Map<String, dynamic> toJson() => {
        'en': en,
        'de': de,
        'es': es,
        'fr': fr,
        'it': it,
        'pl': pl,
        'ro': ro,
        'hu': hu,
        'nl': nl,
        'pt': pt,
        'sv': sv,
        'vi': vi,
        'tr': tr,
        'ru': ru,
        'ja': ja,
        'zh': zh,
        'zh-tw': zhTw,
        'ko': ko,
        'ar': ar,
        'th': th,
        'id': id,
        'cs': cs,
        'da': da,
        'el': el,
        'hi': hi,
        'no': no,
        'sk': sk,
        'uk': uk,
        'he': he,
        'fi': fi,
        'bg': bg,
        'hr': hr,
        'lt': lt,
        'sl': sl,
      };

  Localization copyWith({
    String? en,
    String? de,
    String? es,
    String? fr,
    String? it,
    String? pl,
    String? ro,
    String? hu,
    String? nl,
    String? pt,
    String? sv,
    String? vi,
    String? tr,
    String? ru,
    String? ja,
    String? zh,
    String? zhTw,
    String? ko,
    String? ar,
    String? th,
    String? id,
    String? cs,
    String? da,
    String? el,
    String? hi,
    String? no,
    String? sk,
    String? uk,
    String? he,
    String? fi,
    String? bg,
    String? hr,
    String? lt,
    String? sl,
  }) {
    return Localization(
      en: en ?? this.en,
      de: de ?? this.de,
      es: es ?? this.es,
      fr: fr ?? this.fr,
      it: it ?? this.it,
      pl: pl ?? this.pl,
      ro: ro ?? this.ro,
      hu: hu ?? this.hu,
      nl: nl ?? this.nl,
      pt: pt ?? this.pt,
      sv: sv ?? this.sv,
      vi: vi ?? this.vi,
      tr: tr ?? this.tr,
      ru: ru ?? this.ru,
      ja: ja ?? this.ja,
      zh: zh ?? this.zh,
      zhTw: zhTw ?? this.zhTw,
      ko: ko ?? this.ko,
      ar: ar ?? this.ar,
      th: th ?? this.th,
      id: id ?? this.id,
      cs: cs ?? this.cs,
      da: da ?? this.da,
      el: el ?? this.el,
      hi: hi ?? this.hi,
      no: no ?? this.no,
      sk: sk ?? this.sk,
      uk: uk ?? this.uk,
      he: he ?? this.he,
      fi: fi ?? this.fi,
      bg: bg ?? this.bg,
      hr: hr ?? this.hr,
      lt: lt ?? this.lt,
      sl: sl ?? this.sl,
    );
  }

  @override
  List<Object?> get props {
    return [
      en,
      de,
      es,
      fr,
      it,
      pl,
      ro,
      hu,
      nl,
      pt,
      sv,
      vi,
      tr,
      ru,
      ja,
      zh,
      zhTw,
      ko,
      ar,
      th,
      id,
      cs,
      da,
      el,
      hi,
      no,
      sk,
      uk,
      he,
      fi,
      bg,
      hr,
      lt,
      sl,
    ];
  }
}
