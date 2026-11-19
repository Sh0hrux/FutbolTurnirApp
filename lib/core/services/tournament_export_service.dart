import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/schedule/domain/entities/match_entity.dart';
import '../../features/standings/domain/entities/standing_row_entity.dart';
import '../../features/teams/domain/entities/team_entity.dart';

class TournamentExportService {
  /// Exports tournament standings table to a professional PDF document
  static Future<void> exportStandingsToPdf({
    required String tournamentName,
    required List<StandingRowEntity> standings,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        tournamentName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 22,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rasmiy turnir jadvali',
                        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 16),
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.green700),
              pw.SizedBox(height: 16),

              // Standings Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green800,
                ),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {
                  1: pw.Alignment.centerLeft, // Team name
                },
                headers: [
                  'Pl',
                  'Team',
                  'G',
                  'Goals',
                  '+/-',
                  'Pts',
                ],
                data: standings.map((row) {
                  return [
                    '${row.pos}.',
                    row.teamName,
                    '${row.played}',
                    '${row.goalsFor}:${row.goalsAgainst}',
                    '${row.goalDifference > 0 ? "+" : ""}${row.goalDifference}',
                    '${row.points}',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'Pl - O‘rin, Team - Jamoa, G - O‘yinlar, Goals - Gollar (Urilgan:O‘tkazilgan), +/- - To‘plar farqi, Pts - Ochkolar.',
                style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Turnir Pro ilovasi orqali yaratildi',
                  style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '$tournamentName - Jadval.pdf',
    );
  }

  /// Captures widget image and shares it
  static Future<void> exportAndShareImage({
    required ScreenshotController screenshotController,
    required String tournamentName,
  }) async {
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/turnir_jadvali.png');
    await file.writeAsBytes(imageBytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$tournamentName — Turnir jadvali',
      ),
    );
  }

  /// Shares a match score or schedule entry
  static Future<void> shareMatchResult({
    required MatchEntity match,
    required TeamEntity homeTeam,
    required TeamEntity awayTeam,
    required String tournamentName,
  }) async {
    final String scoreText;
    if (match.status == MatchStatus.finished) {
      scoreText = '${homeTeam.name} ${match.homeScore ?? 0} : ${match.awayScore ?? 0} ${awayTeam.name}';
    } else {
      scoreText = '${homeTeam.name} VS ${awayTeam.name} (${match.timeSlot})';
    }

    final message = '''
⚽ $tournamentName • ${match.round}-tur
$scoreText
Holat: ${match.status == MatchStatus.finished ? "Tugallangan" : (match.status == MatchStatus.live ? "Jonli" : "Kutilayotgan")}
Vaqt: ${match.timeSlot}
''';

    await SharePlus.instance.share(
      ShareParams(text: message.trim()),
    );
  }

  /// Shares standings in plain text format
  static Future<void> shareStandingsText({
    required String tournamentName,
    required List<StandingRowEntity> standings,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🏆 $tournamentName — Turnir Jadvali\n');
    buffer.writeln('Pl | Team | G | Goals | +/- | Pts');
    buffer.writeln('---------------------------------------');

    for (final row in standings) {
      final gdStr = row.goalDifference > 0 ? '+${row.goalDifference}' : '${row.goalDifference}';
      buffer.writeln(
        '${row.pos}. ${row.teamName} | ${row.played} | ${row.goalsFor}:${row.goalsAgainst} | $gdStr | ${row.points}',
      );
    }

    await SharePlus.instance.share(
      ShareParams(text: buffer.toString()),
    );
  }
}
