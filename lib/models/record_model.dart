class Record {
  final int? id;
  final String uniqueId;
  final String type; // Complaint or Request
  final String recdDate;
  final String requestorName;
  final String requestorLocation;
  final String subject;
  final List<String> incomingImages;
  final List<String> responseImages;
  final String forwardedDept;
  final String forwardedPerson;
  final String expectedClosureDate;
  final String responseSentDate;
  final String actualClosureDate;
  final String status;
  final String remarks;
  final String followupDate;

  Record({
    this.id,
    required this.uniqueId,
    required this.type,
    required this.recdDate,
    required this.requestorName,
    required this.requestorLocation,
    required this.subject,
    required this.incomingImages,
    required this.responseImages,
    required this.forwardedDept,
    required this.forwardedPerson,
    required this.expectedClosureDate,
    required this.responseSentDate,
    required this.actualClosureDate,
    required this.status,
    required this.remarks,
    required this.followupDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'type': type,
      'recd_date': recdDate,
      'requestor_name': requestorName,
      'requestor_location': requestorLocation,
      'subject': subject,
      'incoming_images': incomingImages.join(';'),
      'response_images': responseImages.join(';'),
      'forwarded_dept': forwardedDept,
      'forwarded_person': forwardedPerson,
      'expected_closure_date': expectedClosureDate,
      'response_sent_date': responseSentDate,
      'actual_closure_date': actualClosureDate,
      'status': status,
      'remarks': remarks,
      'followup_date': followupDate,
    };
  }

  static Record fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      uniqueId: map['unique_id'],
      type: map['type'],
      recdDate: map['recd_date'],
      requestorName: map['requestor_name'],
      requestorLocation: map['requestor_location'],
      subject: map['subject'],
      incomingImages: (map['incoming_images'] as String).isEmpty ? [] : (map['incoming_images'] as String).split(';'),
      responseImages: (map['response_images'] as String).isEmpty ? [] : (map['response_images'] as String).split(';'),
      forwardedDept: map['forwarded_dept'],
      forwardedPerson: map['forwarded_person'],
      expectedClosureDate: map['expected_closure_date'],
      responseSentDate: map['response_sent_date'],
      actualClosureDate: map['actual_closure_date'],
      status: map['status'],
      remarks: map['remarks'],
      followupDate: map['followup_date'],
    );
  }
}

