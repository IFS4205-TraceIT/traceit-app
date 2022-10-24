import 'package:flutter/material.dart';
import 'package:traceit_app/contact_upload_manager.dart';
import 'package:traceit_app/utils.dart';

class ContactUploadScreen extends StatefulWidget {
  const ContactUploadScreen({super.key});

  @override
  State<ContactUploadScreen> createState() => _ContactUploadScreenState();
}

class _ContactUploadScreenState extends State<ContactUploadScreen> {
  final ContactUploadManager _contactUploadManager = ContactUploadManager();

  bool _canUpload = false;
  bool _isUploading = false;
  bool _completedUpload = false;

  Future<void> _refreshUploadStatus() async {
    // Get upload status from server
    bool? uploadStatus = await _contactUploadManager.getUploadStatus();
    if (uploadStatus == null) {
      // Error getting upload status
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Error retrieving upload status',
          color: Colors.red,
        );
      }
      return;
    }

    setState(() {
      _canUpload = uploadStatus;
    });

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<void> _uploadCloseContacts() async {
    setState(() {
      _isUploading = true;
    });

    Map<String, dynamic> uploadStatus =
        await _contactUploadManager.uploadCloseContacts();
    bool hasUploaded = uploadStatus['uploaded'];
    String message = uploadStatus['message'];

    setState(() {
      _isUploading = false;
      _completedUpload = hasUploaded;
    });

    if (mounted) {
      Utils.showSnackBar(
        context,
        message,
        color: hasUploaded ? Colors.green : Colors.red,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _refreshUploadStatus();
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
            height: MediaQuery.of(context).size.height - 150,
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
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(
                          width: 300,
                          child: Text(
                            'By uploading your close contact history, you '
                            'consent to the collection and use of the collected'
                            ' data by official contact tracers for contact '
                            'tracing purposes.',
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
