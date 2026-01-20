import 'package:flutter/services.dart';


Future<String> getFolders() async {

  const pdfPickerChannel = MethodChannel("pdfPickerPlatform");
  final String result = await pdfPickerChannel.invokeMethod('pickPdf');
  print(result);
  return result;

}