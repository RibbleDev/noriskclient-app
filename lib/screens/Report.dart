import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:http/http.dart' as http;
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/ReportTypes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/widgets/NoRiskButton.dart';
import 'package:mcreal/widgets/NoRiskCheckbox.dart';

class Report extends StatefulWidget {
  const Report(
      {super.key,
      required this.type,
      required this.contentId,
      required this.userData});

  final ReportType type;
  final String contentId;
  final Map<String, dynamic> userData;

  @override
  State<Report> createState() => ProfileState();
}

class ProfileState extends State<Report> {
  // OBSCENITY,
  // HATE_SPEECH,
  // COPYRIGHT_INFRINGEMENT,
  // PRIVACY_VIOLATION,
  // SPAM_OR_FRAUD,
  // INAPPROPRIATE_FOR_MINORS,
  // OTHER
  bool obscenity = false;
  bool hateSpeech = false;
  bool copyrightInfringement = false;
  bool privacyViolation = false;
  bool spamOrFraud = false;
  bool inappropriateForMinors = false;
  bool other = false;

  final TextEditingController infoController = TextEditingController();
  final FocusNode infoFocus = FocusNode();
  bool hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: McRealColors.background,
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    widget.type == ReportType.POST
                        ? AppLocalizations.of(context)!.mcRealReport_title_post
                        : AppLocalizations.of(context)!
                            .mcRealReport_title_comment,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.mcRealReport_whatHappened,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 40),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          obscenity = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_obscenity),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          hateSpeech = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_hateSpeach),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          copyrightInfringement = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_copyrightInfringement),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          privacyViolation = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_privacyViolation),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          spamOrFraud = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_spamOrFraud),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          inappropriateForMinors = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_inappropriateForMinors),
                const SizedBox(height: 10),
                NoRiskCheckbox(
                    onChanged: (value) => setState(() {
                          other = value;
                        }),
                    name: AppLocalizations.of(context)!
                        .mcRealReport_reason_other),
                const SizedBox(height: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.5),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2)),
                      fillColor: McRealColors.darkerBackground,
                      // hintText: ,
                      labelText:
                          AppLocalizations.of(context)!.mcRealReport_info_hint,
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.5),
                          gapPadding: 3.5,
                          borderSide: const BorderSide(
                              color: McRealColors.light, width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.5),
                          gapPadding: 3.5,
                          borderSide: const BorderSide(
                              color: McRealColors.light, width: 2)),
                      filled: true,
                      isDense: true,
                    ),
                    enabled: true,
                    maxLines: 3,
                    controller: infoController,
                    focusNode: infoFocus,
                    keyboardType: TextInputType.text,
                    maxLength: 200,
                    cursorHeight: 12.5,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    autofocus: false,
                    canRequestFocus: true,
                    scrollPadding: const EdgeInsets.all(0),
                    onSubmitted: (value) => infoFocus.unfocus(),
                    onTapOutside: (event) => infoFocus.unfocus(),
                  ),
                ),
                const SizedBox(height: 20),
                NoRiskButton(
                    onTap: report,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
                    child: Text(
                        AppLocalizations.of(context)!.mcRealReport_report,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)))
              ],
            )));
  }

  Future<void> report() async {
    String reasons = '';
    if (obscenity) reasons += '&reasons=OBSCENITY';
    if (hateSpeech) reasons += '&reasons=HATE_SPEECH';
    if (copyrightInfringement) {
      reasons += '&reasons=COPYRIGHT_INFRINGEMENT';
    }
    if (privacyViolation) reasons += '&reasons=PRIVACY_VIOLATION';
    if (spamOrFraud) reasons += '&reasons=SPAM_OR_FRAUD';
    if (inappropriateForMinors) {
      reasons += '&reasons=INAPPROPRIATE_FOR_MINORS';
    }
    if (other) reasons += '&reasons=OTHER';

    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/${widget.type == ReportType.COMMENT ? 'comment' : 'post'}/${widget.contentId}/report?uuid=${widget.userData['uuid']}$reasons&info=${infoController.text}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    Navigator.of(context).pop();
  }
}
