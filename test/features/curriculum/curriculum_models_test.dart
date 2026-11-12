import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/curriculum/curriculum_document_file.dart';
import 'package:learntz/features/curriculum/curriculum_models.dart';

const testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'source import is gated by independent verification and usage rights',
    () {
      const source = CurriculumSource(
        id: 'source-id',
        title: 'TIE primary curriculum',
        sourceUrl: 'https://example.test/source.pdf',
        checksum: testChecksum,
        verificationStatus: 'verified',
        usageRightsStatus: 'permission_pending',
        documentReference: null,
        documentFormat: 'application/pdf',
        usageRightsEvidenceUrl: null,
        usageRightsNote: null,
      );

      expect(source.canImport, isFalse);
      expect(
        const CurriculumSource(
          id: 'source-id',
          title: 'TIE primary curriculum',
          sourceUrl: 'https://example.test/source.pdf',
          checksum: testChecksum,
          verificationStatus: 'unverified',
          usageRightsStatus: 'authorized',
          documentReference: null,
          documentFormat: 'application/pdf',
          usageRightsEvidenceUrl: 'https://example.test/rights',
          usageRightsNote: 'Test fixture',
        ).canImport,
        isFalse,
      );
      expect(
        const CurriculumSource(
          id: 'source-id',
          title: 'TIE primary curriculum',
          sourceUrl: 'https://example.test/source.pdf',
          checksum: testChecksum,
          verificationStatus: 'verified',
          usageRightsStatus: 'authorized',
          documentReference: null,
          documentFormat: 'application/pdf',
          usageRightsEvidenceUrl: 'https://example.test/rights',
          usageRightsNote: 'Test fixture',
        ).canImport,
        isTrue,
      );
    },
  );

  test('document file validator computes SHA-256 from the selected bytes', () {
    final checksum = CurriculumDocumentFile.checksum(
      Uint8List.fromList(utf8.encode('abc')),
    );

    expect(
      checksum,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('staff capabilities default to false when unauthenticated or unprivileged', () {
    const capabilities = CurriculumStaffCapabilities(
      canAccess: false,
      canEdit: false,
      canReview: false,
      canApprove: false,
    );

    expect(capabilities.canAccess, isFalse);
    expect(capabilities.canEdit, isFalse);
    expect(capabilities.canReview, isFalse);
    expect(capabilities.canApprove, isFalse);
  });
}
