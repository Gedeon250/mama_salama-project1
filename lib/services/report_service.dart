import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_models.dart';
import '../theme/app_theme.dart';

PdfColor _pdfColor(Color c) => PdfColor.fromInt(c.toARGB32());

/// Generates the two PRD "Reports" PDFs — a mother's medical summary, and a
/// CHW-authored referral letter. Both open the platform share/print sheet
/// via the `printing` package rather than writing a file directly, so the
/// caller doesn't need storage permissions.
class ReportService {
  static final _primary = _pdfColor(AppBrandColors.primary);
  static final _secondary = _pdfColor(AppBrandColors.secondary);
  static final _outline = _pdfColor(AppBrandColors.outlineVariant);

  static pw.Widget _brandHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MamaSalama', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primary)),
            pw.Text(intl.DateFormat('MMM d, yyyy').format(DateTime.now()), style: pw.TextStyle(color: _secondary, fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Divider(color: _outline, thickness: 1),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _patientInfoBlock({
    required AppUser mother,
    required PregnancyProfile profile,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _outline), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Patient Information', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 6),
          _kv('Name', mother.name),
          _kv('Phone', mother.phone ?? '—'),
          _kv('Pregnancy Week', '${profile.pregnancyWeek}'),
          _kv('Trimester', '${profile.trimester}'),
          _kv('Estimated Due Date', intl.DateFormat('MMM d, yyyy').format(profile.dueDate)),
          _kv('Blood Type', profile.bloodType),
          _kv('Allergies', profile.allergies.isEmpty ? 'None' : profile.allergies.join(', ')),
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label, style: pw.TextStyle(color: _secondary, fontSize: 11))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  static Future<void> generateMedicalSummaryPdf({
    required AppUser mother,
    required PregnancyProfile profile,
    required List<MedicalRecord> records,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          _brandHeader('Medical Summary'),
          _patientInfoBlock(mother: mother, profile: profile),
          pw.SizedBox(height: 16),
          pw.Text('Visit History', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 6),
          if (records.isEmpty)
            pw.Text('No recorded visits yet.', style: pw.TextStyle(color: _secondary, fontSize: 11))
          else
            pw.Table(
              border: pw.TableBorder.all(color: _outline, width: 0.5),
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(4)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
                  children: [
                    _cell('Date', bold: true),
                    _cell('Category', bold: true),
                    _cell('Summary', bold: true),
                  ],
                ),
                ...records.map((r) => pw.TableRow(children: [
                      _cell(intl.DateFormat('MMM d, yyyy').format(r.date)),
                      _cell(r.category),
                      _cell(r.summary),
                    ])),
              ],
            ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'MamaSalama_Medical_Summary_${mother.name.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateReferralLetterPdf({
    required AppUser mother,
    required PregnancyProfile profile,
    required AppUser referringChw,
    required String hospitalName,
    required String reason,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _brandHeader('Referral Letter'),
            pw.Text('To: $hospitalName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            _patientInfoBlock(mother: mother, profile: profile),
            pw.SizedBox(height: 16),
            pw.Text('Reason for Referral', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primary)),
            pw.SizedBox(height: 6),
            pw.Text(reason, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 24),
            pw.Text('Referred by', style: pw.TextStyle(color: _secondary, fontSize: 10)),
            pw.Text(referringChw.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(referringChw.phone ?? referringChw.email, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'MamaSalama_Referral_${mother.name.replaceAll(' ', '_')}.pdf');
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
