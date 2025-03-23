import 'package:flutter/material.dart';
import '../../automaticTransaction/file_upload_screen.dart';

class AutomaticTransactionButton extends StatelessWidget {
  const AutomaticTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 80,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FileUploadScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(height: 8),
              Text('Automatic Transaction'),
            ],
          ),
        ),
      ),
    );
  }
}
