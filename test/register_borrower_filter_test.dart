import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/register/register.dart';
import 'package:key_record/services/key_repository.dart' as repository;

void main() {
  test('staff category keeps a saved staff record visible even without a staff-from value', () {
    final borrower = repository.Borrower(
      name: 'Aiman',
      icPassport: '',
      phone: '0123456789',
      company: 'ABC',
      department: 'Ops',
      staffFrom: '',
    );

    expect(
      borrowerMatchesCategory(
        borrower: borrower,
        borrowerCategory: 'Staff',
      ),
      isTrue,
    );
  });

  test('others category still filters out staff-like records', () {
    final borrower = repository.Borrower(
      name: 'Aiman',
      icPassport: '',
      phone: '0123456789',
      company: 'ABC',
      department: 'Ops',
      staffFrom: '',
    );

    expect(
      borrowerMatchesCategory(
        borrower: borrower,
        borrowerCategory: 'Others',
      ),
      isFalse,
    );
  });
}
