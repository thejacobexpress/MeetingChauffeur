import 'package:meeting_summarizer_app/classes/GroupClass.dart';
import 'package:meeting_summarizer_app/classes/Recipient.dart';

/// Contains all of the ```IndividualClass``` instances that exist.
List<IndividualClass> individuals = [
  IndividualClass("Jacob Express", "thejacobexpress@gmail.com", "This person is the Chief Financial Officer of McKee Co."),
  IndividualClass("Jacob Work", "mckeejacob23@gmail.com", "This person is the Chief Marketing officer of McKee Co."),
  IndividualClass("Jacob Scholar", "jacobmckee192@gmail.com", ""),
];

/// A class representing an individual recipient.
class IndividualClass extends Recipient{

  /// The email for this individual represented as a string.
  String contact;

  /// The groups that this individual is a part of.
  List<GroupClass> groupsList = [];

  IndividualClass(super.name, this.contact, [super.info]);

  /// Returns the list of groups that this individual is a part of.
  List<GroupClass> getGroups() {
    List<GroupClass> list = [];
    for(final group in groups) {
      for(final individual in group.individuals) {
        if(individual == this) {
          list.add(group);
          break;
        }
      }
    }
    return list;
  }

}