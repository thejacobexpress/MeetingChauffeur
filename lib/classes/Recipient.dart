/// The list of current recipients that the user has selected.
List<Recipient> recipients = [];

/// A class representing a recipient for the generated meeting info, which can be an ```IndividualClass``` or a ```GroupClass```.
class Recipient {
  
  /// Name of the recipient.
  String name;

  /// Info for the recipient, used to provide more in-depth generations by checking the ```json['tailored']``` key.
  String info;

  Recipient(this.name, [this.info = ""]);

}