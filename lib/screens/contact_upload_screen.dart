import 'package:flutter/material.dart';

class ContactUploadScreen extends StatefulWidget {
  const ContactUploadScreen({super.key});

  @override
  State<ContactUploadScreen> createState() => _ContactUploadScreenState();
}

class _ContactUploadScreenState extends State<ContactUploadScreen> {
  bool _canUpload = false;
  bool _isUploading = false;
  bool _completedUpload = false;

  Future<void> _refreshUploadStatus() async {
    // TODO: Refresh upload status
    setState(() {
      _canUpload = !_canUpload;
    });

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<void> _uploadCloseContacts() async {
    // TODO: Upload close contacts
    setState(() {
      _isUploading = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    setState(() {
      _isUploading = false;
      _completedUpload = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Close Contact Upload'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUploadStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Visibility(
                    visible: !_canUpload,
                    child: Wrap(
                      direction: Axis.vertical,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 20,
                      children: const [
                        SizedBox(
                          width: 300,
                          child: Text(
                            'Your close contact history is not required at this time.',
                            style: TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 300,
                          child: Text(
                            ' A health official may request your close contact '
                            'history at a later date.',
                            style: TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _canUpload,
                    child: Wrap(
                      direction: Axis.vertical,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        const SizedBox(
                          width: 300,
                          child: Text(
                            'Health officials have requested your close contact'
                            ' history. Please upload your close contacts as '
                            'soon as possible.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isUploading || _completedUpload
                              ? null
                              : _uploadCloseContacts,
                          child: Text(
                            (() {
                              if (_isUploading) {
                                return 'Uploading...';
                              } else if (_completedUpload) {
                                return 'Upload Complete';
                              } else {
                                return 'Upload Close Contacts';
                              }
                            }()),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
